USE ShopeeDB;
GO

-- ============================================================================
-- PHẦN 1: CẬP NHẬT CẤU TRÚC BẢNG 
-- ============================================================================

-- 1.1. Thêm cột 'Tong_tien' vào bảng [Order]
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Order]') AND name = N'Tong_tien')
BEGIN
    ALTER TABLE [Order]
    ADD Tong_tien DECIMAL(18, 2) DEFAULT 0;
END
GO

-- 1.2. Thêm cột 'Don_gia' (Giá thực tế sau giảm do COUPON của 1 sản phẩm) vào Order_item
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'Order_item') AND name = N'Don_gia')
BEGIN
    ALTER TABLE Order_item
    ADD Don_gia DECIMAL(18, 2) DEFAULT 0;
END
GO

-- 1.3. Thêm cột 'So_tien_thanh_toan' vào bảng Payment
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'Payment') AND name = N'So_tien_thanh_toan')
BEGIN
    ALTER TABLE Payment
    ADD So_tien_thanh_toan DECIMAL(18, 2) DEFAULT 0;
END
GO

-- 1.4. Thêm cột điểm đánh giá vào Product và Store
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'Product') AND name = N'Diem_danh_gia_sp')
BEGIN
    ALTER TABLE Product
    ADD Diem_danh_gia_sp DECIMAL(3, 2) DEFAULT 0;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'Store') AND name = N'Diem_danh_gia_store')
BEGIN
    ALTER TABLE Store
    ADD Diem_danh_gia_store DECIMAL(3, 2) DEFAULT 0;
END
GO

-- 1.5. Ràng buộc UNIQUE: Đảm bảo 1 Item chỉ được áp dụng tối đa 1 Coupon
IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'UQ' AND name = 'UQ_OneCouponPerItem')
BEGIN
    ALTER TABLE Ap_dung
    ADD CONSTRAINT UQ_OneCouponPerItem UNIQUE (Order_id, Item_id);
END
GO

-- ============================================================================
-- PHẦN 2: CÁC TRIGGER THUỘC TÍNH DẪN XUẤT
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TRIGGER 1: TÍNH 'ĐƠN GIÁ' (Giá tại thời điểm mua)
-- Giá bán gốc * (1 - %Coupon).
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Calculate_Don_gia_Item
ON Order_item
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE oi
    SET oi.Don_gia = ISNULL(
        v.Gia_ban * (1 - ISNULL(c.Ti_le_giam, 0) / 100.0)
    , 0)
    FROM Order_item oi
    JOIN inserted i ON oi.Order_id = i.Order_id AND oi.Item_id = i.Item_id
    JOIN Variant v ON oi.Product_id = v.Product_id AND oi.SKU = v.SKU
    LEFT JOIN Ap_dung ad ON oi.Order_id = ad.Order_id AND oi.Item_id = ad.Item_id
    LEFT JOIN Coupon c ON ad.Coupon_id = c.Coupon_id;
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 2: TÍNH 'TỔNG TIỀN'
-- Tổng (Don_gia * So_luong). Trigger này tự chạy khi Trigger 1 update.
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Update_Order_Total_From_Items
ON Order_item
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra sự thay đổi của Don_gia và So_luong
    IF NOT UPDATE(Don_gia) AND NOT UPDATE(So_luong) AND NOT EXISTS (SELECT * FROM deleted)
        RETURN;

    -- Lấy danh sách Order bị ảnh hưởng
    DECLARE @AffectedOrders TABLE (Order_id INT);
    INSERT INTO @AffectedOrders (Order_id)
    SELECT DISTINCT Order_id FROM inserted
    UNION
    SELECT DISTINCT Order_id FROM deleted;

    -- Tính tổng tiền
    UPDATE o
    SET o.Tong_tien = (
        SELECT ISNULL(SUM(oi.Don_gia * oi.So_luong), 0)
        FROM Order_item oi
        WHERE oi.Order_id = o.Order_id
    )
    FROM [Order] o
    JOIN @AffectedOrders ao ON o.Order_id = ao.Order_id;
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 3: XỬ LÝ KHI THAY ĐỔI COUPON
-- Khi Coupon đổi -> Update lại Don_gia của Item -> Kích hoạt Trigger 2
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Update_Item_On_Coupon_Change
ON Ap_dung
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy danh sách Item bị ảnh hưởng
    DECLARE @AffectedItems TABLE (Order_id INT, Item_id INT);
    INSERT INTO @AffectedItems (Order_id, Item_id)
    SELECT Order_id, Item_id FROM inserted
    UNION
    SELECT Order_id, Item_id FROM deleted;

    -- Tính lại 'Don_gia' (Logic giống Trigger 1)
    UPDATE oi
    SET oi.Don_gia = ISNULL(
        v.Gia_ban * (1 - ISNULL(c.Ti_le_giam, 0) / 100.0)
    , 0)
    FROM Order_item oi
    JOIN Variant v ON oi.Product_id = v.Product_id AND oi.SKU = v.SKU
    INNER JOIN @AffectedItems ai ON oi.Order_id = ai.Order_id AND oi.Item_id = ai.Item_id
    LEFT JOIN Ap_dung ad ON oi.Order_id = ad.Order_id AND oi.Item_id = ad.Item_id
    LEFT JOIN Coupon c ON ad.Coupon_id = c.Coupon_id;
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 4: ĐỒNG BỘ SANG PAYMENT
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Sync_Order_To_Payment
ON [Order]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(Tong_tien) RETURN;

    UPDATE p
    SET p.So_tien_thanh_toan = i.Tong_tien
    FROM Payment p
    JOIN inserted i ON p.Order_id = i.Order_id;
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 5: TÍNH ĐIỂM ĐÁNH GIÁ PRODUCT
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Update_Product_Rating
ON Danh_gia
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AffectedProducts TABLE (Product_id INT);
    INSERT INTO @AffectedProducts
    SELECT DISTINCT Product_id FROM inserted
    UNION
    SELECT DISTINCT Product_id FROM deleted;

    UPDATE p
    SET p.Diem_danh_gia_sp = (
        SELECT ISNULL(AVG(CAST(d.So_sao AS DECIMAL(3, 2))), 0) 
        FROM Danh_gia d
        WHERE d.Product_id = p.Product_id
    )
    FROM Product p
    JOIN @AffectedProducts ap ON p.Product_id = ap.Product_id;
END;
GO

-- ----------------------------------------------------------------------------
-- TRIGGER 6: TÍNH ĐIỂM ĐÁNH GIÁ STORE
-- ----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_Update_Store_Rating
ON Product
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(Diem_danh_gia_sp) AND NOT EXISTS(SELECT * FROM deleted) RETURN;

    DECLARE @AffectedStores TABLE (Store_id INT);
    INSERT INTO @AffectedStores
    SELECT DISTINCT Store_id FROM inserted
    UNION
    SELECT DISTINCT Store_id FROM deleted;

    UPDATE s
    SET s.Diem_danh_gia_store = (
        SELECT ISNULL(AVG(p.Diem_danh_gia_sp), 0)
        FROM Product p
        WHERE p.Store_id = s.Store_id 
        AND p.Trang_thai_dang <> 'Deleted'
        AND p.Diem_danh_gia_sp > 0
    )
    FROM Store s
    JOIN @AffectedStores as_store ON s.Store_id = as_store.Store_id;
END;
GO

-- ============================================================================
-- PHẦN 3: ĐỒNG BỘ DỮ LIỆU
-- ============================================================================

PRINT N'>>> Bắt đầu đồng bộ dữ liệu cũ...';

-- Tính 'Don_gia' cho toàn bộ Order_item
UPDATE oi
SET oi.Don_gia = ISNULL(
    v.Gia_ban * (1 - ISNULL(c.Ti_le_giam, 0) / 100.0)
, 0)
FROM Order_item oi
JOIN Variant v ON oi.Product_id = v.Product_id AND oi.SKU = v.SKU
LEFT JOIN Ap_dung ad ON oi.Order_id = ad.Order_id AND oi.Item_id = ad.Item_id
LEFT JOIN Coupon c ON ad.Coupon_id = c.Coupon_id;
PRINT N'   - Đã cập nhật xong Don_gia.';

-- Tính 'Tong_tien' cho toàn bộ Order (Dựa trên Don_gia và So_luong)
UPDATE o
SET o.Tong_tien = (
    SELECT ISNULL(SUM(oi.Don_gia * oi.So_luong), 0)
    FROM Order_item oi
    WHERE oi.Order_id = o.Order_id
)
FROM [Order] o;
PRINT N'   - Đã cập nhật xong Tong_tien Order.';

-- Đồng bộ sang Payment
UPDATE p
SET p.So_tien_thanh_toan = o.Tong_tien
FROM Payment p
JOIN [Order] o ON p.Order_id = o.Order_id;
PRINT N'   - Đã cập nhật xong Payment.';

PRINT N'>>> Hoàn tất quá trình cài đặt Trigger và đồng bộ dữ liệu!';
GO