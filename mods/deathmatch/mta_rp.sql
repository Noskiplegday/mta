-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1
-- Thời gian đã tạo: Th5 26, 2026 lúc 03:14 PM
-- Phiên bản máy phục vụ: 10.4.32-MariaDB
-- Phiên bản PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `mta_rp`
--

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `accounts`
--

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` text NOT NULL,
  `serial` varchar(100) NOT NULL,
  `register_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `accounts`
--

INSERT INTO `accounts` (`id`, `username`, `password`, `serial`, `register_date`) VALUES
(4, 'User_1011', 'default_password', '0F4E85E282F61C0EBAAAB903A1341CA4', '2026-05-26 10:36:34');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `characters`
--

CREATE TABLE `characters` (
  `id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `char_name` varchar(100) NOT NULL,
  `cash` int(11) DEFAULT 5000,
  `skin` int(11) DEFAULT 0,
  `pos_x` float DEFAULT -1987.5,
  `pos_y` float DEFAULT 137.5,
  `pos_z` float DEFAULT 27.5,
  `pos_rot` float DEFAULT 90
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `characters`
--

INSERT INTO `characters` (`id`, `account_id`, `char_name`, `cash`, `skin`, `pos_x`, `pos_y`, `pos_z`, `pos_rot`) VALUES
(3, 4, 'User_1011', 49983456, 0, 2053.84, 1084.81, 10.6719, 266.857);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `inventory`
--

CREATE TABLE `inventory` (
  `id` int(11) NOT NULL,
  `char_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `item_count` int(11) DEFAULT 1,
  `slot_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `inventory`
--

INSERT INTO `inventory` (`id`, `char_id`, `item_id`, `item_count`, `slot_id`) VALUES
(3, 2, 1, 2, 1),
(4, 2, 4, 1, 1);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `my_accounts`
--

CREATE TABLE `my_accounts` (
  `id` int(11) NOT NULL,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `serial` varchar(100) DEFAULT NULL,
  `ip_addr` varchar(40) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `my_accounts`
--

INSERT INTO `my_accounts` (`id`, `username`, `password`, `email`, `serial`, `ip_addr`) VALUES
(1, 'Admin123', '123', 'Admin123@vancanh.com', '0F4E85E282F61C0EBAAAB903A1341CA4', '127.0.0.1');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `my_characters`
--

CREATE TABLE `my_characters` (
  `id` int(11) NOT NULL,
  `account_id` int(11) DEFAULT NULL,
  `char_name` varchar(50) DEFAULT NULL,
  `money` int(11) DEFAULT 5000,
  `health` float DEFAULT 100,
  `armor` float DEFAULT 0,
  `premium_points` int(11) DEFAULT 0,
  `x` float DEFAULT 0,
  `y` float DEFAULT 0,
  `z` float DEFAULT 3,
  `interior` int(11) DEFAULT 0,
  `dimension` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `my_characters`
--

INSERT INTO `my_characters` (`id`, `account_id`, `char_name`, `money`, `health`, `armor`, `premium_points`, `x`, `y`, `z`, `interior`, `dimension`) VALUES
(1, 1, 'Admin123_City', 49983456, 0, 0, 0, 2053.84, 1084.81, 10.6719, 0, 0);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `vehicles`
--

CREATE TABLE `vehicles` (
  `id` int(11) NOT NULL,
  `char_id` int(11) NOT NULL,
  `model` int(11) NOT NULL,
  `pos_x` float NOT NULL,
  `pos_y` float NOT NULL,
  `pos_z` float NOT NULL,
  `pos_rot` float NOT NULL,
  `color_r` int(11) DEFAULT 255,
  `color_g` int(11) DEFAULT 255,
  `color_b` int(11) DEFAULT 255,
  `locked` int(11) DEFAULT 0,
  `respawned` int(11) DEFAULT 1,
  `fuel` int(11) NOT NULL DEFAULT 100
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `vehicles`
--

INSERT INTO `vehicles` (`id`, `char_id`, `model`, `pos_x`, `pos_y`, `pos_z`, `pos_rot`, `color_r`, `color_g`, `color_b`, `locked`, `respawned`, `fuel`) VALUES
(2, 2, 411, -2025.41, 139.803, 28.5667, 175.15, 255, 255, 255, 0, 1, 100),
(3, 4, 411, 16.001, 0.041016, 3.11719, 219.31, 255, 255, 255, 0, 1, 94),
(4, 4, 511, 339.36, 1355.46, 8.16603, 343.292, 255, 255, 255, 0, 1, 99),
(5, 4, 461, 352.881, 1404.15, 6.68142, 254.56, 255, 255, 255, 0, 1, 0),
(6, 4, 522, 1729.03, 1290.89, 10.6719, 260.674, 255, 255, 255, 0, 1, 0),
(7, 4, 411, 1732.22, 1296.9, 10.7204, 191.322, 255, 255, 255, 0, 1, 0),
(8, 4, 465, 2037.62, 949.708, 10.1296, 142.629, 255, 255, 255, 0, 1, 100),
(9, 4, 512, 2048.15, 966.245, 10.3817, 346.528, 255, 255, 255, 0, 1, 100);

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Chỉ mục cho bảng `characters`
--
ALTER TABLE `characters`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `char_name` (`char_name`),
  ADD KEY `account_id` (`account_id`);

--
-- Chỉ mục cho bảng `inventory`
--
ALTER TABLE `inventory`
  ADD PRIMARY KEY (`id`);

--
-- Chỉ mục cho bảng `my_accounts`
--
ALTER TABLE `my_accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Chỉ mục cho bảng `my_characters`
--
ALTER TABLE `my_characters`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `char_name` (`char_name`),
  ADD KEY `account_id` (`account_id`);

--
-- Chỉ mục cho bảng `vehicles`
--
ALTER TABLE `vehicles`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT cho bảng `characters`
--
ALTER TABLE `characters`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT cho bảng `inventory`
--
ALTER TABLE `inventory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT cho bảng `my_accounts`
--
ALTER TABLE `my_accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT cho bảng `my_characters`
--
ALTER TABLE `my_characters`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT cho bảng `vehicles`
--
ALTER TABLE `vehicles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Các ràng buộc cho các bảng đã đổ
--

--
-- Các ràng buộc cho bảng `characters`
--
ALTER TABLE `characters`
  ADD CONSTRAINT `characters_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE;

--
-- Các ràng buộc cho bảng `my_characters`
--
ALTER TABLE `my_characters`
  ADD CONSTRAINT `my_characters_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `my_accounts` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
