local sx, sy = guiGetScreenSize()

local healthIcon = dxCreateTexture("files/health.png")
local armorIcon = dxCreateTexture("files/armor.png")
local moneyIcon = dxCreateTexture("files/money.png")

-- Tắt HUD GTA SA mặc định khi resource bắt đầu
addEventHandler("onClientResourceStart", resourceRoot,
function()

    local components = {
        "ammo",
        "armour",
        "breath",
        "clock",
        "health",
        "money",
        "radar",
        "vehicle_name",
        "weapon",
        "radio",
        "wanted"
    }

    for _, v in ipairs(components) do
        setPlayerHudComponentVisible(v, false)
    end

end)

function roundedBox(x,y,w,h,color)
    dxDrawRectangle(x,y,w,h,color)
end

-- Vẽ HUD mới bằng dxDraw
addEventHandler("onClientRender", root,
function()
    local hp = math.floor(getElementHealth(localPlayer))
    local armor = math.floor(getPedArmor(localPlayer))
    local money = getPlayerMoney(localPlayer)

    -- MAIN PANEL
    roundedBox(
        25,
        sy - 155,
        320,
        115,
        tocolor(15,15,15,180)
    )

    -- HEALTH ICON
    dxDrawImage(
        40,
        sy - 135,
        24,
        24,
        healthIcon
    )

    -- HEALTH BAR BG
    dxDrawRectangle(
        75,
        sy - 128,
        220,
        10,
        tocolor(40,40,40,220)
    )

    -- HEALTH BAR
    dxDrawRectangle(
        75,
        sy - 128,
        hp * 2.2,
        10,
        tocolor(220,60,60,255)
    )

    -- ARMOR ICON
    dxDrawImage(
        40,
        sy - 95,
        24,
        24,
        armorIcon
    )

    -- ARMOR BG
    dxDrawRectangle(
        75,
        sy - 88,
        220,
        10,
        tocolor(40,40,40,220)
    )

    -- ARMOR BAR
    dxDrawRectangle(
        75,
        sy - 88,
        armor * 2.2,
        10,
        tocolor(70,140,255,255)
    )

    -- MONEY ICON
    dxDrawImage(
        40,
        sy - 55,
        24,
        24,
        moneyIcon
    )

    -- MONEY TEXT
    dxDrawText(
        "$"..money,
        75,
        sy - 60,
        0,
        0,
        tocolor(80,255,120),
        1.2,
        "default-bold"
    )

    -- SERVER NAME
    dxDrawText(
        "LUU ROLEPLAY",
        25,
        sy - 185,
        0,
        0,
        tocolor(255,255,255),
        1.3,
        "default-bold"
    )

end)