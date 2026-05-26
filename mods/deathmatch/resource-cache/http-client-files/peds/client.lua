-- peds/client.lua
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- [QUAN TRỌNG]: Đặt mật độ người đi bộ tối đa ở phía máy người chơi (Mức 3)
    setPlayerPedDensity(localPlayer, 3)
end)