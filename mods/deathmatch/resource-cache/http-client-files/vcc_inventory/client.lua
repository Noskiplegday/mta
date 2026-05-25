-- vcc_inventory/client.lua
local screenW, screenH = guiGetScreenSize()
local invBrowser = nil
local isOpen = false

local function openInventory()
    if isOpen then return end
    isOpen = true

    invBrowser = createBrowser(screenW, screenH, false, false)
    addEventHandler("onClientBrowserCreated", invBrowser, function()
        loadBrowserURL(invBrowser, "http://mta/local/vcc_inventory/inventory.html")
        -- Send inventory data after a short delay
        setTimer(function()
            if invBrowser then
                triggerServerEvent("vcc:requestInventory", localPlayer)
            end
        end, 500, 1)
    end)

    showCursor(true)
    toggleControl("fire", false)
    toggleControl("aim_weapon", false)
    toggleControl("next_weapon", false)
    toggleControl("previous_weapon", false)
end

local function closeInventory()
    if not isOpen then return end
    isOpen = false
    if invBrowser then
        destroyElement(invBrowser)
        invBrowser = nil
    end
    showCursor(false)
    toggleControl("fire", true)
    toggleControl("aim_weapon", true)
    toggleControl("next_weapon", true)
    toggleControl("previous_weapon", true)
end

-- Toggle với phím I
bindKey("i", "down", function()
    if isOpen then closeInventory()
    else openInventory() end
end)

-- ESC close
bindKey("escape", "down", function()
    if isOpen then closeInventory() end
end)

addEventHandler("onClientRender", root, function()
    if invBrowser and isOpen then
        drawImage(0, 0, screenW, screenH, invBrowser, 0, 0, 0, 0xFFFFFFFF)
    end
end)

-- Sự kiện từ HTML
addEvent("onInventoryClose", false)
addEventHandler("onInventoryClose", root, function()
    closeInventory()
end)

addEvent("onInventoryUse", false)
addEventHandler("onInventoryUse", root, function(itemId, qty)
    triggerServerEvent("vcc:useItem", localPlayer, itemId, tonumber(qty) or 1)
end)

addEvent("onInventoryDrop", false)
addEventHandler("onInventoryDrop", root, function(itemId, qty)
    triggerServerEvent("vcc:dropItem", localPlayer, itemId, tonumber(qty) or 1)
end)

-- Nhận data từ server
addEvent("vcc:sendInventory", true)
addEventHandler("vcc:sendInventory", root, function(itemsJson, money)
    if invBrowser then
        executeBrowserJavascript(invBrowser, "setInventory("..itemsJson..")")
        executeBrowserJavascript(invBrowser, "setMoney("..tostring(money)..")")
    end
end)

addEvent("vcc:itemUsed", true)
addEventHandler("vcc:itemUsed", root, function(itemId, success, msg)
    if invBrowser then
        if success then
            executeBrowserJavascript(invBrowser, "removeItemResult('"..itemId.."', true)")
        else
            executeBrowserJavascript(invBrowser, "removeItemResult('"..itemId.."', false)")
        end
    end
    if msg then outputChatBox("[Inventory] "..msg, 39, 174, 96) end
end)

addEvent("vcc:itemAdded", true)
addEventHandler("vcc:itemAdded", root, function(itemId)
    outputChatBox("🎁 [Inventory] Nhận được vật phẩm: "..itemId, 243, 156, 18)
    if invBrowser then
        executeBrowserJavascript(invBrowser, "addItemEffect('"..itemId.."')")
    end
end)
