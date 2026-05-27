# 🎮 MTA Roleplay Server - Cấu Trúc & Roadmap

## 📋 Mục lục
1. [Tổng Quan Server](#tổng-quan-server)
2. [Kiến Trúc Hệ Thống](#kiến-trúc-hệ-thống)
3. [Các Hệ Thống Core](#các-hệ-thống-core)
4. [Game Modes](#game-modes)
5. [Admin & Quản Lý](#admin--quản-lý)
6. [Tài Nguyên & Plugins](#tài-nguyên--plugins)
7. [Lộ Trình Phát Triển](#lộ-trình-phát-triển)
8. [Hướng Dẫn Setup & Maintain](#hướng-dẫn-setup--maintain)

---

## 🎯 Tổng Quan Server

**Tên Server:** VanCanhCity Roleplay  
**Loại:** Multi Theft Auto (MTA) Roleplay Server  
**Cấu hình:**
- **Max Players:** 500
- **Port Game:** 22010
- **Port HTTP:** 22011
- **Languages:** Vietnamese
- **Tags:** roleplay, rp, vietnam, vancanh

### Mục Đích
Cung cấp một nền tảng roleplay hoàn chỉnh với:
- Hệ thống đăng nhập/tạo tài khoản
- Quản lý nhân vật (character)
- Hệ thống job & kinh tế
- Game modes đa dạng
- Admin tools & quản lý server

---

## 🏗️ Kiến Trúc Hệ Thống

### Cấu Trúc Thư Mục

```
mods/deathmatch/
├── mtaserver.conf              # Cấu hình chính server
├── acl.xml                      # Access Control List
├── banlist.xml                  # Danh sách ban
├── settings.xml                 # Cài đặt server
├── vehiclecolors.conf           # Màu xe
├── local.conf                   # Config local
├── editor.conf                  # Config editor
├── server-id.keys               # Server keys
│
├── databases/                   # Database storage
│   ├── global/                  # Global data
│   └── system/                  # System data
│
├── logs/                        # Server logs
│
├── resource-cache/              # Cache tài nguyên
│   ├── http-client-files/       # Files cho client
│   ├── http-client-files-no-client-cache/
│   └── unzipped/                # Unzipped resources
│
└── resources/                   # 👈 **CHÍNH: Nơi chứa tất cả code**
    ├── [core]/                  # Hệ thống cơ bản
    ├── [gameplay]/              # Gameplay features
    ├── [managers]/              # Quản lý server
    ├── [gamemodes]/             # Các game mode
    ├── [admin]/                 # Admin tools
    ├── [web]/                   # Web interface
    └── [editor]/                # Editor tools
```

---

## 💾 Các Hệ Thống Core

### 📂 [core]/ - Hệ Thống Cốt Lõi

| Module | Mô tả hiện tại | Trạng thái |
|--------|---------------|-----------|
| **mysql/** | Kết nối MySQL chính, dbConnect tới `mta_rp` | Đang hoạt động |
| **account/** | Tự động tạo tài khoản theo Serial máy, đăng nhập trực tiếp, bảng `accounts` | Đã có |
| **character/** | Load/save nhân vật, spawn player, lưu vị trí và tiền khi quit | Đã có |
| **login_ui/** | Giao diện CEF login/register HTML; schema `my_accounts`, `my_characters` | Có nhưng trùng lặp |
| **chat/** | Local chat 20m, /me, /do, lệnh /gotopos | Đã có |
| **vehicle/** | Tải xe từ DB, createvehicle, lock, engine, seatbelt, hood, trunk, lights | Đã có |
| **vehicle_system/** | Hệ thống xe nâng cao: spawnveh/despawnveh, buyvehicle, park, refuel, fuel drain | Đã có |
| **traffic/** | Bật traffic light tự động | Đơn giản |
| **peds/** | Script ped server/client | Chờ mở rộng |
| **help_system/** | Client help script | Cơ bản |
| **inventory/** | Chưa kiểm tra rõ các lệnh/asset | Chưa rõ hiện trạng |

**Lưu ý quan trọng:**
- Hiện tại có hai luồng đăng nhập/tài khoản song song: `account/` và `login_ui/`.
- `account/` dùng `accounts`/`characters` và login tự động qua Serial.
- `login_ui/` dùng UI CEF, bảng `my_accounts`/`my_characters`, đăng ký và đăng nhập bằng username/password.
- Cần quyết định chọn 1 luồng auth duy nhất hoặc hợp nhất dữ liệu ngay lập tức.

---

## ℹ️ Current Implementation - Thực tế vừa cập nhật

### 🔧 Auth / Account / Character
- `resources\[core]\mysql\connection.lua` kết nối MySQL mặc định `127.0.0.1`, database `mta_rp`.
- `resources\[core]\account\server.lua`:
  - Tạo bảng `accounts` nếu chưa có.
  - Tự động tạo tài khoản mới khi player join nếu Serial chưa tồn tại.
  - Gọi `exports["character"]:loadPlayerCharacter(...)` để load nhân vật.
- `resources\[core]\character\server.lua`:
  - Tạo bảng `characters` nếu chưa có.
  - Tạo nhân vật mới mặc định nếu chưa có record.
  - Spawn player tại San Fierro, set tiền mặc định 5000$
  - Lưu vị trí/skin/cash khi player quit.

### 🧩 Login UI
- `resources\[core]\login_ui\client.lua` mở CEF browser và gửi sự kiện `onLoginSubmit`/`onRegisterSubmit`.
- `resources\[core]\login_ui\server.lua`:
  - Tạo bảng `my_accounts`, `my_characters`.
  - Xử lý đăng ký: kiểm tra username/email, tạo account + character.
  - Xử lý đăng nhập: so sánh password thô, spawn player và set tiền/sức khỏe/armor.
  - Lưu dữ liệu user khi quit.
- UI HTML đã được deploy trong `resources\[core]\login_ui\html\index.html`.

### 💬 Chat & Roleplay
- `resources\[core]\chat\server.lua`:
  - Chat local trong 20m.
  - Lệnh `/me` và `/do` với thông báo RP.
  - Admin test command `/gotopos X Y Z` không kiểm tra quyền.

### 🚗 Vehicle System
- `resources\[core]\vehicle\server.lua`:
  - Load vehicles từ DB `vehicles` khi resource start.
  - Lệnh `/createvehicle`, `/lock`, `/engine`, `/seatbelt`, `/hood`, `/trunk`, `/lights`.
  - Lưu vị trí và trạng thái khi resource stop.
- `resources\[core]\vehicle_system\server.lua`:
  - Fuel drain mỗi 10s khi xe nổ máy.
  - Lệnh `/spawnveh`, `/despawnveh`, `/park`, `/refuel`, `/buyvehicle`, `/lockvehicle`.
  - Hỗ trợ lock/unlock, engine toggle, seatbelt, hood/trunk bằng lệnh và sự kiện từ client.
  - Lưu fuel khi resource stop hoặc khi cất xe.

### 🚦 Traffic
- `resources\[core]\traffic\server.lua` chỉ bật chế độ traffic light auto.

---

### 📂 Các Module Core Chi Tiết

| Resource | Notes |
|----------|-------|
| `[core]/mysql` | Kết nối DB chung, export `getConnection()` |
| `[core]/account` | Auto signup/login qua Serial |
| `[core]/character` | Load + save char, spawn mặc định |
| `[core]/login_ui` | CEF login/register UI - 2nd auth flow |
| `[core]/chat` | Local chat + RP commands + uproot admin command |
| `[core]/vehicle` | Persistent vehicle loading + owner command |
| `[core]/vehicle_system` | Personal vehicle management, fuel, buy/spawn/despawn |
| `[core]/traffic` | Traffic lights on auto |
| `[core]/peds` | Basic ped server/client script |
| `[core]/help_system` | help UI client stub |

---

### 🎯 Thực trạng chính xác
- `Login` & `Character` đã hoạt động với 2 luồng: auto Serial và login UI.
- `Vehicle` đã có hệ thống tính năng tương đối đầy đủ với DB persistence.
- `Chat` đã có tính năng RP cơ bản.
- `Inventory`, `Job`, `Economy`, `Property` chưa thấy code rõ ràng.
- `Admin tools` có lệnh thử nghiệm, nhưng chưa có ACL/permission đầy đủ.

---

### ⚠️ Vấn đề cần giải quyết ngay
- Đồng nhất hệ thống đăng nhập: `account/` vs `login_ui/`.
- Mật khẩu lưu thô trong `login_ui` cần hash/salt.
- Quyền admin hiện tại chưa có kiểm tra ACL.
- Cần thống nhất DB schema để tránh duplicate account records.

---

### 🧪 Tình trạng phát triển

| Tính năng | Trạng thái |
|-----------|------------|
| Auth cơ bản | Có, nhưng 2 luồng trùng lặp |
| Character load/save | Hoạt động |
| Roleplay chat | Hoạt động |
| Vehicle persistence | Hoạt động |
| Vehicle advanced | Hoạt động |
| Traffic | Hoạt động cơ bản |
| Web admin/GUI | Chưa đánh giá chi tiết |
| Inventory | Chưa rõ |
| Job/Economy | Chưa triển khai |
| Property | Chưa triển khai |

---

### 🔄 Kế hoạch gộp lại ngay
1. Chọn 1 hệ thống auth duy nhất.
2. Viết lại `mysql` schema chung cho accounts/characters/vehicles.
3. Tách `login_ui` thành front-end cho cùng backend `account`/`character`.
4. Thêm permission check cho lệnh admin trong `chat` và `vehicle`.

---

### 🧩 Cập nhật nhanh cho roadmap
- `MySQL connection` ổn, cần kiểm tra config `login_ui` và `mysql` cùng DB.
- `Login/Register` đã có: auto Serial + HTML UI.
- `Character management` đã có cơ bản.
- `Chat` đã xong mức RP cơ bản.
- `Vehicle` đã xong nhiều lệnh và persistence.
- `Admin tools` cần xác thực quyền.

---

### 🎯 Tập trung tiếp theo
- Consolidate auth/character database.
- Hash password cho `login_ui`.
- Kiểm tra DB `vehicles` schema và các cột tồn tại.
- Test `createvehicle`, `spawnveh`, `despawnveh`, `refuel`, `park`.

---

## 🎪 Game Modes

### 📂 [gamemodes]/ - 11 Game Mode Khác Nhau

| Game Mode | Thư Mục | Mô Tả |
|-----------|---------|-------|
| **Assault** | `[assault]/` | Chế độ tấn công |
| **Briefcase Race** | `[briefcaserace]/` | Đua với vali |
| **Capture The Flag** | `[ctf]/` | CTF - Cố Gắng Chiếm Lá Cờ |
| **CTV** | `[ctv]/` | Chế độ TV/Broadcast |
| **Deathmatch** | `[deathmatch]/` | Deathmatch thông thường |
| **Fallout** | `[fallout]/` | Chế độ Fallout |
| **Hay** | `[hay]/` | Game Hay |
| **Play** | `[play]/` | Chế độ Play mặc định |
| **Race** | `[race]/` | Đua xe |
| **Stealth** | `[stealth]/` | Chế độ Stealth/Assassin |
| **Team Deathmatch** | `[tdm]/` | Team Deathmatch |

**Cấu trúc mỗi game mode:**
```
[gamemode_name]/
├── meta.xml          # Metadata
├── server.lua        # Server-side logic
├── client.lua        # Client-side code
└── ...assets
```

---

## 🔐 Admin & Quản Lý

### 📂 [admin]/ - Admin Tools & Panels

| Tool | Loại | Mục Đích |
|------|------|----------|
| **acpanel.zip** | Admin Command Panel | Giao diện lệnh admin |
| **admin.zip** | Main Admin Module | Lệnh admin chính |
| **admin/** | Admin Folder | Source code admin |
| **ipb.zip** | IP Banning | IP Ban Manager |
| **runcode.zip** | Code Runner | Chạy code trực tiếp |

### Các Lệnh Admin Cơ Bản (dự kiến):
```
/kick <player>           - Kick player khỏi server
/ban <player>            - Ban player
/unban <player>          - Unban player
/mute <player>           - Mute chat
/freeze <player>         - Đóng băng player
/teleport <player> <x,y,z>  - Teleport
/setjob <player> <job>   - Set job cho player
/setmoney <player> <amount> - Set tiền
```

---

## 🌐 Web Interface

### 📂 [web]/ - Web Management Tools

| Module | Chức Năng |
|--------|----------|
| **ajax.zip** | AJAX requests handler |
| **elementbrowser.zip** | Browse elements |
| **performancebrowser.zip** | Performance monitor |
| **resourcebrowser.zip** | Browse resources |
| **resourcemanager.zip** | Manage resources |
| **webadmin.zip** | 🔑 **Web Admin Panel** |
| **webmap.zip** | Web-based map |
| **webstats.zip** | Statistics dashboard |

---

## 📊 Hệ Thống Editor

### 📂 [editor]/ - Mapping Tools
- Editor GUI, assets, và tools cho việc tạo map

---

## 📈 Lộ Trình Phát Triển (Roadmap)

### 🔴 Phase 1: Foundation (Database & Auth) - *HIỆN TẠI*
**Ưu tiên:** CRITICAL

- [ ] ✅ MySQL connection setup & testing
- [ ] ✅ Database schema design (accounts, characters, properties)
- [ ] ✅ Login/Register system (account/character)
- [ ] [ ] Hash password correctly
- [ ] [ ] Session management

**Tasks:**
```
1. Setup MySQL database với proper tables
2. Test connection string từ server
3. Implement login validation
4. Implement character creation
5. Test account persistence
```

---

### 🟡 Phase 2: Core Systems - *WEEK 1-2*
**Ưu tiên:** HIGH

- [ ] Chat system (world, local, /do, /me, /whisper)
- [ ] Inventory system (items, weight limit)
- [ ] Vehicle system (spawn, despawn, ownership)
- [ ] Basic admin commands (kick, ban, mute, teleport)
- [ ] Spawn manager (spawn points, selection UI)

**Tasks:**
```
1. Implement chat prefixes & levels
2. Add inventory UI & item management
3. Create vehicle spawn/despawn logic
4. Implement admin permission checking
5. Create spawn location selection UI
```

---

### 🟠 Phase 3: Gameplay Features - *WEEK 2-3*
**Ưu tiên:** MEDIUM

- [ ] Job system (police, taxi, doctor, etc.)
- [ ] Money/Economy system (earning, spending)
- [ ] Property system (houses, businesses)
- [ ] NPC/Traffic system
- [ ] Death/Respawn system
- [ ] Damage/Health system

**Tasks:**
```
1. Create job database & UI
2. Implement money transactions
3. Add property ownership & rent
4. Configure NPC spawning
5. Test damage/death mechanics
```

---

### 🟢 Phase 4: Game Modes - *WEEK 3-4*
**Ưu tiên:** MEDIUM

- [ ] Fine-tune Deathmatch mode
- [ ] Implement Race mode fully
- [ ] Setup Team Deathmatch
- [ ] Configure CTF rules
- [ ] Test all 11 game modes

**Tasks:**
```
1. Test each gamemode thoroughly
2. Fix spawn bugs
3. Adjust weapon distributions
4. Test team balancing
5. Add scoreboard proper display
```

---

### 🔵 Phase 5: Admin & Web Panel - *WEEK 4*
**Ưu tiên:** HIGH

- [ ] Web Admin Dashboard
- [ ] In-game Admin Command Panel
- [ ] Player statistics view
- [ ] Server settings management
- [ ] Log viewer

**Tasks:**
```
1. Setup web admin authentication
2. Create player management UI
3. Add resource browser
4. Implement settings editor
5. Create server monitoring dashboard
```

---

### 🟣 Phase 6: Polish & Optimization - *WEEK 5*
**Ưu tiên:** MEDIUM

- [ ] Performance optimization
- [ ] Bug fixes & stability
- [ ] UI/UX improvements
- [ ] Server load testing (500 players)
- [ ] Documentation

**Tasks:**
```
1. Profile server performance
2. Optimize Lua scripts
3. Fix known bugs
4. Load test with 500 players
5. Write deployment guide
```

---

## 📋 Checklist Phát Triển

### Core Systems Status
```
[x] Server base structure
[x] MySQL connection - Priority: CRITICAL
[x] Login system - Priority: CRITICAL (2 luồng: account + login_ui)
[x] Character management - Priority: CRITICAL
[x] Chat system - Priority: HIGH
[ ] Inventory system - Priority: HIGH
[x] Vehicle system - Priority: HIGH
[ ] Admin tools - Priority: HIGH (permission missing)
[ ] Job system - Priority: MEDIUM
[ ] Economy system - Priority: MEDIUM
[ ] Property system - Priority: MEDIUM
```

### Game Modes Status
```
[ ] Deathmatch - Fine-tune
[ ] Team Deathmatch - Implement
[ ] Race - Optimize
[ ] CTF - Test
[ ] Assault - Configure
[ ] Stealth - Implement
[ ] Fallout - Test
[ ] Briefcase Race - Implement
[ ] CTV - Configure
[ ] Hay - Test
[ ] Play - Default mode
```

### Admin Tools Status
```
[ ] Web Admin Panel - Create UI
[ ] In-game Commands - Implement
[ ] Ban system - Test
[ ] Kick system - Implement
[ ] Teleport system - Implement
[ ] Money commands - Implement
[ ] Admin logs - Create
```

---

## 📖 Hướng Dẫn Setup & Maintain

### 1️⃣ Initial Setup

**Prerequisites:**
- MTA Server installed
- MySQL Server running
- Git (optional)

**Steps:**
```bash
1. Clone/Copy server files to MTA directory
2. Edit mtaserver.conf:
   - servername
   - maxplayers
   - serverport
   - httpport
3. Setup MySQL database
4. Configure connection string in mysql.lua
5. Test connection
6. Start server: mta-server.exe
```

### 2️⃣ Daily Maintenance

**Checks:**
```
- Monitor CPU/Memory usage
- Check server logs for errors
- Verify database backups
- Monitor player count
- Check admin panel for issues
```

**Commands:**
```
/status              - Server status
/restart <time>      - Schedule restart
/savedb              - Save database
/gamemode <mode>     - Change gamemode
```

### 3️⃣ Database Backup

**Location:** `databases/global/` & `databases/system/`

**Backup Schedule:**
- Hourly: Auto backup
- Daily: Manual backup
- Weekly: External backup

### 4️⃣ Resource Management

**Enable Resource:**
```
In server console: start [resourcename]
```

**Restart Resource:**
```
In server console: restart [resourcename]
```

**Monitor Resource:**
```
Web Admin: Resources → Monitor → [resourcename]
```

### 5️⃣ Troubleshooting

**Server won't start:**
```
✓ Check ports 22010, 22011 not in use
✓ Check MySQL connection
✓ Review server logs
✓ Verify resource syntax
```

**Players can't login:**
```
✓ Check MySQL connection
✓ Verify login system resource enabled
✓ Check database has accounts table
✓ Review server logs for errors
```

**High lag/poor performance:**
```
✓ Check CPU/Memory usage
✓ Reduce max players if necessary
✓ Profile Lua scripts
✓ Optimize database queries
✓ Reduce rendering distance
```

---

## 🎯 Next Immediate Tasks

### 👉 **This Week Priority:**

1. **[CRITICAL]** Consolidate Authentication
   - Decide dùng `account/` hay `login_ui/` làm chính
   - Đồng bộ DB schema `accounts` / `characters` / `vehicles`
   - Loại bỏ duplicate records và risk trùng lặp

2. **[CRITICAL]** Secure Login UI
   - Hash/salt password trước khi lưu
   - Kiểm tra `my_accounts`/`my_characters` và chuyển sang schema chung
   - Test đăng ký + đăng nhập bằng UI

3. **[HIGH]** Verify Vehicle System
   - Test `/createvehicle`, `/spawnveh`, `/despawnveh`, `/park`, `/refuel`
   - Kiểm tra fuel drain và persistence
   - Bổ sung permission/ACL nếu cần

4. **[HIGH]** Validate Chat & Admin
   - Test chat RP 20m, `/me`, `/do`
   - Kiểm tra lệnh `/gotopos` và thêm kiểm tra quyền admin
   - Xem lại `help_system` nếu cần hướng dẫn người chơi

### 📝 Quick Reference Files

**Important Config Files:**
- `mtaserver.conf` - Server configuration
- `acl.xml` - Access Control List
- `settings.xml` - Server settings
- `banlist.xml` - Banned players/IPs

**Important Resource Files:**
- `resources/[core]/mysql/connection.lua` - DB connection
- `resources/[core]/account/` - Auto auth by Serial
- `resources/[core]/login_ui/` - CEF login/register UI
- `resources/[core]/character/` - Character load/save logic
- `resources/[core]/chat/` - Roleplay chat and /me /do
- `resources/[core]/vehicle/` - Persistent vehicle commands
- `resources/[core]/vehicle_system/` - Advanced personal vehicle system
- `resources/[admin]/admin/` - Admin source and configuration

---

## 📞 Support & Resources

**Documentation Location:** Refer to in-game help system

**Debug Console:**
- Server: `type debugscript 3` for max verbosity
- Client: F8 to open console

**Performance Monitor:**
- Web Admin: `http://localhost:22011`
- In-game: `/perfstats`

---

## 📄 Version History

**Current Version:** 1.0.0 - Development  
**Last Updated:** 2026-05-27  
**Status:** 🟡 **IN DEVELOPMENT - FOUNDATION PHASE**

---

## ✅ Document Guide

**How to use this roadmap:**

1. **For New Developers:** Read "Kiến Trúc Hệ Thống" first to understand structure
2. **For Task Assignment:** Check "Lộ Trình Phát Triển" phases
3. **For Debugging:** Refer to "Hướng Dẫn Setup & Maintain"
4. **For Status:** Update checklist as you complete tasks
5. **For Resources:** Check [web]/ or [managers]/ sections for tools

---

**Last Maintained:** 2026-05-26  
**Next Review:** Upon completion of Phase 1  
**Owner:** Development Team

---

