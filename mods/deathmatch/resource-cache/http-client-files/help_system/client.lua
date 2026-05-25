local helpWindow = nil
local categoryList = nil
local contentMemo = nil

-- Mảng dữ liệu gốc của bạn (Giữ nguyên 5 danh mục cũ)
local helpData = {
    { category = "1. Luat Server", text = "1. Luon tuan thu cac quy tac Roleplay chung.\n2. Khong lam dung loi game (Bug Abuse).\n3. Ton trong nguoi choi khac khi chat OOC." },
    { category = "2. Lenh Chat Roleplay", text = "/me [hanh dong]: Dien ta hanh dong cua nhan vat.\nVi du: /me lay vi tien ra tu tui quan.\n\n/do [trang thai]: Mo ta moi truong hoac trang thai nhan vat.\nVi du: /do Vi tien co nhan hieu Nike mau den.\n\n/b [noi dung]: Chat ngoai doi thuc (OOC)." },
    { category = "3. Tai Khoan Nhan Vat", text = "He thong tu dong luu va tai du lieu nhan vat qua MySQL.\nTai san, vi tri va thong tin cua ban se duoc bao mat tuyet doi." },
    { category = "4. Lenh Admin Tool", text = "Danh rieng cho Ban Quan Tri:\n/tp [Ten/ID] - Dich chuyen den nguoi choi.\n/kick [Ten/ID] [Ly do] - Duoi nguoi choi khoi server.\n/ban [Ten/ID] [Ly do] - Khoa tai khoan nguoi choi." },
    { category = "5. He Thong Khac", text = "He thong Tui do (Inventory) va Ngan hang (Economy) dang duoc hoan thien.\nSu dung phim tat theo huong dan tren man hinh de tuong tact." }
}

-- HÀM TỰ ĐỘNG QUÉT TOÀN BỘ LỆNH ĐANG CHẠY TRÊN SERVER
function taiTatCaLenhServer()
    local textLenh = "DANH SÁCH TẤT CẢ CÁC LỆNH ĐANG HOẠT ĐỘNG:\n"
    textLenh = textLenh .. "=====================================\n\n"
    
    local allCommands = getCommandHandlers()
    if allCommands and #allCommands > 0 then
        local count = 0
        for _, commandData in ipairs(allCommands) do
            local cmdName = commandData[1]
            if cmdName ~= "say" and cmdName ~= "me" and cmdName ~= "register" and cmdName ~= "msg" then
                textLenh = textLenh .. "👉 /" .. cmdName .. "\n"
                count = count + 1
            end
        end
        textLenh = textLenh .. "\nTổng cộng phát hiện: " .. count .. " lệnh đang chạy."
    else
        textLenh = textLenh .. "[Lỗi] Không thể quét được dữ liệu lệnh từ hệ thống!"
    end
    return textLenh
end

-- Ham tao giao dien tro giup
function createHelpWindow()
    if helpWindow then return end

    local lenhQuetDuoc = taiTatCaLenhServer()
    if helpData[6] then table.remove(helpData, 6) end
    table.insert(helpData, { category = "6. Lệnh Hệ Thống", text = lenhQuetDuoc })

    local sW, sH = guiGetScreenSize()
    local wW, wH = 600, 420
    local wX, wY = (sW - wW) / 2, (sH - wH) / 2

    helpWindow = guiCreateWindow(wX, wY, wW, wH, "HE THONG TRO GIUP SERVER - ROLEPLAY", false)
    guiWindowSetSizable(helpWindow, false)

    categoryList = guiCreateGridList(15, 35, 180, 310, false, helpWindow)
    local column = guiGridListAddColumn(categoryList, "Danh Muc", 0.85)

    contentMemo = guiCreateMemo(210, 35, 375, 310, "Vui long chon mot danh muc ben trai de xem huong dan chi tiet.", false, helpWindow)
    guiMemoSetReadOnly(contentMemo, true)

    local closeButton = guiCreateButton(240, 365, 120, 35, "DONG MENU (X)", false, helpWindow)

    for i, data in ipairs(helpData) do
        local row = guiGridListAddRow(categoryList)
        guiGridListSetItemText(categoryList, row, column, data.category, false, false)
    end

    addEventHandler("onClientGUIClick", categoryList, updateHelpContent, false)
    addEventHandler("onClientGUIClick", closeButton, toggleHelpWindow, false)
end

-- Ham cap nhat text khi click vao danh muc
function updateHelpContent()
    local selectedRow, selectedColumn = guiGridListGetSelectedItem(categoryList)
    if selectedRow and selectedRow ~= -1 then
        local categoryName = guiGridListGetItemText(categoryList, selectedRow, selectedColumn)
        for i, data in ipairs(helpData) do
            if data.category == categoryName then
                guiSetText(contentMemo, data.text)
                break
            end
        end
    end
end

-- Ham Bat / Tat giao dien (Tu dong quan ly chuot)
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

-- Đăng ký các lệnh hoạt động chính thức
addCommandHandler("trogiup", toggleHelpWindow)
addCommandHandler("idhelp", toggleHelpWindow)

-- Tự động dọn dẹp tắt chuột nếu resource bị quản trị viên restart hoặc người chơi bị out đột ngột
addEventHandler("onClientResourceStop", resourceRoot, function()
    showCursor(false)
end)