
USE ShopeeDB;
GO


-- Trigger: validate coupons when Ap_dung changes
IF OBJECT_ID('dbo.trg_ApDung_CheckCoupon_AfterIU','TR') IS NOT NULL
	DROP TRIGGER dbo.trg_ApDung_CheckCoupon_AfterIU;
GO

CREATE TRIGGER dbo.trg_ApDung_CheckCoupon_AfterIU
ON dbo.Ap_dung
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (
		SELECT 1
		FROM (
			SELECT DISTINCT Order_id
			FROM inserted
			WHERE Order_id IS NOT NULL
			UNION
			SELECT DISTINCT Order_id FROM deleted WHERE Order_id IS NOT NULL
		) ao
		JOIN dbo.Ap_dung ad ON ad.Order_id = ao.Order_id
		JOIN dbo.Coupon c ON c.Coupon_id = ad.Coupon_id
		CROSS APPLY (
			SELECT ISNULL(SUM(oi.So_luong * v.Gia_ban), 0) AS OrderTotal
			FROM dbo.Order_item oi
			JOIN dbo.Variant v ON oi.Product_id = v.Product_id AND oi.SKU = v.SKU
			WHERE oi.Order_id = ao.Order_id
		) t
		WHERE t.OrderTotal < c.Dieu_kien_gia_toi_thieu
	)
	BEGIN
		RAISERROR (N'Coupon khong kha dung.', 16, 1);
		ROLLBACK TRANSACTION;
		RETURN;
	END
END;
GO 
