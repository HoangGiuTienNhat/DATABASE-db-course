--=====================================================================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
--=====================================================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--=====================================================================================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--=====================================================================================================


--thủ tục thêm hàng mới
CREATE OR ALTER PROCEDURE Insert_Product 
	-- Add the parameters for the stored procedure here
	@Store_id INT,
	@Ten_san_pham NVARCHAR(200),
	@Mo_ta_chi_tiet NVARCHAR(MAX),
	@Tinh_trang VARCHAR(20),
	@Trong_luong DECIMAL(10,2)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET @Ten_san_pham = LTRIM(RTRIM(@Ten_san_pham));
    SET @Mo_ta_chi_tiet = LTRIM(RTRIM(@Mo_ta_chi_tiet));

	--1. kiểm tra store_id trong có tồn tại ko
	IF NOT EXISTS (SELECT Store_id FROM Store WHERE Store_id = @Store_id)
	BEGIN
		--Raiserror('thông báo', độ nghiêm trọng, trạng thái)
		RAISERROR(N'Lỗi: Gian hàng chưa tồn tại, vui lòng kiểm tra lại', 16, 1);
		RETURN;
	END

	--2. kiểm tra tên sản phẩm không được trống
	IF @Ten_san_pham IS NULL OR @Ten_san_pham = ''
	BEGIN
		RAISERROR(N'Lỗi: Tên sản phẩm không được để trống', 16, 1);
		RETURN;
	END

	--3. kiểm tra mô tả sản phẩm không được để trống
	IF @Mo_ta_chi_tiet IS NULL OR @Mo_ta_chi_tiet = ''
	BEGIN
		RAISERROR(N'Lỗi: Mô tả không được để trống', 16, 1);
		RETURN;
	END

	--4. kiểm tra trọng lượng
	IF @Trong_luong IS NULL OR @Trong_luong <= 0
	BEGIN
		RAISERROR(N'Lỗi: Trọng lượng không được để trống hoặc bé hơn 0', 16, 1);
		RETURN;
	END

	--5. kiểm tra tình trạng
	IF @Tinh_trang NOT IN ('New', 'Used', 'Refurbished')
	BEGIN
		RAISERROR(N'Lỗi: Tình trạng phải thuộc "New", "Used" hoặc "Refurbished" ', 16, 1);
		RETURN;
	END

	--6. kiểm tra có tồn tại sản phầm có tồn tại trước đó không
	IF EXISTS (
        SELECT Product_id 
        FROM Product  
        WHERE Store_id = @Store_id 
          AND Ten_san_pham = @Ten_san_pham
          AND Trang_thai_dang <> 'Deleted' --trạng thái phải khác 'Deleted'
    )
    BEGIN
        RAISERROR(N'Lỗi: Tên sản phẩm này đã tồn tại trong cửa hàng của bạn, vui lòng dùng tên khác hoặc cập nhật sản phẩm cũ.', 16, 1);
        RETURN;
    END
   
	--thêm hàng mới
	INSERT INTO Product (Store_id, Ten_san_pham, Mo_ta_chi_tiet, Tinh_trang, Trong_luong, Trang_thai_dang)
    VALUES (@Store_id, @Ten_san_pham, @Mo_ta_chi_tiet, @Tinh_trang, @Trong_luong, 'Hidden');
	
	PRINT N'Thông báo: Thêm sản phẩm thành công! ID sản phẩm mới là: ' + CAST(SCOPE_IDENTITY() AS NVARCHAR(10));
END;
GO

--=====================================================================================================

--thủ tục cập nhật hàng mới
CREATE OR ALTER PROCEDURE Update_Product
    @Product_id INT,
    @Ten_san_pham NVARCHAR(200),
    @Mo_ta_chi_tiet NVARCHAR(MAX),
    @Tinh_trang VARCHAR(20),
    @Trong_luong DECIMAL(10,2),
    @Trang_thai_dang VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
	
	--lưu tạm store_id dùng để xét trường hợp trùng
	DECLARE @CurrentStoreId INT;
    SELECT @CurrentStoreId = Store_id FROM Product WHERE Product_id = @Product_id;
	SET @Ten_san_pham = LTRIM(RTRIM(@Ten_san_pham));
    SET @Mo_ta_chi_tiet = LTRIM(RTRIM(@Mo_ta_chi_tiet));

	--1. kiểm tra sản phẩm có tồn tại hay không
	IF NOT EXISTS (SELECT Product_id FROM Product WHERE Product_id = @Product_id)
	BEGIN
		RAISERROR(N'Lỗi: Không tìm thấy sản phẩm với ID này.', 16, 1);
        RETURN;
    END

	--2. kiểm tra tên sản phầm không được trống
	IF @Ten_san_pham IS NULL OR @Ten_san_pham = ''
	BEGIN
		RAISERROR(N'Lỗi: Tên sản phẩm không được để trống', 16, 1);
		RETURN;
	END

	--3. kiểm tra mô tả sản phẩm không được để trống
	IF @Mo_ta_chi_tiet IS NULL OR @Mo_ta_chi_tiet = ''
	BEGIN
		RAISERROR(N'Lỗi: Mô tả không được để trống', 16, 1);
		RETURN;
	END

	--4. kiểm tra trọng lượng
	IF @Trong_luong IS NULL OR @Trong_luong <= 0
	BEGIN
		RAISERROR(N'Lỗi: Trọng lượng không được để trống hoặc bé hơn 0', 16, 1);
		RETURN;
	END

	--5. kiểm tra tình trạng
	IF @Tinh_trang NOT IN ('New', 'Used', 'Refurbished')
	BEGIN
		RAISERROR(N'Lỗi: Tình trạng phải thuộc "New", "Used" hoặc "Refurbished" ', 16, 1);
		RETURN;
	END

	--6. kiểm tra logic Active
	IF @Trang_thai_dang = 'Active'
	BEGIN
        --kiểm tra ảnh 
        IF NOT EXISTS (SELECT Image_id FROM [Image] WHERE Product_id = @Product_id)
        BEGIN
            RAISERROR(N'Lỗi: Không thể Active sản phẩm vì chưa có hình ảnh nào.', 16, 1);
            RETURN;
        END
        --kiểm tra danh mục
        IF NOT EXISTS (SELECT Product_id FROM Thuoc_ve WHERE Product_id = @Product_id)
        BEGIN
            RAISERROR(N'Lỗi: Không thể Active sản phẩm vì chưa thuộc danh mục nào.', 16, 1);
            RETURN;
        END
    END

	--7. kiểm tra có bị trùng với sản phẩm khác hay không
	IF EXISTS (
        SELECT 1 
        FROM Product 
        WHERE Store_id = @CurrentStoreId      --tìm trong cùng shop
          AND Ten_san_pham = @Ten_san_pham
          AND Product_id <> @Product_id       --loại trừ chính nó
          AND Trang_thai_dang <> 'Deleted'
    )
    BEGIN
        RAISERROR(N'Lỗi: Tên sản phẩm này đang bị trùng với một sản phẩm khác trong cửa hàng.', 16, 1);
        RETURN;
    END

	--8. kiểm tra sản phẩm có bị xóa hay chưa
	DECLARE @IsDeleted VARCHAR(20);
    SELECT @IsDeleted = Trang_thai_dang  FROM Product WHERE Product_id = @Product_id;
	IF @IsDeleted = 'Deleted'
	BEGIN
        RAISERROR(N'Lỗi: Sản phẩm đã bị xóa rồi.', 16, 1);
        RETURN;
    END


	--tiến hành cập nhật
	UPDATE Product
    SET Ten_san_pham = @Ten_san_pham,
        Mo_ta_chi_tiet = @Mo_ta_chi_tiet,
        Tinh_trang = @Tinh_trang,
        Trong_luong = @Trong_luong,
        Trang_thai_dang = @Trang_thai_dang
    WHERE Product_id = @Product_id;

    PRINT N'Thông báo: Cập nhật sản phẩm thành công!';
END;
GO

--=====================================================================================================

--thủ tục xóa hàng
CREATE OR ALTER PROCEDURE Delete_Product
    @Product_id INT
AS
BEGIN
    SET NOCOUNT ON;

    --1. kiểm tra sản phẩm có tồn tại không
    IF NOT EXISTS (SELECT Product_id FROM Product WHERE Product_id = @Product_id)
    BEGIN
        RAISERROR(N'Lỗi: Sản phẩm muốn xóa không tồn tại.', 16, 1);
        RETURN;
    END

	--2. kiểm tra sản phẩm có bị xóa hay chưa
	DECLARE @IsDeleted VARCHAR(20);
    SELECT @IsDeleted = Trang_thai_dang  FROM Product WHERE Product_id = @Product_id;
	IF @IsDeleted = 'Deleted'
	BEGIN
        RAISERROR(N'Lỗi: Sản phẩm đã bị xóa trước đó.', 16, 1);
        RETURN;
    END

    -- kiểm tra product này có được mua hay chưa
    IF EXISTS (
        SELECT oi.Product_id 
        FROM Order_item oi JOIN Variant v 
		ON oi.Product_id = v.Product_id AND oi.SKU = v.SKU
        WHERE v.Product_id = @Product_id
    )
    BEGIN
        --có lịch sử không xóa
        PRINT N'Thông báo: Sản phẩm đã từng phát sinh đơn hàng, chuyển trạng thái thành "Deleted"';
        
        UPDATE Product 
        SET Trang_thai_dang = 'Deleted' 
        WHERE Product_id = @Product_id;
    END
    ELSE
    BEGIN
        --không có lịch sử nên xóa được
        --chỉ cần xóa bảng này do có Cadecase
        DELETE FROM Product WHERE Product_id = @Product_id;
        
        PRINT N'Thông báo: Sản phẩm chưa phát sinh giao dịch, đã xóa vĩnh viễn khỏi hệ thống';
    END
END;
GO