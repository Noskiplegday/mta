local dbHandler = false

function connectDatabase()
    local host = "127.0.0.1"
    local username = "root"
    local password = "" -- Mặc định của XAMPP là để trống
    local dbName = "mta_rp"
    local port = 3306

    -- Thực hiện kết nối thông qua driver mysql của MTA
    dbHandler = dbConnect("mysql", "dbname=" .. dbName .. ";host=" .. host .. ";port=" .. port .. ";charset=utf8", username, password)

    if dbHandler then
        outputDebugString("[MYSQL] Ket noi database thanh cong!")
    else
        outputDebugString("[MYSQL] Ket noi database THAT BAI!", 1) -- Số 1 để hiển thị thông báo lỗi màu đỏ
    end
end
addEventHandler("onResourceStart", resourceRoot, connectDatabase)

-- Hàm export giúp các resource khác (như hệ thống đăng nhập, hệ thống xe...) lấy quyền truy cập database
function getConnection()
    return dbHandler
end