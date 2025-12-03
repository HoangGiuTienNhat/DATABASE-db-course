-- ============================================================
-- TEST CASES CHO TRIGGER trg_ApDung_CheckCoupon_AfterIU
-- ============================================================
USE ShopeeDB;
GO

PRINT N'========================================';
PRINT N'BẮT ĐẦU TEST TRIGGER KIỂM TRA COUPON';
PRINT N'========================================';
PRINT N'';

-- ============================================================
-- CHUẨN BỊ DỮ LIỆU TEST
-- ============================================================

-- Kiểm tra các coupon hiện có
PRINT N'--- Danh sách Coupon hiện có ---';
SELECT 
    Coupon_id, 
    Ti_le_giam, 
    Dieu_kien_gia_toi_thieu,
    Thoi_han
FROM Coupon
WHERE Thoi_han > GETDATE()
ORDER BY Dieu_kien_gia_toi_thieu;
GO

PRINT N'';
PRINT N'--- Danh sách Order_item có thể test ---';
SELECT TOP 5
    oi.Order_id,
    oi.Item_id,
    oi.Product_id,
    oi.SKU,
    oi.So_luong,
    v.Gia_ban,
    (oi.So_luong * v.Gia_ban) AS Tong_gia_tri
FROM Order_item oi
JOIN Variant v ON oi.Product_id = v.Product_id AND oi.SKU = v.SKU
ORDER BY (oi.So_luong * v.Gia_ban) DESC;
GO

PRINT N'';
PRINT N'========================================';
PRINT N'TEST CASE 1: ÁP DỤNG COUPON THÀNH CÔNG';
PRINT N'========================================';
PRINT N'Mô tả: Order_item có giá trị >= điều kiện tối thiểu của coupon';
PRINT N'';

-- Tạo đơn hàng test
INSERT INTO [Order] (Buyer_id, Trang_thai_don, Dia_chi_giao_hang) 
VALUES (11, N'Chờ Xác Nhận', N'Địa chỉ test 1');

DECLARE @TestOrder1 INT = SCOPE_IDENTITY();

-- Thêm order_item: Mua Samsung S24 Ultra (33,990,000đ) - đủ điều kiện cho mọi coupon
INSERT INTO Order_item (Order_id, Item_id, Product_id, SKU, So_luong)
VALUES (@TestOrder1, 1, 1, 'S24U-TITAN-512', 1);

PRINT N'Thêm order_item: Samsung S24 Ultra - 33,990,000đ';
PRINT N'Áp dụng Coupon 1 (điều kiện >= 150,000đ)';

BEGIN TRY
    INSERT INTO Ap_dung (Order_id, Item_id, Coupon_id)
    VALUES (@TestOrder1, 1, 1);
    
    PRINT N'✓ PASS: Áp dụng coupon thành công!';
    PRINT N'';
END TRY
BEGIN CATCH
    PRINT N'✗ FAIL: ' + ERROR_MESSAGE();
    PRINT N'';
END CATCH
GO

PRINT N'========================================';
PRINT N'TEST CASE 2: ÁP DỤNG COUPON THẤT BẠI';
PRINT N'========================================';
PRINT N'Mô tả: Order_item có giá trị < điều kiện tối thiểu của coupon';
PRINT N'';

-- Tạo đơn hàng test
INSERT INTO [Order] (Buyer_id, Trang_thai_don, Dia_chi_giao_hang) 
VALUES (12, N'Chờ Xác Nhận', N'Địa chỉ test 2');

DECLARE @TestOrder2 INT = SCOPE_IDENTITY();

-- Thêm order_item: Mua Sách (108,000đ) - KHÔNG đủ điều kiện cho coupon có điều kiện >= 150,000đ
INSERT INTO Order_item (Order_id, Item_id, Product_id, SKU, So_luong)
VALUES (@TestOrder2, 1, 3, 'SACH-BIA-MEM', 1);

PRINT N'Thêm order_item: Sách - 108,000đ';
PRINT N'Áp dụng Coupon 1 (điều kiện >= 150,000đ)';

BEGIN TRY
    INSERT INTO Ap_dung (Order_id, Item_id, Coupon_id)
    VALUES (@TestOrder2, 1, 1);
    
    PRINT N'✗ FAIL: Không nên cho phép áp dụng coupon!';
    PRINT N'';
END TRY
BEGIN CATCH
    PRINT N'✓ PASS: Trigger chặn thành công - ' + ERROR_MESSAGE();
    PRINT N'';
END CATCH
GO
