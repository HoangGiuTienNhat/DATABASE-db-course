USE master;
GO
-- Xóa database cũ nếu tồn tại
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'ShopeeDB')
BEGIN
    ALTER DATABASE ShopeeDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ShopeeDB;
END
GO

CREATE DATABASE ShopeeDB;
GO

USE ShopeeDB;
GO

-- ============================================================
-- 1. BẢNG USER (Người dùng)
-- ============================================================
CREATE TABLE [User] (
    User_id INT IDENTITY(1,1) PRIMARY KEY,
    Ten_dang_nhap VARCHAR(50) NOT NULL UNIQUE,
    Mat_khau VARCHAR(255) NOT NULL, 
    Email VARCHAR(100) NOT NULL UNIQUE,
    SDT VARCHAR(15) NOT NULL UNIQUE,
    Ho NVARCHAR(50) NOT NULL,
    Ten NVARCHAR(50) NOT NULL,
    Ten_lot NVARCHAR(50),
    Trang_thai_tai_khoan VARCHAR(20) DEFAULT 'Active' CHECK (Trang_thai_tai_khoan IN ('Active', 'Inactive', 'Suspended')),
    CONSTRAINT CHK_Email_Format CHECK (Email LIKE '%_@__%.__%'),
    CHECK (SDT NOT LIKE '%[^0-9]%' AND LEN(SDT) >= 10)
);
GO

-- ============================================================
-- 2. BẢNG SELLER (Người bán)
-- ============================================================
CREATE TABLE Seller (
    User_id INT PRIMARY KEY,
    Seller_type VARCHAR(50) CHECK (Seller_type IN ('Individual', 'Business', 'Enterprise')), 
    CONSTRAINT FK_Seller_User FOREIGN KEY (User_id) REFERENCES [User](User_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 3. BẢNG BUYER (Người mua)
-- ============================================================
CREATE TABLE Buyer (
    User_id INT PRIMARY KEY,    
    CONSTRAINT FK_Buyer_User FOREIGN KEY (User_id) REFERENCES [User](User_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 4. BẢNG STORE (Gian hàng)
-- ============================================================
CREATE TABLE Store (
    Store_id INT IDENTITY(1,1) PRIMARY KEY,
    Seller_id INT NOT NULL,
    Ten_gian_hang NVARCHAR(100) NOT NULL,
    Mo_ta NVARCHAR(255),
    Ngay_tao DATETIME DEFAULT GETDATE(),
    Thong_tin_phap_ly NVARCHAR(MAX),
    CONSTRAINT FK_Store_Seller FOREIGN KEY (Seller_id) REFERENCES Seller(User_id) 
);
GO

-- ============================================================
-- 5. BẢNG CATEGORY (Danh mục)
-- ============================================================
CREATE TABLE Category (
    Category_id INT IDENTITY(1,1) PRIMARY KEY,
    Ten NVARCHAR(100) NOT NULL,
    Mo_ta NVARCHAR(255),
    Super_Category_id INT NULL,
    CONSTRAINT FK_Category_Super FOREIGN KEY (Super_Category_id) REFERENCES Category(Category_id)
);
GO

-- ============================================================
-- 6. BẢNG PRODUCT (Sản phẩm)
-- ============================================================
CREATE TABLE Product (
    Product_id INT IDENTITY(1,1) PRIMARY KEY,
    Store_id INT NOT NULL,
    Ten_san_pham NVARCHAR(200) NOT NULL,
    Mo_ta_chi_tiet NVARCHAR(MAX) NOT NULL, 
    Tinh_trang VARCHAR(20) CHECK (Tinh_trang IN ('New', 'Used', 'Refurbished')),
    Trong_luong DECIMAL(10,2) NOT NULL CHECK (Trong_luong > 0),
    Trang_thai_dang VARCHAR(20) DEFAULT 'Hidden' CHECK (Trang_thai_dang IN ('Active', 'Hidden', 'Deleted')),
    Ngay_dang DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Product_Store FOREIGN KEY (Store_id) REFERENCES Store(Store_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 7. BẢNG VARIANT (Phân loại sản phẩm)
-- ============================================================
CREATE TABLE Variant (
    Product_id INT NOT NULL,
    SKU NVARCHAR(100) NOT NULL,
    Mau_sac NVARCHAR(50) NOT NULL,
    Kich_thuoc NVARCHAR(50) NOT NULL,
    Gia_ban DECIMAL(18,2) NOT NULL CHECK (Gia_ban >= 0),
    So_luong_ton_kho INT DEFAULT 0 CHECK (So_luong_ton_kho >= 0),
    
    PRIMARY KEY (Product_id, SKU),
    CONSTRAINT FK_Variant_Product FOREIGN KEY (Product_id) REFERENCES Product(Product_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 8. BẢNG IMAGE (Hình ảnh sản phẩm)
-- ============================================================
CREATE TABLE [Image] (
    Product_id INT NOT NULL,
    Image_id INT NOT NULL,
    Duong_dan_anh NVARCHAR(500) NOT NULL,
    
    PRIMARY KEY (Product_id, Image_id),
    CONSTRAINT FK_Image_Product FOREIGN KEY (Product_id) REFERENCES Product(Product_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 9. BẢNG THUOC_VE (Quan hệ Product-Category)
-- ============================================================
CREATE TABLE Thuoc_ve (
    Category_id INT NOT NULL,
    Product_id INT NOT NULL,
    
    PRIMARY KEY (Category_id, Product_id),
    CONSTRAINT FK_Thuoc_ve_Category FOREIGN KEY (Category_id) REFERENCES Category(Category_id) ON DELETE CASCADE,
    CONSTRAINT FK_Thuoc_ve_Product FOREIGN KEY (Product_id) REFERENCES Product(Product_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 10. BẢNG ORDER (Đơn hàng)
-- ============================================================
CREATE TABLE [Order] (
    Order_id INT IDENTITY(1,1) PRIMARY KEY,
    Buyer_id INT NOT NULL,
    Trang_thai_don NVARCHAR(50) DEFAULT N'Chờ Xác Nhận' 
        CHECK (Trang_thai_don IN (N'Chờ Xác Nhận', N'Chờ Lấy Hàng', N'Đang Vận Chuyển', N'Đã Giao', N'Đã Hủy', N'Hoàn Trả')),
    Ngay_dat_hang DATETIME DEFAULT GETDATE(),
    Dia_chi_giao_hang NVARCHAR(255) NOT NULL,
    
    CONSTRAINT FK_Order_Buyer FOREIGN KEY (Buyer_id) REFERENCES Buyer(User_id)
);
GO

-- ============================================================
-- 11. BẢNG ORDER_ITEM (Chi tiết đơn hàng)
-- ============================================================
CREATE TABLE Order_item (
    Order_id INT NOT NULL,
    Item_id INT NOT NULL,
    Product_id INT NOT NULL,
    SKU NVARCHAR(100) NOT NULL, 
    So_luong INT NOT NULL CHECK (So_luong > 0),
    
    PRIMARY KEY (Order_id, Item_id),
    CONSTRAINT FK_Order_item_Order FOREIGN KEY (Order_id) REFERENCES [Order](Order_id) ON DELETE CASCADE,
    CONSTRAINT FK_Order_item_Variant FOREIGN KEY (Product_id, SKU) REFERENCES Variant(Product_id, SKU) ON UPDATE CASCADE
);
GO

-- ============================================================
-- 12. BẢNG COUPON (Mã giảm giá)
-- ============================================================
CREATE TABLE Coupon (
    Coupon_id INT IDENTITY(1,1) PRIMARY KEY, 
    Ti_le_giam DECIMAL(5,2) CHECK (Ti_le_giam >= 0 AND Ti_le_giam <= 100),
    Thoi_han DATETIME NOT NULL,
    Dieu_kien_gia_toi_thieu DECIMAL(18,2) DEFAULT 0 CHECK (Dieu_kien_gia_toi_thieu >= 0)
);
GO

-- ============================================================
-- 13. BẢNG AP_DUNG (Áp dụng coupon cho order_item)
-- ============================================================
CREATE TABLE Ap_dung (
    Order_id INT NOT NULL,
    Item_id INT NOT NULL,
    Coupon_id INT NOT NULL,
    
    PRIMARY KEY (Order_id, Item_id, Coupon_id),
    CONSTRAINT FK_Ap_dung_Order_item FOREIGN KEY (Order_id, Item_id) REFERENCES Order_item(Order_id, Item_id) ON DELETE CASCADE,
    CONSTRAINT FK_Ap_dung_Coupon FOREIGN KEY (Coupon_id) REFERENCES Coupon(Coupon_id) 
);
GO

-- ============================================================
-- 14. BẢNG PAYMENT (Thanh toán)
-- ============================================================
CREATE TABLE Payment (
    Payment_id INT IDENTITY(1,1) PRIMARY KEY,
    Order_id INT NOT NULL UNIQUE, -- Một order chỉ có một payment
    Trang_thai_thanh_toan NVARCHAR(50) DEFAULT N'Chờ Thanh Toán' 
        CHECK (Trang_thai_thanh_toan IN (N'Chờ Thanh Toán', N'Đã Thanh Toán', N'Thất Bại', N'Hoàn Tiền')),
    Phuong_thuc_thanh_toan NVARCHAR(100) 
        CHECK (Phuong_thuc_thanh_toan IN ('COD', 'Credit Card', 'Debit Card', 'ShopeePay', 'Bank Transfer', 'SPayLater')),
    Ma_giao_dich NVARCHAR(100) UNIQUE, -- Mã giao dịch duy nhất từ cổng thanh toán
    
    
    CONSTRAINT FK_Payment_Order FOREIGN KEY (Order_id) REFERENCES [Order](Order_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 15. BẢNG SHIPPER (Đơn vị vận chuyển)
-- ============================================================
CREATE TABLE Shipper (
    Shipper_id INT IDENTITY(1,1) PRIMARY KEY,
    Ten NVARCHAR(100) NOT NULL,
    Thong_tin_lien_he NVARCHAR(255)
);
GO

-- ============================================================
-- 16. BẢNG SHIPMENT (Vận chuyển)
-- ============================================================
CREATE TABLE Shipment (
    Shipment_id INT IDENTITY(1,1) PRIMARY KEY,
    Order_id INT NOT NULL UNIQUE, -- Một order chỉ có một shipment
    Shipper_id INT NOT NULL,
    Phuong_thuc_van_chuyen NVARCHAR(100),
    Ma_theo_doi NVARCHAR(100) UNIQUE,
    Ngay_gui DATETIME,
    Ngay_giao_du_kien DATETIME,
    Ngay_giao_thuc_te DATETIME NULL, 
    
    CONSTRAINT FK_Shipment_Order FOREIGN KEY (Order_id) REFERENCES [Order](Order_id) ON DELETE CASCADE,
    CONSTRAINT FK_Shipment_Shipper FOREIGN KEY (Shipper_id) REFERENCES Shipper(Shipper_id),
    CONSTRAINT CHK_Shipment_Dates CHECK (Ngay_giao_du_kien IS NULL OR Ngay_gui IS NULL OR Ngay_giao_du_kien > Ngay_gui),
    CONSTRAINT CHK_Shipment_Dates_real CHECK (Ngay_giao_thuc_te IS NULL OR Ngay_gui IS NULL OR Ngay_giao_thuc_te > Ngay_gui)
);
GO

-- ============================================================
-- 17. BẢNG TRO_CHUYEN (Cuộc trò chuyện giữa Seller và Buyer)
-- ============================================================
CREATE TABLE Tro_Chuyen (
    Seller_id INT NOT NULL,
    Buyer_id INT NOT NULL,
    
    PRIMARY KEY (Seller_id, Buyer_id),
    CONSTRAINT FK_Tro_Chuyen_Seller FOREIGN KEY (Seller_id) REFERENCES Seller(User_id),
    CONSTRAINT FK_Tro_Chuyen_Buyer FOREIGN KEY (Buyer_id) REFERENCES Buyer(User_id)
);
GO

-- ============================================================
-- 18. BẢNG CUOC_TRO_CHUYEN (Tin nhắn trong cuộc trò chuyện)
-- ============================================================
CREATE TABLE Cuoc_Tro_Chuyen (
    Seller_id INT NOT NULL,
    Buyer_id INT NOT NULL,
    Thoi_gian DATETIME NOT NULL DEFAULT GETDATE(),
    Noi_dung NVARCHAR(255) NOT NULL,
    
    PRIMARY KEY (Seller_id, Buyer_id, Thoi_gian, Noi_dung),
    CONSTRAINT FK_Cuoc_Tro_Chuyen_Tro_Chuyen FOREIGN KEY (Seller_id, Buyer_id) 
        REFERENCES Tro_Chuyen(Seller_id, Buyer_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 19. BẢNG ADDRESS_BUYER (Địa chỉ người mua)
-- ============================================================
CREATE TABLE Address_buyer (
    Buyer_id INT NOT NULL,
    Dia_chi NVARCHAR(255) NOT NULL,
    
    PRIMARY KEY (Buyer_id, Dia_chi),
    CONSTRAINT FK_Address_buyer_Buyer FOREIGN KEY (Buyer_id) REFERENCES Buyer(User_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 20. BẢNG ADDRESS_STORE (Địa chỉ gian hàng)
-- ============================================================
CREATE TABLE Address_store (
    Store_id INT NOT NULL,
    Dia_chi NVARCHAR(255) NOT NULL,
    
    PRIMARY KEY (Store_id, Dia_chi),
    CONSTRAINT FK_Address_store_Store FOREIGN KEY (Store_id) REFERENCES Store(Store_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 21. BẢNG DANH_GIA (Đánh giá sản phẩm)
-- ============================================================
CREATE TABLE Danh_gia (
    Product_id INT NOT NULL,
    Order_id INT NOT NULL,
    Ngay_danh_gia DATETIME DEFAULT GETDATE(),
    So_sao INT NOT NULL CHECK (So_sao >= 1 AND So_sao <= 5),
    Noi_dung_binh_luan NVARCHAR(MAX),
    Phan_hoi_cua_nguoi_ban NVARCHAR(MAX),
    
    PRIMARY KEY (Product_id, Order_id),
    CONSTRAINT FK_Danh_gia_Product FOREIGN KEY (Product_id) REFERENCES Product(Product_id),
    CONSTRAINT FK_Danh_gia_Order FOREIGN KEY (Order_id) REFERENCES [Order](Order_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- TRIGGERS - RÀNG BUỘC NGỮ NGHĨA
-- ============================================================

-- TRIGGER 1: Người mua không được mua sản phẩm từ cửa hàng của chính mình
DROP TRIGGER IF EXISTS trg_Prevent_Self_Purchase;
GO

-- TẠO TRIGGER MỚI TRÊN Order_item
CREATE TRIGGER trg_Prevent_Self_Purchase
ON Order_item
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN [Order] o ON i.Order_id = o.Order_id
        INNER JOIN Product p ON i.Product_id = p.Product_id
        INNER JOIN Store s ON p.Store_id = s.Store_id
        WHERE o.Buyer_id = s.Seller_id
    )
    BEGIN
        RAISERROR (N'The buyer is not allowed to purchase products from their own store.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO


-- TRIGGER 2: Sản phẩm chỉ được Active khi có ít nhất 1 ảnh và thuộc category
GO
CREATE TRIGGER trg_Product_Active_Validation
ON Product
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.Trang_thai_dang = 'Active'
        AND (
            -- Không có ảnh
            NOT EXISTS (SELECT 1 FROM [Image] WHERE Product_id = i.Product_id)
            -- Hoặc không thuộc category nào
            OR NOT EXISTS (SELECT 1 FROM Thuoc_ve WHERE Product_id = i.Product_id)
        )
    )
    BEGIN
        RAISERROR (N'Sản phẩm chỉ được Active khi có ít nhất 1 ảnh và thuộc category.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- TRIGGER 3: Buyer chỉ được đánh giá sau khi đơn hàng "Đã Giao"
GO
CREATE TRIGGER trg_Review_After_Delivery
ON Danh_gia
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN [Order] o ON i.Order_id = o.Order_id
        WHERE o.Trang_thai_don <> N'Đã Giao'
    )
    BEGIN
        RAISERROR (N'Người mua chỉ được đánh giá sau khi đơn hàng đã được giao thành công.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO






PRINT N'========================================';
PRINT N'Tạo cơ sở dữ liệu thành công!';
PRINT N'Tổng số bảng: 21';
PRINT N'Tổng số triggers: 6';
PRINT N'========================================';
GO

-- ============================================================
-- PHẦN 2: NHẬP DỮ LIỆU MẪU THỰC TẾ (REALISTIC DATA)
-- ============================================================
PRINT N'Đang bắt đầu nhập dữ liệu...'

-- 1. INSERT USER (20 User: 10 Chủ doanh nghiệp, 10 Khách hàng)
INSERT INTO [User] (Ten_dang_nhap, Mat_khau, Email, SDT, Ho, Ten, Ten_lot) VALUES
-- Sellers (Chủ shop)
('samsung_official', 'SS@123456', 'contact@samsung.vn', '0901234567', N'Nguyễn', N'Minh', N'Quang'),
('coolmate_vn', 'Cool@2024', 'ceo@coolmate.me', '0912345678', N'Phạm', N'Thành', N'Nhu'),
('fahasa_book', 'Book@Store', 'support@fahasa.com', '0987654321', N'Lê', N'Văn', N'Chương'),
('anker_vn', 'Anker#Tech', 'sales@anker.vn', '0909090901', N'Trần', N'Tuấn', N'Anh'),
('larocheposay', 'LRP@Skin', 'cskh@loreal.com', '0909090902', N'Võ', N'Thị', N'Sáu'),
('locknlock_vn', 'Lock#House', 'info@locknlock.vn', '0909090903', N'Hoàng', N'Gia', N'Bảo'),
('bitis_hunter', 'Hunter@Go', 'marketing@bitis.com.vn', '0909090904', N'Đặng', N'Lê', N'Nguyên'),
('hades_studio', 'Hades@Street', 'contact@hades.vn', '0909090905', N'Bùi', N'Tiến', N'Dũng'),
('food_hailua', 'Lua@Ngon', 'hailua@food.vn', '0909090906', N'Ngô', N'Bá', N'Khá'),
('homedecor_vip', 'Decor@Home', 'design@homedecor.com', '0909090907', N'Dương', N'Quá', N'Văn'),

-- Buyers (Người mua)
('thanh.nguyen99', 'Thanh@123', 'thanh.nguyen@gmail.com', '0908888881', N'Nguyễn', N'Thanh', N'Văn'),
('hoa.le2000', 'Hoa@Pink', 'hoale.cute@yahoo.com', '0908888882', N'Lê', N'Hoa', N'Thị'),
('minh_tuan_dev', 'Code@Hard', 'tuan.dev@outlook.com', '0908888883', N'Trần', N'Tuấn', N'Minh'),
('lan_ngoc_model', 'Showbiz@VN', 'ngoc.lan@gmail.com', '0908888884', N'Ninh', N'Ngọc', N'Lan'),
('hung_bds', 'Dat@Vang', 'hung.bds@gmail.com', '0908888885', N'Phạm', N'Hùng', N'Quốc'),
('mai_phuong', 'Mai@1234', 'phuong.mai@icloud.com', '0908888886', N'Đỗ', N'Phương', N'Mai'),
('duy_manh', 'Manh@Music', 'manh.duy@gmail.com', '0908888887', N'Nguyễn', N'Mạnh', N'Duy'),
('kieu_trinh', 'Trinh@Xinh', 'trinh.kieu@gmail.com', '0908888888', N'Lý', N'Trinh', N'Kiều'),
('bao_lam', 'Lam@Hai', 'lam.bao@gmail.com', '0908888889', N'Lê', N'Lâm', N'Bảo'),
('huong_tram', 'Tram@Sing', 'huong.tram@gmail.com', '0908888890', N'Phạm', N'Tràm', N'Hương');
GO

-- 2. INSERT SELLER 
INSERT INTO Seller (User_id, Seller_type) VALUES 
(1, 'Enterprise'), -- Samsung
(2, 'Business'),    -- Coolmate
(3, 'Enterprise'), -- Fahasa
(4, 'Business'),    -- Anker
(5, 'Enterprise'), -- La Roche-Posay
(6, 'Enterprise'), -- Lock&Lock
(7, 'Enterprise'), -- Bitis
(8, 'Business'),    -- Hades
(9, 'Individual'), -- Hai Lua
(10, 'Individual');-- Home Decor
GO

-- 3. INSERT BUYER
INSERT INTO Buyer (User_id) VALUES 
(11), (12), (13), (14), (15), (16), (17), (18), (19), (20);
GO

-- 4. INSERT STORE 

-- 4. INSERT STORE 
INSERT INTO Store (Seller_id, Ten_gian_hang, Mo_ta, Thong_tin_phap_ly) VALUES
(1, N'Samsung Official Store', N'Gian hàng chính hãng Samsung Việt Nam', N'GPKD số 0303030303 do Sở KHĐT TP.HCM cấp'),
(2, N'Coolmate Official', N'Giải pháp ăn mặc cơ bản cho nam giới', N'MST: 0123456789 - Công ty TNHH Fastech Asia'),
(3, N'Nhà Sách Fahasa', N'Hệ thống nhà sách chuyên nghiệp', NULL),
(4, N'Anker Flagship Store', N'Phụ kiện sạc cáp số 1 thế giới', NULL),
(5, N'La Roche-Posay Chính Hãng', N'Dược mỹ phẩm chăm sóc da', NULL),
(6, N'Lock&Lock Mall', N'Gia dụng thông minh Hàn Quốc', NULL),
(7, N'Biti''s Hunter', N'Nâng niu bàn chân Việt', NULL),
(8, N'HADES STUDIO', N'Streetwear Local Brand', NULL),
(9, N'Đặc Sản Hai Lúa', N'Khô gà, khô bò, cơm cháy', NULL),
(10, N'Decor Xinh', N'Trang trí nhà cửa phong cách Bắc Âu', NULL);
GO

-- 5. INSERT ADDRESS_STORE 
INSERT INTO Address_store (Store_id, Dia_chi) VALUES
(1, N'Bitexco Financial Tower, Q1, TP.HCM'),
(2, N'Tầng 3, 193 Nguyễn Tuân, Thanh Xuân, Hà Nội'),
(3, N'60-62 Lê Lợi, Q1, TP.HCM'),
(4, N'215 Nam Kỳ Khởi Nghĩa, Q3, TP.HCM'),
(5, N'Lotte Center, Liễu Giai, Hà Nội'),
(6, N'Aeon Mall Long Biên, Hà Nội'),
(7, N'22 Lý Chiêu Hoàng, Q6, TP.HCM'),
(8, N'45 Hai Bà Trưng, Q1, TP.HCM'),
(9, N'Chợ Cái Răng, Cần Thơ'),
(10, N'12 Đường 3/2, Q10, TP.HCM');
GO

-- 6. INSERT ADDRESS_BUYER 
INSERT INTO Address_buyer (Buyer_id, Dia_chi) VALUES
(11, N'12 Tôn Đản, Q4, TP.HCM'),
(12, N'Căn hộ S2.05 Vinhomes Grand Park, Q9'),
(13, N'Ngõ 68 Cầu Giấy, Hà Nội'),
(14, N'Biệt thự Thảo Điền, Q2, TP.HCM'),
(15, N'Tòa nhà Landmark 81, Bình Thạnh'),
(16, N'Ký túc xá ĐHQG, Thủ Đức'),
(17, N'Số 5 Đường Láng, Hà Nội'),
(18, N'Chung cư Hoàng Anh Gia Lai, Đà Nẵng'),
(19, N'Đường Trần Phú, Nha Trang'),
(20, N'Số 1 Đại Lộ Hòa Bình, Cần Thơ');
GO

-- 7. INSERT CATEGORY 
INSERT INTO Category (Ten, Mo_ta, Super_Category_id) VALUES
(N'Thiết Bị Điện Tử', N'Electronic Devices', NULL),         -- 1
(N'Thời Trang Nam', N'Men Fashion', NULL),                  -- 2
(N'Nhà Sách Online', N'Books', NULL),                        -- 3
(N'Sắc Đẹp', N'Beauty & Personal Care', NULL),               -- 4
(N'Nhà Cửa & Đời Sống', N'Home & Living', NULL),             -- 5
(N'Điện Thoại & Phụ Kiện', N'Phones & Accessories', 1),      -- 6
(N'Áo Thun', N'T-Shirts', 2),                                -- 7
(N'Sách Văn Học', N'Literature', 3),                         -- 8
(N'Chăm Sóc Da', N'Skincare', 4),                            -- 9
(N'Dụng Cụ Nhà Bếp', N'Kitchenware', 5);                     -- 10
GO

-- 8. INSERT SHIPPER
INSERT INTO Shipper (Ten, Thong_tin_lien_he) VALUES
(N'SPX Express', N'https://spx.vn'),
(N'Giao Hàng Nhanh', N'1900 636677'),
(N'Giao Hàng Tiết Kiệm', N'1800 6092'),
(N'Viettel Post', N'1900 8095'),
(N'J&T Express', N'1900 1088'),
(N'Ninja Van', N'1900 886877'),
(N'GrabExpress', N'Book qua app'),
(N'AhaMove', N'1900 545411');
GO

-- 9. INSERT COUPON 
INSERT INTO Coupon (Ti_le_giam, Thoi_han, Dieu_kien_gia_toi_thieu) VALUES
(15.00, DATEADD(day, 30, GETDATE()), 150000), -- Giảm 15% đơn từ 150k
(50.00, DATEADD(day, 1, GETDATE()), 0),       -- Flash Sale 50%
(8.00, DATEADD(month, 3, GETDATE()), 500000), -- Giảm 8% đơn to
(10.00, DATEADD(day, 7, GETDATE()), 0),       -- Mã Freeship Xtra (quy ra %)
(20.00, DATEADD(day, 30, GETDATE()), 200000), -- Mã shop mới
(5.00, DATEADD(day, 60, GETDATE()), 0),
(12.00, DATEADD(day, 15, GETDATE()), 300000),
(25.00, DATEADD(day, 5, GETDATE()), 1000000); -- Mã Luxury
GO

-- 10. INSERT PRODUCT
INSERT INTO Product (Store_id, Ten_san_pham, Mo_ta_chi_tiet, Tinh_trang, Trong_luong, Trang_thai_dang) VALUES
(1, N'Điện thoại Samsung Galaxy S24 Ultra 5G', N'AI Phone, Camera 200MP, Titan Frame', 'New', 0.5, 'Hidden'),      
(2, N'Áo Polo Nam Coolmate Excool', N'Công nghệ thoáng khí, khử mùi', 'New', 0.2, 'Hidden'),          
(3, N'Sách - Cây Cam Ngọt Của Tôi', N'Tiểu thuyết kinh điển về Zeze', 'New', 0.4, 'Hidden'),     
(4, N'Cáp Sạc Nhanh Anker PowerLine III Flow', N'Siêu bền, mềm mại, sạc nhanh 20W', 'New', 0.1, 'Hidden'),
(5, N'Kem Dưỡng La Roche-Posay Cicaplast Baume B5+', N'Phục hồi da, làm dịu kích ứng', 'New', 0.1, 'Hidden'),
(6, N'Nồi Chiên Không Dầu Lock&Lock 5.2L', N'Công nghệ Rapid Air, Giỏ chiên chống dính', 'New', 5.0, 'Hidden'),      
(7, N'Giày Thể Thao Biti''s Hunter X', N'Đế LiteFlex, quai kháng khuẩn', 'New', 1.0, 'Hidden'),     
(8, N'Áo Thun HADES Wolf Gang', N'Cotton 2 chiều, in lụa cao cấp', 'New', 0.3, 'Hidden'),    
(9, N'Khô Gà Lá Chanh 500g', N'Thơm ngon giòn rụm, đạt chuẩn VSATTP', 'New', 0.6, 'Hidden'),       
(10, N'Gương Đứng Toàn Thân', N'Khung gỗ sồi, kích thước 1m6 x 50cm', 'New', 8.0, 'Hidden');     
GO

-- 11. INSERT IMAGE (ĐÃ CẬP NHẬT LINK ẢNH PLACEHOLDER)
INSERT INTO [Image] (Product_id, Image_id, Duong_dan_anh) VALUES
(1, 1, N'./Ảnh Minh Họa/SSG_S24_Ultra.jpg'), 
(2, 1, N'./Ảnh Minh Họa/Ao_Polo_Nam.jfif'), 
(3, 1, N'./Ảnh Minh Họa/Cay_Cam_Ngot.jpg'),
(4, 1, N'./Ảnh Minh Họa/Cap_Sac_Anker.jpg'), 
(5, 1, N'./Ảnh Minh Họa/Kem_Duong_La_Roche.png'), 
(6, 1, N'./Ảnh Minh Họa/Noi_Chien_Khong_Dau.jpg'),
(7, 1, N'./Ảnh Minh Họa/Giay_Bitis_HunterX.jfif'), 
(8, 1, N'./Ảnh Minh Họa/Ao_Thun_Hades.jfif'), 
(9, 1, N'./Ảnh Minh Họa/Kho_Ga_La_Chanh_500G.jfif'), 
(10, 1, N'./Ảnh Minh Họa/Guong_Dung_Toan_Than.jpg');
GO

-- 12. INSERT THUOC_VE (Mapping)
INSERT INTO Thuoc_ve (Category_id, Product_id) VALUES
(6, 1), -- S24 Ultra -> Điện thoại
(7, 2), -- Polo -> Áo thun
(8, 3), -- Sách -> Văn học
(6, 4), -- Cáp -> Phụ kiện điện thoại
(9, 5), -- Kem dưỡng -> Chăm sóc da
(10, 6), -- Nồi chiên -> Bếp
(2, 7), -- Giày -> Thời trang nam
(7, 8), -- Áo Hades -> Áo thun
(5, 9), -- Khô gà -> Nhà cửa (Tạm)
(5, 10); -- Gương -> Nhà cửa
GO

-- 13. UPDATE PRODUCT -> ACTIVE
UPDATE Product SET Trang_thai_dang = 'Active';
GO

-- 14. INSERT VARIANT 
INSERT INTO Variant (Product_id, SKU, Mau_sac, Kich_thuoc, Gia_ban, So_luong_ton_kho) VALUES
(1, 'S24U-TITAN-512', N'Xám Titan', '512GB', 33990000, 50),
(2, 'POLO-EX-XANH-L', N'Xanh Navy', 'L', 299000, 100),
(3, 'SACH-BIA-MEM', N'Bìa Mềm', 'Standard', 108000, 200),
(4, 'ANKER-USBC-1M', N'Hồng Pastel', '1m', 250000, 50),
(5, 'B5-100ML', N'Trắng', '100ml', 385000, 80),
(6, 'LOCK-EJF-DEN', N'Đen Bóng', '5.2L', 2500000, 30),
(7, 'HUNTERX-42', N'Đen Cam', '42', 999000, 40),
(8, 'HADES-WOLF-XL', N'Wash Xám', 'XL', 450000, 60),
(9, 'KHOGA-500G', N'Cay Vừa', 'Hũ 500g', 110000, 500),
(10, 'GUONG-GO-SOI', N'Màu Gỗ', '1m6x50', 650000, 10);
GO

-- 15. INSERT ORDER (12 Đơn hàng - 8 Đã giao, 4 trạng thái khác)
INSERT INTO [Order] (Buyer_id, Trang_thai_don, Dia_chi_giao_hang) VALUES
(11, N'Đã Giao', N'12 Tôn Đản, Q4'),         -- Mua Samsung
(12, N'Đã Giao', N'S2.05 Vin Grand Park'),  -- Mua Coolmate
(13, N'Đã Giao', N'68 Cầu Giấy'),           -- Mua Sách
(14, N'Đã Giao', N'Thảo Điền Q2'),          -- Mua Anker
(15, N'Đã Giao', N'Landmark 81'),           -- Mua B5
(16, N'Đã Giao', N'KTX Khu A'),             -- Mua Nồi chiên
(17, N'Đã Giao', N'5 Láng Hạ'),             -- Mua Bitis
(18, N'Đã Giao', N'HAGL Đà Nẵng'),          -- Mua Hades
(19, N'Chờ Lấy Hàng', N'Trần Phú Nha Trang'), -- Mua Khô gà
(20, N'Đang Vận Chuyển', N'Ninh Kiều Cần Thơ'), -- Mua Gương
(11, N'Đã Hủy', N'12 Tôn Đản, Q4'),          -- Đổi ý
(12, N'Chờ Xác Nhận', N'S2.05 Vin Grand Park');
GO

-- 16. INSERT ORDER_ITEM
INSERT INTO Order_item (Order_id, Item_id, Product_id, SKU, So_luong) VALUES
(1, 1, 1, 'S24U-TITAN-512', 1),
(2, 1, 2, 'POLO-EX-XANH-L', 2),
(3, 1, 3, 'SACH-BIA-MEM', 1),
(4, 1, 4, 'ANKER-USBC-1M', 1),
(5, 1, 5, 'B5-100ML', 2),
(6, 1, 6, 'LOCK-EJF-DEN', 1),
(7, 1, 7, 'HUNTERX-42', 1),
(8, 1, 8, 'HADES-WOLF-XL', 1),
(9, 1, 9, 'KHOGA-500G', 5),
(10, 1, 10, 'GUONG-GO-SOI', 1),
(11, 1, 1, 'S24U-TITAN-512', 1),
(12, 1, 2, 'POLO-EX-XANH-L', 3);
GO

-- 17. INSERT AP_DUNG
INSERT INTO Ap_dung (Order_id, Item_id, Coupon_id) VALUES
(1, 1, 8), (2, 1, 1), (3, 1, 4), (4, 1, 4),
(5, 1, 1), (6, 1, 3), (7, 1, 1), (8, 1, 7),
(9, 1, 6), (10, 1, 3), (11, 1, 8), (12, 1, 5);
GO

-- 18. INSERT PAYMENT
INSERT INTO Payment (Order_id, Trang_thai_thanh_toan, Phuong_thuc_thanh_toan, Ma_giao_dich) VALUES
(1, N'Đã Thanh Toán', 'ShopeePay', 'SPP112233'),
(2, N'Đã Thanh Toán', 'COD', 'COD110305'),
(3, N'Đã Thanh Toán', 'SPayLater', 'SPL998877'),
(4, N'Đã Thanh Toán', 'Credit Card', 'VISA4455'),
(5, N'Đã Thanh Toán', 'Bank Transfer', 'VCB0011'),
(6, N'Đã Thanh Toán', 'COD', 'COD221006'),
(7, N'Đã Thanh Toán', 'ShopeePay', 'SPP556677'),
(8, N'Đã Thanh Toán', 'COD', 'COD221025'),
(9, N'Chờ Thanh Toán', 'Bank Transfer', 'MB113522106'),
(10, N'Đã Thanh Toán', 'ShopeePay', 'SPP9999'),
(11, N'Hoàn Tiền', 'Credit Card', 'VCBDEBIT001'),
(12, N'Thất Bại', 'Credit Card', 'VISA1122');
GO

-- 19. INSERT SHIPMENT (Logic: Đã Giao phải có ngày thực tế)
INSERT INTO Shipment (Order_id, Shipper_id, Phuong_thuc_van_chuyen, Ma_theo_doi, Ngay_gui, Ngay_giao_du_kien, Ngay_giao_thuc_te) VALUES
(1, 1, N'Hỏa Tốc', 'SPX01', DATEADD(d,-2,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(2, 2, N'Nhanh', 'GHN02', DATEADD(d,-3,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(3, 3, N'Tiết Kiệm', 'GHTK03', DATEADD(d,-4,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(4, 1, N'Nhanh', 'SPX04', DATEADD(d,-3,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(5, 4, N'Nhanh', 'VTP05', DATEADD(d,-2,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(6, 6, N'Hàng Cồng Kềnh', 'NJV06', DATEADD(d,-5,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(7, 2, N'Nhanh', 'GHN07', DATEADD(d,-3,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(8, 5, N'Nhanh', 'JT08', DATEADD(d,-4,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(9, 3, N'Nhanh', 'GHTK09', NULL, NULL, NULL), -- Chờ lấy
(10, 6, N'Hàng Cồng Kềnh', 'NJV10', GETDATE(), DATEADD(d,3,GETDATE()), NULL), -- Đang giao
(11, 1, N'Nhanh', 'SPX11', DATEADD(d,-5,GETDATE()), NULL, NULL), -- Hủy
(12, 2, N'Nhanh', NULL, NULL, NULL, NULL); -- Chờ xác nhận
GO

-- 20. INSERT TRO_CHUYEN
INSERT INTO Tro_Chuyen (Seller_id, Buyer_id) VALUES
(1, 11), (2, 12), (3, 13), (4, 14), (5, 15), (6, 16), (7, 17), (8, 18);
GO

-- 21. INSERT CUOC_TRO_CHUYEN 
INSERT INTO Cuoc_Tro_Chuyen (Seller_id, Buyer_id, Noi_dung) VALUES
(1, 11, N'Shop ơi S24 Ultra bản Titan có sẵn không ạ?'),
(1, 11, N'Dạ bên em sẵn hàng ạ, anh đặt hỏa tốc em giao liền.'),
(2, 12, N'Áo này 1m7 65kg mặc size gì vừa?'),
(2, 12, N'Dạ size L là chuẩn form ạ.'),
(3, 13, N'Sách có bọc plastic không shop?'),
(4, 14, N'Dây này sạc được iPhone 15 không?'),
(6, 16, N'Nồi này điện 220V hay 110V vậy?'),
(8, 18, N'Áo wash xám có bị ra màu khi giặt không?');
GO

-- 22. INSERT DANH_GIA 
INSERT INTO Danh_gia (Product_id, Order_id, So_sao, Noi_dung_binh_luan, Phan_hoi_cua_nguoi_ban) VALUES
(1, 1, 5, N'Máy đẹp xuất sắc, giao hỏa tốc 30p là có. 10 điểm cho Samsung!', N'Cảm ơn quý khách đã tin dùng sản phẩm Samsung.'),
(2, 2, 4, N'Vải mát, nhẹ, nhưng form hơi rộng so với mình.', N'Dạ Coolmate hỗ trợ đổi size miễn phí trong 60 ngày ạ.'),
(3, 3, 5, N'Sách mới cứng, đóng gói 3 lớp xốp nổ. Fahasa uy tín.', NULL),
(4, 4, 5, N'Dây mềm sờ rất thích, sạc nhanh cho 15prm ok.', NULL),
(5, 5, 5, N'Dùng B5 phục hồi da sau nặn mụn siêu đỉnh, hàng auth.', N'La Roche-Posay cảm ơn bạn nhiều ạ <3'),
(6, 6, 3, N'Nồi hơi ồn, nhưng chiên gà ngon. Giao hàng hơi lâu.', N'Dạ do đợt sale đơn quá tải mong bạn thông cảm ạ.'),
(7, 7, 5, N'Giày êm, nhẹ, đi chạy bộ rất sướng. Ủng hộ hàng Việt.', NULL),
(8, 8, 4, N'Áo đẹp, hình in sắc nét, nhưng vải hơi dày mặc mùa hè hơi nóng.', NULL);
GO

-----INSERT THÊM DỮ LIỆU
-- Thêm sản phẩm mới cho Store 1 (Samsung) - Trạng thái Active ngay từ đầu
INSERT INTO Product (Store_id, Ten_san_pham, Mo_ta_chi_tiet, Tinh_trang, Trong_luong, Trang_thai_dang) VALUES
(1, N'Samsung Galaxy Buds2 Pro', N'Tai nghe không dây, chống ồn chủ động ANC', 'New', 0.05, 'Active'),
(1, N'Samsung Galaxy Watch 6', N'Đồng hồ thông minh, theo dõi sức khỏe 24/7', 'New', 0.3, 'Active'),
(1, N'Samsung Smart TV 55 inch QLED', N'Tivi QLED 4K, Quantum HDR', 'New', 15.0, 'Active');
GO

-- Thêm sản phẩm mới cho Store 2 (Coolmate) - Trạng thái Active ngay từ đầu
INSERT INTO Product (Store_id, Ten_san_pham, Mo_ta_chi_tiet, Tinh_trang, Trong_luong, Trang_thai_dang) VALUES
(2, N'Quần Short Nam Excool', N'Quần short thể thao, vải thoáng mát', 'New', 0.2, 'Active'),
(2, N'Áo Sơ Mi Nam Basic', N'Áo sơ mi oxford, form regular fit', 'New', 0.25, 'Active'),
(2, N'Áo Khoác Gió Nam', N'Áo khoác chống nước, nhẹ, gọn', 'New', 0.4, 'Active');
GO

-- Thêm sản phẩm mới cho Store 3 (Fahasa) - Trạng thái Active ngay từ đầu
INSERT INTO Product (Store_id, Ten_san_pham, Mo_ta_chi_tiet, Tinh_trang, Trong_luong, Trang_thai_dang) VALUES
(3, N'Sách - Đắc Nhân Tâm', N'Dale Carnegie - Nghệ thuật giao tiếp', 'New', 0.35, 'Active'),
(3, N'Sách - Nhà Giả Kim', N'Paulo Coelho - Tiểu thuyết triết lý', 'New', 0.3, 'Active'),
(3, N'Sách - Tôi Thấy Hoa Vàng Trên Cỏ Xanh', N'Nguyễn Nhật Ánh - Văn học Việt Nam', 'New', 0.35, 'Active');
GO

-- Thêm hình ảnh cho các sản phẩm mới (Product_id từ 11-19) - ĐÃ CẬP NHẬT LINK ẢNH
INSERT INTO [Image] (Product_id, Image_id, Duong_dan_anh) VALUES
-- Samsung (Product 11, 12, 13)
(11, 1, N'./Ảnh Minh Họa/Buds2_Purple.jfif'),
(11, 2, N'./Ảnh Minh Họa/Buds2_White.jfif'),
(12, 1, N'./Ảnh Minh Họa/Watch6_Graphite.jfif'),
(12, 2, N'./Ảnh Minh Họa/Watch6_Silver.jfif'),
(13, 1, N'./Ảnh Minh Họa/TV_QLED_Front.jfif'),
(13, 2, N'./Ảnh Minh Họa/TV_QLED_Side.jfif'),

-- Coolmate (Product 14, 15, 16)
(14, 1, N'./Ảnh Minh Họa/Short_Excool_Black.jfif'),
(14, 2, N'./Ảnh Minh Họa/Short_Excool_Navy.jfif'),
(15, 1, N'./Ảnh Minh Họa/Shirt_Basic_White.jfif'),
(15, 2, N'./Ảnh Minh Họa/Shirt_Basic_Blue.jfif'),
(16, 1, N'./Ảnh Minh Họa/Jacket_Wind_Black.jfif'),
(16, 2, N'./Ảnh Minh Họa/Jacket_Wind_Navy.jfif'),

-- Fahasa (Product 17, 18, 19)
(17, 1, N'./Ảnh Minh Họa/Dac_Nhan_Tam.jfif'),
(18, 1, N'./Ảnh Minh Họa/Nha_Gia_Kim.jfif'),
(19, 1, N'./Ảnh Minh Họa/Toi_Thay_Hoa_Vang_Co_Xanh.jfif');
GO

-- Thêm mapping Category cho sản phẩm mới
INSERT INTO Thuoc_ve (Category_id, Product_id) VALUES
-- Samsung (Category 6: Điện thoại & Phụ kiện, Category 1: Thiết bị điện tử)
(6, 11),  -- Buds
(6, 12),  -- Watch
(1, 13),  -- TV

-- Coolmate (Category 2: Thời trang nam, Category 7: Áo thun)
(2, 14),  -- Short
(7, 15),  -- Sơ mi
(2, 16),  -- Áo khoác

-- Fahasa (Category 8: Sách văn học)
(8, 17),
(8, 18),
(8, 19);
GO

-- Thêm Variant cho sản phẩm mới
INSERT INTO Variant (Product_id, SKU, Mau_sac, Kich_thuoc, Gia_ban, So_luong_ton_kho) VALUES
-- Buds2 Pro (Product 11)
(11, 'BUDS2PRO-PURPLE', N'Tím', 'Standard', 4990000, 30),
(11, 'BUDS2PRO-WHITE', N'Trắng', 'Standard', 4990000, 25),

-- Watch 6 (Product 12)
(12, 'WATCH6-44MM-GRAPH', N'Graphite', '44mm', 7990000, 20),
(12, 'WATCH6-44MM-SILV', N'Bạc', '44mm', 7990000, 15),

-- TV 55 inch (Product 13)
(13, 'TV55-QLED-2024', N'Đen', '55 inch', 18990000, 10),

-- Short Excool (Product 14)
(14, 'SHORT-EX-BLK-M', N'Đen', 'M', 199000, 50),
(14, 'SHORT-EX-BLK-L', N'Đen', 'L', 199000, 60),
(14, 'SHORT-EX-NAV-M', N'Navy', 'M', 199000, 45),
(14, 'SHORT-EX-NAV-L', N'Navy', 'L', 199000, 55),

-- Sơ mi (Product 15)
(15, 'SHIRT-WHT-M', N'Trắng', 'M', 399000, 40),
(15, 'SHIRT-WHT-L', N'Trắng', 'L', 399000, 45),
(15, 'SHIRT-BLU-M', N'Xanh', 'M', 399000, 35),

-- Áo khoác (Product 16)
(16, 'JACKET-BLK-L', N'Đen', 'L', 599000, 30),
(16, 'JACKET-NAV-L', N'Navy', 'L', 599000, 25),

-- Sách (Product 17, 18, 19)
(17, 'BOOK-DNT-BM', N'Bìa Mềm', 'Standard', 86000, 150),
(17, 'BOOK-DNT-BC', N'Bìa Cứng', 'Standard', 156000, 50),
(18, 'BOOK-NGK-BM', N'Bìa Mềm', 'Standard', 79000, 200),
(19, 'BOOK-HV-BM', N'Bìa Mềm', 'Standard', 95000, 180);
GO

-- Thêm đơn hàng cho sản phẩm mới (đã giao để có thể đánh giá)
INSERT INTO [Order] (Buyer_id, Trang_thai_don, Dia_chi_giao_hang) VALUES
(13, N'Đã Giao', N'Ngõ 68 Cầu Giấy'),            -- Mua Buds2 Pro
(14, N'Đã Giao', N'Biệt thự Thảo Điền, Q2'),   -- Mua Watch 6
(15, N'Đã Giao', N'Landmark 81'),                -- Mua TV
(16, N'Đã Giao', N'KTX ĐHQG, Thủ Đức'),        -- Mua Short
(17, N'Đã Giao', N'Số 5 Láng Hạ'),              -- Mua Sơ mi
(18, N'Đã Giao', N'Chung cư HAGL, Đà Nẵng'),   -- Mua Áo khoác
(19, N'Đã Giao', N'Đường Trần Phú, Nha Trang'), -- Mua Đắc Nhân Tâm
(20, N'Đã Giao', N'Đại Lộ Hòa Bình, Cần Thơ');  -- Mua Nhà Giả Kim
GO

-- Thêm Order_item cho đơn hàng mới
INSERT INTO Order_item (Order_id, Item_id, Product_id, SKU, So_luong) VALUES
(13, 1, 11, 'BUDS2PRO-PURPLE', 1),
(14, 1, 12, 'WATCH6-44MM-GRAPH', 1),
(15, 1, 13, 'TV55-QLED-2024', 1),
(16, 1, 14, 'SHORT-EX-BLK-L', 2),
(17, 1, 15, 'SHIRT-WHT-L', 1),
(18, 1, 16, 'JACKET-BLK-L', 1),
(19, 1, 17, 'BOOK-DNT-BM', 1),
(20, 1, 18, 'BOOK-NGK-BM', 1);
GO

-- Thêm Payment cho đơn hàng mới
INSERT INTO Payment (Order_id, Trang_thai_thanh_toan, Phuong_thuc_thanh_toan, Ma_giao_dich) VALUES
(13, N'Đã Thanh Toán', 'ShopeePay', 'SPP220001'),
(14, N'Đã Thanh Toán', 'Credit Card', 'VISA220002'),
(15, N'Đã Thanh Toán', 'Bank Transfer', 'VCB220003'),
(16, N'Đã Thanh Toán', 'COD', 'COD220004'),
(17, N'Đã Thanh Toán', 'ShopeePay', 'SPP220005'),
(18, N'Đã Thanh Toán', 'COD', 'COD220006'),
(19, N'Đã Thanh Toán', 'SPayLater', 'SPL220007'),
(20, N'Đã Thanh Toán', 'Bank Transfer', 'ACB220008');
GO

-- Thêm Shipment cho đơn hàng mới
INSERT INTO Shipment (Order_id, Shipper_id, Phuong_thuc_van_chuyen, Ma_theo_doi, Ngay_gui, Ngay_giao_du_kien, Ngay_giao_thuc_te) VALUES
(13, 1, N'Hỏa Tốc', 'SPX013', DATEADD(d,-3,GETDATE()), DATEADD(d,-1,GETDATE()), DATEADD(d,-1,GETDATE())),
(14, 2, N'Nhanh', 'GHN014', DATEADD(d,-4,GETDATE()), DATEADD(d,-1,GETDATE()), DATEADD(d,-1,GETDATE())),
(15, 6, N'Hàng Cồng Kềnh', 'NJV015', DATEADD(d,-5,GETDATE()), DATEADD(d,-2,GETDATE()), DATEADD(d,-2,GETDATE())),
(16, 3, N'Nhanh', 'GHTK016', DATEADD(d,-3,GETDATE()), DATEADD(d,-1,GETDATE()), DATEADD(d,-1,GETDATE())),
(17, 2, N'Nhanh', 'GHN017', DATEADD(d,-4,GETDATE()), DATEADD(d,-1,GETDATE()), DATEADD(d,-1,GETDATE())),
(18, 5, N'Nhanh', 'JT018', DATEADD(d,-3,GETDATE()), DATEADD(d,-1,GETDATE()), DATEADD(d,-1,GETDATE())),
(19, 3, N'Tiết Kiệm', 'GHTK019', DATEADD(d,-5,GETDATE()), DATEADD(d,-2,GETDATE()), DATEADD(d,-2,GETDATE())),
(20, 4, N'Nhanh', 'VTP020', DATEADD(d,-4,GETDATE()), DATEADD(d,-1,GETDATE()), DATEADD(d,-1,GETDATE()));
GO

-- Thêm áp dụng coupon cho đơn hàng mới
INSERT INTO Ap_dung (Order_id, Item_id, Coupon_id) VALUES
(13, 1, 1),  -- Giảm 15%
(14, 1, 3),  -- Giảm 8%
(15, 1, 8),  -- Giảm 25% (Luxury)
(16, 1, 4),  -- Giảm 10%
(17, 1, 1),  -- Giảm 15%
(18, 1, 5),  -- Giảm 20%
(19, 1, 6),  -- Giảm 5%
(20, 1, 6);  -- Giảm 5%
GO

-- Thêm đánh giá cho sản phẩm mới
INSERT INTO Danh_gia (Product_id, Order_id, So_sao, Noi_dung_binh_luan, Phan_hoi_cua_nguoi_ban) VALUES
(11, 13, 5, N'Tai nghe chống ồn tuyệt vời, pin trâu, âm thanh trong trẻo. Đáng tiền!', N'Cảm ơn bạn đã tin dùng sản phẩm Samsung.'),
(12, 14, 5, N'Đồng hồ đẹp, màn hình sắc nét, theo dõi sức khỏe chính xác. Rất hài lòng.', N'Samsung rất vui khi bạn hài lòng với sản phẩm!'),
(13, 15, 4, N'Tivi đẹp, màu sắc sống động, nhưng giá hơi cao. Giao hàng cẩn thận.', N'Cảm ơn bạn. Samsung luôn cam kết chất lượng cao cấp.'),
(14, 16, 5, N'Quần vừa vặn, vải mát lạnh, mặc tập gym rất thoải mái. Sẽ mua thêm!', N'Coolmate cảm ơn bạn. Chúc bạn tập luyện hiệu quả!'),
(15, 17, 5, N'Áo sơ mi đẹp, vải mềm, form chuẩn. Mặc đi làm sang trọng.', N'Cảm ơn bạn đã lựa chọn Coolmate!'),
(16, 18, 4, N'Áo khoác nhẹ, chống nước tốt, nhưng hơi ôm. Size L hơi nhỏ.', N'Dạ Coolmate sẽ cải thiện size chart. Cảm ơn góp ý!'),
(17, 19, 5, N'Sách hay, in đẹp, giấy tốt. Nội dung rất bổ ích cho công việc.', NULL),
(18, 20, 5, N'Nhà Giả Kim luôn là cuốn sách yêu thích. Fahasa giao nhanh, đóng gói cẩn thận.', NULL);
GO

PRINT N'========================================';
PRINT N'========================================';
PRINT N'Hoàn thành tạo dữ liệu mẫu';
PRINT N'========================================';
PRINT N'========================================';
GO



PRINT N'--- BẮT ĐẦU QUÁ TRÌNH THÊM DỮ LIỆU MỚI ---';

-- ============================================================
-- 1. THÊM SẢN PHẨM (PRODUCT) - ID TỪ 20 TRỞ ĐI
-- ============================================================

-- STORE 1: SAMSUNG (6 Sản phẩm mới: ID 20 -> 25)
INSERT INTO Product (Store_id, Ten_san_pham, Mo_ta_chi_tiet, Tinh_trang, Trong_luong, Trang_thai_dang) VALUES
(1, N'Samsung Galaxy S23 FE 5G', N'Camera chuẩn Flagship, Hiệu năng mạnh mẽ với Exynos 2200, Pin 4500mAh', 'New', 0.2, 'Active'), -- ID 20
(1, N'Loa Thanh Samsung HW-Q990C', N'Âm thanh vòm chuẩn 11.1.4 kênh, Q-Symphony, SpaceFit Sound Pro', 'New', 7.5, 'Active'), -- ID 21
(1, N'Samsung Galaxy A55 5G', N'Khung viền kim loại, Camera chụp đêm sắc nét, Khánh nước IP67', 'New', 0.2, 'Active'), -- ID 22
(1, N'Màn hình Thông Minh Samsung M8', N'Không cần PC, tích hợp Office 365 và Netflix, Camera SlimFit quay 4K', 'New', 4.0, 'Active'), -- ID 23
(1, N'Tủ Chăm Sóc Quần Áo AirDresser', N'Hấp sấy chuẩn spa, khử khuẩn, giữ nếp quần áo, sấy khô nhẹ nhàng', 'New', 80.0, 'Active'), -- ID 24
(1, N'Máy Hút Bụi Cầm Tay Jet 75', N'Lực hút 200W, Hệ thống lọc đa lớp 99.999%, Pin rời linh hoạt', 'New', 2.5, 'Active'); -- ID 25
GO

-- STORE 2: COOLMATE (6 Sản phẩm mới: ID 26 -> 31)
INSERT INTO Product (Store_id, Ten_san_pham, Mo_ta_chi_tiet, Tinh_trang, Trong_luong, Trang_thai_dang) VALUES
(2, N'Áo Polo Thể Thao ProMax-S1', N'Vải Poly thể thao, thấm hút mồ hôi cực nhanh, công nghệ Chafe-Free', 'New', 0.2, 'Active'), -- ID 26
(2, N'Quần Jogger Kaki Excool', N'Co giãn 4 chiều, dáng Slimfit, mặc đi làm đi chơi đều đẹp', 'New', 0.4, 'Active'), -- ID 27
(2, N'Áo Hoodie Nỉ Bông Essential', N'Giữ ấm tốt, form rộng thoải mái, không xù lông sau khi giặt', 'New', 0.5, 'Active'), -- ID 28
(2, N'Combo 3 Quần Lót Boxer Modal', N'Gỗ sồi thiên nhiên, mềm mại gấp 2 lần Cotton, đai lưng êm ái', 'New', 0.15, 'Active'), -- ID 29
(2, N'Áo Ba Lỗ Thể Thao Training', N'Thoáng nách, vải nhẹ, chuyên dụng tập Gym và chạy bộ', 'New', 0.1, 'Active'), -- ID 30
(2, N'Tất Cổ Cao Bamboo Khử Mùi', N'Công nghệ Nano bạc, chống hôi chân tuyệt đối, cổ chun co giãn', 'New', 0.05, 'Active'); -- ID 31
GO

-- ============================================================
-- 2. THÊM HÌNH ẢNH (IMAGE)
-- ============================================================
INSERT INTO [Image] (Product_id, Image_id, Duong_dan_anh) VALUES
-- Samsung
(20, 1, N'./Ảnh Minh Họa/s23_fe_green.jfif'),
(21, 1, N'./Ảnh Minh Họa/soundbar_q990c.jfif'),
(22, 1, N'./Ảnh Minh Họa/a55_navy.jfif'),
(23, 1, N'./Ảnh Minh Họa/monitor_m8_white.jfif'),
(24, 1, N'./Ảnh Minh Họa/airdresser.jfif'),
(25, 1, N'./Ảnh Minh Họa/jet75_vacuum.jfif'),
-- Coolmate
(26, 1, N'./Ảnh Minh Họa/polo_promax_blue.jfif'),
(27, 1, N'./Ảnh Minh Họa/jogger_kaki_black.jfif'),
(28, 1, N'./Ảnh Minh Họa/hoodie_grey.jfif'),
(29, 1, N'./Ảnh Minh Họa/boxer_modal_set3.jfif'),
(30, 1, N'./Ảnh Minh Họa/tanktop_gym_red.jfif'),
(31, 1, N'./Ảnh Minh Họa/socks_bamboo_high.jfif');
GO

-- ============================================================
-- 3. THÊM CATEGORY MAPPING (THUOC_VE)
-- ============================================================
INSERT INTO Thuoc_ve (Category_id, Product_id) VALUES
-- Samsung
(6, 20), (6, 22), -- Điện thoại
(1, 21), (1, 23), -- Điện tử (Loa, Màn hình)
(5, 24), (5, 25), -- Nhà cửa (Tủ, Máy hút bụi)
-- Coolmate
(7, 26), (7, 30), -- Áo thun/Ba lỗ
(2, 27), (2, 28), -- Thời trang nam (Quần, Hoodie)
(2, 29), (2, 31); -- Đồ lót/Tất
GO

-- ============================================================
-- 4. THÊM BIẾN THỂ (VARIANT) - SKU
-- ============================================================
INSERT INTO Variant (Product_id, SKU, Mau_sac, Kich_thuoc, Gia_ban, So_luong_ton_kho) VALUES
-- Samsung
(20, 'S23FE-8-128-GRN', N'Xanh Mint', '128GB', 12990000, 40),
(21, 'HW-Q990C-BLK', N'Đen', 'Standard', 21900000, 10),
(22, 'A55-5G-NAVY', N'Tím Navy', '256GB', 9690000, 50),
(23, 'M8-32INCH-WHT', N'Trắng', '32 inch', 14500000, 15),
(24, 'AIRDRESSER-DF60', N'Mặt Gương', 'Standard', 29900000, 5),
(25, 'JET75-PREMIUM', N'Bạc', '200W', 8500000, 20),
-- Coolmate
(26, 'POLO-PRO-BLU-L', N'Xanh Biển', 'L', 249000, 80),
(27, 'JOGGER-KAKI-XL', N'Đen', 'XL', 399000, 60),
(28, 'HOODIE-GREY-M', N'Xám', 'M', 499000, 45),
(29, 'BOXER-MODAL-L', N'Đa Sắc', 'L', 299000, 120),
(30, 'TANK-GYM-RED-L', N'Đỏ', 'L', 159000, 70),
(31, 'SOCKS-HIGH-BLK', N'Đen', 'Freesize', 49000, 300);
GO

-- ============================================================
-- 5. TẠO ĐƠN HÀNG MỚI (ORDER) - BẮT BUỘC TỪ 21
-- ============================================================

-- QUAN TRỌNG: Lệnh này đặt lại bộ đếm ID về 20, để đơn hàng tiếp theo CHẮC CHẮN là 21.
DBCC CHECKIDENT ('[Order]', RESEED, 20);
GO

-- Tạo 12 Đơn hàng (Sẽ có ID từ 21 -> 32)
INSERT INTO [Order] (Buyer_id, Trang_thai_don, Dia_chi_giao_hang) VALUES
(13, N'Đã Giao', N'68 Cầu Giấy, HN'),         -- Order 21 (Mua S23 FE)
(15, N'Đã Giao', N'Landmark 81, HCM'),        -- Order 22 (Mua Loa Q990C)
(16, N'Đã Giao', N'KTX Khu A, Thủ Đức'),      -- Order 23 (Mua A55)
(18, N'Đã Giao', N'HAGL Đà Nẵng'),            -- Order 24 (Mua Hoodie)
(19, N'Đã Giao', N'Nha Trang'),               -- Order 25 (Mua Boxer)
(20, N'Đã Giao', N'Cần Thơ'),                 -- Order 26 (Mua Jogger)
(13, N'Đã Giao', N'68 Cầu Giấy, HN'),         -- Order 27 (Mua Máy hút bụi)
(14, N'Đã Giao', N'Thảo Điền, Q2'),           -- Order 28 (Mua Polo)
(11, N'Đã Giao', N'12 Tôn Đản, Q4'),          -- Order 29 (Mua Màn hình M8)
(12, N'Hoàn Trả', N'S2.05 Vin Grand Park'),    -- Order 30 (Mua Tất)
(17, N'Đã Giao', N'5 Láng Hạ, HN'),           -- Order 31 (Mua Ba lỗ)
(15, N'Đã Giao', N'Landmark 81, HCM');        -- Order 32 (Mua Tủ AirDresser)
GO

-- ============================================================
-- 6. TẠO CHI TIẾT ĐƠN (ORDER_ITEM)
-- ============================================================
-- Mapping thủ công chính xác ID 21-32 với Product 20-31
INSERT INTO Order_item (Order_id, Item_id, Product_id, SKU, So_luong) VALUES
(21, 1, 20, 'S23FE-8-128-GRN', 1),  -- Đơn 21 mua S23 FE
(22, 1, 21, 'HW-Q990C-BLK', 1),     -- Đơn 22 mua Loa
(23, 1, 22, 'A55-5G-NAVY', 1),      -- Đơn 23 mua A55
(24, 1, 28, 'HOODIE-GREY-M', 1),    -- Đơn 24 mua Hoodie
(25, 1, 29, 'BOXER-MODAL-L', 2),    -- Đơn 25 mua 2 Boxer
(26, 1, 27, 'JOGGER-KAKI-XL', 1),   -- Đơn 26 mua Jogger
(27, 1, 25, 'JET75-PREMIUM', 1),    -- Đơn 27 mua Máy hút bụi
(28, 1, 26, 'POLO-PRO-BLU-L', 2),   -- Đơn 28 mua 2 Polo
(29, 1, 23, 'M8-32INCH-WHT', 1),    -- Đơn 29 mua Màn hình
(30, 1, 31, 'SOCKS-HIGH-BLK', 5),   -- Đơn 30 mua 5 đôi tất
(31, 1, 30, 'TANK-GYM-RED-L', 1),   -- Đơn 31 mua Ba lỗ
(32, 1, 24, 'AIRDRESSER-DF60', 1);  -- Đơn 32 mua Tủ chăm sóc áo
GO

-- ============================================================
-- 7. THANH TOÁN (PAYMENT)
-- ============================================================
INSERT INTO Payment (Order_id, Trang_thai_thanh_toan, Phuong_thuc_thanh_toan, Ma_giao_dich) VALUES
(21, N'Đã Thanh Toán', 'ShopeePay', 'TX21'),
(22, N'Đã Thanh Toán', 'Credit Card', 'TX22'),
(23, N'Đã Thanh Toán', 'COD', 'TX23'),
(24, N'Đã Thanh Toán', 'SPayLater', 'TX24'),
(25, N'Đã Thanh Toán', 'COD', 'TX25'),
(26, N'Đã Thanh Toán', 'Bank Transfer', 'TX26'),
(27, N'Đã Thanh Toán', 'Credit Card', 'TX27'),
(28, N'Đã Thanh Toán', 'ShopeePay', 'TX28'),
(29, N'Đã Thanh Toán', 'Bank Transfer', 'TX29'),
(30, N'Đã Thanh Toán', 'COD', 'TX30'),
(31, N'Đã Thanh Toán', 'ShopeePay', 'TX31'),
(32, N'Đã Thanh Toán', 'Credit Card', 'TX32');
GO

-- ============================================================
-- 8. VẬN CHUYỂN (SHIPMENT)
-- ============================================================
INSERT INTO Shipment (Order_id, Shipper_id, Phuong_thuc_van_chuyen, Ma_theo_doi, Ngay_gui, Ngay_giao_du_kien, Ngay_giao_thuc_te) VALUES
(21, 1, N'Nhanh', 'SPX-21', DATEADD(d,-3,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(22, 6, N'Hàng Cồng Kềnh', 'NJV-22', DATEADD(d,-4,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()), -- Loa to
(23, 2, N'Nhanh', 'GHN-23', DATEADD(d,-2,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(24, 3, N'Tiết Kiệm', 'GHTK-24', DATEADD(d,-5,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(25, 1, N'Nhanh', 'SPX-25', DATEADD(d,-3,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(26, 2, N'Nhanh', 'GHN-26', DATEADD(d,-3,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(27, 4, N'Nhanh', 'VTP-27', DATEADD(d,-4,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(28, 4, N'Nhanh', 'VTP-28', DATEADD(d,-2,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(29, 6, N'Hàng Cồng Kềnh', 'NJV-29', DATEADD(d,-3,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()), -- Màn hình to
(30, 3, N'Tiết Kiệm', 'GHTK-30', DATEADD(d,-4,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(31, 1, N'Nhanh', 'SPX-31', DATEADD(d,-2,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()),
(32, 6, N'Hàng Cồng Kềnh', 'NJV-32', DATEADD(d,-5,GETDATE()), DATEADD(d,-1,GETDATE()), GETDATE()); -- Tủ rất to
GO

-- ============================================================
-- 9. ÁP DỤNG COUPON
-- ============================================================
INSERT INTO Ap_dung (Order_id, Item_id, Coupon_id) VALUES
(21, 1, 8), (22, 1, 8), (23, 1, 1), (24, 1, 5), 
(25, 1, 4), (26, 1, 5), (27, 1, 1), (28, 1, 6),
(29, 1, 8), (30, 1, 4), (31, 1, 6), (32, 1, 8);
GO

-- ============================================================
-- 10. ĐÁNH GIÁ (REVIEW)
-- ============================================================
INSERT INTO Danh_gia (Product_id, Order_id, So_sao, Noi_dung_binh_luan, Phan_hoi_cua_nguoi_ban) VALUES
(20, 21, 5, N'S23 FE màu mint siêu đẹp, chụp ảnh nét căng.', N'Cảm ơn quý khách đã tin dùng Samsung.'),
(21, 22, 5, N'Loa nghe nhạc xem phim như rạp, bass chắc nịch.', NULL),
(22, 23, 5, N'A55 thiết kế đẹp, pin trâu dùng cả ngày chưa hết.', NULL),
(28, 24, 4, N'Hoodie ấm, nỉ dày dặn, nhưng giao hàng hơi chậm.', N'Shop xin lỗi vì sự chậm trễ của bên vận chuyển ạ.'),
(29, 25, 5, N'Boxer Modal mặc như không mặc, rất thích.', NULL),
(27, 26, 5, N'Quần kaki co giãn tốt, mặc đi làm rất lịch sự.', NULL),
(25, 27, 5, N'Máy hút mạnh, nhẹ tay, hút sạch bụi mịn trên sofa.', N'Samsung cảm ơn đánh giá của bạn.'),
(26, 28, 5, N'Áo thể thao thoáng mát, mồ hôi khô nhanh.', NULL),
(23, 29, 5, N'Màn hình thông minh quá tiện, không cần PC vẫn làm việc được.', NULL),

(30, 31, 4, N'Ba lỗ vải nhẹ, nhưng màu đỏ hơi tươi quá.', NULL),
(24, 32, 5, N'Tủ xịn, quần áo thơm phức phẳng phiu, đáng tiền.', N'Cảm ơn quý khách đã lựa chọn sản phẩm cao cấp của Samsung.');
GO

PRINT N'--- HOÀN TẤT! ĐÃ THÊM 12 SP MỚI VÀ 12 ĐƠN HÀNG (ID 21-32) ---';
GO