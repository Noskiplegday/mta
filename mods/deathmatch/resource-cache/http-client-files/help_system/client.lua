local helpWindow = nil
local categoryList = nil
local contentMemo = nil

-- CHUYỂN SANG DẠNG MẢNG CÓ THỨ TỰ (Chắc chắn 100% không bị lỗi mất dữ liệu khi load)
local helpData = {
    { category = "1. Luat Server", text = "1. Luon tuan thu cac quy tac Roleplay chung.\n2. Khong lam dung loi game (Bug Abuse).\n3. Ton trong nguoi choi khac khi chat OOC." },
    { category = "2. Lenh Chat Roleplay", text = "/me [hanh dong]: Dien ta hanh dong cua nhan vat.\nVi du: /me lay vi tien ra tu tui quan.\n\n/do [trang thai]: Mo ta moi truong hoac trang thai nhan vat.\nVi du: /do Vi tien co nhan hieu Nike mau den.\n\n/b [noi dung]: Chat ngoai doi thuc (OOC)." },
    { category = "3. Tai Khoan Nhan Vat", text = "He thong tu dong luu va tai du lieu nhan vat qua MySQL.\nTai san, vi tri va thong tin cua ban se duoc bao mat tuyet doi." },
    { category = "4. Lenh Admin Tool", text = "Danh rieng cho Ban Quan Tri:\n/tp [Ten/ID] - Dich chuyen den nguoi choi.\n/kick [Ten/ID] [Ly do] - Duoi nguoi choi khoi server.\n/ban [Ten/ID] [Ly do] - Khoa tai khoan nguoi choi." },
    { category = "5. He Thong Khac", text = "He thong Tui do (Inventory) va Ngan hang (Economy) dang duoc hoan thien.\nSu dung phim tat theo huong dan tren man hinh de tuong tac." }
}

-- Ham tao giao dien tro giup
function createHelpWindow()
    if helpWindow then return end

    -- Lay do phan giai man hinh de can giua
    local sW, sH = guiGetScreenSize()
    local wW, wH = 600, 420
    local wX, wY = (sW - wW) / 2, (sH - wH) / 2

    -- Cua so chinh
    helpWindow = guiCreateWindow(wX, wY, wW, wH, "HE THONG TRO GIUP SERVER - ROLEPLAY", false)
    guiWindowSetSizable(helpWindow, false)

    -- Bang danh muc ben trai
    categoryList = guiCreateGridList(15, 35, 180, 310, false, helpWindow)
    local column = guiCreateGridListAddColumn(categoryList, "Danh Muc", 0.85)

    -- O hien thi noi dung ben phai
    contentMemo = guiCreateMemo(210, 35, 375, 310, "Vui long chon mot danh muc ben trai de xem huong dan chi tiet.", false, helpWindow)
    guiMemoSetReadOnly(contentMemo, true)

    -- Nut dong menu
    local closeButton = guiCreateButton(240, 365, 120, 35, "DONG MENU (X)", false, helpWindow)

    -- SỬ DỤNG VÒNG LẶP IPAIRS: Duyệt dữ liệu theo đúng số thứ tự từ 1 đến 5
    for i, data in ipairs(helpData) do
        local row = guiCreateGridListAddRow(categoryList)
        guiCreateGridListSetItemText(categoryList, row, column, data.category, false, false)
    end

    -- Dang ky cac su kien click chuot
    addEventHandler("onClientGUIClick", categoryList, updateHelpContent, false)
    addEventHandler("onClientGUIClick", closeButton, toggleHelpWindow, false)
end

-- Ham cap nhat text khi click vao danh muc
function updateHelpContent()
    local selectedRow, selectedColumn = guiGridListGetSelectedItem(categoryList)
    if selectedRow and selectedRow ~= -1 then
        local categoryName = guiGridListGetItemText(categoryList, selectedRow, selectedColumn)
        
        -- Tim kiem text phu hop trong mang helpData
        local text = ""
        for i, data in ipairs(helpData) do
            if data.category == categoryName then
                text = data.text
                break
            end
        end
        guiSetText(contentMemo, text)
    end
end

-- Ham Bat / Tat giao dien (Tu dong quan ly chuot)
function toggleHelpWindow()
    if not helpWindow then
        createHelpWindow()
        showCursor(true) -- Hien chuot khi mo bảng
    else
        destroyElement(helpWindow)
        helpWindow = nil
        showCursor(false) -- An chuot khi tat bảng
    end
end

-- ĐƯA COMMANDHANDLER VỀ CLIENT: Đảm bảo gõ lệnh nào cũng nhận ngay lập tức
addCommandHandler("help", toggleHelpWindow)
addCommandHandler("trogiup", toggleHelpWindow)
addCommandHandler("idhelp", toggleHelpWindow)
