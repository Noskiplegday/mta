-- vcc_loadscreen/client.lua
local screenW, screenH = guiGetScreenSize()
local loadBrowser = nil
local isLoading = false
local loadPct = 0

addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Tạo browser loadscreen
    loadBrowser = createBrowser(screenW, screenH, false, false)
    isLoading = true

    addEventHandler("onClientBrowserCreated", loadBrowser, function()
        loadBrowserURL(loadBrowser, "http://mta/local/vcc_loadscreen/loadscreen.html")
    end)

    showCursor(false)
    setPlayerHudComponentVisible("all", false)
    toggleAllControls(false)

    -- Auto-progress simulation (bạn có thể control từ server)
    local steps = {
        {10, "Đang kết nối server..."},
        {25, "Đang tải dữ liệu người chơi..."},
        {45, "Đang khởi tạo bản đồ..."},
        {65, "Đang tải nhân vật..."},
        {80, "Đang kết nối database..."},
        {95, "Hoàn tất khởi tạo..."},
        {100, "Chào mừng đến Van Canh City!"},
    }

    local stepIndex = 1
    local progressTimer = setTimer(function()
        if stepIndex <= #steps and loadBrowser then
            local p, s = steps[stepIndex][1], steps[stepIndex][2]
            executeBrowserJavascript(loadBrowser, "setLoadProgress("..p..", '"..s.."')")
            loadPct = p
            stepIndex = stepIndex + 1

            if p >= 100 then
                setTimer(function()
                    destroyLoadScreen()
                end, 1200, 1)
            end
        end
    end, 600, #steps + 1)
end)

function destroyLoadScreen()
    if loadBrowser then
        destroyElement(loadBrowser)
        loadBrowser = nil
    end
    isLoading = false
    setPlayerHudComponentVisible("all", true)
    toggleAllControls(true)
end

addEventHandler("onClientRender", root, function()
    if loadBrowser and isLoading then
        drawImage(0, 0, screenW, screenH, loadBrowser, 0, 0, 0, 0xFFFFFFFF)
    end
end)

-- Event từ server để set progress thủ công
addEvent("vcc:setLoadProgress", true)
addEventHandler("vcc:setLoadProgress", root, function(pct, status)
    if loadBrowser then
        executeBrowserJavascript(loadBrowser, "setLoadProgress("..pct..", '"..tostring(status).."')")
    end
end)

addEvent("vcc:hideLoadscreen", true)
addEventHandler("vcc:hideLoadscreen", root, function()
    destroyLoadScreen()
end)
