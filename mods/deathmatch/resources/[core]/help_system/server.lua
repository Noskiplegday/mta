-- Tạo lệnh /trogiup hoặc /help để mở menu
function requestHelpMenu(thePlayer)
    -- Gửi tín hiệu kích hoạt giao diện qua client của người chơi đó
    triggerClientEvent(thePlayer, "triggerHelpUI", thePlayer)
end
addCommandHandler("trogiup", requestHelpMenu)
addCommandHandler("help", requestHelpMenu)
