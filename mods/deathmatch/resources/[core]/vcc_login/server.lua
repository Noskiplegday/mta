-- vcc_login/server.lua
-- Yêu cầu: có mysql/sqlite hoặc dùng internal accounts
-- Đây là ví dụ dùng accounts nội bộ MTA

addEvent("vcc:login", true)
addEventHandler("vcc:login", root, function(username, password)
    local player = client
    if not username or not password or username == "" or password == "" then
        triggerClientEvent(player, "vcc:loginResult", player, false, "Vui lòng nhập đầy đủ thông tin!")
        return
    end

    local account = getAccount(username, password)
    if account then
        local result = logIn(player, account, password)
        if result then
            triggerClientEvent(player, "vcc:loginResult", player, true, "Đăng nhập thành công! Chào mừng trở lại!")
            outputChatBox("✅ [VCC] "..username.." đã đăng nhập.", root, 39, 174, 96)
        else
            triggerClientEvent(player, "vcc:loginResult", player, false, "Đăng nhập thất bại. Thử lại!")
        end
    else
        triggerClientEvent(player, "vcc:loginResult", player, false, "Sai tên tài khoản hoặc mật khẩu!")
    end
end)

addEvent("vcc:register", true)
addEventHandler("vcc:register", root, function(username, password)
    local player = client
    if not username or not password or username == "" or password == "" then
        triggerClientEvent(player, "vcc:registerResult", player, false, "Vui lòng nhập đầy đủ thông tin!")
        return
    end
    if #password < 6 then
        triggerClientEvent(player, "vcc:registerResult", player, false, "Mật khẩu phải có ít nhất 6 ký tự!")
        return
    end
    if getAccount(username) then
        triggerClientEvent(player, "vcc:registerResult", player, false, "Tên tài khoản đã tồn tại!")
        return
    end

    local newAccount = addAccount(username, password)
    if newAccount then
        triggerClientEvent(player, "vcc:registerResult", player, true, "Đăng ký thành công! Hãy đăng nhập ngay!")
        outputChatBox("🎉 [VCC] "..username.." đã tạo tài khoản mới.", root, 241, 196, 15)
    else
        triggerClientEvent(player, "vcc:registerResult", player, false, "Đăng ký thất bại. Thử lại sau!")
    end
end)
