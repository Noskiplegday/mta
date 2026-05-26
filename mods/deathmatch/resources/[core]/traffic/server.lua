-- traffic/server.lua
addEventHandler("onResourceStart", resourceRoot, function()
    -- Bật luồng giao thông đèn xanh đèn đỏ tự động của GTA
    setTrafficLightState("auto")
end)