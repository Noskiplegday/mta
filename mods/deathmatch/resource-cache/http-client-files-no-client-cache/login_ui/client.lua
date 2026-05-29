local loginBrowser = nil
local browser = nil

addEventHandler("onClientResourceStart", resourceRoot, function()
    setElementFrozen(localPlayer, true)
    toggleAllControls(false)
    showChat(false)
    setPlayerHudComponentVisible("all", false)
    setPlayerHudComponentVisible("crosshair", false)

    local sx, sy = guiGetScreenSize()
    loginBrowser = guiCreateBrowser(0, 0, sx, sy, true, true, false)
    
    addEventHandler("onClientBrowserCreated", loginBrowser, function()
        browser = source
        loadBrowserURL(source, "http://mta/local/html/index.html")
        showCursor(true)
        guiSetInputMode("no_binds")
    end)
end)

-- Gửi dữ liệu Đăng nhập lên Server
addEvent("onLoginSubmit", true)
addEventHandler("onLoginSubmit", root, function(username, password)
    triggerServerEvent("onLoginSubmit", localPlayer, username, password)
end)

-- Gửi dữ liệu Đăng ký lên Server
addEvent("onRegisterSubmit", true)
addEventHandler("onRegisterSubmit", root, function(username, password)
    outputDebugString("CLIENT REGISTER EVENT")
    outputDebugString("USERNAME CLIENT: "..tostring(username))
    outputDebugString("PASSWORD CLIENT: "..tostring(password))

    triggerServerEvent("onRegisterSubmit", resourceRoot, username, password)
end)

-- Nhận phản hồi từ Server
addEvent("loginResponse", true)
addEventHandler("loginResponse", root, function(success, message)
    outputChatBox(message)

    if isElement(browser) then
        executeBrowserJavascript(browser, string.format(
            "showMessage('%s', %s)",
            message,
            tostring(success)
        ))
    end
end)

-- Xóa UI khi thành công
addEvent("closeLoginUI", true)
addEventHandler("closeLoginUI", root, function()
    if isElement(loginBrowser) then
        destroyElement(loginBrowser)
        loginBrowser = nil
        browser = nil
    end
    showCursor(false)
    guiSetInputMode("allow_binds")
    setPlayerHudComponentVisible("all", true)
    setElementFrozen(localPlayer, false)
    toggleAllControls(true)
    showChat(true)
end)