local helpWindow = nil
local categoryList = nil
local contentMemo = nil

-- Dữ liệu hướng dẫn (Có thể tự do chỉnh sửa nội dung)
local helpData = {
    ["Luật Server"] = "1. Không được DM (Deathmatch).\n2. Không được phép Powergaming (PG).\n3. Luôn tuân thủ luật Roleplay.",
    ["Lệnh Cơ Bản"] = "/me [hành động]: Biểu thị hành động nhân vật.\n/do [trạng thái]: Mô tả trạng thái môi trường.\n/b [nội dung]: Kênh chat OOC ngoài đời thực.",
    ["Hệ thống Việc Làm"] = "Hãy đến Tòa Thị Chính (City Hall) trên bản đồ để nhận các công việc như: Giao báo, Thợ mỏ, Trucker để kiếm tiền.",
    ["Trợ giúp Tài Khoản"] = "Nếu gặp lỗi hoặc bị kẹt, hãy sử dụng lệnh /report [nội dung] để gửi yêu cầu hỗ trợ đến Admin."
}

-- Hàm khởi tạo giao diện
function createHelpWindow()
    if helpWindow then return end

    -- Lấy độ phân giải màn hình
    local sW, sH = guiGetScreenSize()
    local wW, wH = 600, 400
    local wX, wY = (sW - wW) / 2, (sH - wH) / 2

    -- Tạo cửa sổ chính
    helpWindow = guiCreateWindow(wX, wY, wW, wH, "HỆ THỐNG TRỢ GIÚP - ROLEPLAY", false)
    guiWindowSetSizable(helpWindow, false)

    -- Tạo danh sách danh mục (Bên trái)
    categoryList = guiCreateGridList(10, 30, 180, 320, false, helpWindow)
    local column = guiCreateGridListAddColumn(categoryList, "Danh Mục Trợ Giúp", 0.85)

    -- Tạo ô hiển thị nội dung (Bên phải)
    contentMemo = guiCreateMemo(200, 30, 390, 320, "Vui lòng chọn một danh mục bên trái để xem hướng dẫn.", false, helpWindow)
    guiMemoSetReadOnly(contentMemo, true)

    -- Nút đóng cửa sổ
    local closeButton = guiCreateButton(250, 360, 100, 30, "Đóng", false, helpWindow)

    -- Thêm dữ liệu vào Gridlist
    for category, _ in pairs(helpData) do
        local row = guiCreateGridListAddRow(categoryList)
        guiCreateGridListSetItemText(categoryList, row, column, category, false, false)
    end

    -- Sự kiện khi click vào danh mục
    addEventHandler("onClientGUIClick", categoryList, updateHelpContent, false)
    
    -- Sự kiện khi bấm nút Đóng
    addEventHandler("onClientGUIClick", closeButton, toggleHelpWindow, false)
end

-- Hàm cập nhật nội dung khi chọn danh mục
function updateHelpContent()
    local selectedRow, selectedColumn = guiGridListGetSelectedItem(categoryList)
    if selectedRow ~= -1 then
        local categoryName = guiGridListGetItemText(categoryList, selectedRow, selectedColumn)
        local text = helpData[categoryName] or ""
        guiSetText(contentMemo, text)
    end
end

-- Hàm bật/tắt giao diện
function toggleHelpWindow()
    if not helpWindow then
        createHelpWindow()
        showCursor(true)
    else
        destroyElement(helpWindow)
        helpWindow = nil
        showCursor(false)
    end
end
addEvent("triggerHelpUI", true)
addEventHandler("triggerHelpUI", root, toggleHelpWindow)
