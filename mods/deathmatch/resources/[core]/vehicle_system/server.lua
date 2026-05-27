-- Hàm lấy kết nối MySQL từ resource mysql của bạn
function getDB()
    local mysqlResource = getResourceFromName("mysql")
    if mysqlResource and getResourceState(mysqlResource) == "running" then
        return exports["mysql"]:getConnection()
    end
    return false
end

-- [TÍNH NĂNG 3]: BỎ TỰ ĐỘNG SPAWN XE KHI START RESOURCE ĐỂ TRÁNH LAG MAP
addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[VEHICLE] Hệ thống xe đã sẵn sàng. Người chơi dùng /spawnveh để gọi xe!")
    
    -- Khởi động vòng lặp kiểm tra tiêu hao xăng (Mỗi 10 giây kiểm tra 1 lần)
    setTimer(function()
        for _, veh in ipairs(getElementsByType("vehicle")) do
            -- Nếu xe đang nổ máy (Engine = true)
            if getVehicleEngineState(veh) then
                local fuel = getElementData(veh, "veh:fuel") or 100
                if fuel > 0 then
                    fuel = fuel - 1 -- Mỗi 10 giây trừ 1% xăng
                    setElementData(veh, "veh:fuel", fuel)
                    
                    -- Nếu hết xăng thì tắt máy xe
                    if fuel <= 0 then
                        setVehicleEngineState(veh, false)
                        local driver = getVehicleController(veh)
                        if driver then
                            outputChatBox("#FF0000[Xe Cá Nhân] Xe của bạn đã hết xăng và chết máy!", driver, 255, 255, 255, true)
                        end
                    end
                end
            end
        end
    end, 10000, 0)
end)

-- [TÍNH NĂNG 3]: LỆNH GỌI XE (/spawnveh)
addCommandHandler("spawnveh", function(player, cmd)
    local charID = getElementData(player, "char:id")
    local db = getDB()
    if not charID or not db then return end

    -- Kiểm tra xem người chơi đã gọi chiếc xe nào ra chưa (Tránh gọi trùng xe)
    for _, v in ipairs(getElementsByType("vehicle")) do
        if getElementData(v, "veh:owner") == charID then
            outputChatBox("#FF0000[Lỗi] Bạn đã gọi xe của mình ra map rồi!", player, 255, 255, 255, true)
            return
        end
    end

    -- Lấy vị trí bến đỗ (hoặc vị trí lưu cũ) từ DB lên để spawn
    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        if result and #result > 0 then
            local row = result[1]
            local modelID = tonumber(row.model)
            
            if modelID then
                local veh = createVehicle(modelID, row.pos_x, row.pos_y, row.pos_z, 0, 0, row.pos_rot)
                if veh then
                    setVehicleColor(veh, row.color_r, row.color_g, row.color_b)
                    setVehicleLocked(veh, row.locked == 1)
                    
                    -- Mặc định xe gọi ra sẽ tắt máy để tránh tốn xăng lúc chưa lên xe
                    setVehicleEngineState(veh, false)
                    
                    setElementData(veh, "veh:id", row.id)
                    setElementData(veh, "veh:owner", charID)
                    setElementData(veh, "veh:fuel", row.fuel or 100) -- Nạp dữ liệu xăng từ DB
                    
                    outputChatBox("#E74C3C[Xe Cá Nhân] Đã gọi xe thành công về vị trí bến đỗ!", player, 255, 255, 255, true)
                end
            end
        else
            outputChatBox("#FF0000[Lỗi] Bạn chưa sở hữu chiếc xe nào! Hãy đến cửa hàng mua.", player, 255, 255, 255, true)
        end
    end, db, "SELECT * FROM vehicles WHERE char_id = ? LIMIT 1", charID)
end)

-- [TÍNH NĂNG 3]: LỆNH CẤT XE (/despawnveh)
function despawnPlayerVehicle(player)
    local charID = getElementData(player, "char:id")
    local db = getDB()
    if not charID or not db then return false end

    for _, veh in ipairs(getElementsByType("vehicle")) do
        if getElementData(veh, "veh:owner") == charID then
            local dbID = getElementData(veh, "veh:id")
            local fuel = getElementData(veh, "veh:fuel") or 100
            
            -- Chỉ cập nhật lượng xăng hiện tại vào DB khi cất xe (giữ nguyên tọa độ bến đỗ cũ)
            dbExec(db, "UPDATE vehicles SET fuel = ? WHERE id = ?", fuel, dbID)
            
            destroyElement(veh) -- Xóa chiếc xe khỏi bản đồ
            return true
        end
    end
    return false
end

addCommandHandler("despawnveh", function(player, cmd)
    if despawnPlayerVehicle(player) then
        outputChatBox("#00FF00[Xe Cá Nhân] Bạn đã cất chiếc xe của mình vào kho an toàn.", player, 255, 255, 255, true)
    else
        outputChatBox("#FF0000[Lỗi] Xe của bạn hiện không có trên bản đồ!", player, 255, 255, 255, true)
    end
end)

-- Tự động cất xe để giải phóng map khi người chơi thoát game (Quit)
addEventHandler("onPlayerQuit", root, function()
    despawnPlayerVehicle(source)
end)

-- [TÍNH NĂNG 1]: LỆNH ĐẬU XE CỐ ĐỊNH (/park)
addCommandHandler("park", function(player, cmd)
    local charID = getElementData(player, "char:id")
    local db = getDB()
    if not charID or not db then return end

    local veh = getPedOccupiedVehicle(player)
    if not veh then
        outputChatBox("#FF0000[Lỗi] Bạn phải ngồi trên chiếc xe của mình mới có thể đậu xe!", player, 255, 255, 255, true)
        return
    end

    if getElementData(veh, "veh:owner") ~= charID then
        outputChatBox("#FF0000[Lỗi] Đây không phải là xe thuộc sở hữu của bạn!", player, 255, 255, 255, true)
        return
    end

    local dbID = getElementData(veh, "veh:id")
    local x, y, z = getElementPosition(veh)
    local _, _, rot = getElementRotation(veh)
    local fuel = getElementData(veh, "veh:fuel") or 100

    -- Cập nhật tọa độ mới này thành bến đỗ vĩnh viễn trong MySQL
    dbExec(db, "UPDATE vehicles SET pos_x = ?, pos_y = ?, pos_z = ?, pos_rot = ?, fuel = ? WHERE id = ?", 
        x, y, z, rot, fuel, dbID)

    outputChatBox("#E74C3C[Bến Đỗ] Đã đặt vị trí này làm bến đỗ mặc định cho xe thành công!", player, 255, 255, 255, true)
end)

-- [TÍNH NĂNG 2]: LỆNH ĐỔ XĂNG (/refuel) tại cây xăng
addCommandHandler("refuel", function(player, cmd)
    local veh = getPedOccupiedVehicle(player)
    if not veh then
        outputChatBox("#FF0000[Cây Xăng] Bạn phải ngồi trong xe mới đổ xăng được!", player, 255, 255, 255, true)
        return
    end

    local fuel = getElementData(veh, "veh:fuel") or 100
    if fuel >= 100 then
        outputChatBox("#FFCC00[Cây Xăng] Bình nhiên liệu của xe đã đầy sẵn!", player, 255, 255, 255, true)
        return
    end

    -- Tính tiền xăng dựa trên lượng tiêu thụ (Ví dụ: 10$ cho mỗi 1% xăng)
    local fuelNeeded = 100 - fuel
    local cost = fuelNeeded * 10 

    if getPlayerMoney(player) < cost then
        outputChatBox("#FF0000[Cây Xăng] Bạn không đủ tiền đổ xăng! Chi phí: " .. cost .. "$", player, 255, 255, 255, true)
        return
    end

    takePlayerMoney(player, cost)
    setElementData(veh, "veh:fuel", 100)
    outputChatBox("#E74C3C[Cây Xăng] Đã nạp đầy bình xăng thành công! Chi phí: " .. cost .. "$", player, 255, 255, 255, true)
end)

-- 2. LỆNH MUA XE VẪN GIỮ NGUYÊN FORM CŨ
addCommandHandler("buyvehicle", function(player, cmd, modelID)
    local charID = getElementData(player, "char:id")
    local db = getDB()
    
    if not charID or not db then return end
    if not modelID then
        outputChatBox("Sử dụng: /buyvehicle [ID xe] (Ví dụ: 411 là xe Infernus)", player, 255, 200, 0)
        return
    end

    modelID = tonumber(modelID)
    local x, y, z = getElementPosition(player)
    local _, _, rot = getElementRotation(player)
    
    local playerMoney = getPlayerMoney(player)
    if playerMoney < 20000 then
        outputChatBox("#FF0000[Cửa Hàng] Bạn không đủ 20,000$ để mua chiếc xe này!", player, 255, 255, 255, true)
        return
    end

    takePlayerMoney(player, 20000)

    dbExec(db, "INSERT INTO vehicles (char_id, model, pos_x, pos_y, pos_z, pos_rot, fuel) VALUES (?, ?, ?, ?, ?, ?, 100)", 
        charID, modelID, x + 2, y + 2, z, rot)

    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        if result and #result > 0 then
            local lastVeh = result[1]
            local veh = createVehicle(lastVeh.model, lastVeh.pos_x, lastVeh.pos_y, lastVeh.pos_z, 0, 0, lastVeh.pos_rot)
            
            if veh then
                setVehicleEngineState(veh, false)
                setElementData(veh, "veh:id", lastVeh.id)
                setElementData(veh, "veh:owner", charID) 
                setElementData(veh, "veh:fuel", 100)
                outputChatBox("#00FF00[Cửa Hàng] Mua xe thành công! Gõ /park để đổi bến đỗ, bấm 'K' để Khóa xe.", player, 255, 255, 255, true)
            end
        end
    end, db, "SELECT * FROM vehicles WHERE char_id = ? ORDER BY id DESC LIMIT 1", charID)
end)

-- 4. LOGIC KHÓA / MỞ KHÓA XE (Phím K)
function toggleVehicleLock(player)
    local charID = getElementData(player, "char:id")
    if not charID then return end

    local px, py, pz = getElementPosition(player)
    local targetVehicle = nil

    -- Kiểm tra nếu đang ngồi trong xe
    local currentVeh = getPedOccupiedVehicle(player)
    if currentVeh and getElementData(currentVeh, "veh:owner") == charID then
        targetVehicle = currentVeh
    else
        -- Kiểm tra bán kính 4m xung quanh
        for _, veh in ipairs(getElementsByType("vehicle")) do
            local vx, vy, vz = getElementPosition(veh)
            if getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz) <= 4 then
                if getElementData(veh, "veh:owner") == charID then
                    targetVehicle = veh
                    break
                end
            end
        end
    end

    if targetVehicle then
        local isLocked = isVehicleLocked(targetVehicle)
        setVehicleLocked(targetVehicle, not isLocked)
        
        if not isLocked then
            outputChatBox("#FFCC00[Xe Cá Nhân] Bạn đã KHÓA chiếc xe của mình.", player, 255, 255, 255, true)
        else
            outputChatBox("#00FF00[Xe Cá Nhân] Bạn đã MỞ KHÓA chiếc xe của mình.", player, 255, 255, 255, true)
        end
    else
        outputChatBox("#FF0000[Lỗi] Không tìm thấy chiếc xe nào của bạn ở gần đây!", player, 255, 255, 255, true)
    end
end
addCommandHandler("lockvehicle", toggleVehicleLock)
addCommandHandler("lock", toggleVehicleLock) -- Đồng bộ thêm lệnh ngắn /lock cho người chơi tiện gõ

-- 5. LỆNH ĐIỀU KHIỂN ĐỘNG CƠ XE (Phím M)
function toggleVehicleEngine(player)
    local veh = getPedOccupiedVehicle(player)
    if not veh then 
        outputChatBox("#FF0000[Lỗi] Bạn phải ngồi trên xe mới có thể bật/tắt động cơ!", player, 255, 255, 255, true)
        return 
    end

    if getVehicleController(veh) ~= player then return end

    local charID = getElementData(player, "char:id")
    if getElementData(veh, "veh:owner") ~= charID then
        outputChatBox("#FF0000[Lỗi] Bạn không phải là chủ sở hữu chiếc xe này!", player, 255, 255, 255, true)
        return
    end

    local fuel = getElementData(veh, "veh:fuel") or 100
    if fuel <= 0 then
        outputChatBox("#FF0000[Lỗi] Xe đã cạn kiệt nhiên liệu, không thể khởi động!", player, 255, 255, 255, true)
        return
    end

    local currentState = getVehicleEngineState(veh)
    setVehicleEngineState(veh, not currentState)
    if currentState then
        outputChatBox("#FF9900* Bạn đã tắt động cơ phương tiện. *", player, 255, 255, 255, true)
    else
        outputChatBox("#00FF00* Động cơ phương tiện đã được khởi động. *", player, 255, 255, 255, true)
    end
end
addCommandHandler("engine", toggleVehicleEngine)

-- 6. LỆNH THẮT DÂY AN TOÀN (Phím G)
function toggleVehicleSeatbelt(player)
    local veh = getPedOccupiedVehicle(player)
    if not veh then 
        outputChatBox("#FF0000[Lỗi] Bạn phải ngồi trong xe mới sử dụng được dây an toàn!", player, 255, 255, 255, true)
        return 
    end

    local currentBelt = getElementData(player, "seatbelt") or false
    setElementData(player, "seatbelt", not currentBelt)
    if currentBelt then
        outputChatBox("#FF9900* Bạn đã tháo dây an toàn. *", player, 255, 255, 255, true)
    else
        outputChatBox("#00FF00* Bạn đã thắt dây an toàn chặt chẽ. *", player, 255, 255, 255, true)
    end
end
addCommandHandler("seatbelt", toggleVehicleSeatbelt)

-- 7. LỆNH MỞ/ĐÓNG NẮP CAPO (/hood) - ĐÃ ĐỔI SANG HÀM CHUẨN CỦA MTA
function toggleVehicleHood(player)
    local veh = getPedOccupiedVehicle(player)
    if not veh or getVehicleController(veh) ~= player then return end

    local currentRatio = getVehicleDoorOpenRatio(veh, 0)
    if currentRatio == 0 then
        setVehicleDoorOpenRatio(veh, 0, 1, 500)
        outputChatBox("#00FF00* Bạn đã mở nắp capo xe. *", player, 255, 255, 255, true)
    else
        setVehicleDoorOpenRatio(veh, 0, 0, 500)
        outputChatBox("#FF9900* Bạn đã đóng nắp capo xe. *", player, 255, 255, 255, true)
    end
end
addCommandHandler("hood", toggleVehicleHood)

-- 8. LỆNH MỞ/ĐÓNG CỐP XE (/trunk) - ĐÃ ĐỔI SANG HÀM CHUẨN CỦA MTA
function toggleVehicleTrunk(player)
    local veh = getPedOccupiedVehicle(player)
    if not veh or getVehicleController(veh) ~= player then return end

    local currentRatio = getVehicleDoorOpenRatio(veh, 1)
    if currentRatio == 0 then
        setVehicleDoorOpenRatio(veh, 1, 1, 500)
        outputChatBox("#00FF00* Bạn đã mở cốp xe. *", player, 255, 255, 255, true)
    else
        setVehicleDoorOpenRatio(veh, 1, 0, 500)
        outputChatBox("#FF9900* Bạn đã đóng cốp xe. *", player, 255, 255, 255, true)
    end
end
addCommandHandler("trunk", toggleVehicleTrunk)

-- 9. LỆNH BẬT/TẮT ĐÈN XE THỦ CÔNG (/lights)
function toggleVehicleLights(player)
    local veh = getPedOccupiedVehicle(player)
    if not veh or getVehicleController(veh) ~= player then return end

    local currentLights = getVehicleOverrideLights(veh)
    if currentLights == 2 then
        setVehicleOverrideLights(veh, 1)
        outputChatBox("#FF9900* Bạn đã tắt đèn xe. *", player, 255, 255, 255, true)
    else
        setVehicleOverrideLights(veh, 2)
        outputChatBox("#00FF00* Bạn đã bật đèn xe. *", player, 255, 255, 255, true)
    end
end
addCommandHandler("lights", toggleVehicleLights)

-- ─── BỘ NHẬN TÍN HIỆU PHÍM TẮT TỪ CLIENT GỬI LÊN (GỌI TRỰC TIẾP KHÔNG QUA TRUNG GIAN) ───
addEvent("vcc_vehicle:triggerCommand", true)
addEventHandler("vcc_vehicle:triggerCommand", root, function(cmdName)
    if cmdName == "lock" then
        toggleVehicleLock(source)
    elseif cmdName == "engine" then
        toggleVehicleEngine(source)
    elseif cmdName == "seatbelt" then
        toggleVehicleSeatbelt(source)
    elseif cmdName == "hood" then
        toggleVehicleHood(source)
    elseif cmdName == "trunk" then
        toggleVehicleTrunk(source)
    elseif cmdName == "lights" then
        toggleVehicleLights(source)
    end
end)

-- TỰ ĐỘNG LƯU KHI RESOURCE STOP GIỮ NGUYÊN FORM CŨ
addEventHandler("onResourceStop", resourceRoot, function()
    local db = getDB()
    if not db then return end

    for _, veh in ipairs(getElementsByType("vehicle")) do
        local dbID = getElementData(veh, "veh:id")
        if dbID then
            local fuel = getElementData(veh, "veh:fuel") or 100
            dbExec(db, "UPDATE vehicles SET fuel = ? WHERE id = ?", fuel, dbID)
        end
    end
end)