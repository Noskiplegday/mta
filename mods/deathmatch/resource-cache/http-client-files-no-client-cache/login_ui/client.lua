local loginBrowser = nil

addEventHandler("onClientResourceStart", resourceRoot, function()
    setElementFrozen(localPlayer, true)
    toggleAllControls(false)
    showChat(false)
    setPlayerHudComponentVisible("all", false)
    setPlayerHudComponentVisible("crosshair", false)

    local sx, sy = guiGetScreenSize()
    loginBrowser = guiCreateBrowser(0, 0, sx, sy, true, true, false)
    local actualBrowser = guiGetBrowser(loginBrowser)
    
    addEventHandler("onClientBrowserCreated", actualBrowser, function()
        loadBrowserURL(actualBrowser, "http://mta/local/html/index.html")
        showCursor(true)
        guiSetInputMode("no_binds")
    end)
end)

-- Nhận dữ liệu Đăng nhập từ HTML
addEvent("onLoginSubmit", true)
addEventHandler("onLoginSubmit", root, function(username, password)
    triggerServerEvent("onServerLoginAttempt", resourceRoot, username, password)
end)

-- Nhận dữ liệu Đăng ký từ HTML (Đã đổi tên sự kiện thành onRegisterSubmit để khớp với HTML của bạn)
addEvent("onRegisterSubmit", true)
addEventHandler("onRegisterSubmit", root, function(username, password)
    -- Tự động tạo email/char khớp với server để tránh lỗi nhập liệu
    local email = username .. "@vancanh.com"
    local characterName = username .. "_City"
    
    -- Gửi lệnh lên Server để ghi vào Database
    triggerServerEvent("onServerRegisterAttempt", resourceRoot, username, password, email, characterName)
end)

-- Nhận phản hồi từ Server (lỗi hoặc thành công) để đẩy vào HTML
addEvent("sendAuthMessageToWeb", true)
addEventHandler("sendAuthMessageToWeb", root, function(message, isSuccess)
    if isElement(loginBrowser) then
        local actualBrowser = guiGetBrowser(loginBrowser)
        -- Gọi trực tiếp hàm showResponse trong HTML
        executeBrowserJavascript(actualBrowser, string.format("showResponse('%s', %s);", message, tostring(isSuccess)))
    end
end)

-- Xóa UI khi thành công
addEvent("onAuthSuccessClearUI", true)
addEventHandler("onAuthSuccessClearUI", root, function()
    if isElement(loginBrowser) then
        destroyElement(loginBrowser)
        loginBrowser = nil
    end
    showCursor(false)
    
    -- DÒNG FIX PHÍM XE:
    guiSetInputMode("allow_binds") 
    
    setPlayerHudComponentVisible("all", true)
    setElementFrozen(localPlayer, false)
    toggleAllControls(true)
    showChat(true)
end)