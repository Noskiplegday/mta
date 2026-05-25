local screenW, screenH = guiGetScreenSize()
local isVisible = false
local inventoryData = {}

-- Cấu hình kích thước giao diện
local invW, invH = 500, 400
local invX, invY = (screenW - invW) / 2, (screenH - invH) / 2
local slotSize = 70
local padding = 10

-- Lưu vị trí các ô để bắt sự kiện Click chuột
local slotRects = {}

-- Danh mục tên vật phẩm đồng bộ từ server để hiện lên UI
local itemNames = {
    [1] = "Bánh Mì",
    [2] = "Nước Suối",
    [3] = "Băng Gạc",
    [4] = "Súng M4"
}

-- Hàm vẽ đồ họa Dx kéo lưới 30 ô (5 hàng x 6 cột)
function drawInventoryUI()
    if not isVisible then return end
    
    -- Vẽ khung nền chính của Túi Đồ (Màu đen xám trong suốt)
    dxDrawRectangle(invX, invY, invW, invH, tocolor(20, 20, 20, 220))
    dxDrawRectangle(invX, invY, invW, 40, tocolor(10, 10, 10, 255))
    dxDrawText("TÚI ĐỒ NHÂN VẬT (Bấm 'I' để đóng)", invX + 15, invY + 10, invW, invH, tocolor(255, 255, 255, 255), 1.1, "default-bold")
    
    slotRects = {} -- Reset danh sách tọa độ click
    
    -- Vẽ lưới 30 ô vật phẩm
    local startX = invX + 20
    local startY = invY + 60
    local columns = 6
    
    for i = 1, 30 do
        local row = math.floor((i - 1) / columns)
        local col = (i - 1) % columns
        
        local x = startX + col * (slotSize + padding)
        local y = startY + row * (slotSize + padding)
        
        -- Vẽ ô trống mặc định (Màu xám)
        dxDrawRectangle(x, y, slotSize, slotSize, tocolor(40, 40, 40, 150))
        
        -- Tìm xem ô (slot_id) này hiện tại đang có dữ liệu vật phẩm nào không
        local currentItem = nil
        for _, item in ipairs(inventoryData) do
            if item.slot_id == i then
                currentItem = item
                break
            end
        end
        
        -- Nếu ô có đồ, vẽ chữ tên đồ và số lượng lên ô đó
        if currentItem then
            local name = itemNames[currentItem.item_id] or "Vật phẩm"
            dxDrawText(name, x + 5, y + 15, x + slotSize - 5, y + slotSize, tocolor(255, 200, 0, 255), 0.9, "default-bold", "center", "top", true)
            dxDrawText("x" .. currentItem.item_count, x, y + slotSize - 15, x + slotSize - 5, y + slotSize, tocolor(255, 255, 255, 255), 0.9, "default", "right")
            
            -- Lưu lại thông tin tọa độ ô có đồ để lát nữa xử lý double click
            table.insert(slotRects, {x = x, y = y, w = slotSize, h = slotSize, dbID = currentItem.id, itemID = currentItem.item_id})
        end
    end
end

-- Nhận mảng dữ liệu từ Server gửi về và cập nhật vào UI
addHash = false
local lastClick = 0

registerClientEvent = addEvent("inventory:receiveData", true)
addEventHandler("inventory:receiveData", root, function(data)
    inventoryData = data
end)

-- Bắt sự kiện phím I để mở/đóng túi đồ
bindKey("i", "down", function()
    isVisible = not isVisible
    showCursor(isVisible)
    
    if isVisible then
        -- Gửi yêu cầu lên server bắt nạp dữ liệu từ MySQL về máy Client
        triggerServerEvent("inventory:requestLoad", localPlayer)
        addEventHandler("onClientRender", root, drawInventoryUI)
    else
        removeEventHandler("onClientRender", root, drawInventoryUI)
    end
end)

-- Xử lý sự kiện Double-click chuột để sử dụng vật phẩm
addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY)
    if not isVisible or button ~= "left" or state ~= "down" then return end
    
    local now = getTickCount()
    -- Kiểm tra xem khoảng cách giữa 2 lần click chuột có nhỏ hơn 300ms không (Định nghĩa Double Click)
    if now - lastClick < 300 then
        for _, rect in ipairs(slotRects) do
            if absoluteX >= rect.x and absoluteX <= rect.x + rect.w and absoluteY >= rect.y and absoluteY <= rect.y + rect.h then
                -- Phát lệnh lên server dùng vật phẩm ngay lập tức
                triggerServerEvent("inventory:useItem", localPlayer, rect.dbID, rect.itemID)
                break
            end
        end
    end
    lastClick = now
end)