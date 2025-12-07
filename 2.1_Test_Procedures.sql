USE ShopeeDB;
GO
-- ============================================================
-- Các thủ tục cho các trường hợp
-- ============================================================
SET NOCOUNT ON;

-- ============================================================
-- THỦ TỤC INSERT
-- ============================================================

--1. Trường hợp bình thường
EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'Giày Nike Air Force 1',
    @Mo_ta_chi_tiet = N'Giày thể thao chính hãng, trẻ trung, mới nhất 2025',
    @Tinh_trang = 'New',
    @Trong_luong = 1.2;

--2. Trường hợp Store_id không tồn tại
EXEC Insert_Product
    @Store_id = 20,            
    @Ten_san_pham = N'Giày Nike Air Force 1',
    @Mo_ta_chi_tiet = N'Giày thể thao chính hãng, trẻ trung, mới nhất 2025',
    @Tinh_trang = 'New',
    @Trong_luong = 1.2;


--3. Trường hợp tên sản phẩm bị trống
EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'',
    @Mo_ta_chi_tiet = N'Giày thể thao chính hãng, trẻ trung, mới nhất 2025',
    @Tinh_trang = 'New',
    @Trong_luong = 1.2;

--4. Trường hợp mô tả chi tiết bị trống
EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'Giày Nike Air Force 1',
    @Mo_ta_chi_tiet = N'',
    @Tinh_trang = 'New',
    @Trong_luong = 1.2;

--5.1. Trường hợp trọng lượng bé hơn 0
EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'Giày Nike Air Force 1',
    @Mo_ta_chi_tiet = N'Giày thể thao chính hãng, trẻ trung, mới nhất 2025',
    @Tinh_trang = 'New',
    @Trong_luong = -11;

--5.2. Trường hợp trọng lượng bằng 0
EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'Giày Nike Air Force 1',
    @Mo_ta_chi_tiet = N'Giày thể thao chính hãng, trẻ trung, mới nhất 2025',
    @Tinh_trang = 'New',
    @Trong_luong = 0;

--6. Trường hợp tình trạng không đúng chuẩn
EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'Giày Nike Air Force 1',
    @Mo_ta_chi_tiet = N'Giày thể thao chính hãng, trẻ trung, mới nhất 2025',
    @Tinh_trang = 'SecondHand',
    @Trong_luong = 1.2;

--7. Trường hợp hai sản phẩm cùng cửa hàng bị trùng tên (tránh spam sản phẩm)(trùng tên nhưng đã bị xóa thì vẫn ok)
EXEC Insert_Product
    @Store_id = 3,            
    @Ten_san_pham = N'Sách - Cây Cam Ngọt Của Tôi',
    @Mo_ta_chi_tiet = N'Sách mới về hàng, mới cứng',
    @Tinh_trang = 'New',
    @Trong_luong = 0.4;


-- ============================================================
-- THỦ TỤC UPDATE
-- ============================================================

--1. Trường hợp bình thường
EXEC Update_Product
    @Product_id = 3,
    @Ten_san_pham = N'Sách - Cây Cam Ngọt Của Tôi',
    @Mo_ta_chi_tiet = N'Tiểu thuyết kinh điển về Zeze, MỚI NHẤT',
    @Tinh_trang = 'New',
    @Trong_luong = 0.4,
    @Trang_thai_dang = Active;

--2. Trường hợp Product_id không tồn tại
EXEC Update_Product
    @Product_id = 0,
    @Ten_san_pham = N'Sách - Cây Cam Ngọt Của Tôi',
    @Mo_ta_chi_tiet = N'Tiểu thuyết kinh điển về Zeze, MỚI NHẤT',
    @Tinh_trang = 'New',
    @Trong_luong = 0.4,
    @Trang_thai_dang = Active;

--3. Trường hợp tên sản phẩm bị để trống
EXEC Update_Product
    @Product_id = 3,
    @Ten_san_pham = N'',
    @Mo_ta_chi_tiet = N'Tiểu thuyết kinh điển về Zeze, MỚI NHẤT',
    @Tinh_trang = 'New',
    @Trong_luong = 0.4,
    @Trang_thai_dang = Active;

--4. Trường hợp mô tả sản phẩm bị để trống
EXEC Update_Product
    @Product_id = 3,
    @Ten_san_pham = N'Sách - Cây Cam Ngọt Của Tôi',
    @Mo_ta_chi_tiet = N'',
    @Tinh_trang = 'New',
    @Trong_luong = 0.4,
    @Trang_thai_dang = Active;

--5.1. Trường hợp trọng lượng bé hơn 0
EXEC Update_Product
    @Product_id = 3,
    @Ten_san_pham = N'Sách - Cây Cam Ngọt Của Tôi',
    @Mo_ta_chi_tiet = N'Tiểu thuyết kinh điển về Zeze, MỚI NHẤT',
    @Tinh_trang = 'New',
    @Trong_luong = -1,
    @Trang_thai_dang = Active;

--5.2. Trường hợp trọng lượng bằng 0
EXEC Update_Product
    @Product_id = 3,
    @Ten_san_pham = N'Sách - Cây Cam Ngọt Của Tôi',
    @Mo_ta_chi_tiet = N'Tiểu thuyết kinh điển về Zeze, MỚI NHẤT',
    @Tinh_trang = 'New',
    @Trong_luong = 0,
    @Trang_thai_dang = Active;

--6. Trường hợp tình trạng không đúng chuẩn
EXEC Update_Product
    @Product_id = 3,
    @Ten_san_pham = N'Sách - Cây Cam Ngọt Của Tôi',
    @Mo_ta_chi_tiet = N'Tiểu thuyết kinh điển về Zeze, MỚI NHẤT',
    @Tinh_trang = 'SecondHand',
    @Trong_luong = 0.4,
    @Trang_thai_dang = Active;

--7. Trường hợp sản phẩm chưa có ảnh và danh mục
DECLARE @Id_theo_ten INT;
IF EXISTS (SELECT Product_id FROM Product WHERE Ten_san_pham = N'Xe đạp 1 bánh')
BEGIN
    SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe đạp 1 bánh'
    EXEC Delete_Product
        @Product_id = @Id_theo_ten
END
EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'Xe đạp 1 bánh',
    @Mo_ta_chi_tiet = N'Xe đạp được xuất xứ Trung Quốc, được bảo hành 5 năm',
    @Tinh_trang = 'New',
    @Trong_luong = 2;

SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe đạp 1 bánh'
EXEC Update_Product
    @Product_id = @Id_theo_ten,
    @Ten_san_pham = N'Xe đạp 1 bánh',
    @Mo_ta_chi_tiet = N'Xe đạp được xuất xứ Trung Quốc, được bảo hành 5 năm',
    @Tinh_trang = 'New',
    @Trong_luong = 2,
    @Trang_thai_dang = Active;

--8. Trường hợp sửa tên bị trùng với sản phẩm đã tồn tại trong shop trước đó
DECLARE @Id_theo_ten INT;
SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe đạp 2 bánh'
IF EXISTS (SELECT Product_id FROM Product WHERE Ten_san_pham = N'Xe đạp 2 bánh')
BEGIN
    SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe đạp 2 bánh'
    EXEC Delete_Product
        @Product_id = @Id_theo_ten
END
SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe đạp 4 bánh'
IF EXISTS (SELECT Product_id FROM Product WHERE Ten_san_pham = N'Xe đạp 4 bánh')
BEGIN
    SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe đạp 4 bánh'
    EXEC Delete_Product
        @Product_id = @Id_theo_ten
END


EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'Xe đạp 2 bánh',
    @Mo_ta_chi_tiet = N'Xe đạp được xuất xứ Trung Quốc, được bảo hành 5 năm',
    @Tinh_trang = 'New',
    @Trong_luong = 2;

EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'Xe đạp 4 bánh',
    @Mo_ta_chi_tiet = N'Xe đạp được xuất xứ Trung Quốc, được bảo hành 5 năm',
    @Tinh_trang = 'New',
    @Trong_luong = 2;

DECLARE @Id_theo_ten INT;
SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe đạp 4 bánh'
EXEC Update_Product
    @Product_id = @Id_theo_ten,
    @Ten_san_pham = N'Xe đạp 2 bánh',
    @Mo_ta_chi_tiet = N'Xe đạp được xuất xứ Trung Quốc, được bảo hành 5 năm',
    @Tinh_trang = 'New',
    @Trong_luong = 2,
    @Trang_thai_dang = Hidden;
GO

--9. Trường hợp sản phẩm đã bị xóa

--CHỈNH ID ĐỂ TEST NHEN
    DECLARE @Id_theo_ten INT;
    SET @Id_theo_ten = 13;

    EXEC Delete_Product
    @Product_id = @Id_theo_ten;

    EXEC Update_Product
    @Product_id = @Id_theo_ten,
    @Ten_san_pham = N'Bánh tráng trộn đóng hộp (Đã sửa)',
    @Mo_ta_chi_tiet = N'Bánh tráng xuất xứ Trung Quốc, đảm bảo chất lượng',
    @Tinh_trang = 'New',
    @Trong_luong = 1,
    @Trang_thai_dang = Hidden;
GO
    


-- ============================================================
-- THỦ TỤC DELETE
-- ============================================================

--1. Trường hợp bình thường và không có lịch sử mua hàng
EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'Xe điện Testbla',
    @Mo_ta_chi_tiet = N'Xe đạp được xuất xứ Trung Quốc, được bảo hành 5 năm',
    @Tinh_trang = 'New',
    @Trong_luong = 5;

DECLARE @Id_theo_ten INT;
SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe điện Testbla'
IF EXISTS (SELECT Product_id FROM Product WHERE Ten_san_pham = N'Xe điện Testbla')
BEGIN
    SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe điện Testbla'
    EXEC Delete_Product
        @Product_id = @Id_theo_ten
END

--2. Trường hợp bình thường và đã có lịch sử mua hàng
EXEC Insert_Product
    @Store_id = 1,            
    @Ten_san_pham = N'Xe điện Testbla',
    @Mo_ta_chi_tiet = N'Xe đạp được xuất xứ Trung Quốc, được bảo hành 5 năm',
    @Tinh_trang = 'New',
    @Trong_luong = 5;

DECLARE @Id_theo_ten INT;
SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe điện Testbla' AND Trang_thai_dang <> 'Deleted'
INSERT INTO Variant (Product_id, SKU, Mau_sac, Kich_thuoc, Gia_ban, So_luong_ton_kho) VALUES
(@Id_theo_ten, 'TESTLA123', N'Xám Titan', '300x200', 33990000000, 50);
GO

INSERT INTO [Order] (Buyer_id, Trang_thai_don, Dia_chi_giao_hang) VALUES
(11, N'Đã Giao', N'12 Tôn Đản, Thủ Đức');

DECLARE @Id_theo_ten INT;
DECLARE @Order_id INT;
SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe điện Testbla' AND Trang_thai_dang <> 'Deleted'
SELECT @Order_id = Order_id FROM [Order] WHERE Dia_chi_giao_hang = N'12 Tôn Đản, Thủ Đức' ORDER BY Order_id ASC
INSERT INTO Order_item (Order_id, Item_id, Product_id, SKU, So_luong) VALUES
(@Order_id, 1, @Id_theo_ten, 'TESTLA123', 1);
GO

DECLARE @Id_theo_ten INT;
SELECT @Id_theo_ten = Product_id FROM Product WHERE Ten_san_pham = N'Xe điện Testbla' AND Trang_thai_dang <> 'Deleted'
IF EXISTS (SELECT Product_id FROM Product WHERE Ten_san_pham = N'Xe điện Testbla')
BEGIN
    EXEC Delete_Product
        @Product_id = @Id_theo_ten
END
GO

--3. Trường hợp sản phẩm không tồn tại
EXEC Delete_Product
        @Product_id = 0

--4. Trường hợp sản phẩm đã bị xóa

--CHỈNH ID ĐỂ TEST NHEN
    DECLARE @Id_theo_ten INT;
    SET @Id_theo_ten = 13;

    EXEC Delete_Product
    @Product_id = @Id_theo_ten;

    EXEC Delete_Product
    @Product_id = @Id_theo_ten;
GO

-- SELECT * FROM "Product"