outputDebugString("LOGIN SERVER LOADED")

-- Đảm bảo lấy database connection an toàn
function getDB()
    if getResourceFromName("mysql") and getResourceState(getResourceFromName("mysql")) == "running" then
        return exports.mysql:getConnection()
    end
    return false
end

local db = false

addEvent("registerAccount", true)
addEvent("loginAccount", true)

addEventHandler(
    "registerAccount",
    root,
    function(username,password)

        outputDebugString("REGISTER EVENT TRIGGERED: " .. tostring(username))

        db = getDB()
        if not db then
            triggerClientEvent(source, "authResult", source, false, "#FF4444Lỗi: MySQL chưa khởi động!")
            return
        end

        if username == "" or password == "" then
            triggerClientEvent(
                source,
                "authResult",
                source,
                false,
                "#FF4444Vui lòng nhập đầy đủ thông tin!"
            )
            return
        end

        local q = dbQuery(db, "SELECT id FROM accounts WHERE username=? LIMIT 1", username)
        local result =
            dbPoll(q,-1)

        if #result > 0 then
            triggerClientEvent(
                source,
                "authResult",
                source,
                false,
                "#FF4444Tài khoản đã tồn tại!"
            )
            return
        end

        dbExec(db, "INSERT INTO accounts (username,password) VALUES (?,?)", username, password)

        outputDebugString("REGISTER SUCCESS: " .. tostring(username))
        triggerClientEvent(
            source,
            "authResult",
            source,
            false,
            "#00FF00Đăng ký thành công!"
        )
    end
)

addEventHandler(
    "loginAccount",
    root,
    function(username,password)

        outputDebugString("LOGIN EVENT TRIGGERED: " .. tostring(username))

        db = getDB()
        if not db then
            triggerClientEvent(source, "authResult", source, false, "#FF4444Lỗi: MySQL chưa khởi động!")
            return
        end

        local q =
            dbQuery(
                db,
                "SELECT * FROM accounts WHERE username=? AND password=? LIMIT 1",
                username,
                password
            )

        local result = dbPoll(q,-1)

        if not result or #result == 0 then
            triggerClientEvent(
                source,
                "authResult",
                source,
                false,
                "#FF4444Sai tài khoản hoặc mật khẩu!"
            )
            return
        end

        local account = result[1]

        -- Kiểm tra an toàn trước khi gọi export sang resource character
        local charRes = getResourceFromName("character")
        if not charRes or getResourceState(charRes) ~= "running" then
            outputDebugString("CRITICAL: Character resource is NOT running!", 1)
            triggerClientEvent(source, "authResult", source, false, "#FF4444Lỗi: Character System Offline!")
            return
        end

        exports.character:loadPlayerCharacter(
            source,
            account.id,
            username
        )

        outputDebugString("LOGIN SUCCESS: " .. tostring(username))
        triggerClientEvent(
            source,
            "authResult",
            source,
            true,
            "#00FF00Đăng nhập thành công!"
        )
    end
)
