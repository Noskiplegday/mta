local sW, sH = guiGetScreenSize()
local loginWindow = nil
local editUser = nil
local editPass = nil
local btnLogin = nil
local btnRegister = nil

function createLoginWindow()
    if loginWindow then return end

    -- Kích thước khung đăng nhập
    local wW, wH = 350, 280
    local wX, wY = (sW - wW) / 2, (sH - wH) / 2

    -- 1. Cửa sổ Đăng Nhập chính (Hiện giữa màn hình)
    loginWindow = guiCreateWindow(wX, wY, wW, wH, "HỆ THỐNG XÁC THỰC - ROLEPLAY", false)
    guiWindowSetSizable(loginWindow, false)

    -- 2. Nhãn và Ô nhập TÀI KHOẢN
    guiCreateLabel(30, 45, 290, 20, "Tài khoản nhân vật:", false, loginWindow)
    editUser = guiCreateEdit(30, 65, 290, 30, "", false, loginWindow)
    guiEditSetMaxLength(editUser, 20) -- Giới hạn tên tài khoản tài khoản 20 ký tự

    -- 3. Nhãn và Ô nhập MẬT KHẨU
    guiCreateLabel(30, 110, 290, 20, "Mật khẩu bảo mật:", false, loginWindow)
    editPass = guiCreateEdit(30, 130, 290, 30, "", false, loginWindow)
    guiEditSetMasked(editPass, true) -- Ép mật khẩu ẩn thành dấu *

    -- 4. NÚT ĐĂNG NHẬP (Màu xanh hoặc mặc định)
    btnLogin = guiCreateButton(30, 185, 135, 40, "ĐĂNG NHẬP", false, loginWindow)
    
    -- 5. NÚT ĐĂNG KÝ (Nếu chưa có tài khoản)
    btnRegister = guiCreateButton(185, 185, 135, 40, "ĐĂNG KÝ MỚI", false, loginWindow)

    -- Hiện chuột lên để người chơi click gõ chữ
    showCursor(true)

    -- Đăng ký sự kiện click chuột cho 2 nút bấm
    addEventHandler("onClientGUIClick", btnLogin, xuLyDangNhap, false)
    addEventHandler("onClientGUIClick", btnRegister, xuLyDangKy, false)
end

-- Hàm xử lý khi ấn ĐĂNG NHẬP
function xuLyDangNhap(button, state)
    if button == "left" and state == "up" then
        local taiKhoan = guiGetText(editUser)
        local matKhau = guiGetText(editPass)

        if taiKhoan == "" or matKhau == "" then
            outputChatBox("#FF0000[Thất Bại] Vui lòng không để trống tài khoản/mật khẩu!", 255, 255, 255, true)
        else
            -- Sau này bạn sẽ kết nối đoạn này với file Server để check MySQL
            outputChatBox("#00FF00[Thành Công] Chào mừng danh tính " .. taiKhoan .. " đã tham gia server!", 255, 255, 255, true)
            
            -- Tắt giao diện Login, ẩn chuột và cho vào game
            destroyElement(loginWindow)
            loginWindow = nil
            showCursor(false)
        end
    end
end

-- Hàm xử lý khi ấn ĐĂNG KÝ
function xuLyDangKy(button, state)
    if button == "left" and state == "up" then
        local taiKhoan = guiGetText(editUser)
        local matKhau = guiGetText(editPass)

        if taiKhoan == "" or matKhau == "" then
            outputChatBox("#FF0000[Thất Bại] Vui lòng điền tên và pass muốn đăng ký!", 255, 255, 255, true)
        else
            outputChatBox("#FFFF00[Hệ Thống] Đã đăng ký thành công tài khoản: " .. taiKhoan .. ". Giờ bạn có thể bấm Đăng Nhập!", 255, 255, 255, true)
        end
    end
end

-- Tự động gọi màn hình Login lên khi bắt đầu
addEventHandler("onClientResourceStart", resourceRoot, createLoginWindow)

-- Tự động dọn chuột nếu tắt resource đột ngột
addEventHandler("onClientResourceStop", resourceRoot, function()
    showCursor(false)
end)