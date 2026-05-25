-- Hàm lấy kết nối từ resource mysql của bạn
function getDB()
    local mysqlResource = getResourceFromName("mysql")
    if mysqlResource and getResourceState(mysqlResource) == "running" then
        return exports["mysql"]:getConnection()
    end
    return false
end

-- Định nghĩa thông tin vật phẩm (ID, Tên, Loại, Giá trị sử dụng)
local itemConfig = {
    [1] = {name = "Bánh Mì", type = "food", value = 30},     -- Hồi 30 máu
    [2] = {name = "Nước Suối", type = "drink", value = 20},   -- Hồi 20 máu
    [3] = {name = "Băng Gạc", type = "medkit", value = 50},   -- Hồi 50 máu
    [4] = {name = "Súng M4", type = "weapon", weaponID = 31, ammo = 90} -- Đưa súng M4, 90 viên đạn
}

-- Hàm load túi đồ của người chơi gửi về Client
addEvent("inventory:requestLoad", true)
addEventHandler("inventory:requestLoad", root, function()
    local player = source
    local charID = getElementData(player, "char:id")
    local db = getDB()
    
    if not charID or not db then return end
    
    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        -- Gửi toàn bộ mảng vật phẩm về Client để vẽ lên UI
        triggerClientEvent(player, "inventory:receiveData", player, result or {})
    end, db, "SELECT * FROM inventory WHERE char_id = ?", charID)
end)

-- Hàm thêm vật phẩm vào túi đồ (Exported)
function givePlayerItem(player, itemID, count)
    local charID = getElementData(player, "char:id")
    local db = getDB()
    if not charID or not db or not itemConfig[itemID] then return false end
    
    -- Tìm xem túi đồ còn ô trống không (Tối đa 30 ô)
    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        local usedSlots = {}
        for _, row in ipairs(result) do
            usedSlots[row.slot_id] = true
            -- Nếu item đã có sẵn, cộng dồn số lượng (Tính năng Stack)
            if row.item_id == itemID and itemConfig[itemID].type ~= "weapon" then
                dbExec(db, "UPDATE inventory SET item_count = item_count + ? WHERE id = ?", count, row.id)
                triggerEvent("inventory:requestLoad", player) -- Reload UI
                return
            end
        end
        
        -- Tìm ô (slot) trống đầu tiên từ 1 đến 30
        local freeSlot = nil
        for i = 1, 30 do
            if not usedSlots[i] then
                freeSlot = i
                break
            end
        end
        
        if freeSlot then
            dbExec(db, "INSERT INTO inventory (char_id, item_id, item_count, slot_id) VALUES (?, ?, ?, ?)", charID, itemID, count, freeSlot)
            triggerEvent("inventory:requestLoad", player)
        else
            outputChatBox("#FF0000[Inventory] Túi đồ của bạn đã đầy!", player, 255, 255, 255, true)
        end
    end, db, "SELECT * FROM inventory WHERE char_id = ?", charID)
end

-- Hàm xử lý khi người chơi double click dùng vật phẩm từ UI Client gửi lên
addEvent("inventory:useItem", true)
addEventHandler("inventory:useItem", root, function(dbID, itemID)
    local player = source
    local db = getDB()
    if not db or not itemConfig[itemID] then return end
    
    local item = itemConfig[itemID]
    
    -- Kiểm tra lại trong DB xem người chơi thực sự có vật phẩm này không
    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        if not result or #result == 0 then return end
        
        local currentCount = result[1].item_count
        
        -- XỬ LÝ LOGIC SỬ DỤNG THEO LOẠI VẬT PHẨM
        if item.type == "food" or item.type == "drink" or item.type == "medkit" then
            local currentHealth = getElementHealth(player)
            setElementHealth(player, math.min(100, currentHealth + item.value))
            outputChatBox("#00FF00[Inventory] Bạn đã sử dụng " .. item.name .. ".", player, 255, 255, 255, true)
        elseif item.type == "weapon" then
            giveWeapon(player, item.weaponID, item.ammo, true)
            outputChatBox("#00FF00[Inventory] Bạn đã trang bị súng " .. item.name .. ".", player, 255, 255, 255, true)
        end
        
        -- CẬP NHẬT SỐ LƯỢNG TRONG DATABASE
        if currentCount > 1 then
            dbExec(db, "UPDATE inventory SET item_count = item_count - 1 WHERE id = ?", dbID)
        else
            dbExec(db, "DELETE FROM inventory WHERE id = ?", dbID)
        end
        
        -- Nạp lại giao diện mới sau khi dùng
        triggerEvent("inventory:requestLoad", player)
        
    end, db, "SELECT * FROM inventory WHERE id = ? LIMIT 1", dbID)
end)

-- Tạo lệnh nhận đồ test thử nhanh gõ in-game (/getitems)
addCommandHandler("getitems", function(player, cmd)
    givePlayerItem(player, 1, 2) -- Tặng 2 bánh mì
    givePlayerItem(player, 4, 1) -- Tặng 1 khẩu M4
    outputChatBox("#00FF00[Inventory] Đã cấp vật phẩm test. Bấm 'I' để mở túi đồ!", player, 255, 255, 255, true)
end)