-- Khi người chơi bấm phím K, tự động kích hoạt lệnh lockvehicle ở phía server
bindKey("k", "down", function()
    executeCommandHandler("lockvehicle")
end)