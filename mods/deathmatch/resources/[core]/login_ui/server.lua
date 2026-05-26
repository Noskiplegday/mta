local dbConn = nil

-- ĐIỀN CONFIG MYSQL CỦA BẠN VÀO ĐÂY
local host = "127.0.0.1"
local user = "root"
local pass = ""
local dbName = "mta_rp"

addEventHandler("onResourceStart", resourceRoot, function()
    dbConn = dbConnect("mysql", "dbname="..dbName..";host="..host..";charset=utf8", user, pass, "share=1")
    if dbConn then
        outputDebugString("[LOGIN_UI] Kết nối cơ sở dữ liệu MySQL thành công!")
        
        -- Tạo bảng tài khoản hệ thống mới
        dbExec(dbConn, [[
            CREATE TABLE IF NOT EXISTS my_accounts (
                id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(50) UNIQUE,
                password VARCHAR(50),
                email VARCHAR(100),
                serial VARCHAR(100),
                ip_addr VARCHAR(40)
            )
        ]])
        
        -- Tạo bảng nhân vật hệ thống mới
        dbExec(dbConn, [[
            CREATE TABLE IF NOT EXISTS my_characters (
                id INT AUTO_INCREMENT PRIMARY KEY,
                account_id INT,
                char_name VARCHAR(50) UNIQUE,
                money INT DEFAULT 5000,
                health FLOAT DEFAULT 100.0,
                armor FLOAT DEFAULT 0.0,
                premium_points INT DEFAULT 0,
                x FLOAT DEFAULT 0.0,
                y FLOAT DEFAULT 0.0,
                z FLOAT DEFAULT 3.0,
                interior INT DEFAULT 0,
                dimension INT DEFAULT 0,
                FOREIGN KEY (account_id) REFERENCES my_accounts(id) ON DELETE CASCADE
            )
        ]])
    else
        outputDebugString("[LOGIN_UI] LỖI: Kết nối MySQL thất bại! Hãy kiểm tra lại config.", 1)
    end
end)

-- XỬ LÝ ĐĂNG KÝ
addEvent("onServerRegisterAttempt", true)
addEventHandler("onServerRegisterAttempt", resourceRoot, function(user, pass, email, char)
    local player = client
    if not dbConn then return end

    dbQuery(function(qh)
        local accCheck = dbPoll(qh, 0)
        if accCheck and #accCheck > 0 then
            triggerClientEvent(player, "sendAuthMessageToWeb", player, "Tài khoản hoặc Email đã tồn tại!", false)
            return
        end

        dbQuery(function(qhChar)
            local charCheck = dbPoll(qhChar, 0)
            if charCheck and #charCheck > 0 then
                triggerClientEvent(player, "sendAuthMessageToWeb", player, "Tên nhân vật này đã có người dùng!", false)
                return
            end

            local serial = getPlayerSerial(player)
            local ip = getPlayerIP(player)
            
            dbQuery(function(qhInsert)
                local _, _, insertId = dbPoll(qhInsert, 0)
                if insertId then
                    dbExec(dbConn, "INSERT INTO my_characters (account_id, char_name) VALUES (?, ?)", insertId, char)
                    triggerClientEvent(player, "sendAuthMessageToWeb", player, "Đăng ký thành công! Hãy đăng nhập.", true)
                end
            end, dbConn, "INSERT INTO my_accounts (username, password, email, serial, ip_addr) VALUES (?, ?, ?, ?, ?)", user, pass, email, serial, ip)

        end, dbConn, "SELECT id FROM my_characters WHERE char_name = ? LIMIT 1", char)
    end, dbConn, "SELECT id FROM my_accounts WHERE username = ? OR email = ? LIMIT 1", user, email)
end)

-- XỬ LÝ ĐĂNG NHẬP
addEvent("onServerLoginAttempt", true)
addEventHandler("onServerLoginAttempt", resourceRoot, function(user, pass)
    local player = client
    if not dbConn then return end

    dbQuery(function(qh)
        local accRes = dbPoll(qh, 0)
        if accRes and #accRes > 0 then
            local account = accRes[1]
            
            if account.password == pass then
                dbQuery(function(qhChar)
                    local charRes = dbPoll(qhChar, 0)
                    if charRes and #charRes > 0 then
                        local character = charRes[1]
                        
                        -- Set Element Data riêng biệt sạch sẽ
                        setElementData(player, "user:dbId", account.id)
                        setElementData(player, "user:logged", true)
                        setElementData(player, "char:dbId", character.id)
                        setElementData(player, "char:name", character.char_name)
                        setElementData(player, "char:pp", tonumber(character.premium_points) or 0)

                        -- Đưa người chơi vào game tại vị trí cũ
                        spawnPlayer(player, character.x, character.y, character.z, 0, 0, character.interior, character.dimension)
                        setPlayerMoney(player, character.money)
                        setElementHealth(player, character.health)
                        setPedArmor(player, character.armor)
                        setCameraTarget(player, player)
                        
                        -- Lệnh xóa UI ở máy client
                        triggerClientEvent(player, "onAuthSuccessClearUI", player)
                    else
                        triggerClientEvent(player, "sendAuthMessageToWeb", player, "Lỗi dữ liệu: Không thấy nhân vật!", false)
                    end
                end, dbConn, "SELECT * FROM my_characters WHERE account_id = ? LIMIT 1", account.id)
            else
                triggerClientEvent(player, "sendAuthMessageToWeb", player, "Sai mật khẩu! Vui lòng thử lại.", false)
            end
        else
            triggerClientEvent(player, "sendAuthMessageToWeb", player, "Tài khoản không tồn tại trên hệ thống!", false)
        end
    end, dbConn, "SELECT * FROM my_accounts WHERE username = ? LIMIT 1", user)
end)

-- HÀM LƯU DỮ LIỆU TỰ ĐỘNG KHI THOÁT GAME
function savePlayerCharacterData(player)
    if isElement(player) and getElementData(player, "user:logged") then
        local charId = getElementData(player, "char:dbId")
        if charId and dbConn then
            local money = getPlayerMoney(player) or 0
            local health = getElementHealth(player) or 100
            local armor = getPedArmor(player) or 0
            local pp = tonumber(getElementData(player, "char:pp")) or 0
            
            local x, y, z = getElementPosition(player)
            local interior = getElementInterior(player) or 0
            local dimension = getElementDimension(player) or 0

            dbExec(dbConn, [[
                UPDATE my_characters SET 
                money = ?, health = ?, armor = ?, premium_points = ?, 
                x = ?, y = ?, z = ?, interior = ?, dimension = ? 
                WHERE id = ?
            ]], money, health, armor, pp, x, y, z, interior, dimension, charId)
        end
    end
end

addEventHandler("onPlayerQuit", root, function()
    savePlayerCharacterData(source)
end)

addEventHandler("onResourceStop", resourceRoot, function()
    if dbConn then
        for _, player in ipairs(getElementsByType("player")) do
            savePlayerCharacterData(player)
        end
    end
end)