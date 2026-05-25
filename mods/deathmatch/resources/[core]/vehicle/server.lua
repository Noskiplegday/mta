local spawnedVehicles = {} -- Bảng tạm để quản lý các xe đang chạy trên server

function getDB()
    local mysqlResource = getResourceFromName("mysql")
    if mysqlResource and getResourceState(mysqlResource) == "running" then
        return exports["mysql"]:getConnection()
    end
    return false
end

-- 1. TỰ ĐỘNG SPAWN TẤT CẢ XE KHI SERVER KHỞI ĐỘNG
function loadAllVehicles()
    local db = getDB()
    if not db then return end

    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        for _, row in ipairs(result) do
            local veh = createVehicle(row.model, row.pos_x, row.pos_y, row.pos_z, 0, 0, row.pos_rot)
            if veh then
                setVehicleColor(veh, row.color_r, row.color_g, row.color_b)
                setElementData(veh, "veh:id", row.id)
                setElementData(veh, "veh:owner", row.char_id)
                setElementData(veh, "veh:locked", row.locked)
                
                if row.locked == 1 then
                    setVehicleLocked(veh, true)
                end
                spawnedVehicles[row.id] = veh
            end
        end
        outputDebugString("[VEHICLE] Da tai tat ca xe tu database len map!")
    end, db, "SELECT * FROM vehicles")
end
addEventHandler("onResourceStart", resourceRoot, loadAllVehicles)

-- 2. LỆNH ADMIN TẠO XE MỚI (/createvehicle [ID Xe])
addCommandHandler("createvehicle", function(player, cmd, modelID)
    local charID = getElementData(player, "char:id") -- Lấy ID nhân vật của bạn
    if not charID then return end
    
    modelID = tonumber(modelID)
    if not modelID or modelID < 400 or modelID > 611 then
        outputChatBox("Cú pháp: /createvehicle [400 - 611]", player, 255, 0, 0)
        return
    end

    local db = getDB()
    if not db then return end

    local x, y, z = getElementPosition(player)
    local _, _, rot = getElementRotation(player)
    x = x + 2 -- Tạo xe dịch ra trước mặt một chút

    -- Lưu xe mới vào database trước
    dbExec(db, "INSERT INTO vehicles (char_id, model, pos_x, pos_y, pos_z, pos_rot) VALUES (?, ?, ?, ?, ?, ?)", 
        charID, modelID, x, y, z, rot)

    -- Lấy ID xe vừa tạo để spawn ra game
    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        if #result > 0 then
            local vehData = result[1]
            local veh = createVehicle(vehData.model, vehData.pos_x, vehData.pos_y, vehData.pos_z, 0, 0, vehData.pos_rot)
            
            setElementData(veh, "veh:id", vehData.id)
            setElementData(veh, "veh:owner", charID)
            setElementData(veh, "veh:locked", 0)
            
            outputChatBox("#00FF00[VanCanhCity] Bạn đã tạo xe thành công! ID Xe của bạn là: " .. vehData.id, player, 255, 255, 255, true)
        end
    end, db, "SELECT * FROM vehicles WHERE char_id = ? ORDER BY id DESC LIMIT 1", charID)
end)

-- 3. LỆNH KHÓA/MỞ KHÓA XE (/lock)
addCommandHandler("lock", function(player, cmd)
    local charID = getElementData(player, "char:id")
    if not charID then return end

    local pX, pY, pZ = getElementPosition(player)
    local targetVehicle = false

    -- Tìm chiếc xe gần người chơi nhất trong bán kính 5 mét
    for _, veh in ipairs(getElementsByType("vehicle")) do
        local vX, vY, vZ = getElementPosition(veh)
        if getDistanceBetweenPoints3D(pX, pY, pZ, vX, vY, vZ) <= 5 then
            if getElementData(veh, "veh:owner") == charID then
                targetVehicle = veh
                break
            end
        end
    end

    if targetVehicle then
        local currentLock = getElementData(targetVehicle, "veh:locked") or 0
        local vehID = getElementData(targetVehicle, "veh:id")
        local db = getDB()

        if currentLock == 0 then
            -- Tiến hành khóa
            setElementData(targetVehicle, "veh:locked", 1)
            setVehicleLocked(targetVehicle, true)
            outputChatBox("#FF9900* Bạn đã KHÓA cửa chiếc xe của mình. *", player, 255, 255, 255, true)
            if db then dbExec(db, "UPDATE vehicles SET locked = 1 WHERE id = ?", vehID) end
        else
            -- Tiến hành mở khóa
            setElementData(targetVehicle, "veh:locked", 0)
            setVehicleLocked(targetVehicle, false)
            outputChatBox("#00FF00* Bạn đã MỞ KHÓA cửa chiếc xe của mình. *", player, 255, 255, 255, true)
            if db then dbExec(db, "UPDATE vehicles SET locked = 0 WHERE id = ?", vehID) end
        end
    else
        outputChatBox("#FF0000[Lỗi] Không tìm thấy xe của bạn ở gần đây!", player, 255, 255, 255, true)
    end
end)

-- 4. TỰ ĐỘNG LƯU VỊ TRÍ XE KHI SERVER TẮT (SHUTDOWN)
addEventHandler("onResourceStop", resourceRoot, function()
    local db = getDB()
    if not db then return end

    for _, veh in ipairs(getElementsByType("vehicle")) do
        local vehID = getElementData(veh, "veh:id")
        if vehID then
            local x, y, z = getElementPosition(veh)
            local _, _, rot = getElementRotation(veh)
            dbExec(db, "UPDATE vehicles SET pos_x = ?, pos_y = ?, pos_z = ?, pos_rot = ? WHERE id = ?", 
                x, y, z, rot, vehID)
        end
    end
    outputDebugString("[VEHICLE] Da luu lai toan bo vi tri xe vao database truoc khi tat resource!")
end)