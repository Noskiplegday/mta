function getDB()
    local mysqlResource = getResourceFromName("mysql")
    if mysqlResource and getResourceState(mysqlResource) == "running" then
        return exports["mysql"]:getConnection()
    end
    return false
end

-- Tự động tạo bảng tài khoản khi khởi động resource
addEventHandler("onResourceStart", resourceRoot, function()
    local db = getDB()
    if db then
        dbExec(db, [[
            CREATE TABLE IF NOT EXISTS accounts (
                id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(50) NOT NULL UNIQUE,
                password VARCHAR(255) NOT NULL,
                serial VARCHAR(100) NOT NULL UNIQUE
            )
        ]])
    end
end)

-- Lắng nghe khi người chơi bước chân vào kết nối server
addEventHandler("onPlayerJoin", root, function()
    local player = source
    local serial = getPlayerSerial(player) -- Lấy mã máy (Serial) của người chơi
    local db = getDB()

    if not db then return end

    -- Tìm xem mã máy này đã đăng ký tài khoản nào chưa
    dbQuery(function(queryHandle)
        local result = dbPoll(queryHandle, 0)
        
        if not result or #result == 0 then
            -- TRƯỜNG HỢP ĐĂNG KÝ: Chưa có tài khoản -> Tự động tạo một tên ngẫu nhiên
            local defaultUsername = "User_" .. math.random(1000, 9999)
            local defaultPassword = "default_password"
            
            dbExec(db, "INSERT INTO accounts (username, password, serial) VALUES (?, ?, ?)", defaultUsername, defaultPassword, serial)
            
            -- Lấy lại dữ liệu ID vừa tạo để truyền sang cho hệ thống nhân vật
            dbQuery(function(handle)
                local res = dbPoll(handle, 0)
                if res and #res > 0 then
                    setPlayerName(player, defaultUsername)
                    outputChatBox("#00FF00[VanCanhCity] Tài khoản mới của bạn đã được đăng ký tự động qua Serial máy!", player, 255, 255, 255, true)
                    
                    -- GỌI SANG HÀM EXPORT CỦA RESOURCE CHARACTER ĐỂ XỬ LÝ TIẾP
                    exports["character"]:loadPlayerCharacter(player, res[1].id, defaultUsername)
                end
            end, db, "SELECT id FROM accounts WHERE serial = ? LIMIT 1", serial)
            
        else
            -- TRƯỜNG HỢP ĐĂNG NHẬP: Đã có tài khoản -> Đăng nhập thẳng bằng tên cũ trong DB
            local accountData = result[1]
            setPlayerName(player, accountData.username)
            
            -- GỌI SANG HÀM EXPORT CỦA RESOURCE CHARACTER ĐỂ XỬ LÝ TIẾP
            exports["character"]:loadPlayerCharacter(player, accountData.id, accountData.username)
        end
        
    end, db, "SELECT * FROM accounts WHERE serial = ? LIMIT 1", serial)
end)