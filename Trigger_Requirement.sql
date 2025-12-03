USE ShopeeDB;
GO

IF OBJECT_ID('dbo.trg_ApDung_CheckCoupon_AfterIU','TR') IS NOT NULL
    DROP TRIGGER dbo.trg_ApDung_CheckCoupon_AfterIU;
GO

CREATE TRIGGER dbo.trg_ApDung_CheckCoupon_AfterIU
ON dbo.Ap_dung
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /* Kiểm tra từng Order_item được áp dụng coupon */
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Order_item oi 
            ON oi.Order_id = i.Order_id
           AND oi.Item_id  = i.Item_id
        JOIN dbo.Variant v
            ON v.Product_id = oi.Product_id
           AND v.SKU        = oi.SKU
        JOIN dbo.Coupon c
            ON c.Coupon_id = i.Coupon_id
        WHERE (oi.So_luong * v.Gia_ban) < c.Dieu_kien_gia_toi_thieu
    )
    BEGIN
        RAISERROR (N'Coupon không khả dụng cho order_item này.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO
