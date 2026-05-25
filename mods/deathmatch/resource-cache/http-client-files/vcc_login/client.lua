-- vcc_login/client.lua
local loginBrowser = nil
local screenW, screenH = guiGetScreenSize()

local function createLoginUI()
    loginBrowser = createBrowser(screenW, screenH, false, false)
    local bw, bh = screenW, screenH
    
    addEventHandler("onClientBrowserCreated", loginBrowser, function()
        loadBrowserURL(loginBrowser, "http://mta/local/vcc_login/login.html")
    end)

    showCursor(true)
    setPlayerHudComponentVisible("all", false)
    toggleAllControls(false)
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    createLoginUI()
end)

addEventHandler("onClientRender", root, function()
    if loginBrowser then
        drawImage(0, 0, screenW, screenH, loginBrowser, 0, 0, 0, 0xFFFFFFFF)
    end
end)

-- Nhận event từ browser HTML
addEventHandler("onClientBrowserMessage", resourceRoot, function(browser, msg)
end)

-- Trigger từ JS trong HTML
function onLoginSubmit(username, password)
    triggerServerEvent("vcc:login", localPlayer, username, password)
end
addEvent("onLoginSubmit", false)
addEventHandler("onLoginSubmit", root, onLoginSubmit)

function onRegisterSubmit(username, password)
    triggerServerEvent("vcc:register", localPlayer, username, password)
end
addEvent("onRegisterSubmit", false)
addEventHandler("onRegisterSubmit", root, onRegisterSubmit)

-- Nhận phản hồi từ server
addEvent("vcc:loginResult", true)
addEventHandler("vcc:loginResult", root, function(success, msg)
    if loginBrowser then
        if success then
            executeBrowserJavascript(loginBrowser, "showLoginSuccess('"..msg.."')")
            setTimer(function()
                destroyElement(loginBrowser)
                loginBrowser = nil
                showCursor(false)
                setPlayerHudComponentVisible("all", true)
                toggleAllControls(true)
                triggerEvent("vcc:onLoggedIn", localPlayer)
            end, 1500, 1)
        else
            executeBrowserJavascript(loginBrowser, "showLoginError('"..msg.."')")
        end
    end
end)

addEvent("vcc:registerResult", true)
addEventHandler("vcc:registerResult", root, function(success, msg)
    if loginBrowser then
        if success then
            executeBrowserJavascript(loginBrowser, "showRegSuccess('"..msg.."')")
        else
            executeBrowserJavascript(loginBrowser, "showRegError('"..msg.."')")
        end
    end
end)
