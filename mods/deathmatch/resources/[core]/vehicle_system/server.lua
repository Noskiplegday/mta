-- Hàm lấy kết nối MySQL từ resource mysql của bạn
function getDB()
    local mysqlResource = getResourceFromName("mysql")
    if mysqlResource and getResourceState(mysqlResource) == "running" then
        return exports["mysql"]:getConnection()
    end
    return false
end

-- 1. TỰ ĐỘNG NẠP TOÀN BỘ XE TỪ DATABASE LÊN KHI SERVER KHỞI ĐỘNG
addEventHandler("onResourceStart", resourceRoot, function()
    local db = getDB()
    if not db then return end

    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        if not result then return end

        for _, row in ipairs(result) do
            -- Tạo xe ra thế giới game dựa trên tọa độ lưu trong DB
            local veh = createVehicle(row.model_id, row.pos_x, row.pos_y, row.pos_z, 0, 0, row.pos_rot)
            if veh then
                -- Đặt màu sắc và trạng thái khóa
                setVehicleColor(veh, row.color_r, row.color_g, row.color_b)
                setVehicleLocked(veh, row.locked == 1)
                
                -- Gắn dữ liệu ngầm vào chiếc xe để quản lý
                setElementData(veh, "veh:id", row.id)
                setElementData(veh, "veh:owner", row.owner_id)
            end
        end
        outputDebugString("[VEHICLE] Đã nạp thành công " .. #result .. " chiếc xe từ Database lên bản đồ!")
    end, db, "SELECT * FROM vehicles")
end)

-- 2. LỆNH MUA XE (/buyvehicle [Model ID])
addCommandHandler("buyvehicle", function(player, cmd, modelID)
    local charID = getElementData(player, "char:id") -- ID tài khoản người chơi
    local db = getDB()
    
    if not charID or not db then return end
    if not modelID then
        outputChatBox("Sử dụng: /buyvehicle [ID xe] (Ví dụ: 411 là xe Infernus)", player, 255, 200, 0)
        return
    end

    modelID = tonumber(modelID)
    local x, y, z = getElementPosition(player)
    local _, _, rot = getElementRotation(player)
    
    -- Giả định giá xe đồng giá 20,000$, check tiền người chơi
    local playerMoney = getPlayerMoney(player)
    if playerMoney < 20000 then
        outputChatBox("#FF0000[Cửa Hàng] Bạn không đủ 20,000$ để mua chiếc xe này!", player, 255, 255, 255, true)
        return
    end

    -- Trừ tiền người chơi
    takePlayerMoney(player, 20000)

    -- Thêm xe vào Database
    dbExec(db, "INSERT INTO vehicles (owner_id, model_id, pos_x, pos_y, pos_z, pos_rot) VALUES (?, ?, ?, ?, ?, ?)", 
        charID, modelID, x + 2, y + 2, z, rot) -- Spawn lệch ra một chút tránh đè lên người

    -- Lấy lại ID xe vừa tạo trong DB để spawn xe ra game luôn
    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        if result and #result > 0 then
            local lastVeh = result[1]
            local veh = createVehicle(lastVeh.model_id, lastVeh.pos_x, lastVeh.pos_y, lastVeh.pos_z, 0, 0, lastVeh.pos_rot)
            
            if veh then
                setElementData(veh, "veh:id", lastVeh.id)
                setElementData(veh, "veh:owner", charID)
                outputChatBox("#00FF00[Cửa Hàng] Mua xe thành công! Chi phí: 20,000$. Bấm 'K' để Khóa/Mở khóa.", player, 255, 255, 255, true)
            end
        end
    end, db, "SELECT * FROM vehicles WHERE owner_id = ? ORDER BY id DESC LIMIT 1", charID)
end)

-- 3. TỰ ĐỘNG LƯU VỊ TRÍ XE KHI SERVER TẮT HOẶC RESTART RESOURCE
addEventHandler("onResourceStop", resourceRoot, function()
    local db = getDB()
    if not db then return end

    -- ĐÃ FIX DÒNG NÀY: Loại bỏ chữ 'do' vô duyên ở giữa vòng lặp
    for _, veh in ipairs(getElementsByType("vehicle")) do
        local dbID = getElementData(veh, "veh:id")
        if dbID then
            local x, y, z = getElementPosition(veh)
            local _, _, rot = getElementRotation(veh)
            local locked = isVehicleLocked(veh) and 1 or 0
            
            -- Cập nhật tọa độ thực tế hiện tại của xe vào MySQL
            dbExec(db, "UPDATE vehicles SET pos_x = ?, pos_y = ?, pos_z = ?, pos_rot = ?, locked = ? WHERE id = ?", 
                x, y, z, rot, locked, dbID)
        end
    end
    outputDebugString("[VEHICLE] Đã lưu vị trí toàn bộ xe vào Database thành công!")
end)

-- 4. LOGIC KHÓA / MỞ KHÓA XE (Người chơi ấn phím K)
addCommandHandler("lockvehicle", function(player, cmd)
    local charID = getElementData(player, "char:id")
    if not charID then return end

    local px, py, pz = getElementPosition(player)
    local targetVehicle = nil

    -- Tìm chiếc xe gần người chơi nhất trong bán kính 4 mét
    for _, veh in ipairs(getElementsByType("vehicle")) do
        local vx, vy, vz = getElementPosition(veh)
        if getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz) <= 4 then
            -- Kiểm tra xem người chơi này có phải chủ xe không
            if getElementData(veh, "veh:owner") == charID then
                targetVehicle = veh
                break
            end
        end
    end

    -- Tiến hành đóng/mở khóa xe
    if targetVehicle then
        local isLocked = isVehicleLocked(targetVehicle)
        setVehicleLocked(targetVehicle, not isLocked) -- Đảo ngược trạng thái khóa
        
        if not isLocked then
            outputChatBox("#FFCC00[Xe Cá Nhân] Bạn đã KHÓA chiếc xe của mình.", player, 255, 255, 255, true)
        else
            outputChatBox("#00FF00[Xe Cá Nhân] Bạn đã MỞ KHÓA chiếc xe của mình.", player, 255, 255, 255, true)
        end
    else
        outputChatBox("#FF0000[Lỗi] Không tìm thấy chiếc xe nào của bạn ở gần đây!", player, 255, 255, 255, true)
    end
end)