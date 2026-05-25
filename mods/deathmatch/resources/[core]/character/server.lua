-- Hàm lấy kết nối từ resource mysql
function getDB()
    local mysqlResource = getResourceFromName("mysql")
    if mysqlResource and getResourceState(mysqlResource) == "running" then
        return exports["mysql"]:getConnection()
    end
    return false
end

-- Tự động kiểm tra và tạo bảng nhân vật khi khởi động resource
addEventHandler("onResourceStart", resourceRoot, function()
    local db = getDB()
    if db then
        dbExec(db, [[
            CREATE TABLE IF NOT EXISTS characters (
                id INT AUTO_INCREMENT PRIMARY KEY,
                account_id INT NOT NULL,
                char_name VARCHAR(50) NOT NULL,
                pos_x FLOAT DEFAULT -1987.5,
                pos_y FLOAT DEFAULT 137.5,
                pos_z FLOAT DEFAULT 27.5,
                pos_rot FLOAT DEFAULT 90.0,
                skin INT DEFAULT 0,
                cash INT DEFAULT 5000
            )
        ]])
    end
end)

-- HÀM CỐT LÕI: Được gọi từ resource account sau khi đăng nhập thành công
function loadPlayerCharacter(player, accountID, charName)
    local db = getDB()
    if not db then return false end

    -- Làm đen màn hình tạm thời để tránh việc thấy map chưa kịp nạp
    fadeCamera(player, false, 0)

    -- Tìm kiếm dữ liệu nhân vật dựa trên ID tài khoản
    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        
        if not result or #result == 0 then
            -- TRƯỜNG HỢP 1: Tài khoản mới, chưa có nhân vật -> Thêm mới vào DB
            dbExec(db, "INSERT INTO characters (account_id, char_name) VALUES (?, ?)", accountID, charName)
            
            -- Spawn tại vị trí mặc định (Ga San Fierro)
            spawnPlayer(player, -1987.5, 137.5, 27.5, 90, 0, 0, 0)
            setElementData(player, "char:money", 5000)
            givePlayerMoney(player, 5000)
            outputChatBox("#00FF00[VanCanhCity] Khởi tạo nhân vật mới thành công!", player, 255, 255, 255, true)
        else
            -- TRƯỜNG HỢP 2: Tài khoản cũ, đã có nhân vật -> Lấy dữ liệu cũ ra
            local charData = result[1]
            local px = charData.pos_x or -1987.5
            local py = charData.pos_y or 137.5
            local pz = charData.pos_z or 27.5
            local prot = charData.pos_rot or 90
            local pskin = charData.skin or 0
            local pcash = charData.cash or 5000

            -- Hồi sinh người chơi theo đúng vị trí cũ trong DB
            spawnPlayer(player, px, py, pz, prot, pskin, 0, 0)
            setElementData(player, "char:money", pcash)
            givePlayerMoney(player, pcash)
            outputChatBox("#00FF00[VanCanhCity] Tải dữ liệu nhân vật thành công! Chào mừng trở lại.", player, 255, 255, 255, true)
        end
        
        -- ĐỒNG BỘ ĐỒ HỌA: Đặt camera đi theo người chơi và mở màn hình sáng lên
        setCameraTarget(player, player)
        fadeCamera(player, true, 1.0) -- Sáng lên từ từ trong 1 giây
        
        -- Lưu ID tài khoản vào người chơi để dùng khi thoát game
        setElementData(player, "char:id", accountID)
        
    end, db, "SELECT * FROM characters WHERE account_id = ? LIMIT 1", accountID)
    
    return true
end

-- Tự động cập nhật vị trí, tiền tệ của nhân vật khi thoát game (Quit)
addEventHandler("onPlayerQuit", root, function()
    local player = source
    local accountID = getElementData(player, "char:id")
    
    if accountID then
        local db = getDB()
        if not db then return end
        
        local x, y, z = getElementPosition(player)
        local _, _, rot = getElementRotation(player)
        local skin = getElementModel(player)
        local cash = getPlayerMoney(player)
        
        dbExec(db, "UPDATE characters SET pos_x = ?, pos_y = ?, pos_z = ?, pos_rot = ?, skin = ?, cash = ? WHERE account_id = ?", 
            x, y, z, rot, skin, cash, accountID)
    end
end)