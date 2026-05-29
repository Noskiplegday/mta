
-- vehicle/server.lua
local spawnedVehicles = {} -- Bảng tạm để quản lý các xe đang chạy trên server

function getDB()
    local mysqlResource = getResourceFromName("mysql")
    if mysqlResource and getResourceState(mysqlResource) == "running" then
        return exports["mysql"]:getConnection()
    end
    return false
end

-- Helper function to find the nearest vehicle
local function getNearestVehicle(player, radius)
    local x, y, z = getElementPosition(player)
    local nearestVehicle = false
    local minDist = radius or 5
    for _, veh in ipairs(getElementsByType("vehicle")) do
        local vx, vy, vz = getElementPosition(veh)
        local dist = getDistanceBetweenPoints3D(x, y, z, vx, vy, vz)
        if dist < minDist then
            minDist = dist
            nearestVehicle = veh
        end
    end
    return nearestVehicle
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
function lockVehicle(player)
    local charID = getElementData(player, "char:id")
    if not charID then return end

    local veh = getPedOccupiedVehicle(player) or getNearestVehicle(player)

    if veh and getElementData(veh, "veh:owner") == charID then
        setElementData(veh, "veh:locked", 1)
        setVehicleLocked(veh, true)
        outputChatBox("#FF4444* Bạn đã KHÓA cửa chiếc xe của mình. *", player, 255, 255, 255, true)
        
        local db = getDB()
        if db then dbExec(db, "UPDATE vehicles SET locked = 1 WHERE id = ?", getElementData(veh, "veh:id")) end
    else
        outputChatBox("#FF0000[Lỗi] Không tìm thấy xe của bạn ở gần đây!", player, 255, 255, 255, true)
    end
end
addCommandHandler("lock", lockVehicle)

function unlockVehicle(player)
    local charID = getElementData(player, "char:id")
    if not charID then return end

    local veh = getPedOccupiedVehicle(player) or getNearestVehicle(player)

    if veh and getElementData(veh, "veh:owner") == charID then
        setElementData(veh, "veh:locked", 0)
        setVehicleLocked(veh, false)
        outputChatBox("#00FF00* Bạn đã MỞ KHÓA cửa chiếc xe của mình. *", player, 255, 255, 255, true)
        
        local db = getDB()
        if db then dbExec(db, "UPDATE vehicles SET locked = 0 WHERE id = ?", getElementData(veh, "veh:id")) end
    else
        outputChatBox("#FF0000[Lỗi] Không tìm thấy xe của bạn ở gần đây!", player, 255, 255, 255, true)
    end
end
addCommandHandler("unlock", unlockVehicle)

-- 4. LOGIC ĐỘNG CƠ XE
function toggleEngine(player)
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
end
addCommandHandler("engine", toggleEngine)

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
function toggleHood(player)
    local veh = getPedOccupiedVehicle(player) or getNearestVehicle(player)

    if not veh then
        outputChatBox("#FF4444Không có xe gần bạn!", player, 255, 255, 255, true)
        return
    end

    local ratio = getVehicleDoorOpenRatio(veh, 0)

    if ratio > 0 then
        setVehicleDoorOpenRatio(veh, 0, 0, 1000)
        outputChatBox("#FF4444Đã đóng capo.", player, 255, 255, 255, true)
    else
        setVehicleDoorOpenRatio(veh, 0, 1, 1000)
        outputChatBox("#00FF00Đã mở capo.", player, 255, 255, 255, true)
    end
end
addCommandHandler("hood", toggleHood)

-- 7. LỆNH MỞ/ĐÓNG CỐP XE (/trunk)
function toggleTrunk(player)
    local veh = getPedOccupiedVehicle(player) or getNearestVehicle(player)

    if not veh then
        outputChatBox("#FF4444Không có xe gần bạn!", player, 255, 255, 255, true)
        return
    end

    local ratio = getVehicleDoorOpenRatio(veh, 1)

    if ratio > 0 then
        setVehicleDoorOpenRatio(veh, 1, 0, 1000)
        outputChatBox("#FF4444Đã đóng cốp.", player, 255, 255, 255, true)
    else
        setVehicleDoorOpenRatio(veh, 1, 1, 1000)
        outputChatBox("#00FF00Đã mở cốp.", player, 255, 255, 255, true)
    end
end
addCommandHandler("trunk", toggleTrunk)

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

addEvent("vehicle:lock", true)
addEvent("vehicle:unlock", true)
addEvent("vehicle:engine", true)
addEvent("vehicle:hood", true)
addEvent("vehicle:trunk", true)
addEvent("vehicle:lights", true)
addEvent("vehicle:radio", true)

addEventHandler("vehicle:lock", root, function()
    -- Sử dụng lại function lockVehicle đã viết ở trên để đồng bộ Logic và Database
    lockVehicle(source)
end)

addEventHandler("vehicle:unlock", root, function()
    -- Sử dụng lại function unlockVehicle để đồng bộ Logic và Database
    unlockVehicle(source)
end)

addEventHandler("vehicle:engine", root, function()
    toggleEngine(source)
end)

addEventHandler("vehicle:hood", root, function()
    toggleHood(source)
end)

addEventHandler("vehicle:trunk", root, function()
    toggleTrunk(source)
end)

addEventHandler("vehicle:lights", root, function()
    local veh = getPedOccupiedVehicle(source)
    if not veh then return end

    local state = getVehicleOverrideLights(veh)
    if state == 2 then
        setVehicleOverrideLights(veh, 1)
        outputChatBox("#FF4444Đã tắt đèn.", source, 255, 255, 255, true)
    else
        setVehicleOverrideLights(veh, 2)
        outputChatBox("#00FF00Đã bật đèn.", source, 255, 255, 255, true)
    end
end)

addEventHandler("vehicle:radio", root, function()
    local veh = getPedOccupiedVehicle(source)
    if not veh then return end

    local radio = getElementData(veh, "vehicle:radio")
    radio = not radio
    setElementData(veh, "vehicle:radio", radio)

    if radio then
        outputChatBox("#00FF00Radio đã bật.", source, 255, 255, 255, true)
    else
        outputChatBox("#FF4444Radio đã tắt.", source, 255, 255, 255, true)
    end
end)
