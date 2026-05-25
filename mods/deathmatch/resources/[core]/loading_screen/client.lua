local sW, sH = guiGetScreenSize()
local loadingWindow = nil
local loadingProgress = nil
local loadingLabel = nil
local progressValue = 0

function taoLoadingScreen()
    -- Tạo một cái ảnh phủ kín toàn bộ màn hình làm nền
    loadingWindow = guiCreateStaticImage(0, 0, sW, sH, "background.jpg", false)
    
    -- Tạo chữ hiển thị trạng thái ở giữa gần cuối màn hình
    loadingLabel = guiCreateLabel(sW/2 - 150, sH - 110, 300, 20, "ĐANG TẢI DỮ LIỆU SERVER: 0%", false, loadingWindow)
    guiLabelSetHorizontalAlign(loadingLabel, "center")
    guiSetFont(loadingLabel, "default-bold-small")
    
    -- Tạo thanh Loading chạy (ProgressBar) màu xanh của hệ thống
    loadingProgress = guiCreateProgressBar(sW/2 - 200, sH - 80, 400, 25, false, loadingWindow)
    
    -- Chạy vòng lặp thời gian để tăng tiến trình tải giả lập
    setTimer(capNhatTienTrinhTai, 50, 100)
end

function capNhatTienTrinhTai()
    if not isElement(loadingProgress) then return end
    
    progressValue = progressValue + 1
    guiProgressBarSetProgress(loadingProgress, progressValue)
    guiSetText(loadingLabel, "ĐANG TẢI DỮ LIỆU SERVER: " .. progressValue .. "%")
    
    -- Khi tải xong 100% thì tự động xóa màn hình Loading đi
    if progressValue >= 100 then
        destroyElement(loadingWindow)
    end
end

addEventHandler("onClientResourceStart", resourceRoot, taoLoadingScreen)