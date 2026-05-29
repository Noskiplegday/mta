local sx, sy = guiGetScreenSize()
local showLogin = true
local mode = "login" -- "login" hoặc "register"
local username = ""
local password = ""
local selected = nil
local message = ""
local messageColor = {255, 255, 255}
local alpha = 0

addEventHandler("onClientResourceStart", resourceRoot,
function()
    showCursor(true)
    fadeCamera(true)
    setCameraTarget(localPlayer)
    guiSetInputMode("no_binds_when_editing")
    toggleAllControls(false)
    showChat(false)
end)

function drawLoginUI()
    if not showLogin then 
        if alpha > 0 then alpha = math.max(0, alpha - 5) end
    else
        if alpha < 255 then alpha = math.min(255, alpha + 5) end
    end
    
    if alpha <= 0 then return end

    -- Colors (Style Đỏ - Đen)
    local colorBG = tocolor(15, 15, 15, math.min(alpha, 240))
    local colorCard = tocolor(22, 22, 22, alpha)
    local colorAccent = tocolor(179, 32, 32, alpha) -- #b32020
    local colorAccentHover = tocolor(255, 68, 68, alpha) -- #ff4444
    local colorText = tocolor(255, 255, 255, alpha)
    local colorInput = tocolor(35, 35, 35, alpha)

    -- Fullscreen Background
    dxDrawRectangle(0, 0, sx, sy, colorBG)

    -- Login/Register Card
    local w, h = 400, 420
    local x, y = (sx - w) / 2, (sy - h) / 2
    dxDrawRectangle(x, y, w, h, colorCard)
    dxDrawRectangle(x, y, w, 3, colorAccent) -- Top border

    -- Header
    dxDrawText("VANCANH CITY", x, y + 30, x + w, 0, colorAccent, 2.5, "default-bold", "center")
    dxDrawText(mode == "login" and "ĐĂNG NHẬP" or "ĐĂNG KÝ", x, y + 75, x + w, 0, colorText, 1.2, "default", "center")

    -- Message Area
    if message ~= "" then
        dxDrawText(message, x + 20, y + 105, x + w - 20, 0, tocolor(messageColor[1], messageColor[2], messageColor[3], alpha), 1, "default-bold", "center")
    end

    -- Inputs
    local inputW, inputH = 320, 45
    local inputX = (sx - inputW) / 2
    
    -- Username
    dxDrawText("Tài khoản", inputX, y + 130, 0, 0, tocolor(150, 150, 150, alpha), 1, "default")
    dxDrawRectangle(inputX, y + 150, inputW, inputH, selected == "username" and tocolor(50, 50, 50, alpha) or colorInput)
    dxDrawText(username, inputX + 10, y + 150, inputX + inputW, y + 150 + inputH, colorText, 1.1, "default", "left", "center")
    if selected == "username" and (getTickCount() % 1000 < 500) then
        local tw = dxGetTextWidth(username, 1.1, "default")
        dxDrawRectangle(inputX + 12 + tw, y + 160, 2, 25, colorAccent)
    end

    -- Password
    dxDrawText("Mật khẩu", inputX, y + 210, 0, 0, tocolor(150, 150, 150, alpha), 1, "default")
    dxDrawRectangle(inputX, y + 230, inputW, inputH, selected == "password" and tocolor(50, 50, 50, alpha) or colorInput)
    dxDrawText(string.rep("•", #password), inputX + 10, y + 230, inputX + inputW, y + 230 + inputH, colorText, 1.5, "default", "left", "center")
    if selected == "password" and (getTickCount() % 1000 < 500) then
        local tw = dxGetTextWidth(string.rep("•", #password), 1.5, "default")
        dxDrawRectangle(inputX + 12 + tw, y + 240, 2, 25, colorAccent)
    end

    -- Main Button
    local btnHover = isCursorOver(inputX, y + 300, inputW, 50)
    dxDrawRectangle(inputX, y + 300, inputW, 50, btnHover and colorAccentHover or colorAccent)
    dxDrawText(mode == "login" and "ĐĂNG NHẬP" or "ĐĂNG KÝ NGAY", inputX, y + 300, inputX + inputW, y + 350, colorText, 1.2, "default-bold", "center", "center")

    -- Toggle Mode Button
    local toggleText = mode == "login" and "Chưa có tài khoản? Đăng ký" or "Đã có tài khoản? Đăng nhập"
    local toggleHover = isCursorOver(inputX, y + 365, inputW, 20)
    dxDrawText(toggleText, x, y + 365, x + w, 0, toggleHover and colorAccentHover or tocolor(180, 180, 180, alpha), 1, "default", "center")

end
addEventHandler("onClientRender", root, drawLoginUI)

addEventHandler("onClientClick", root, function(button, state)
    if not showLogin or button ~= "left" or state ~= "down" then return end
    local w, h = 400, 420
    local x, y = (sx - w) / 2, (sy - h) / 2
    local inputW, inputH = 320, 45
    local inputX = (sx - inputW) / 2

    if isCursorOver(inputX, y + 150, inputW, inputH) then
        selected = "username"
    elseif isCursorOver(inputX, y + 230, inputW, inputH) then
        selected = "password"
    elseif isCursorOver(inputX, y + 300, inputW, 50) then
        if username ~= "" and password ~= "" then
            message = "Đang xử lý..."
            messageColor = {255, 255, 255}
            local event = (mode == "login") and "loginAccount" or "registerAccount"
            triggerServerEvent(event, localPlayer, username, password)
        else
            message = "Vui lòng nhập đủ thông tin!"
            messageColor = {255, 50, 50}
        end
    elseif isCursorOver(inputX, y + 365, inputW, 20) then
        mode = (mode == "login") and "register" or "login"
        message = ""
    else
        selected = nil
    end
end)

addEventHandler("onClientCharacter", root, function(character)
    if not selected then return end
    if #username < 32 and selected == "username" then
        username = username .. character
    elseif #password < 32 and selected == "password" then
        password = password .. character
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if not press or not selected then return end
    if key == "backspace" then
        if selected == "username" then
            username = username:sub(1, #username - 1)
        elseif selected == "password" then
            password = password:sub(1, #password - 1)
        end
        cancelEvent()
    elseif key == "enter" then
        if username ~= "" and password ~= "" then
            message = "Đang xử lý..."
            messageColor = {255, 255, 255}
            local event = (mode == "login") and "loginAccount" or "registerAccount"
            triggerServerEvent(event, localPlayer, username, password)
        end
    end
end)

-- Nhận kết quả từ Server (Đồng bộ với authResult)
addEvent("authResult", true)
addEventHandler("authResult", root, function(success, msg)
    -- Bóc tách mã màu HEX từ msg (ví dụ #FF4444)
    if msg:find("#") then
        local r = tonumber(msg:sub(2,3), 16) or 255
        local g = tonumber(msg:sub(4,5), 16) or 255
        local b = tonumber(msg:sub(6,7), 16) or 255
        messageColor = {r, g, b}
        message = msg:sub(8)
    else
        message = msg
    end

    if success then
        showLogin = false
        showCursor(false)
        guiSetInputMode("allow_binds")
        showChat(true)
        toggleAllControls(true)
        fadeCamera(true)
        setCameraTarget(localPlayer)
    end
end)

-- Utils
function isCursorOver(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    cx, cy = cx * sx, cy * sy
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end