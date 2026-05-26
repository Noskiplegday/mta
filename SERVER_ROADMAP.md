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

| Module | Mục Đích |
|--------|----------|
| **account/** | Hệ thống tài khoản, đăng nhập, đăng ký |
| **character/** | Quản lý nhân vật (tạo, load, save) |
| **chat/** | Hệ thống chat (world, local, roleplay) |
| **help_system/** | Hệ thống trợ giúp cho người chơi |
| **inventory/** | Hệ thống kho đồ, items |
| **login_ui/** | Giao diện đăng nhập |
| **mysql/** | ⚠️ **CRITICAL** - Kết nối Database MySQL |
| **peds/** | Quản lý NPC (Pedestrians) |
| **traffic/** | Hệ thống giao thông, traffic |
| **vehicle/** | Hệ thống phương tiện cơ bản |
| **vehicle_system/** | Quản lý chi tiết xe (damage, fuel, etc.) |

**Ưu tiên phát triển:** MySQL → Account → Character → Inventory

---

### 🎮 [gameplay]/ - Gameplay Features

Chứa 40+ module .zip chính:

**Nhóm Cơ Bản:**
- `dialogs.zip` - UI dialogs
- `glue.zip` - Core glue code
- `easytext.zip` - Text utilities

**Nhóm Vũ Khí & Chiến Đấu:**
- `deathpickups.zip` - Loot sau khi chết
- `deathmessages.zip` - Thông báo khi chết
- `headshot.zip` - Hệ thống headshot
- `killmessages.zip` - Thông báo kill

**Nhóm Bản Đồ:**
- `mapfixes.zip` - Fix bug bản đồ
- `maplimits.zip` - Ranh giới bản đồ
- `mapratings.zip` - Xếp hạng bản đồ
- `interiors.zip` - Interior locations
- `mapmanager.zip` - Quản lý map

**Nhóm Xe & Giao Thông:**
- `realdriveby.zip` - Drive-by shooting
- `trainhorn.zip` - Âm thanh tàu
- `sirenEdit.zip` - Chỉnh sửa siren

**Nhóm Tiện Ích:**
- `gps.zip` - Bản đồ GPS
- `speedometer.zip` - Máy đo tốc độ
- `parachute.zip` - Dù nhảy dù
- `superman.zip` - Flying mode
- `freecam.zip` - Tự do camera
- `webbrowser.zip` - Trình duyệt web

**Nhóm Âm Thanh & Broadcast:**
- `voice.zip` - Chat thoại
- `voice_local.zip` - Voice local
- `internetradio.zip` - Radio internet
- `joinquit.zip` - Notify join/quit
- `missiontimer.zip` - Mission timer

**Nhóm Khác:**
- `scoreboard.zip` - Bảng điểm
- `scores.zip` - Score tracking
- `pickuphandler.zip` - Xử lý pickups
- `sfxbrowser.zip` - Sound browser
- `visualiser.zip` - Audio visualizer

---

### 🛠️ [managers]/ - Quản Lý Server

Các manager module (7 modules .zip):

| Manager | Chức Năng |
|---------|----------|
| **chatmanager.zip** | Quản lý hệ thống chat server-wide |
| **helpmanager.zip** | Quản lý help system |
| **mapcycler.zip** | Tự động xoay map |
| **mapmanager.zip** | Quản lý & load map |
| **spawnmanager.zip** | Quản lý spawn point |
| **teammanager.zip** | Quản lý team & faction |
| **votemanager.zip** | Hệ thống vote server |

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
[ ] MySQL connection - Priority: CRITICAL
[ ] Login system - Priority: CRITICAL
[ ] Character management - Priority: CRITICAL
[ ] Chat system - Priority: HIGH
[ ] Inventory system - Priority: HIGH
[ ] Vehicle system - Priority: HIGH
[ ] Admin tools - Priority: HIGH
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

1. **[CRITICAL]** Verify MySQL connection
   - Test database connectivity
   - Validate table schemas
   - Check connection string

2. **[CRITICAL]** Test Login System
   - Create test accounts
   - Verify account persistence
   - Test character creation

3. **[HIGH]** Setup Admin Tools
   - Implement basic admin commands
   - Test ban/kick system
   - Verify permission levels

4. **[HIGH]** Configure Game Mode
   - Choose primary gamemode (Deathmatch)
   - Test spawn points
   - Verify weapon distribution

### 📝 Quick Reference Files

**Important Config Files:**
- `mtaserver.conf` - Server configuration
- `acl.xml` - Access Control List
- `settings.xml` - Server settings
- `banlist.xml` - Banned players/IPs

**Important Resource Files:**
- `mysql/connection.lua` - DB connection
- `core/login/` - Login system
- `core/character/` - Character system
- `admin/admin.lua` - Admin commands

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
**Last Updated:** 2026-05-26  
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

