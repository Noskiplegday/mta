local themeR, themeG, themeB = 60, 184, 130

local screenW, screenH = guiGetScreenSize()
local panelW, panelH = 400, 400 
local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2 

local showLogin = false
local currentMenu = "login"
local userEdit, passEdit, passConfirmEdit, emailEdit, charEdit 
local pinEdit, newPassEdit, newPassConfEdit

local rememberData = false 

local fontTitle, fontText, fontIcon, fontButton, fontLoaderIcon, fontServerName
local activeInput = nil
local animTick = 0

local hasRegisteredAccount = false
local isDeveloper = false 

local showStreamerPrompt = false
local allowMusic = false
local isDraggingVolume = false

local formAlpha = 255
local fadeState = "idle" 
local fadeStartTick = 0
local targetMenu = ""
local fadeDuration = 250 

local currentProgress = 0
local lastRenderTick = 0
local isLoadingPaused = false
local loadingPauseEndTime = 0
local nextPauseThreshold = 0

local activeTooltip = nil
local musicStarted = false 

local lastResetClick = 0
local resetCooldown = 60000

local dropStartTick = 0
local dropDuration = 3500
local camTargetX, camTargetY, camTargetZ = 0, 0, 0

local isBanned = false
local banReason = ""
local banAdmin = ""
local banExpire = ""
local banDate = ""

local playlist = {
    {path = "assets/audio/track1.wav", name = "Metin 2 - Enter The East"},
    {path = "assets/audio/track2.wav", name = "Coolio - Gangsta's Paradise ft. L.V."},
    {path = "assets/audio/track3.wav", name = "Eminem - Shake That ft. Nate Dogg"}
}

local currentTrack = nil
local bgMusic = nil
local favoriteTrack = nil
local musicVolume = 0.5
local isMusicPaused = false

local function saveFavoriteTrack(trackNum)
    local xml = xmlLoadFile("login.xml")
    if not xml then xml = xmlCreateFile("login.xml", "login") end
    if xml then
        if trackNum then
            xmlNodeSetAttribute(xml, "favoriteTrack", tostring(trackNum))
        else
            xmlNodeSetAttribute(xml, "favoriteTrack", "0")
        end
        xmlSaveFile(xml)
        xmlUnloadFile(xml)
    end
end

local function loadFavoriteTrack()
    local xml = xmlLoadFile("login.xml")
    if xml then
        local savedTrack = xmlNodeGetAttribute(xml, "favoriteTrack")
        xmlUnloadFile(xml)
        if savedTrack and savedTrack ~= "0" and savedTrack ~= "" then 
            return tonumber(savedTrack) 
        end
    end
    return nil
end

local function playCurrentTrack()
    if isElement(bgMusic) then destroyElement(bgMusic) end
    if #playlist == 0 then return end
    
    bgMusic = playSound(playlist[currentTrack].path, true)
    setSoundVolume(bgMusic, musicVolume)
    setSoundPaused(bgMusic, isMusicPaused)
end

function isMouseInPosition(x, y, width, height)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    local cx, cy = cx * screenW, cy * screenH
    return (cx >= x and cx <= x + width and cy >= y and cy <= y + height)
end

local function saveLoginData(user, pass)
    local xml = xmlLoadFile("login.xml")
    if not xml then xml = xmlCreateFile("login.xml", "login") end
    if xml then
        if rememberData then
            xmlNodeSetAttribute(xml, "user", user)
            xmlNodeSetAttribute(xml, "pass", pass)
        else
            xmlNodeSetAttribute(xml, "user", "")
            xmlNodeSetAttribute(xml, "pass", "")
        end
        xmlSaveFile(xml)
        xmlUnloadFile(xml)
    end
end

local function loadLoginData()
    local xml = xmlLoadFile("login.xml")
    if xml then
        local savedUser = xmlNodeGetAttribute(xml, "user")
        local savedPass = xmlNodeGetAttribute(xml, "pass")
        if savedUser and savedPass and savedUser ~= "" then
            guiSetText(userEdit, savedUser)
            guiSetText(passEdit, savedPass)
            rememberData = true
        end
        xmlUnloadFile(xml)
    end
end

local function saveStreamerSetting(musicAllowed)
    local xml = xmlLoadFile("login.xml")
    if not xml then xml = xmlCreateFile("login.xml", "login") end
    if xml then

        xmlNodeSetAttribute(xml, "allowMusic", musicAllowed and "1" or "0")
        xmlSaveFile(xml)
        xmlUnloadFile(xml)
    end
end

local function loadStreamerSetting()
    local xml = xmlLoadFile("login.xml")
    if xml then
        local setting = xmlNodeGetAttribute(xml, "allowMusic")
        xmlUnloadFile(xml)
        
        if setting == "1" then return true, true
        elseif setting == "0" then return true, false end
    end
    return false, false
end

local function renderCameraDrop()
    local progress = (getTickCount() - dropStartTick) / dropDuration
    
    if progress < 1 then
        local cX = interpolateBetween(camTargetX, 0, 0, camTargetX, 0, 0, progress, "InOutQuad")
        local cY = interpolateBetween(camTargetY - 30, 0, 0, camTargetY - 3, 0, 0, progress, "InOutQuad")
        local cZ = interpolateBetween(camTargetZ + 100, 0, 0, camTargetZ + 1, 0, 0, progress, "InOutQuad")
        
        local lookX = camTargetX
        local lookY = camTargetY
        local lookZ = interpolateBetween(camTargetZ, 0, 0, camTargetZ + 0.5, 0, 0, progress, "InOutQuad")
        
        setCameraMatrix(cX, cY, cZ, lookX, lookY, lookZ)
    else
        removeEventHandler("onClientRender", root, renderCameraDrop)
        
        setCameraTarget(localPlayer)
        
        setPlayerHudComponentVisible("all", false)
        setPlayerHudComponentVisible("crosshair", true)
        
        showChat(true)
        
        triggerServerEvent("onPlayerCameraDropEnd", resourceRoot)
    end
end

local function focusEdit(editBox)
    guiBringToFront(editBox)
    guiEditSetCaretIndex(editBox, string.len(guiGetText(editBox)))
end

addEvent("receiveAccountStatus", true)
addEventHandler("receiveAccountStatus", root, function(status, username, devStatus)
    hasRegisteredAccount = status
    isDeveloper = devStatus or false 
end)

addEvent("onClientPasswordResetStep", true)
addEventHandler("onClientPasswordResetStep", root, function(nextMenu)
    if fadeState == "idle" then
        fadeState = "out"
        fadeStartTick = getTickCount()
        targetMenu = nextMenu
        activeInput = nil
    end
end)

addEvent("onClientRegistrationSuccess", true)
addEventHandler("onClientRegistrationSuccess", root, function()
    if showLogin and fadeState == "idle" then
        fadeState = "out"
        fadeStartTick = getTickCount()
        targetMenu = "login"
        activeInput = nil
    end
end)

local function renderBanScreen()
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(30, 30, 30, 255))
    dxDrawImage(0, 0, screenW, screenH, "assets/img/vignette.dds", 0, 0, 0, tocolor(15, 15, 15, 150))
    
    local boxW, boxH = 600, 360
    local boxX, boxY = (screenW - boxW) / 2, (screenH - boxH) / 2
    
    dxDrawText("CSATLAKOZÁS MEGSZAKÍTVA!", boxX, boxY - 50, boxX + boxW, boxY, tocolor(255, 255, 255, 255), 1, fontServerName, "center", "center")
    
    dxDrawText("Ki vagy tiltva a SAS NETWORK szerveréről!", boxX, boxY + 20, boxX + boxW, boxY + 60, tocolor(220, 60, 60, 255), 1, fontTitle, "center", "center")
    
    dxDrawText("Adminisztrátor: #ffffff" .. banAdmin, boxX, boxY + 100, boxX + boxW, boxY + 130, tocolor(180, 180, 180, 255), 1, fontText, "center", "center", false, false, false, true)
    dxDrawText("Kitiltás időpontja: #ffffff" .. banDate, boxX, boxY + 140, boxX + boxW, boxY + 170, tocolor(180, 180, 180, 255), 1, fontText, "center", "center", false, false, false, true)
    dxDrawText("Kitiltás lejár: #ffffff" .. banExpire, boxX, boxY + 180, boxX + boxW, boxY + 210, tocolor(180, 180, 180, 255), 1, fontText, "center", "center", false, false, false, true)
    dxDrawText("Indoklás: #ffffff" .. banReason, boxX, boxY + 220, boxX + boxW, boxY + 250, tocolor(180, 180, 180, 255), 1, fontText, "center", "center", false, false, false, true)
    
    dxDrawText("Ha szerinted jogtalan a kitiltás, unban kérelemre fórumon van lehetőséged!", boxX, boxY + 300, boxX + boxW, boxY + 340, tocolor(100, 100, 100, 255), 1, fontText, "center", "center")
end

local function drawInputField(id, icon, yPos, hiddenEdit, isPassword, placeholder, tooltipText)
    local boxX, boxY, boxW, boxH = panelX + 30, yPos, 340, 35
    local hover = fadeState == "idle" and isMouseInPosition(boxX, boxY, boxW, boxH)

    if hover and tooltipText then activeTooltip = tooltipText end

    local bgAlpha = (hover and 255 or 200) * (formAlpha / 255)
    local textAlpha = 255 * (formAlpha / 255)
    local placeholderAlpha = 150 * (formAlpha / 255)
    local iconAlpha = 150 * (formAlpha / 255)
    local dividerAlpha = 150 * (formAlpha / 255)

    dxDrawRectangle(boxX, boxY, boxW, boxH, tocolor(45, 45, 45, bgAlpha))
    dxDrawText(icon, boxX + 15, boxY, boxX + 35, boxY + boxH, tocolor(150, 150, 150, iconAlpha), 1, fontIcon, "center", "center")
    dxDrawText("|", boxX + 45, boxY, boxX + 50, boxY + boxH - 2, tocolor(100, 100, 100, dividerAlpha), 1, fontText, "center", "center")

    local rawText = guiGetText(hiddenEdit)
    local displayText = isPassword and string.rep("*", utf8.len(rawText) or string.len(rawText)) or rawText
    local textX = boxX + 60

    if rawText == "" then
        if activeInput ~= id then
            dxDrawText(placeholder, textX, boxY, boxX + boxW - 10, boxY + boxH, tocolor(150, 150, 150, placeholderAlpha), 1, fontText, "left", "center")
        end
    else
        dxDrawText(displayText, textX, boxY, boxX + boxW - 10, boxY + boxH, tocolor(255, 255, 255, textAlpha), 1, fontText, "left", "center", true)
    end

    if activeInput == id and fadeState == "idle" then
        local progress = math.min((getTickCount() - animTick) / 300, 1)
        local easeOut = 1 - math.pow(1 - progress, 3)
        local lineW = boxW * easeOut
        local lineX = boxX + (boxW / 2) - (lineW / 2)
        dxDrawRectangle(lineX, boxY + boxH - 2, lineW, 2, tocolor(themeR, themeG, themeB, textAlpha))
        if (getTickCount() % 1000) < 500 then
            local textWidth = dxGetTextWidth(displayText, 1, fontText)
            local cursorX = textX + math.min(textWidth, boxW - 75) + 2
            dxDrawRectangle(cursorX, boxY + 8, 1, boxH - 16, tocolor(255, 255, 255, textAlpha))
        end
    end
end

function renderLoginPanel()
    if not showLogin then return end
    
    activeTooltip = nil

    if fadeState == "out" then
        local progress = (getTickCount() - fadeStartTick) / fadeDuration
        formAlpha = interpolateBetween(255, 0, 0, 0, 0, 0, progress, "Linear")
        if progress >= 1 then
            formAlpha = 0
            currentMenu = targetMenu
            fadeState = "in"
            fadeStartTick = getTickCount()
            guiSetText(passEdit, "") 
            guiSetText(passConfirmEdit, "")
        end
    elseif fadeState == "in" then
        local progress = (getTickCount() - fadeStartTick) / fadeDuration
        formAlpha = interpolateBetween(0, 0, 0, 255, 0, 0, progress, "Linear")
        if progress >= 1 then
            formAlpha = 255
            fadeState = "idle"
        end
    end

    dxDrawRectangle(0, 0, screenW, screenH, tocolor(30, 30, 30, 255))
    dxDrawImage(0, 0, screenW, screenH, "assets/img/vignette.dds", 0, 0, 0, tocolor(15, 15, 15, 120))
    
    local currentTitleY = panelY + 105
    if currentMenu == "register" then currentTitleY = panelY + 60
    elseif currentMenu == "forgot" or currentMenu == "forgot_pin" then currentTitleY = panelY + 150 
    elseif currentMenu == "forgot_newpass" then currentTitleY = panelY + 125 end
    
    local titleRenderY = currentTitleY
    if fadeState == "out" and targetMenu ~= "" then
        local nextTitleY = panelY + 105
        if targetMenu == "register" then nextTitleY = panelY + 60
        elseif targetMenu == "forgot" or targetMenu == "forgot_pin" then nextTitleY = panelY + 150 
        elseif targetMenu == "forgot_newpass" then nextTitleY = panelY + 125 end
        local progress = (getTickCount() - fadeStartTick) / fadeDuration
        titleRenderY = interpolateBetween(currentTitleY, 0, 0, nextTitleY, 0, 0, math.min(progress, 1), "InOutQuad")
    end

    dxDrawText("S A S - N E T W O R K", panelX, titleRenderY - 60, panelX + panelW, titleRenderY - 15, tocolor(255, 255, 255, 255), 1, fontServerName, "center", "bottom")

    if currentMenu == "login" then
        drawInputField("user", "", panelY + 105, userEdit, false, "Felhasználónév")
        drawInputField("pass", "", panelY + 150, passEdit, true, "Jelszó")

        local cbX, cbY = panelX + 30, panelY + 195
        local cbSize = 16
        local cbHover = fadeState == "idle" and isMouseInPosition(cbX, cbY, cbSize, cbSize)
        dxDrawRectangle(cbX, cbY, cbSize, cbSize, tocolor(45, 45, 45, (cbHover and 255 or 200) * (formAlpha / 255)))
        if rememberData then dxDrawRectangle(cbX + 3, cbY + 3, cbSize - 6, cbSize - 6, tocolor(themeR, themeG, themeB, formAlpha)) end
        dxDrawText("Adatok megjegyzése", cbX + 25, cbY, cbX + 150, cbY + cbSize, tocolor(200, 200, 200, 200 * (formAlpha / 255)), 1, fontText, "left", "center")

        local fgW = dxGetTextWidth("Elfelejtett adatok?", 1, fontText)
        local fgX = panelX + 370 - fgW
        local fgHover = fadeState == "idle" and isMouseInPosition(fgX, cbY, fgW, cbSize)
        dxDrawText("Elfelejtett adatok?", fgX, cbY, fgX + fgW, cbY + cbSize, tocolor(fgHover and 255 or 150, fgHover and 255 or 150, fgHover and 255 or 150, (fgHover and 255 or 200) * (formAlpha / 255)), 1, fontText, "right", "center")
        if fgHover then dxDrawRectangle(fgX, cbY + cbSize - 2, fgW, 1, tocolor(255, 255, 255, formAlpha)) end

        local btnY = panelY + 245
        local loginHover = fadeState == "idle" and isMouseInPosition(panelX + 30, btnY, 340, 40)
        dxDrawRectangle(panelX + 30, btnY, 340, 40, tocolor(themeR, themeG, themeB, (loginHover and 255 or 200) * (formAlpha / 255)))
        dxDrawText("Belepes", panelX + 30, btnY, panelX + 370, btnY + 40, tocolor(255, 255, 255, formAlpha), 1, fontButton, "center", "center")

        if not hasRegisteredAccount or isDeveloper then
            local swW = dxGetTextWidth("Nincs még fiókod? Regisztrálj!", 1, fontText)
            local swH = dxGetFontHeight(1, fontText)
            local swX, swY = panelX + (panelW / 2) - (swW / 2), panelY + 315 - (swH / 2)
            local switchHover = fadeState == "idle" and isMouseInPosition(swX, swY, swW, swH)
            dxDrawText("Nincs még fiókod? Regisztrálj!", panelX, panelY + 300, panelX + panelW, panelY + 330, switchHover and tocolor(255, 255, 255, formAlpha) or tocolor(150, 150, 150, formAlpha), 1, fontText, "center", "center")
            if switchHover then dxDrawRectangle(swX, swY + swH, swW, 1, tocolor(255, 255, 255, formAlpha)) end
        end

    elseif currentMenu == "register" then
        drawInputField("user", "", panelY + 60, userEdit, false, "Felhasználónév", "A fiókod bejelentkezési neve.")
        drawInputField("email", "", panelY + 105, emailEdit, false, "Email cím", "Valós email cím a jelszó-visszaállításhoz.")
        drawInputField("pass", "", panelY + 150, passEdit, true, "Jelszó", "Minimum 6 karakter hosszú, biztonságos jelszó.")
        drawInputField("passConf", "", panelY + 195, passConfirmEdit, true, "Jelszó újra", "Írd be újra a fenti jelszavadat a megerősítéshez.")
        drawInputField("char", "", panelY + 240, charEdit, false, "Játékosnév (pl. Player123)...", "Csak betű és szám (min. 4 karakter).")

        local btnY = panelY + 295
        local regHover = fadeState == "idle" and isMouseInPosition(panelX + 30, btnY, 340, 40)
        dxDrawRectangle(panelX + 30, btnY, 340, 40, tocolor(themeR, themeG, themeB, (regHover and 255 or 200) * (formAlpha / 255)))
        dxDrawText("Regisztracio", panelX + 30, btnY, panelX + 370, btnY + 40, tocolor(255, 255, 255, formAlpha), 1, fontButton, "center", "center")

        local swW = dxGetTextWidth("Már van fiókod? Lépj be!", 1, fontText)
        local swH = dxGetFontHeight(1, fontText)
        local swX, swY = panelX + (panelW / 2) - (swW / 2), panelY + 355 - (swH / 2)
        local switchHoverReg = fadeState == "idle" and isMouseInPosition(swX, swY, swW, swH)
        dxDrawText("Már van fiókod? Lépj be!", panelX, panelY + 340, panelX + panelW, panelY + 370, switchHoverReg and tocolor(255, 255, 255, formAlpha) or tocolor(150, 150, 150, formAlpha), 1, fontText, "center", "center")
        if switchHoverReg then dxDrawRectangle(swX, swY + swH, swW, 1, tocolor(255, 255, 255, formAlpha)) end

    elseif currentMenu == "forgot" then
        drawInputField("email", "", panelY + 150, emailEdit, false, "Regisztrált Email cím...", "Add meg az email címedet a visszaállításhoz.")

        local btnY = panelY + 205
        local forgotHover = fadeState == "idle" and isMouseInPosition(panelX + 30, btnY, 340, 40)
        dxDrawRectangle(panelX + 30, btnY, 340, 40, tocolor(themeR, themeG, themeB, (forgotHover and 255 or 200) * (formAlpha / 255)))
        dxDrawText("Visszaallitas", panelX + 30, btnY, panelX + 370, btnY + 40, tocolor(255, 255, 255, formAlpha), 1, fontButton, "center", "center")

        local swW = dxGetTextWidth("Vissza a bejelentkezéshez", 1, fontText)
        local swH = dxGetFontHeight(1, fontText)
        local swX, swY = panelX + (panelW / 2) - (swW / 2), panelY + 265 - (swH / 2)
        local swHover = fadeState == "idle" and isMouseInPosition(swX, swY, swW, swH)
        dxDrawText("Vissza a bejelentkezéshez", panelX, panelY + 250, panelX + panelW, panelY + 280, swHover and tocolor(255, 255, 255, formAlpha) or tocolor(150, 150, 150, formAlpha), 1, fontText, "center", "center")
        if swHover then dxDrawRectangle(swX, swY + swH, swW, 1, tocolor(255, 255, 255, formAlpha)) end
        
    elseif currentMenu == "forgot_pin" then
        drawInputField("pin", "", panelY + 150, pinEdit, false, "6-jegyű email kód...", "Írd be az emailben kapott 6 számjegyű kódot.")

        local btnY = panelY + 205
        local pinHover = fadeState == "idle" and isMouseInPosition(panelX + 30, btnY, 340, 40)
        dxDrawRectangle(panelX + 30, btnY, 340, 40, tocolor(themeR, themeG, themeB, (pinHover and 255 or 200) * (formAlpha / 255)))
        dxDrawText("Kod ellenorzese", panelX + 30, btnY, panelX + 370, btnY + 40, tocolor(255, 255, 255, formAlpha), 1, fontButton, "center", "center")

        local swW = dxGetTextWidth("Vissza a bejelentkezéshez", 1, fontText)
        local swH = dxGetFontHeight(1, fontText)
        local swX, swY = panelX + (panelW / 2) - (swW / 2), panelY + 265 - (swH / 2)
        local swHover = fadeState == "idle" and isMouseInPosition(swX, swY, swW, swH)
        dxDrawText("Vissza a bejelentkezéshez", panelX, panelY + 250, panelX + panelW, panelY + 280, swHover and tocolor(255, 255, 255, formAlpha) or tocolor(150, 150, 150, formAlpha), 1, fontText, "center", "center")
        if swHover then dxDrawRectangle(swX, swY + swH, swW, 1, tocolor(255, 255, 255, formAlpha)) end

    elseif currentMenu == "forgot_newpass" then
        drawInputField("newpass", "", panelY + 125, newPassEdit, true, "Új jelszó...", "Minimum 6 karakter hosszú jelszó.")
        drawInputField("newpassconf", "", panelY + 170, newPassConfEdit, true, "Új jelszó újra...", "Írd be újra a megerősítéshez.")

        local btnY = panelY + 225
        local saveHover = fadeState == "idle" and isMouseInPosition(panelX + 30, btnY, 340, 40)
        dxDrawRectangle(panelX + 30, btnY, 340, 40, tocolor(themeR, themeG, themeB, (saveHover and 255 or 200) * (formAlpha / 255)))
        dxDrawText("Uj jelszo mentese", panelX + 30, btnY, panelX + 370, btnY + 40, tocolor(255, 255, 255, formAlpha), 1, fontButton, "center", "center")

        local swW = dxGetTextWidth("Megse (Vissza a bejelentkezeshez)", 1, fontText)
        local swH = dxGetFontHeight(1, fontText)
        local swX, swY = panelX + (panelW / 2) - (swW / 2), panelY + 285 - (swH / 2)
        local swHover = fadeState == "idle" and isMouseInPosition(swX, swY, swW, swH)
        dxDrawText("Megse (Vissza a bejelentkezeshez)", panelX, panelY + 270, panelX + panelW, panelY + 300, swHover and tocolor(255, 255, 255, formAlpha) or tocolor(150, 150, 150, formAlpha), 1, fontText, "center", "center")
        if swHover then dxDrawRectangle(swX, swY + swH, swW, 1, tocolor(255, 255, 255, formAlpha)) end
    end
    
    if activeTooltip and formAlpha > 0 then
        local cx, cy = getCursorPosition()
        if cx and cy then
            cx, cy = cx * screenW, cy * screenH
            local tooltipW = dxGetTextWidth(activeTooltip, 1, fontText) + 20 
            local tooltipH = dxGetFontHeight(1, fontText) + 14 
            local tipX, tipY = cx + 15, cy + 15
            
            if tipX + tooltipW > screenW then tipX = cx - tooltipW - 10 end
            if tipY + tooltipH > screenH then tipY = cy - tooltipH - 10 end
            
            dxDrawRectangle(tipX, tipY, tooltipW, tooltipH, tocolor(20, 20, 20, formAlpha * 0.95), true)
            dxDrawRectangle(tipX, tipY, 2, tooltipH, tocolor(themeR, themeG, themeB, formAlpha), true)
            dxDrawText(activeTooltip, tipX + 10, tipY, tipX + tooltipW - 10, tipY + tooltipH, tocolor(220, 220, 220, formAlpha), 1, fontText, "left", "center", false, false, true)
        end
    end

    local mpW, mpH = 260, 80
    local mpX, mpY = 30, screenH - mpH - 30
    local mpAlpha = formAlpha
    
    if mpAlpha > 0 then
        dxDrawRectangle(mpX, mpY, mpW, mpH, tocolor(20, 20, 20, mpAlpha * 0.9))
        dxDrawRectangle(mpX, mpY, 3, mpH, tocolor(themeR, themeG, themeB, mpAlpha))
        
        local currentTrackName = playlist[currentTrack].name
        dxDrawText(currentTrackName, mpX + 15, mpY + 8, mpX + mpW - 30, mpY + 25, tocolor(200, 200, 200, mpAlpha), 1, fontText, "left", "center", true)
        
        local starX = mpX + mpW - 25
        local starY = mpY + 8
        local starHover = isMouseInPosition(starX, starY - 5, 20, 20)
        
        local isFav = (favoriteTrack ~= nil and currentTrack == favoriteTrack)
        local starColor = tocolor(100, 100, 100, mpAlpha)
        
        if isFav then
            starColor = tocolor(255, 215, 0, mpAlpha)
        elseif starHover then
            starColor = tocolor(200, 200, 200, mpAlpha)
        end
        
        dxDrawText("", starX, starY - 5, starX + 20, starY + 15, starColor, 0.8, fontIcon, "center", "center")
        
        local btnY = mpY + 30
        
        local prevHover = isMouseInPosition(mpX + 80, btnY, 20, 20)
        dxDrawText("", mpX + 80, btnY, mpX + 100, btnY + 20, tocolor(255, 255, 255, prevHover and mpAlpha or mpAlpha * 0.5), 1, fontIcon, "center", "center")
        
        local playHover = isMouseInPosition(mpX + 120, btnY, 20, 20)
        local playIcon = isMusicPaused and "" or ""
        dxDrawText(playIcon, mpX + 120, btnY, mpX + 140, btnY + 20, tocolor(themeR, themeG, themeB, playHover and mpAlpha or mpAlpha * 0.7), 1, fontIcon, "center", "center")
        
        local nextHover = isMouseInPosition(mpX + 160, btnY, 20, 20)
        dxDrawText("", mpX + 160, btnY, mpX + 180, btnY + 20, tocolor(255, 255, 255, nextHover and mpAlpha or mpAlpha * 0.5), 1, fontIcon, "center", "center")

        local sliderX = mpX + 20
        local sliderY = mpY + 60
        local sliderW = mpW - 40
        local sliderH = 4

        if getKeyState("mouse1") and isCursorShowing() then
            if isMouseInPosition(sliderX - 5, sliderY - 5, sliderW + 10, sliderH + 10) or isDraggingVolume then
                isDraggingVolume = true
                local cx, cy = getCursorPosition()
                cx = cx * screenW
                local newVol = (cx - sliderX) / sliderW
                musicVolume = math.max(0, math.min(1, newVol))
                if isElement(bgMusic) then setSoundVolume(bgMusic, musicVolume) end
            end
        else
            isDraggingVolume = false
        end

        dxDrawRectangle(sliderX, sliderY, sliderW, sliderH, tocolor(0, 0, 0, mpAlpha * 0.6))
        dxDrawRectangle(sliderX, sliderY, sliderW * musicVolume, sliderH, tocolor(themeR, themeG, themeB, mpAlpha))
        dxDrawRectangle(sliderX + (sliderW * musicVolume) - 4, sliderY - 4, 8, 12, tocolor(255, 255, 255, mpAlpha))
    end
end

function clickLoginPanel(button, state)
    if not showLogin or button ~= "left" or state ~= "down" or fadeState ~= "idle" then return end

    local mpW, mpH = 260, 80
    local mpX, mpY = 30, screenH - mpH - 30
    local btnY = mpY + 30
    
    local starX = mpX + mpW - 25
    local starY = mpY + 8

    if isMouseInPosition(starX, starY - 5, 20, 20) then
        if favoriteTrack == currentTrack then
            favoriteTrack = nil 
        else
            favoriteTrack = currentTrack 
        end
        saveFavoriteTrack(favoriteTrack)
        return
        
    elseif isMouseInPosition(mpX + 80, btnY, 20, 20) then 
        currentTrack = currentTrack - 1
        if currentTrack < 1 then currentTrack = #playlist end
        playCurrentTrack()
        return
    elseif isMouseInPosition(mpX + 120, btnY, 20, 20) then 
        if not isElement(bgMusic) then
            isMusicPaused = false
            playCurrentTrack()
        else
            isMusicPaused = not isMusicPaused
            setSoundPaused(bgMusic, isMusicPaused)
        end
        return
    elseif isMouseInPosition(mpX + 160, btnY, 20, 20) then 
        currentTrack = currentTrack + 1
        if currentTrack > #playlist then currentTrack = 1 end
        playCurrentTrack()
        return
    end

    if currentMenu == "login" then
        if isMouseInPosition(panelX + 30, panelY + 105, 340, 35) then focusEdit(userEdit) return
        elseif isMouseInPosition(panelX + 30, panelY + 150, 340, 35) then focusEdit(passEdit) return
        end

        local cbTextW = dxGetTextWidth("Adatok megjegyzése", 1, fontText)
        if isMouseInPosition(panelX + 30, panelY + 195, 16 + 10 + cbTextW, 16) then
            rememberData = not rememberData
            return
        end

        local fgW = dxGetTextWidth("Elfelejtett adatok?", 1, fontText)
        if isMouseInPosition(panelX + 370 - fgW, panelY + 195, fgW, 16) then
            fadeState = "out"
            fadeStartTick = getTickCount()
            targetMenu = "forgot"
            activeInput = nil
            return
        end

        if isMouseInPosition(panelX + 30, panelY + 245, 340, 40) then
            local user = guiGetText(userEdit)
            local pass = guiGetText(passEdit)
            
            if user == "" or pass == "" then exports.sas_interface:addNotification("warning", "Töltsd ki az adatokat!") return end
            saveLoginData(user, pass)
            triggerServerEvent("onPlayerRequestLogin", resourceRoot, user, pass)
            return
        end
        
        if not hasRegisteredAccount or isDeveloper then
            local swW = dxGetTextWidth("Nincs még fiókod? Regisztrálj!", 1, fontText)
            local swH = dxGetFontHeight(1, fontText)
            local swX, swY = panelX + (panelW / 2) - (swW / 2), panelY + 315 - (swH / 2)
            if isMouseInPosition(swX, swY, swW, swH) then
                fadeState = "out"
                fadeStartTick = getTickCount()
                targetMenu = "register"
                activeInput = nil
            end
        end
        
    elseif currentMenu == "register" then
        if isMouseInPosition(panelX + 30, panelY + 60, 340, 35) then focusEdit(userEdit) return
        elseif isMouseInPosition(panelX + 30, panelY + 105, 340, 35) then focusEdit(emailEdit) return
        elseif isMouseInPosition(panelX + 30, panelY + 150, 340, 35) then focusEdit(passEdit) return
        elseif isMouseInPosition(panelX + 30, panelY + 195, 340, 35) then focusEdit(passConfirmEdit) return
        elseif isMouseInPosition(panelX + 30, panelY + 240, 340, 35) then focusEdit(charEdit) return 
        end

        if isMouseInPosition(panelX + 30, panelY + 295, 340, 40) then
            local user = guiGetText(userEdit)
            local pass = guiGetText(passEdit)
            local passConf = guiGetText(passConfirmEdit)
            local email = guiGetText(emailEdit)
            local char = guiGetText(charEdit)

            if user == "" or pass == "" or email == "" or char == "" then exports.sas_interface:addNotification("error", "Minden mezőt ki kell tölteni!") return end
            if pass ~= passConf then exports.sas_interface:addNotification("error", "A két jelszó nem egyezik!") return end
            if utf8.len(char) < 4 then exports.sas_interface:addNotification("warning", "A játékosnévnek legalább 4 karakterből kell állnia!") return end
            if not string.match(char, "^[a-zA-Z0-9]+$") then exports.sas_interface:addNotification("warning", "A játékosnév csak betűt és számot tartalmazhat!") return end
            
            triggerServerEvent("onPlayerRequestRegister", resourceRoot, user, pass, email, char)
            return
        end

        local swW = dxGetTextWidth("Már van fiókod? Lépj be!", 1, fontText)
        local swH = dxGetFontHeight(1, fontText)
        local swX, swY = panelX + (panelW / 2) - (swW / 2), panelY + 355 - (swH / 2)
        if isMouseInPosition(swX, swY, swW, swH) then
            fadeState = "out"
            fadeStartTick = getTickCount()
            targetMenu = "login"
            activeInput = nil
        end

    elseif currentMenu == "forgot" then
        if isMouseInPosition(panelX + 30, panelY + 150, 340, 35) then focusEdit(emailEdit) return end

        if isMouseInPosition(panelX + 30, panelY + 205, 340, 40) then
            local email = guiGetText(emailEdit)
            if email == "" then exports.sas_interface:addNotification("warning", "Add meg az email címed!") return end
            
            local now = getTickCount()
            if now - lastResetClick < resetCooldown then
                local remaining = math.ceil((resetCooldown - (now - lastResetClick)) / 1000)
                exports.sas_interface:addNotification("info", "Várj " .. remaining .. " másodpercet az újabb kérés előtt!")
                return
            end
            
            lastResetClick = now
            triggerServerEvent("onPlayerRequestPasswordReset", resourceRoot, email)
            return
        end

        local swW = dxGetTextWidth("Vissza a bejelentkezéshez", 1, fontText)
        local swH = dxGetFontHeight(1, fontText)
        local swX, swY = panelX + (panelW / 2) - (swW / 2), panelY + 265 - (swH / 2)
        if isMouseInPosition(swX, swY, swW, swH) then
            fadeState = "out"
            fadeStartTick = getTickCount()
            targetMenu = "login"
            activeInput = nil
        end
        
    elseif currentMenu == "forgot_pin" then
        if isMouseInPosition(panelX + 30, panelY + 150, 340, 35) then focusEdit(pinEdit) return end

        if isMouseInPosition(panelX + 30, panelY + 205, 340, 40) then
            local pin = guiGetText(pinEdit)
            if string.len(pin) ~= 6 then exports.sas_interface:addNotification("info", "A kódnak pontosan 6 számjegyből kell állnia!") return end
            triggerServerEvent("onPlayerVerifyResetPIN", resourceRoot, pin)
            return
        end

        local swW = dxGetTextWidth("Vissza a bejelentkezéshez", 1, fontText)
        local swH = dxGetFontHeight(1, fontText)
        local swX, swY = panelX + (panelW / 2) - (swW / 2), panelY + 265 - (swH / 2)
        if isMouseInPosition(swX, swY, swW, swH) then
            fadeState = "out"
            fadeStartTick = getTickCount()
            targetMenu = "login"
            activeInput = nil
        end

    elseif currentMenu == "forgot_newpass" then
        if isMouseInPosition(panelX + 30, panelY + 125, 340, 35) then focusEdit(newPassEdit) return
        elseif isMouseInPosition(panelX + 30, panelY + 170, 340, 35) then focusEdit(newPassConfEdit) return end

        if isMouseInPosition(panelX + 30, panelY + 225, 340, 40) then
            local np1 = guiGetText(newPassEdit)
            local np2 = guiGetText(newPassConfEdit)
            if np1 == "" or np2 == "" then exports.sas_interface:addNotification("info", "Töltsd ki mindkét mezőt!") return end
            if string.len(np1) < 6 then exports.sas_interface:addNotification("warning", "A jelszónak minimum 6 karakternek kell lennie!") return end
            if np1 ~= np2 then exports.sas_interface:addNotification("error", "A két jelszó nem egyezik!") return end
            
            triggerServerEvent("onPlayerResetPassword", resourceRoot, np1)
            return
        end

        local swW = dxGetTextWidth("Megse (Vissza a bejelentkezeshez)", 1, fontText)
        local swH = dxGetFontHeight(1, fontText)
        local swX, swY = panelX + (panelW / 2) - (swW / 2), panelY + 285 - (swH / 2)
        if isMouseInPosition(swX, swY, swW, swH) then
            fadeState = "out"
            fadeStartTick = getTickCount()
            targetMenu = "login"
            activeInput = nil
        end
    end
end

local function setupFocusHandlers(element, id)
    addEventHandler("onClientGUIFocus", element, function()
        if activeInput ~= id and fadeState == "idle" then
            activeInput = id
            animTick = getTickCount()
        end
    end, false)
    addEventHandler("onClientGUIBlur", element, function()
        if activeInput == id then activeInput = nil end
    end, false)
end

local function initLoginPanel()
    showLogin = true
    showCursor(true)
    
    if hasRegisteredAccount or isDeveloper then currentMenu = "login" else currentMenu = "register" end
    
    rememberData = false 
    formAlpha = 255
    fadeState = "idle"
    
    userEdit = guiCreateEdit(-1000, -1000, 0, 0, "", false)
    passEdit = guiCreateEdit(-1000, -1000, 0, 0, "", false)
    passConfirmEdit = guiCreateEdit(-1000, -1000, 0, 0, "", false)
    emailEdit = guiCreateEdit(-1000, -1000, 0, 0, "", false)
    charEdit = guiCreateEdit(-1000, -1000, 0, 0, "", false)
    pinEdit = guiCreateEdit(-1000, -1000, 0, 0, "", false)
    newPassEdit = guiCreateEdit(-1000, -1000, 0, 0, "", false)
    newPassConfEdit = guiCreateEdit(-1000, -1000, 0, 0, "", false)

    guiEditSetMaxLength(userEdit, 20) 
    guiEditSetMaxLength(passEdit, 20) 
    guiEditSetMaxLength(passConfirmEdit, 20)
    guiEditSetMaxLength(emailEdit, 50)
    guiEditSetMaxLength(charEdit, 30)
    guiEditSetMaxLength(pinEdit, 6) 
    guiEditSetMaxLength(newPassEdit, 20)
    guiEditSetMaxLength(newPassConfEdit, 20)

    setupFocusHandlers(userEdit, "user")
    setupFocusHandlers(passEdit, "pass")
    setupFocusHandlers(passConfirmEdit, "passConf")
    setupFocusHandlers(emailEdit, "email")
    setupFocusHandlers(charEdit, "char")
    setupFocusHandlers(pinEdit, "pin")
    setupFocusHandlers(newPassEdit, "newpass")
    setupFocusHandlers(newPassConfEdit, "newpassconf")
    
    loadLoginData()

    addEventHandler("onClientRender", root, renderLoginPanel)
    addEventHandler("onClientClick", root, clickLoginPanel)
end

local function onStreamerPromptClick(button, state)
    if not showStreamerPrompt or button ~= "left" or state ~= "down" then return end
    
    local pW, pH = 420, 180
    local pX, pY = (screenW - pW) / 2, (screenH - pH) / 2
    local btnW, btnH = 170, 35
    local yesX = pX + 20
    local noX = pX + pW - btnW - 20
    local btnY = pY + 125
    
    if isMouseInPosition(yesX, btnY, btnW, btnH) then
        allowMusic = false
        showStreamerPrompt = false
        saveStreamerSetting(false)
        removeEventHandler("onClientClick", root, onStreamerPromptClick)
    elseif isMouseInPosition(noX, btnY, btnW, btnH) then
        allowMusic = true
        showStreamerPrompt = false
        saveStreamerSetting(true)
        removeEventHandler("onClientClick", root, onStreamerPromptClick)
    end
end

local function renderLoadingScreen()
    local currentTick = getTickCount()
    
    if showStreamerPrompt then
        showCursor(true)
        local pW, pH = 420, 180
        local pX, pY = (screenW - pW) / 2, (screenH - pH) / 2
        
        dxDrawRectangle(0, 0, screenW, screenH, tocolor(30, 30, 30, 255))
        dxDrawImage(0, 0, screenW, screenH, "assets/img/vignette.dds", 0, 0, 0, tocolor(15, 15, 15, 120))
        
        dxDrawText("STREAMER MÓD BEÁLLÍTÁSA", pX, pY + 15, pX + pW, pY + 45, tocolor(themeR, themeG, themeB, 255), 1, fontTitle, "center", "center")
        
        dxDrawText("Szeretnéd bekapcsolni a Streamer módot?\nHa bekapcsolod, a jogvédett zenék automatikusan némítva lesznek.", pX + 20, pY + 50, pX + pW - 20, pY + 110, tocolor(200, 200, 200, 255), 1, fontText, "center", "center", false, false)
        
        local btnW, btnH = 170, 35
        local yesX = pX + 20
        local noX = pX + pW - btnW - 20
        local btnY = pY + 125
        
        local yesHover = isMouseInPosition(yesX, btnY, btnW, btnH)
        dxDrawRectangle(yesX, btnY, btnW, btnH, tocolor(themeR, themeG, themeB, yesHover and 255 or 200))
        dxDrawText("Igen", yesX, btnY, yesX + btnW, btnY + btnH, tocolor(255, 255, 255, 255), 1, fontText, "center", "center")
        
        local noHover = isMouseInPosition(noX, btnY, btnW, btnH)
        dxDrawRectangle(noX, btnY, btnW, btnH, tocolor(243, 90, 90, noHover and 255 or 200))
        dxDrawText("Nem", noX, btnY, noX + btnW, btnY + btnH, tocolor(255, 255, 255, 255), 1, fontText, "center", "center")
        
        lastRenderTick = getTickCount()
        return
    end

    local deltaTime = currentTick - lastRenderTick
    lastRenderTick = currentTick
    
    if currentProgress < 1 then
        if not isLoadingPaused then
            currentProgress = currentProgress + (deltaTime / 30000)
            
            if currentProgress >= nextPauseThreshold and currentProgress < 0.95 then
                isLoadingPaused = true
                loadingPauseEndTime = currentTick + math.random(2000, 4000) 
                nextPauseThreshold = currentProgress + (math.random(15, 30) / 100)
            end
        else
            if currentTick >= loadingPauseEndTime then isLoadingPaused = false end
        end
        
        if allowMusic and currentProgress >= 0.80 and not musicStarted then
            musicStarted = true
            playCurrentTrack()
        end
    end
    
    if currentProgress >= 1 then
        currentProgress = 1
        removeEventHandler("onClientRender", root, renderLoadingScreen)
        initLoginPanel()
        return 
    end

    local cx, cy = screenW / 2, screenH / 2
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(30, 30, 30, 255))
    dxDrawImage(0, 0, screenW, screenH, "assets/img/vignette.dds", 0, 0, 0, tocolor(15, 15, 15, 120))
    
    local rotation = (getTickCount() / 2.5) % 360
    dxDrawText("", cx - 50, cy - 70, cx + 50, cy + 30, tocolor(themeR, themeG, themeB, 255), 1, fontLoaderIcon, "center", "center", false, false, false, false, false, rotation, cx, cy - 20)
    
    local baseText = ""
    if currentProgress < 0.33 then baseText = "Modellek betöltése"
    elseif currentProgress < 0.66 then baseText = "Járművek betöltése"
    else baseText = "Szerver szinkronizáció" end
    
    local dotCount = math.floor(getTickCount() / 400) % 4
    local dots = string.rep(".", dotCount)
    dxDrawText(baseText .. dots, cx - 200, cy + 30, cx + 200, cy + 70, tocolor(255, 255, 255, 255), 1, fontTitle, "center", "center")

    dxDrawRectangle(0, screenH - 6, screenW, 6, tocolor(15, 15, 15, 200))
    dxDrawRectangle(0, screenH - 6, screenW * currentProgress, 6, tocolor(themeR, themeG, themeB, 255))
end

function startDXLogin()
    fadeCamera(true)
    showChat(false)
    setPlayerHudComponentVisible("all", false)
    
    fontTitle = dxCreateFont("assets/BebasNeueBold.otf", 26) or "default-bold"
    fontButton = dxCreateFont("assets/BebasNeueBold.otf", 18) or "default-bold"
    fontText = dxCreateFont("assets/Roboto.ttf", 10) or "default"
    fontIcon = dxCreateFont("assets/FontAwesome.otf", 12) or "default"
    fontLoaderIcon = dxCreateFont("assets/FontAwesome.otf", 45) or "default"
    fontServerName = dxCreateFont("assets/Ubuntu-L.ttf", 24) or "default-bold"
    
    currentProgress = 0
    isLoadingPaused = false
    lastRenderTick = getTickCount()
    nextPauseThreshold = math.random(10, 30) / 100
    musicStarted = false
    
    local hasSetting, savedMusicState = loadStreamerSetting()
    
    favoriteTrack = loadFavoriteTrack()
    
    if favoriteTrack then
        currentTrack = favoriteTrack
    else
        math.randomseed(getTickCount())
        currentTrack = math.random(1, #playlist)
    end
    
    if hasSetting then
        showStreamerPrompt = false
        allowMusic = savedMusicState
    else
        showStreamerPrompt = true
        allowMusic = false
        addEventHandler("onClientClick", root, onStreamerPromptClick)
    end
    
    triggerServerEvent("checkAccountStatus", resourceRoot)
    
    addEventHandler("onClientRender", root, renderLoadingScreen)
end
addEventHandler("onClientResourceStart", resourceRoot, startDXLogin)

addEvent("receiveBanStatus", true)
addEventHandler("receiveBanStatus", root, function(reason, admin, expire, date)
    isBanned = true
    banReason = reason or "Ismeretlen ok"
    banAdmin = admin or "Rendszer"
    banExpire = expire or "Soha"
    banDate = date or "Ismeretlen"
    
    showLogin = false 
    showStreamerPrompt = false 
    showCursor(true)
    
    if isElement(bgMusic) then destroyElement(bgMusic) end
    
    removeEventHandler("onClientRender", root, renderLoadingScreen)
    removeEventHandler("onClientRender", root, renderLoginPanel)
    removeEventHandler("onClientClick", root, clickLoginPanel)
    
    addEventHandler("onClientRender", root, renderBanScreen)
end)

addEvent("closeLoginPanelAndDropCamera", true)
addEventHandler("closeLoginPanelAndDropCamera", root, function(tX, tY, tZ)
    showLogin = false
    showCursor(false)
    removeEventHandler("onClientRender", root, renderLoginPanel)
    removeEventHandler("onClientClick", root, clickLoginPanel)
    
    if isElement(bgMusic) then destroyElement(bgMusic) end
    if isElement(userEdit) then destroyElement(userEdit) end
    if isElement(passEdit) then destroyElement(passEdit) end
    if isElement(passConfirmEdit) then destroyElement(passConfirmEdit) end
    if isElement(emailEdit) then destroyElement(emailEdit) end
    if isElement(charEdit) then destroyElement(charEdit) end
    if isElement(pinEdit) then destroyElement(pinEdit) end
    if isElement(newPassEdit) then destroyElement(newPassEdit) end
    if isElement(newPassConfEdit) then destroyElement(newPassConfEdit) end
    
    if isElement(fontTitle) then destroyElement(fontTitle) end
    if isElement(fontButton) then destroyElement(fontButton) end
    if isElement(fontText) then destroyElement(fontText) end
    if isElement(fontIcon) then destroyElement(fontIcon) end
    if isElement(fontLoaderIcon) then destroyElement(fontLoaderIcon) end
    if isElement(fontServerName) then destroyElement(fontServerName) end

    camTargetX, camTargetY, camTargetZ = tX, tY, tZ
    dropStartTick = getTickCount()
    
    addEventHandler("onClientRender", root, renderCameraDrop)
end)