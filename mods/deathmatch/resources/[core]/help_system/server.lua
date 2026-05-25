-- Hàm xử lý khi người chơi gõ lệnh
function requestHelpMenu(thePlayer)
    -- Gửi sự kiện kích hoạt UI sang Client của người chơi đó
    triggerClientEvent(thePlayer, "triggerHelpUI", thePlayer)
end

-- Đăng ký các lệnh mở/tắt hệ thống trợ giúp
addCommandHandler("help", requestHelpMenu)
addCommandHandler("trogiup", requestHelpMenu)
addCommandHandler("idhelp", requestHelpMenu) -- Thêm lệnh tắt dự phòng
