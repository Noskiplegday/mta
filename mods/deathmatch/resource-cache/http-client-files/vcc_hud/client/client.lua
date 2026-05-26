--[[
  ╔═══════════════════════════════════════════════════════╗
  ║   VanCanhCity HUD — client.lua                        ║
  ║   MTA:SA Resource  |  Neon Đỏ Edition                ║
  ╚═══════════════════════════════════════════════════════╝
  Cài đặt:
    1. Bỏ thư mục [vcc_hud] vào resources/
    2. Thêm start vcc_hud vào mtaserver.conf
    3. Gọi các exported function từ resource khác để
       cập nhật tiền, job, status, v.v.

  API (gọi từ resource khác):
    exports.vcc_hud:setMoney(cash, bank)
    exports.vcc_hud:setJob(jobLabel)
    exports.vcc_hud:setStatus(wanted, onDuty, seatbelt)
    exports.vcc_hud:notify(title, msg, style)
        style: nil/"success"/"warning"/"info"
]]

-- ─── HUD BROWSER INSTANCE ────────────────────────────────
local browser = nil
local isReady = false

local function JS(code)
  if browser and isReady then
    executeBrowserJavascript(browser, code)
  end
end

-- Hàm ẩn toàn bộ thành phần HUD mặc định của GTA/MTA
local function hideDefaultHUD()
  setPlayerHudComponentVisible("health", false)
  setPlayerHudComponentVisible("armour", false)
  setPlayerHudComponentVisible("money", false)
  setPlayerHudComponentVisible("weapon", false)
  setPlayerHudComponentVisible("ammo", false)
  setPlayerHudComponentVisible("clock", false)
  setPlayerHudComponentVisible("radar", false) -- Ẩn minimap mặc định để dời map lên góc phải trên
  showPlayerHudComponent("all", false)
end

-- ─── KHỞI TẠO BROWSER ───────────────────────────────────
addEventHandler("onClientResourceStart", resourceRoot, function()
  -- Ẩn HUD mặc định ngay khi khởi chạy
  hideDefaultHUD()

  local W, H = guiGetScreenSize()
  browser = createBrowser(W, H, false)

  addEventHandler("onClientBrowserCreated", browser, function()
    loadBrowserURL(browser, "http://mta/local/hud.html")
  end)

  addEventHandler("onClientBrowserDocumentReady", browser, function()
    isReady = true
    -- Gửi thông tin lần đầu
    sendInitialData()
    JS("vcc.notify('VanCanhCity RP', 'Chào mừng bạn đã kết nối!', 'success')")
  end)

  -- Render browser lên màn hình
  addEventHandler("onClientRender", root, function()
    if browser then
      local W2, H2 = guiGetScreenSize()
      dxDrawImage(0, 0, W2, H2, browser, 0, 0, 0, tocolor(255,255,255,255), true)
    end
  end)
end)

-- ─── GỬI DỮ LIỆU BAN ĐẦU ────────────────────────────────
function sendInitialData()
  local player   = localPlayer
  local name     = getPlayerName(player)
  local id       = getElementData(player, "playerID") or (getPlayerID and getPlayerID(player)) or 0
  local job      = getElementData(player, "job")      or "Thường Dân"
  local cash     = getElementData(player, "cash")     or 0
  local bank     = getElementData(player, "bank")     or 0

  JS(string.format("vcc.setPlayer('%s', %d, '%s')",
    name:gsub("'","\\'"), tonumber(id) or 0, job:gsub("'","\\'") ))
  JS(string.format("vcc.setMoney(%d, %d)", tonumber(cash) or 0, tonumber(bank) or 0))
end

-- ─── MAIN TICK (500ms) ───────────────────────────────────
local tickCount = 0
setTimer(function()
  if not isReady then return end
  tickCount = tickCount + 1

  local player = localPlayer
  local ped    = localPlayer

  -- ── HP & ARMOR ──
  local hp    = math.floor(getElementHealth(ped))
  local armor = math.floor(getPedArmor(ped))
  local food  = math.floor(getElementData(player, "food")  or 100)
  local water = math.floor(getElementData(player, "water") or 100)
  JS(string.format("vcc.setStats(%d,%d,%d,%d)", hp, armor, food, water))

  -- ── VEHICLE ──
  local veh = getPedOccupiedVehicle(ped)
  if veh then
    local vx, vy, vz = getElementVelocity(veh)
    local kmh    = math.floor(math.sqrt(vx*vx+vy*vy+vz*vz) * 179.3)
    local gear   = getVehicleCurrentGear(veh) or 0
    local fuel   = math.floor(getElementData(veh, "fuel") or 100)
    local engOn  = isVehicleEngineOn(veh) and "true" or "false"
    JS(string.format("vcc.setVehicle(true,%d,%d,%d,%s)", kmh, gear, fuel, engOn))
  else
    JS("vcc.setVehicle(false,0,0,100,true)")
  end

  -- ── THỜI GIAN (mỗi 4 tick = 2 giây) ──
  if tickCount % 4 == 0 then
    local h, m = getTime()
    JS(string.format("vcc.setTime(%d,%d)", h, m))
  end

  -- ── PING (mỗi 6 tick = 3 giây) ──
  if tickCount % 6 == 0 then
    local ping = getPlayerPing(player)
    JS(string.format("vcc.setPing(%d)", ping))
  end

  -- ── THỜI TIẾT (mỗi 20 tick = 10 giây) ──
  if tickCount % 20 == 0 then
    updateWeather()
  end

  -- ── ZONE ──
  if tickCount % 10 == 0 then
    local x, y, z = getElementPosition(player)
    local zone = getZoneName(x, y, z, true) or "Vùng Hoang Dã"
    JS(string.format("vcc.setZone('%s')", zone:gsub("'","\\'")))
  end

  -- ── WANTED LEVEL ──
  if tickCount % 4 == 0 then
    local wanted   = getPlayerWantedLevel(player) > 0
    local onDuty   = getElementData(player, "onDuty") and true or false
    local seatbelt = false -- tùy thuộc vào script seatbelt hệ thống của bạn
    JS(string.format("vcc.setStatus(%s,%s,%s)",
      wanted   and "true" or "false",
      onDuty   and "true" or "false",
      seatbelt and "true" or "false"
    ))
  end

  if tickCount > 10000 then tickCount = 0 end
end, 500, 0)

-- ─── THỜI TIẾT ───────────────────────────────────────────
local weatherNames = {
  [0]="Nắng",[1]="Nhiều Mây",[2]="Mưa",[3]="Sương Mù",
  [4]="Dông",[5]="Đêm Quang",[6]="Bão",[7]="Khô Hạn",
}
function updateWeather()
  local id   = getWeather() or 0
  local name = weatherNames[id] or "Quang Đãng"
  -- Nhiệt độ giả lập theo thời gian trong ngày
  local h = getTime()
  local temp = 22 + math.floor(math.sin((h-6)/24*math.pi*2) * 8)
  JS(string.format("vcc.setWeather('%s', %d)", name, temp))
end

-- ─── EXPORTED FUNCTIONS ──────────────────────────────────

-- Cập nhật tiền từ resource khác:
function setMoney(cash, bank)
  JS(string.format("vcc.setMoney(%d, %d)", tonumber(cash) or 0, tonumber(bank) or 0))
end

-- Cập nhật job:
function setJob(jobLabel)
  JS(string.format("vcc.setPlayer(null, null, '%s')", (jobLabel or "Thường Dân"):gsub("'","\\'")))
end

-- Trạng thái đặc biệt:
function setStatus(wanted, onDuty, seatbelt)
  JS(string.format("vcc.setStatus(%s,%s,%s)",
    wanted   and "true" or "false",
    onDuty   and "true" or "false",
    seatbelt and "true" or "false"
  ))
end

-- Thông báo:
function notify(title, msg, style)
  local s = style and ('"'..style..'"') or "null"
  JS(string.format("vcc.notify('%s','%s',%s)",
    (title or ""):gsub("'","\\'"),
    (msg   or ""):gsub("'","\\'"),
    s
  ))
end

-- ─── EVENTS TỪ SERVER ────────────────────────────────────
addEvent("vcc_hud:updateMoney",  true)
addEvent("vcc_hud:updateJob",    true)
addEvent("vcc_hud:notify",       true)
addEvent("vcc_hud:updateStatus", true)

addEventHandler("vcc_hud:updateMoney",  localPlayer, function(cash, bank) setMoney(cash, bank) end)
addEventHandler("vcc_hud:updateJob",    localPlayer, function(job)        setJob(job)          end)
addEventHandler("vcc_hud:notify",       localPlayer, function(t,m,s)      notify(t,m,s)        end)
addEventHandler("vcc_hud:updateStatus", localPlayer, function(w,d,b)      setStatus(w,d,b)     end)

-- ─── ELEMENTDATA WATCHER ─────────────────────────────────
addEventHandler("onClientElementDataChange", localPlayer, function(key, oldVal, newVal)
  if key == "cash" or key == "bank" then
    local cash = getElementData(localPlayer, "cash") or 0
    local bank = getElementData(localPlayer, "bank") or 0
    setMoney(cash, bank)
  elseif key == "job" then
    setJob(newVal)
  end
end)

-- ─── RESIZE KHI ĐỔI ĐỘ PHÂN GIẢI ────────────────────────
addEventHandler("onClientScreenSizeChange", root, function(w, h)
  -- Ẩn lại HUD gốc để tránh bị lộ khi thay đổi kích thước màn hình
  hideDefaultHUD()

  if browser then
    destroyElement(browser)
    browser  = nil
    isReady  = false
  end
  -- Tạo lại sau 100ms
  setTimer(function()
    local W, H = guiGetScreenSize()
    browser = createBrowser(W, H, false)
    addEventHandler("onClientBrowserCreated", browser, function()
      loadBrowserURL(browser, "http://mta/local/hud.html")
    end)
    addEventHandler("onClientBrowserDocumentReady", browser, function()
      isReady = true
      sendInitialData()
    end)
  end, 100, 1)
end)

addEventHandler("onClientBrowserWhitelistChange", root, function()
  if browser then
    loadBrowserURL(browser, "http://mta/local/hud.html")
  end
end)

-- Yêu cầu quyền nếu chưa có
if not isBrowserDomainBlocked("mta://") then
    requestBrowserDomains({"mta://"})
end