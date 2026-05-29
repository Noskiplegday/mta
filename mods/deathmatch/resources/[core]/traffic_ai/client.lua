-- traffic/client.lua
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- [QUAN TRỌNG]: Đặt mật độ xe chạy tối đa ở phía máy người chơi (Mức 3)
    setPlayerTrafficDensity(localPlayer, 3)
end)