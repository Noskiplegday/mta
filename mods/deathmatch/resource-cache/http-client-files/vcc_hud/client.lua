-- vcc_hud/client.lua
-- Full DX HUD: Máu, Giáp, Đói, Khát, Tiền, Giờ, Mini-info

local screenW, screenH = guiGetScreenSize()
local scale = screenH / 768  -- responsive scale

-- HUD values (sync từ server hoặc local)
local hudData = {
    health  = 100,
    armor   = 0,
    hunger  = 100,  -- 100 = no, 0 = starving
    thirst  = 100,  -- 100 = full, 0 = dehydrated
    money   = 0,
    name    = "Player",
}

-- Animation states
local anim = {
    health = 100, armor = 0, hunger = 100, thirst = 100,
}

-- Colors
local C = {
    red       = tocolor(192, 57, 43, 255),
    redBright = tocolor(231, 76, 60, 255),
    redGlow   = tocolor(192, 57, 43, 80),
    green     = tocolor(39, 174, 96, 255),
    greenB    = tocolor(46, 204, 113, 255),
    blue      = tocolor(52, 152, 219, 255),
    gold      = tocolor(243, 156, 18, 255),
    white     = tocolor(255, 255, 255, 255),
    white80   = tocolor(255, 255, 255, 200),
    white40   = tocolor(255, 255, 255, 100),
    dark      = tocolor(10, 0, 0, 200),
    dark2     = tocolor(0, 0, 0, 140),
    trans     = tocolor(0, 0, 0, 0),
    orange    = tocolor(230, 126, 34, 255),
    yellow    = tocolor(241, 196, 15, 255),
}

local function lerp(a, b, t)
    return a + (b - a) * math.min(t, 1)
end

local function getBarColor(pct)
    if pct > 60 then return C.green
    elseif pct > 30 then return C.orange
    else return C.redBright end
end

local function drawRoundRect(x, y, w, h, r, col)
    dxDrawRectangle(x + r, y, w - 2*r, h, col)
    dxDrawRectangle(x, y + r, w, h - 2*r, col)
    dxDrawCircle(x + r, y + r, r, 180, 270, col, col, 8)
    dxDrawCircle(x + w - r, y + r, r, 270, 360, col, col, 8)
    dxDrawCircle(x + r, y + h - r, r, 90, 180, col, col, 8)
    dxDrawCircle(x + w - r, y + h - r, r, 0, 90, col, col, 8)
end

-- Utility: draw bar with background, fill, icon
local function drawStatBar(x, y, w, h, value, maxVal, icon, label, col)
    local pct = value / maxVal
    local barcol = col or getBarColor(pct * 100)

    -- Background
    dxDrawRectangle(x, y, w, h, tocolor(0, 0, 0, 150), false, false)
    -- Border
    dxDrawRectangle(x - 1, y - 1, w + 2, 1, tocolor(255,255,255,20))
    dxDrawRectangle(x - 1, y + h, w + 2, 1, tocolor(255,255,255,10))

    -- Fill
    local fillW = math.max(0, (w - 2) * pct)
    if fillW > 0 then
        dxDrawRectangle(x + 1, y + 1, fillW, h - 2, barcol)
        -- Shine
        dxDrawRectangle(x + 1, y + 1, fillW, math.floor(h/2) - 1, tocolor(255,255,255,15))
    end

    -- Icon
    dxDrawText(icon, x - 22, y - 2, x, y + h + 2, C.white80, scale * 0.85, "default-bold", "right", "center")

    -- Value text
    local valText = math.floor(value).."%"
    dxDrawText(valText, x + w + 4, y, x + w + 40, y + h, C.white40, scale * 0.7, "default", "left", "center")
end

-- Draw animated pulsing icon when low
local function drawPulseWarning(x, y, text)
    local alpha = math.abs(math.sin(getTickCount() / 400)) * 255
    dxDrawText(text, x, y, x + 100, y + 20, tocolor(231, 76, 60, alpha), scale * 0.85, "default-bold")
end

local hudVisible = true
local showHud = true

addEventHandler("onClientRender", root, function()
    if not showHud then return end
    if isPedDead(localPlayer) then return end

    -- Smooth animation
    local dt = 0.06
    anim.health = lerp(anim.health, hudData.health, dt)
    anim.armor  = lerp(anim.armor, hudData.armor, dt)
    anim.hunger = lerp(anim.hunger, hudData.hunger, dt)
    anim.thirst = lerp(anim.thirst, hudData.thirst, dt)

    -- == LEFT BOTTOM HUD ==
    local bx = 16 * scale
    local by = screenH - 160 * scale
    local bw = 160 * scale
    local bh = 10 * scale
    local gap = 22 * scale

    -- Panel bg
    local panelX, panelY = bx - 30*scale, by - 14*scale
    local panelW, panelH = 220*scale, 120*scale
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(5, 0, 0, 180))
    dxDrawRectangle(panelX, panelY, panelW, 1, C.red)
    dxDrawRectangle(panelX, panelY + panelH - 1, panelW, 1, tocolor(192,57,43,100))
    dxDrawRectangle(panelX, panelY, 1, panelH, C.red)

    -- Player name + money
    local nameStr = hudData.name
    dxDrawText(nameStr, panelX + 4, panelY + 3, panelX + panelW, panelY + 16*scale,
        C.red, scale * 0.75, "default-bold")

    local moneyStr = "$"..tostring(hudData.money):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    dxDrawText(moneyStr, panelX + 4, panelY + 16*scale, panelX + panelW, panelY + 28*scale,
        C.green, scale * 0.8, "default-bold")

    -- HEALTH BAR
    local healthCol = getBarColor(anim.health)
    drawStatBar(bx, by, bw, bh, anim.health, 100, "❤", "HP", healthCol)

    -- ARMOR BAR
    drawStatBar(bx, by + gap, bw, bh, anim.armor, 100, "🛡", "AP", C.blue)

    -- HUNGER BAR
    local hungCol = getBarColor(anim.hunger)
    drawStatBar(bx, by + gap * 2, bw, bh, anim.hunger, 100, "🍖", "ĐÓI", hungCol)

    -- THIRST BAR
    local thirCol = getBarColor(anim.thirst)
    drawStatBar(bx, by + gap * 3, bw, bh, anim.thirst, 100, "💧", "KHÁT", thirCol)

    -- LOW warnings
    if hudData.health < 30 then
        drawPulseWarning(panelX + 5, panelY - 22*scale, "⚠ MÁU THẤP!")
    end
    if hudData.hunger < 20 then
        drawPulseWarning(panelX + 5, panelY - 38*scale, "⚠ ĐÓI!")
    end
    if hudData.thirst < 20 then
        drawPulseWarning(panelX + 5, panelY - 54*scale, "⚠ KHÁT!")
    end

    -- == TOP RIGHT: Clock + Server Info ==
    local tr_x = screenW - 130*scale
    local tr_y = 14*scale
    local hh, mm, ss = tostring(os.date("%H")), tostring(os.date("%M")), tostring(os.date("%S"))
    local timeStr = hh..":"..mm
    dxDrawRectangle(tr_x - 8*scale, tr_y - 6*scale, 125*scale, 32*scale, tocolor(5,0,0,180))
    dxDrawRectangle(tr_x - 8*scale, tr_y - 6*scale, 125*scale, 1, C.red)
    dxDrawText("🕐 "..timeStr, tr_x, tr_y, tr_x + 110*scale, tr_y + 20*scale,
        C.white80, scale * 1.1, "default-bold", "center", "center")
    dxDrawText("VAN CANH CITY", tr_x, tr_y + 22*scale, tr_x + 110*scale, tr_y + 34*scale,
        C.red, scale * 0.6, "default", "center")
end)

-- Update health from MTA
addEventHandler("onClientPlayerDamage", localPlayer, function()
    setTimer(function()
        hudData.health = getElementHealth(localPlayer)
    end, 50, 1)
end)

-- Sync từ server
addEvent("vcc:updateHUD", true)
addEventHandler("vcc:updateHUD", root, function(data)
    if data.health  ~= nil then hudData.health  = data.health  end
    if data.armor   ~= nil then hudData.armor   = data.armor   end
    if data.hunger  ~= nil then hudData.hunger  = data.hunger  end
    if data.thirst  ~= nil then hudData.thirst  = data.thirst  end
    if data.money   ~= nil then hudData.money   = data.money   end
    if data.name    ~= nil then hudData.name    = data.name    end
end)

-- Sync health locally every frame
addEventHandler("onClientRender", root, function()
    hudData.health = getElementHealth(localPlayer)
    hudData.armor  = getPedArmor(localPlayer)
end)

-- Toggle HUD with F7
bindKey("F7", "down", function()
    showHud = not showHud
    setPlayerHudComponentVisible("all", showHud)
    outputChatBox("[VCC] HUD: "..(showHud and "Bật" or "Tắt"), 192, 57, 43)
end)

-- Hide default HUD elements we're replacing
addEventHandler("onClientResourceStart", resourceRoot, function()
    setPlayerHudComponentVisible("health", false)
    setPlayerHudComponentVisible("armour", false)
    setPlayerHudComponentVisible("money", false)
end)
