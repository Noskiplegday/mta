-- vcc_vehicle/server.lua
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
                
                -- Khởi tạo mặc định động cơ tắt khi hồi sinh xe
                setVehicleEngineState(veh, false)
                setElementData(veh, "fuel", 100) -- Cấp xăng mặc định cho HUD nhận diện

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
            setVehicleEngineState(veh, false)
            setElementData(veh, "fuel", 100)
            
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

    -- Ưu tiên kiểm tra nếu đang ngồi trong xe trước
    local currentVeh = getPedOccupiedVehicle(player)
    if currentVeh and getElementData(currentVeh, "veh:owner") == charID then
        targetVehicle = currentVeh
    else
        -- Nếu đứng ngoài, tìm chiếc xe gần người chơi nhất trong bán kính 5 mét
        for _, veh in ipairs(getElementsByType("vehicle")) do
            local vX, vY, vZ = getElementPosition(veh)
            if getDistanceBetweenPoints3D(pX, pY, pZ, vX, vY, vZ) <= 5 then
                if getElementData(veh, "veh:owner") == charID then
                    targetVehicle = veh
                    break
                end
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

-- 4. LỆNH BẬT / TẮT ĐỘNG CƠ XE (/engine)
addCommandHandler("engine", function(player, cmd)
    local veh = getPedOccupiedVehicle(player)
    if not veh then 
        outputChatBox("#FF0000[Lỗi] Bạn phải ngồi trên xe mới có thể bật/tắt động cơ!", player, 255, 255, 255, true)
        return 
    end

    -- Chỉ cho phép người ngồi ghế lái (ghế số 0) điều khiển động cơ
    if getVehicleController(veh) ~= player then return end

    local charID = getElementData(player, "char:id")
    if getElementData(veh, "veh:owner") ~= charID then
        outputChatBox("#FF0000[Lỗi] Bạn không có chìa khóa chiếc xe này!", player, 255, 255, 255, true)
        return
    end

    local currentState = getVehicleEngineState(veh)
    if currentState then
        setVehicleEngineState(veh, false)
        outputChatBox("#FF9900* Bạn đã tắt động cơ phương tiện. *", player, 255, 255, 255, true)
    else
        setVehicleEngineState(veh, true)
        outputChatBox("#00FF00* Động cơ phương tiện đã được khởi động. *", player, 255, 255, 255, true)
    end
end)

-- 5. LỆNH THẮT DÂY AN TOÀN (/seatbelt)
addCommandHandler("seatbelt", function(player, cmd)
    local veh = getPedOccupiedVehicle(player)
    if not veh then 
        outputChatBox("#FF0000[Lỗi] Bạn phải ngồi trong xe mới có thể sử dụng dây an toàn!", player, 255, 255, 255, true)
        return 
    end

    -- Đổi trạng thái dây an toàn (Lưu vào element data để đồng bộ hoặc xử lý va đập)
    local currentBelt = getElementData(player, "seatbelt") or false
    if currentBelt then
        setElementData(player, "seatbelt", false)
        outputChatBox("#FF9900* Bạn đã tháo dây an toàn. *", player, 255, 255, 255, true)
    else
        setElementData(player, "seatbelt", true)
        outputChatBox("#00FF00* Bạn đã thắt dây an toàn chặt chẽ. *", player, 255, 255, 255, true)
    end
end)

-- 6. LỆNH MỞ/ĐÓNG NẮP CAPO (/hood)
addCommandHandler("hood", function(player, cmd)
    local veh = getPedOccupiedVehicle(player)
    if not veh then return end
    if getVehicleController(veh) ~= player then return end

    local currentRatio = getVehicleOpenRatio(veh, 0) -- Khớp số 0 là nắp Capo (Hood)
    if currentRatio == 0 then
        setVehicleOpenRatio(veh, 0, 1, 500) -- Mở ra trong 500ms
        outputChatBox("#00FF00* Bạn đã mở nắp capo xe. *", player, 255, 255, 255, true)
    else
        setVehicleOpenRatio(veh, 0, 0, 500) -- Đóng lại
        outputChatBox("#FF9900* Bạn đã đóng nắp capo xe. *", player, 255, 255, 255, true)
    end
end)

-- 7. LỆNH MỞ/ĐÓNG CỐP XE (/trunk)
addCommandHandler("trunk", function(player, cmd)
    local veh = getPedOccupiedVehicle(player)
    if not veh then return end
    if getVehicleController(veh) ~= player then return end

    local currentRatio = getVehicleOpenRatio(veh, 1) -- Khớp số 1 là Cốp xe (Trunk)
    if currentRatio == 0 then
        setVehicleOpenRatio(veh, 1, 1, 500)
        outputChatBox("#00FF00* Bạn đã mở cốp xe. *", player, 255, 255, 255, true)
    else
        setVehicleOpenRatio(veh, 1, 0, 500)
        outputChatBox("#FF9900* Bạn đã đóng cốp xe. *", player, 255, 255, 255, true)
    end
end)

-- 8. LỆNH BẬT/TẮT ĐÈN XE THỦ CÔNG (/lights)
addCommandHandler("lights", function(player, cmd)
    local veh = getPedOccupiedVehicle(player)
    if not veh then return end
    if getVehicleController(veh) ~= player then return end

    local currentLights = getVehicleOverrideLights(veh)
    if currentLights == 2 then -- 2 có nghĩa là Đang Bật Đèn cưỡng bức
        setVehicleOverrideLights(veh, 1) -- 1 có nghĩa là Tắt Đèn cưỡng bức
        outputChatBox("#FF9900* Bạn đã tắt đèn xe. *", player, 255, 255, 255, true)
    else
        setVehicleOverrideLights(veh, 2)
        outputChatBox("#00FF00* Bạn đã bật đèn xe. *", player, 255, 255, 255, true)
    end
end)

-- 9. TỰ ĐỘNG LƯU VỊ TRÍ XE KHI SERVER TẮT (SHUTDOWN)
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