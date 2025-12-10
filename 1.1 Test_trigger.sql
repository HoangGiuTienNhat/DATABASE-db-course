-- TEST LẠI
PRINT N'--- Test: User 1 (Buyer + Seller) mua hàng từ Store 1 (của chính mình) ---';
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Tạo Order
    INSERT INTO [Order] (Buyer_id, Trang_thai_don, Dia_chi_giao_hang)
    VALUES (1, N'Chờ Xác Nhận', N'Test địa chỉ');
    
    DECLARE @TestOrder INT = SCOPE_IDENTITY();
    
    -- Thêm Order_item (trigger sẽ kích hoạt ở đây)
    INSERT INTO Order_item (Order_id, Item_id, Product_id, SKU, So_luong)
    VALUES (@TestOrder, 1, 1, 'S24U-TITAN-512', 1);
    
    COMMIT TRANSACTION;
    
    PRINT N'✗ FAIL: Trigger không hoạt động';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'✓ PASS: ' + ERROR_MESSAGE();
END CATCH
GO


PRINT '========================================='
PRINT 'TEST CASE 2: trg_Product_Active_Validation'
PRINT '========================================='
PRINT ''

-- Tạo sản phẩm test mới (chưa có ảnh và category)
DECLARE @TestProductId INT;

INSERT INTO Product (Store_id, Ten_san_pham, Mo_ta_chi_tiet, Tinh_trang, Trong_luong, Trang_thai_dang)
VALUES (1, N'Samsung Galaxy Tab Test', N'Tablet for testing trigger', 'New', 0.5, 'Hidden');

SET @TestProductId = SCOPE_IDENTITY();
PRINT 'Created test Product_id = ' + CAST(@TestProductId AS VARCHAR(10))
PRINT ''

-- Tạo Variant cho sản phẩm test
INSERT INTO Variant (Product_id, SKU, Mau_sac, Kich_thuoc, Gia_ban, So_luong_ton_kho)
VALUES (@TestProductId, 'TEST-SKU-001', N'Bạc', '256GB', 15000000, 10);

-- TEST 2.1: NEGATIVE - Active sản phẩm KHÔNG có ảnh và category (Phải FAIL)
PRINT '--- Test 2.1: Active sản phẩm không có ảnh và category (Expected: FAIL) ---'
BEGIN TRY
    BEGIN TRANSACTION;
    
    UPDATE Product
    SET Trang_thai_dang = 'Active'
    WHERE Product_id = @TestProductId;
    
    COMMIT TRANSACTION;
    PRINT 'RESULT: PASSED (But should FAIL) ✗ - BUG DETECTED!'
    PRINT ''
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'RESULT: FAILED as expected '
    PRINT 'Error: ' + ERROR_MESSAGE()
    PRINT ''
END CATCH

-----------------------------------------------------------------------------
-------------------------Testcase3-----------------------------------------
---------------------------------------------------------------------------

PRINT '--- Test 3.1: Đánh giá khi Order_id=9 đang "Chờ Lấy Hàng" (Expected: FAIL) ---'
PRINT 'Buyer: Bao Lam (19), Product: Khô Gà Lá Chanh'
BEGIN TRY
    BEGIN TRANSACTION;
    
    INSERT INTO Danh_gia (Product_id, Order_id, So_sao, Noi_dung_binh_luan)
    VALUES (9, 9, 5, N'Khô gà thơm ngon, nhìn hấp dẫn quá!');
    
    COMMIT TRANSACTION;
    PRINT 'RESULT: PASSED (But should FAIL) ✗ - BUG DETECTED!'
    PRINT ''
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'RESULT: FAILED as expected '
    PRINT 'Error: ' + ERROR_MESSAGE()
    PRINT ''
END CATCH