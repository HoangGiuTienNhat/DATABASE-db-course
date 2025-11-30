-- =========================================================================================
-- MINH HỌA GỌI HÀM 1: fn_Tinh_Doanh_Thu_Rong_Store
-- =========================================================================================

PRINT N'--- TEST CASE 1: Store 1 (Samsung) có bán S24 Ultra trong tháng hiện tại ---'
-- Store 1 bán S24 Ultra (Category 6 - Phí 5%). 
-- Kiểm tra: Lấy doanh thu từ hàm
SELECT dbo.fn_Tinh_Doanh_Thu_Rong_Store(1, MONTH(GETDATE()), YEAR(GETDATE())) AS Doanh_Thu_Rong_Thuc_Te;

PRINT N'--- TEST CASE 2: Store ID không tồn tại (Validate) ---'
SELECT dbo.fn_Tinh_Doanh_Thu_Rong_Store(999, 11, 2025) AS Ket_Qua_Store_Ao;

PRINT N'--- TEST CASE 3: Hiển thị danh sách các Store kèm doanh thu ròng tháng này ---'
SELECT 
    s.Store_id,
    s.Ten_gian_hang,
    dbo.fn_Tinh_Doanh_Thu_Rong_Store(s.Store_id, MONTH(GETDATE()), YEAR(GETDATE())) AS Doanh_Thu_Rong
FROM Store s;
GO

-- =========================================================================================
-- MINH HỌA GỌI HÀM 2: fn_Tinh_Diem_Uy_Tin_Buyer
-- =========================================================================================

PRINT N'--- TEST CASE 1: Buyer 11 (Có mua hàng thành công và 1 đơn hủy) ---'
-- Buyer 11 có 1 đơn 'Đã Giao' (có đánh giá, giá trị > 30tr) và 1 đơn 'Đã Hủy'.
-- Logic tính nhẩm: 
-- Gốc (100) 
-- + Đơn thành công (10) + Đơn to (5) + Đánh giá (2) = 117
-- - Đơn hủy (20) 
-- => Kết quả mong đợi: 97
SELECT 
    User_id AS BuyerID, 
    Ho + ' ' + Ten AS Ho_Ten,
    dbo.fn_Tinh_Diem_Uy_Tin_Buyer(User_id) AS Diem_Uy_Tin
FROM [User] WHERE User_id = 11;

PRINT N'--- TEST CASE 2: Buyer 12 (Mua nhiều đơn) ---'
SELECT 
    User_id AS BuyerID, 
    Ho + ' ' + Ten AS Ho_Ten,
    dbo.fn_Tinh_Diem_Uy_Tin_Buyer(User_id) AS Diem_Uy_Tin
FROM [User] WHERE User_id = 12;

PRINT N'--- TEST CASE 3: Buyer ID không tồn tại (Validate) ---'
SELECT dbo.fn_Tinh_Diem_Uy_Tin_Buyer(99999) AS Ket_Qua_Buyer_Ao; -- Mong đợi: -1

PRINT N'--- TEST CASE 4: Xếp hạng Buyer dựa trên điểm uy tín ---'
SELECT 
    b.User_id,
    u.Ten_dang_nhap,
    dbo.fn_Tinh_Diem_Uy_Tin_Buyer(b.User_id) AS Diem_Uy_Tin,
    CASE 
        WHEN dbo.fn_Tinh_Diem_Uy_Tin_Buyer(b.User_id) >= 150 THEN 'Platinum'
        WHEN dbo.fn_Tinh_Diem_Uy_Tin_Buyer(b.User_id) >= 120 THEN 'Gold'
        WHEN dbo.fn_Tinh_Diem_Uy_Tin_Buyer(b.User_id) >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END AS Xep_Hang
FROM Buyer b
JOIN [User] u ON b.User_id = u.User_id
ORDER BY Diem_Uy_Tin DESC;
GO