USE ShopeeDB;
GO
-- ============================================================
SET NOCOUNT ON;

-- ============================================================
-- Test Trigger_Requirement.sql
-- ============================================================


-- Trigger_Requirement_test.sql
-- End-to-end test for coupon minimum triggers on ShopeeDB.
-- Steps:
-- 1) Create minimal seller/store/product/variant, buyer, order, order_item
-- 2) Create a coupon with minimum > current order total
-- 3) Test 1: try to apply coupon (expect failure)
-- 4) Test 2: increase order total then apply coupon (expect success)
-- 5) Test 3: reduce total while coupon applied (expect failure)
-- 6) Test 4: increase total but still below new coupon minimum then apply (expect failure)
-- 7) Test 5: Delete one order item to reduce total below minimum (expect failure)
-- 8) Test 6: Run a SELECT query (expect success, trigger should not fire)
-- 9) Cleanup

DECLARE @SellerUser INT, @BuyerUser INT, @Store INT, 
		@Product INT, @VariantSKU NVARCHAR(100),
		@Coupon INT, @OrderID INT;
SET @VariantSKU = 'SKU-TEST-TRG-REQ-1';

-- 1) Create a seller user + store + product + variant
INSERT INTO [User] (Ten_dang_nhap, Mat_khau, Email, SDT, Ho, Ten)
VALUES ('test_seller_trgreq', 'pass', 'seller_trgreq@test.local', '0123456789', N'Seller', N'Test');
SET @SellerUser = SCOPE_IDENTITY();

INSERT INTO Seller (User_id, Seller_type) VALUES (@SellerUser, 'Individual');
INSERT INTO Store (Seller_id, Ten_gian_hang) VALUES (@SellerUser, N'Test Store TRGREQ');
SET @Store = SCOPE_IDENTITY();

INSERT INTO Product (Store_id, Ten_san_pham, Tinh_trang, Trong_luong, Trang_thai_dang)
VALUES (@Store, N'Test Product TRGREQ', 'New', 1.0, 'Active');
SET @Product = SCOPE_IDENTITY();

-- Insert a Variant with price 60.00
INSERT INTO Variant (Product_id, SKU, Mau_sac, Kich_thuoc, Gia_ban, So_luong_ton_kho)
VALUES (@Product, @VariantSKU, N'Red', N'M', 60.00, 100);

-- 2) Create buyer and order
INSERT INTO [User] (Ten_dang_nhap, Mat_khau, Email, SDT, Ho, Ten)
VALUES ('test_buyer_trgreq', 'pass', 'buyer_trgreq@test.local', '0987654321', N'Buyer', N'Test');
SET @BuyerUser = SCOPE_IDENTITY();

INSERT INTO Buyer (User_id) VALUES (@BuyerUser);

INSERT INTO [Order] (Buyer_id, Dia_chi_giao_hang) VALUES (@BuyerUser, N'123 Test Street TRGREQ');
SET @OrderID = SCOPE_IDENTITY();

-- 3) Insert order item (quantity 1 => total = 60)
INSERT INTO Order_item (Order_id, Item_id, Product_id, SKU, So_luong)
VALUES (@OrderID, 1, @Product, @VariantSKU, 1);

-- 4) Insert a coupon requiring minimum 100 (explicit column list to avoid identity issues)
INSERT INTO Coupon (Ti_le_giam, Thoi_han, Dieu_kien_gia_toi_thieu)
VALUES (10.0, DATEADD(DAY,30,GETDATE()), 100.00);
SET @Coupon = SCOPE_IDENTITY();

--Tôi cần một biến đếm để đếm các trường hợp thành công và tổng số trường hợp thử nghiệm
DECLARE @TestCount INT = 0;
DECLARE @SuccessCount INT = 0;

-- Apply coupon when total < minimum 
PRINT '===';
PRINT '=== TEST 1:(TRIGGER HOAT ĐONG)';
SET @TestCount = @TestCount + 1;
BEGIN TRY
	BEGIN TRANSACTION;
		INSERT INTO Ap_dung (Order_id, Item_id, Coupon_id)
		VALUES (@OrderID, 1, @Coupon);
	COMMIT TRANSACTION;
	PRINT 'TEST 1: FAIL (IN RA NEU TRIGGER KHONG HOAT ĐONG)';
END TRY
BEGIN CATCH
	PRINT 'TEST 1 MESSAGE: ' + ERROR_MESSAGE();
	SET @SuccessCount = @SuccessCount + 1;
	IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
END CATCH;

-- Increase quantity to reach minimum then apply coupon 
PRINT '===';
PRINT '=== TEST 2:(TRIGGER KHONG HOAT ĐONG)';
SET @TestCount = @TestCount + 1;
BEGIN TRY
	BEGIN TRANSACTION;
		UPDATE Order_item SET So_luong = 2 WHERE Order_id = @OrderID AND Item_id = 1;
		INSERT INTO Ap_dung (Order_id, Item_id, Coupon_id)
		VALUES (@OrderID, 1, @Coupon);
	COMMIT TRANSACTION;
	PRINT 'TEST 2: Success: coupon applied';
	SET @SuccessCount = @SuccessCount + 1;
END TRY
BEGIN CATCH
	PRINT 'TEST 2 MESSAGE: ' + ERROR_MESSAGE();
	PRINT 'TEST 2: FAIL (IN RA NẾU TRIGGER HOAT ĐONG)';
	IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
END CATCH;

-- Reduce quantity so total < minimum while coupon applied 
PRINT '===';
PRINT '=== TEST 3:(TRIGGER HOAT ĐONG)';
SET @TestCount = @TestCount + 1;
BEGIN TRY
	BEGIN TRANSACTION;
		UPDATE Order_item SET So_luong = 1 WHERE Order_id = @OrderID AND Item_id = 1;
		UPDATE Ap_dung SET Coupon_id = @Coupon WHERE Order_id = @OrderID AND Item_id = 1;
	COMMIT TRANSACTION;
	PRINT 'TEST 3: FAIL (IN RA NEU TRIGGER KHONG HOAT ĐONG)';
END TRY
BEGIN CATCH
	PRINT 'TEST 3 MESSAGE: ' + ERROR_MESSAGE();
	SET @SuccessCount = @SuccessCount + 1;
	IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
END CATCH;


--Increase quantity to reach minimum then apply second coupon 
INSERT INTO Coupon (Ti_le_giam, Thoi_han, Dieu_kien_gia_toi_thieu)
VALUES (15.0, DATEADD(DAY,30,GETDATE()), 200.00);
SET @Coupon = SCOPE_IDENTITY();
PRINT '===';
PRINT '=== TEST 4: (TRIGGER HOAT ĐONG)';
SET @TestCount = @TestCount + 1;
BEGIN TRY
	BEGIN TRANSACTION;
		UPDATE Order_item SET So_luong = 3 WHERE Order_id = @OrderID AND Item_id = 1;
		INSERT INTO Ap_dung (Order_id, Item_id, Coupon_id)
		VALUES (@OrderID, 1, @Coupon);
	COMMIT TRANSACTION;
	PRINT 'TEST 4: FAIL (IN RA NEU TRIGGER KHONG HOAT ĐONG)';
END TRY
BEGIN CATCH
	PRINT 'TEST 4 MESSAGE: ' + ERROR_MESSAGE();
	SET @SuccessCount = @SuccessCount + 1;
	IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
END CATCH;

PRINT '===';
PRINT '=== TEST 5: (TRIGGER HOAT ĐONG)';
-- Delete one order item to reduce total below minimum
SET @TestCount = @TestCount + 1;
BEGIN TRY
	BEGIN TRANSACTION;
		UPDATE Order_item SET So_luong = 2 WHERE Order_id = @OrderID AND Item_id = 1;
		UPDATE Ap_dung SET Coupon_id = @Coupon WHERE Order_id = @OrderID AND Item_id = 1;
	COMMIT TRANSACTION;
	PRINT 'TEST 5: FAIL (IN RA NEU TRIGGER KHONG HOAT ĐONG)';
END TRY
BEGIN CATCH
	PRINT 'TEST 5 MESSAGE: ' + ERROR_MESSAGE();
	SET @SuccessCount = @SuccessCount + 1;
	IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
END CATCH;

--TESTcase 6: Khi dùng select để truy vấn thì TRIGGER không hoạt động
PRINT '===';
PRINT '=== TEST 6: (TRIGGER KHONG HOAT ĐONG)';
SET @TestCount = @TestCount + 1;
BEGIN TRY
	BEGIN TRANSACTION;
		-- Chạy một truy vấn SELECT để kiểm tra xem TRIGGER có ảnh hưởng đến nó không
		SELECT * FROM Ap_dung WHERE Order_id = @OrderID;
	COMMIT TRANSACTION;
	PRINT 'TEST 6: Success: SELECT';
	SET @SuccessCount = @SuccessCount + 1;
END TRY	
BEGIN CATCH
	PRINT 'TEST 6 MESSAGE: ' + ERROR_MESSAGE();
	PRINT 'TEST 6: FAIL (IN RA NEU TRIGGER HOAT ĐONG)';
	IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
END CATCH;

PRINT '===';
PRINT 'TEST RESULTS: ' + CAST(@SuccessCount AS NVARCHAR(10)) + ' out of ' + CAST(@TestCount AS NVARCHAR(10)) + ' tests passed.';


--- CLEANUP
PRINT '=== CLEANUP';
BEGIN TRY
	BEGIN TRANSACTION;
		DELETE FROM Ap_dung WHERE Order_id = @OrderID;
		DELETE FROM Order_item WHERE Order_id = @OrderID;
		DELETE FROM [Order] WHERE Order_id = @OrderID;
		DELETE FROM Coupon WHERE Coupon_id = @Coupon;
		DELETE FROM Variant WHERE Product_id = @Product AND SKU = @VariantSKU;
		DELETE FROM Product WHERE Product_id = @Product;
		DELETE FROM Store WHERE Store_id = @Store;
		DELETE FROM Seller WHERE User_id = @SellerUser;
		DELETE FROM Buyer WHERE User_id = @BuyerUser;
		DELETE FROM [User] WHERE User_id IN (@SellerUser, @BuyerUser);
	COMMIT TRANSACTION;
	PRINT 'Cleanup done.';
END TRY
BEGIN CATCH
	IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
	PRINT 'Cleanup failed: ' + ERROR_MESSAGE();
END CATCH;

PRINT 'All tests complete.';