-- help_system/client.lua
local screenW, screenH = guiGetScreenSize()
local scale = screenH / 768 -- Responsive scale

local isHelpOpen = false
local currentTab = "xe" -- Tab mặc định khi mở bảng

-- Danh sách lệnh chia theo các chuyên mục hiển thị trên giao diện
local helpCommands = {
    xe = {
        title = "HỆ THỐNG LỆNH XE CỘ",
        commands = {
            { cmd = "/engine hoặc nút M", desc = "Bật / Tắt động cơ phương tiện" },
            { cmd = "/buyvehicle", desc = "Mua xe mới" },
            { cmd = "/lock hoặc nút K", desc = "Khóa / Mở khóa cửa xe cá nhân" },
            { cmd = "/seatbelt hoặc nút G", desc = "Thắt / Tháo dây an toàn khi ngồi trên xe" },
            { cmd = "/hood hoặc Shift + ,", desc = "Mở / Đóng nắp capo xe" },
            { cmd = "/trunk hoặc Shift + .", desc = "Mở / Đóng cốp xe (Cất/lấy đồ đạc)" },
            { cmd = "/lights hoặc Shift + L", desc = "Bật / Tắt đèn pha thủ công" },
        }
    },
    ban_than = {
        title = "LỆNH CÁ NHÂN & CHUNG",
        commands = {
            { cmd = "/an", desc = "Ăn thức ăn để hồi phục thanh Đói" },
            { cmd = "/uong", desc = "Uống nước để hồi phục thanh Khát" },
            { cmd = "/id", desc = "Xem ID của bản thân và người chơi xung quanh" },
            { cmd = "/pay [ID] [Số tiền]", desc = "Chuyển tiền mặt cho người đứng gần" },
            { cmd = "Phím F7", desc = "Ẩn / Hiện thanh giao diện (HUD)" },
            { cmd = "Phím T hoặc `", desc = "Mở khung Chat hệ thống" },
        }
    }
}

-- Hàm vẽ khung nền
local function drawRoundRect(x, y, w, h, col)
    dxDrawRectangle(x, y, w, h, col)
end

addEventHandler("onClientRender", root, function()
    if not isHelpOpen then return end

    -- Kích thước bảng Help (Chuẩn kích thước gọn gàng)
    local w, h = 550 * scale, 400 * scale
    local x, y = (screenW - w) / 2, (screenH - h) / 2

    -- Khung nền chính (Đen mờ biên Neon Đỏ theo phong cách VanCanhCity)
    drawRoundRect(x, y, w, h, tocolor(10, 10, 10, 230))
    dxDrawRectangle(x, y, w, 2 * scale, tocolor(231, 76, 60, 255)) -- Viền Neon Đỏ phía trên
    dxDrawRectangle(x, y + h - 2 * scale, w, 2 * scale, tocolor(231, 76, 60, 100))

    -- Tiêu đề chính
    dxDrawText("VAN CANH CITY — BẢNG TRỢ GIÚP", x, y + 15 * scale, x + w, y + 40 * scale, 
        tocolor(255, 255, 255, 255), scale * 1.2, "default-bold", "center", "top")
    
    -- Gợi ý nút tắt
    dxDrawText("Bấm [ F1 ] để ĐÓNG bảng trợ giúp", x, y + h - 25 * scale, x + w, y + h, 
        tocolor(150, 150, 150, 255), scale * 0.75, "default-bold", "center", "top")

    -- ─── ĐỔI TAB BẰNG CHUỘT ───
    local tabW = 140 * scale
    local tabH = 30 * scale
    
    -- Tab Xe Cộ
    local tabXeColor = currentTab == "xe" and tocolor(231, 76, 60, 255) or tocolor(40, 40, 40, 255)
    drawRoundRect(x + 20 * scale, y + 55 * scale, tabW, tabH, tabXeColor)
    dxDrawText("🚗 Lệnh Xe Cộ", x + 20 * scale, y + 55 * scale, x + 20 * scale + tabW, y + 55 * scale + tabH,
        tocolor(255, 255, 255, 255), scale * 0.85, "default-bold", "center", "center")

    -- Tab Bản Thân
    local tabUserColor = currentTab == "ban_than" and tocolor(231, 76, 60, 255) or tocolor(40, 40, 40, 255)
    drawRoundRect(x + 170 * scale, y + 55 * scale, tabW, tabH, tabUserColor)
    dxDrawText("👤 Lệnh Cá Nhân", x + 170 * scale, y + 55 * scale, x + 170 * scale + tabW, y + 55 * scale + tabH,
        tocolor(255, 255, 255, 255), scale * 0.85, "default-bold", "center", "center")

    -- ─── HIỂN THỊ NỘI DUNG CHI TIẾT THEO TAB ───
    local activeData = helpCommands[currentTab]
    if activeData then
        dxDrawText(activeData.title, x + 25 * scale, y + 105 * scale, x + w, y + 130 * scale,
            tocolor(231, 76, 60, 255), scale * 0.9, "default-bold", "left")

        local startY = y + 130 * scale
        for i, item in ipairs(activeData.commands) do
            local itemY = startY + (i - 1) * 32 * scale
            
            -- Màu nền xen kẽ giữa các dòng cho dễ nhìn
            local rowBg = (i % 2 == 0) and tocolor(20, 20, 20, 150) or tocolor(30, 30, 30, 150)
            dxDrawRectangle(x + 20 * scale, itemY, w - 40 * scale, 26 * scale, rowBg)

            -- Cột lệnh (Màu xanh lá cây sáng)
            dxDrawText(item.cmd, x + 30 * scale, itemY, x + 220 * scale, itemY + 26 * scale,
                tocolor(231, 76, 60, 255), scale * 0.8, "default-bold", "left", "center")
            
            -- Cột mô tả
            dxDrawText("➔ " .. item.desc, x + 230 * scale, itemY, x + w - 30 * scale, itemY + 26 * scale,
                tocolor(220, 220, 220, 255), scale * 0.8, "default", "left", "center")
        end
    end
end)

-- Xử lý click đổi Tab
addEventHandler("onClientClick", root, function(button, state, absoluteX, absoluteY)
    if not isHelpOpen or state ~= "down" or button ~= "left" then return end

    local w, h = 550 * scale, 400 * scale
    local x, y = (screenW - w) / 2, (screenH - h) / 2
    local tabW, tabH = 140 * scale, 30 * scale

    -- Click Tab Xe
    if absoluteX >= x + 20 * scale and absoluteX <= x + 20 * scale + tabW and
       absoluteY >= y + 55 * scale and absoluteY <= y + 55 * scale + tabH then
        currentTab = "xe"
        playSoundFrontEnd(41)
    end

    -- Click Tab Cá Nhân
    if absoluteX >= x + 170 * scale and absoluteX <= x + 170 * scale + tabW and
       absoluteY >= y + 55 * scale and absoluteY <= y + 55 * scale + tabH then
        currentTab = "ban_than"
        playSoundFrontEnd(41)
    end
end)

-- Bấm F1 mở/tắt bảng Help
bindKey("F1", "down", function()
    isHelpOpen = not isHelpOpen
    showCursor(isHelpOpen)
    guiSetInputMode(isHelpOpen and "no_binds" or "allow_binds")
    playSoundFrontEnd(isHelpOpen and 11 or 12)
end)

-- ─── KHU VỰC ĐỒNG BỘ PHÍM TẮT CHO XE (SỬA ĐỔI ĐỒNG BỘ CHUẨN 100%) ────────────────────
local function sendVehicleCmd(cmdName)
    triggerServerEvent("vcc_vehicle:triggerCommand", localPlayer, cmdName)
end

-- Các phím đơn (Chỉ kích hoạt khi không mở khung chat để tránh lỗi gõ chữ)
bindKey("m", "down", function()
    if getPedOccupiedVehicle(localPlayer) and not isChatBoxInputActive() then
        sendVehicleCmd("engine")
    end
end)

bindKey("k", "down", function()
    if not isChatBoxInputActive() then
        sendVehicleCmd("lock")
    end
end)

bindKey("g", "down", function()
    if getPedOccupiedVehicle(localPlayer) and not isChatBoxInputActive() then
        sendVehicleCmd("seatbelt")
    end
end)

-- Phím Shift + , (Dấu phẩy) để mở Hood (Nắp capo)
bindKey(",", "down", function()
    if (getKeyState("lshift") or getKeyState("rshift")) and getPedOccupiedVehicle(localPlayer) and not isChatBoxInputActive() then
        sendVehicleCmd("hood")
    end
end)

-- Phím Shift + . (Dấu chấm) để mở Trunk (Cốp xe)
bindKey(".", "down", function()
    if (getKeyState("lshift") or getKeyState("rshift")) and getPedOccupiedVehicle(localPlayer) and not isChatBoxInputActive() then
        sendVehicleCmd("trunk")
    end
end)

-- Phím Shift + L để bật/tắt Đèn xe (Tránh trùng chữ l khi gõ văn bản chat thông thường)
bindKey("l", "down", function()
    if (getKeyState("lshift") or getKeyState("rshift")) and getPedOccupiedVehicle(localPlayer) and not isChatBoxInputActive() then
        sendVehicleCmd("lights")
    end
end)