USE ShopeeDB;
GO

-- =========================================================================================
-- HÀM 1: TÍNH DOANH THU RÒNG CỦA CỬA HÀNG TRONG THÁNG (CÓ TRỪ PHÍ SÀN THEO DANH MỤC)
-- Yêu cầu: Có tham số, Validate, Cursor, Loop, If, Select lồng
-- =========================================================================================
CREATE OR ALTER FUNCTION fn_Tinh_Doanh_Thu_Rong_Store (
    @Store_id INT,
    @Thang INT,
    @Nam INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    -- 1. Kiểm tra tham số đầu vào (Validate)
    IF NOT EXISTS (SELECT 1 FROM Store WHERE Store_id = @Store_id)
        RETURN 0; -- Trả về 0 nếu Store không tồn tại

    IF @Thang < 1 OR @Thang > 12 OR @Nam < 2000
        RETURN 0; -- Trả về 0 nếu thời gian không hợp lệ

    DECLARE @Tong_Doanh_Thu_Rong DECIMAL(18,2) = 0;
    
    -- Các biến dùng cho con trỏ
    DECLARE @Gia_Tri_Mon_Hang DECIMAL(18,2);
    DECLARE @Category_id INT;
    DECLARE @Phi_San DECIMAL(18,2);

    -- 2. Khai báo con trỏ (Cursor) để duyệt qua từng món hàng (Order_item) của Store đã bán thành công trong tháng
    DECLARE cursor_san_pham CURSOR FOR
    SELECT 
        (oi.Don_gia * oi.So_luong) AS Thanh_Tien,
        tv.Category_id
    FROM Order_item oi
    JOIN Product p ON oi.Product_id = p.Product_id
    JOIN Thuoc_ve tv ON p.Product_id = tv.Product_id
    JOIN [Order] o ON oi.Order_id = o.Order_id
    WHERE p.Store_id = @Store_id
      AND o.Trang_thai_don = N'Đã Giao' -- Chỉ tính đơn đã giao
      AND MONTH(o.Ngay_dat_hang) = @Thang
      AND YEAR(o.Ngay_dat_hang) = @Nam;

    OPEN cursor_san_pham;

    -- 3. Bắt đầu vòng lặp (LOOP)
    FETCH NEXT FROM cursor_san_pham INTO @Gia_Tri_Mon_Hang, @Category_id;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 4. Sử dụng câu lệnh IF để tính toán phí sàn dựa trên Category
        -- Giả sử: Điện tử (Category 1, 6) phí 5%, Thời trang (2, 7) phí 8%, Còn lại 10%
        IF @Category_id IN (1, 6) 
            SET @Phi_San = 0.05;
        ELSE IF @Category_id IN (2, 7)
            SET @Phi_San = 0.08;
        ELSE
            SET @Phi_San = 0.10;

        -- Cộng dồn vào tổng doanh thu sau khi trừ phí
        SET @Tong_Doanh_Thu_Rong = @Tong_Doanh_Thu_Rong + (@Gia_Tri_Mon_Hang * (1 - @Phi_San));

        FETCH NEXT FROM cursor_san_pham INTO @Gia_Tri_Mon_Hang, @Category_id;
    END

    CLOSE cursor_san_pham;
    DEALLOCATE cursor_san_pham;

    RETURN @Tong_Doanh_Thu_Rong;
END;
GO

-- =========================================================================================
-- HÀM 2: TÍNH ĐIỂM UY TÍN KHÁCH HÀNG (BUYER RANKING SCORE)
-- Yêu cầu: Có tham số, Validate, Cursor, Loop, If, Truy vấn kiểm tra bên trong
-- =========================================================================================
CREATE OR ALTER FUNCTION fn_Tinh_Diem_Uy_Tin_Buyer (
    @Buyer_id INT
)
RETURNS INT
AS
BEGIN
    -- 1. Kiểm tra tham số đầu vào
    IF NOT EXISTS (SELECT 1 FROM Buyer WHERE User_id = @Buyer_id)
        RETURN -1; -- Trả về -1 để báo lỗi nếu Buyer không tồn tại

    DECLARE @Diem_Uy_Tin INT = 100; -- Điểm khởi đầu
    
    -- Biến dùng cho con trỏ
    DECLARE @Order_id INT;
    DECLARE @Trang_thai_don NVARCHAR(50);
    DECLARE @Tong_tien DECIMAL(18,2);
    DECLARE @Co_Danh_Gia BIT;

    -- 2. Khai báo con trỏ duyệt qua tất cả đơn hàng của Buyer
    DECLARE cursor_don_hang CURSOR FOR
    SELECT Order_id, Trang_thai_don, Tong_tien
    FROM [Order]
    WHERE Buyer_id = @Buyer_id;

    OPEN cursor_don_hang;

    -- 3. Vòng lặp
    FETCH NEXT FROM cursor_don_hang INTO @Order_id, @Trang_thai_don, @Tong_tien;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 4. Sử dụng IF/ELSE để tính điểm dựa trên trạng thái đơn
        IF @Trang_thai_don = N'Đã Giao'
        BEGIN
            -- Cộng 10 điểm cho mỗi đơn thành công
            SET @Diem_Uy_Tin = @Diem_Uy_Tin + 10;

            -- Nếu đơn hàng giá trị cao (> 1 triệu), thưởng thêm 5 điểm
            IF @Tong_tien > 1000000
                SET @Diem_Uy_Tin = @Diem_Uy_Tin + 5;

            -- 5. Truy vấn dữ liệu (Select) bên trong Loop để kiểm tra xem đơn này đã đánh giá chưa
            IF EXISTS (SELECT 1 FROM Danh_gia WHERE Order_id = @Order_id)
            BEGIN
                -- Nếu chịu khó đánh giá sản phẩm, cộng thêm 2 điểm
                SET @Diem_Uy_Tin = @Diem_Uy_Tin + 2;
            END
        END
        ELSE IF @Trang_thai_don = N'Đã Hủy' OR @Trang_thai_don = N'Hoàn Trả'
        BEGIN
            -- Trừ 20 điểm nếu hủy đơn hoặc hoàn trả (giả định tính uy tín giảm)
            SET @Diem_Uy_Tin = @Diem_Uy_Tin - 20;
        END

        FETCH NEXT FROM cursor_don_hang INTO @Order_id, @Trang_thai_don, @Tong_tien;
    END

    CLOSE cursor_don_hang;
    DEALLOCATE cursor_don_hang;

    -- Đảm bảo điểm không âm
    IF @Diem_Uy_Tin < 0 SET @Diem_Uy_Tin = 0;

    RETURN @Diem_Uy_Tin;
END;
GO