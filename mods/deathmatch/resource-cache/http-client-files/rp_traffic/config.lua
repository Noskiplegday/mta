-- Tối ưu hóa số lượng để tránh lag server
TRAFFIC_VEHICLES = 30 -- Tổng số xe tối đa trên toàn server (nên điều chỉnh theo số người chơi)
TRAFFIC_PEDS = 40

SPAWN_RADIUS = 150   -- Khoảng cách spawn (nên xa một chút để người chơi không thấy xe hiện ra đột ngột)
DESPAWN_RADIUS = 200 -- Khoảng cách xóa xe

-- Danh sách xe dân sự nhẹ nhàng, tránh xe tải lớn hoặc xe quá nhanh
VEHICLE_MODELS = {
    400, 401, 404, 405, 410,
    418, 421, 426, 436, 445,
    466, 467, 474, 475, 479,
    492, 496, 507, 516, 517
}

PED_MODELS = {7, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26}