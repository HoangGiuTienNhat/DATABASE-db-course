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
    Mo_ta_chi_tiet NVARCHAR(MAX), 
    Tinh_trang VARCHAR(20) CHECK (Tinh_trang IN ('New', 'Used', 'Refurbished')),
    Trong_luong DECIMAL(10,2) CHECK (Trong_luong > 0),
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
    CONSTRAINT FK_Order_item_Variant FOREIGN KEY (Product_id, SKU) REFERENCES Variant(Product_id, SKU)
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
    CONSTRAINT FK_Ap_dung_Coupon FOREIGN KEY (Coupon_id) REFERENCES Coupon(Coupon_id) ON DELETE CASCADE
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
GO
CREATE TRIGGER trg_Prevent_Self_Purchase
ON [Order]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Order_item oi ON i.Order_id = oi.Order_id
        INNER JOIN Product p ON oi.Product_id = p.Product_id
        INNER JOIN Store s ON p.Store_id = s.Store_id
        WHERE i.Buyer_id = s.Seller_id
    )
    BEGIN
        RAISERROR (N'Người mua không được phép đặt mua sản phẩm từ cửa hàng của chính mình.', 16, 1);
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

-- TRIGGER 4: Kiểm tra tồn kho trước khi tạo order_item
GO
CREATE TRIGGER trg_Check_Stock_Before_Order
ON Order_item
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Variant v ON i.Product_id = v.Product_id AND i.SKU = v.SKU
        WHERE v.So_luong_ton_kho < i.So_luong
    )
    BEGIN
        RAISERROR (N'Số lượng sản phẩm trong kho không đủ để đáp ứng đơn hàng.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- TRIGGER 5: Coupon phải còn hạn sử dụng
GO
CREATE TRIGGER trg_Coupon_Valid
ON Ap_dung
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Coupon c ON i.Coupon_id = c.Coupon_id
        WHERE c.Thoi_han < GETDATE()
    )
    BEGIN
        RAISERROR (N'Mã giảm giá đã hết hạn sử dụng.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- TRIGGER 6: Tự động cập nhật ngày giao thực tế khi shipment "Đã Giao"
GO
CREATE TRIGGER trg_Update_Delivery_Date
ON [Order]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE s
    SET Ngay_giao_thuc_te = GETDATE()
    FROM Shipment s
    INNER JOIN inserted i ON s.Order_id = i.Order_id
    WHERE i.Trang_thai_don = N'Đã Giao'
    AND s.Ngay_giao_thuc_te IS NULL;
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
(2, 'Business'),   -- Coolmate
(3, 'Enterprise'), -- Fahasa
(4, 'Business'),   -- Anker
(5, 'Enterprise'), -- La Roche-Posay
(6, 'Enterprise'), -- Lock&Lock
(7, 'Enterprise'), -- Bitis
(8, 'Business'),   -- Hades
(9, 'Individual'), -- Hai Lua
(10, 'Individual');-- Home Decor
GO

-- 3. INSERT BUYER
INSERT INTO Buyer (User_id) VALUES 
(11), (12), (13), (14), (15), (16), (17), (18), (19), (20);
GO

-- 4. INSERT STORE 
INSERT INTO Store (Seller_id, Ten_gian_hang, Mo_ta) VALUES
(1, N'Samsung Official Store', N'Gian hàng chính hãng Samsung Việt Nam'),
(2, N'Coolmate Official', N'Giải pháp ăn mặc cơ bản cho nam giới'),
(3, N'Nhà Sách Fahasa', N'Hệ thống nhà sách chuyên nghiệp'),
(4, N'Anker Flagship Store', N'Phụ kiện sạc cáp số 1 thế giới'),
(5, N'La Roche-Posay Chính Hãng', N'Dược mỹ phẩm chăm sóc da'),
(6, N'Lock&Lock Mall', N'Gia dụng thông minh Hàn Quốc'),
(7, N'Biti''s Hunter', N'Nâng niu bàn chân Việt'),
(8, N'HADES STUDIO', N'Streetwear Local Brand'),
(9, N'Đặc Sản Hai Lúa', N'Khô gà, khô bò, cơm cháy'),
(10, N'Decor Xinh', N'Trang trí nhà cửa phong cách Bắc Âu');
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
(N'Nhà Sách Online', N'Books', NULL),                       -- 3
(N'Sắc Đẹp', N'Beauty & Personal Care', NULL),              -- 4
(N'Nhà Cửa & Đời Sống', N'Home & Living', NULL),            -- 5
(N'Điện Thoại & Phụ Kiện', N'Phones & Accessories', 1),     -- 6
(N'Áo Thun', N'T-Shirts', 2),                               -- 7
(N'Sách Văn Học', N'Literature', 3),                        -- 8
(N'Chăm Sóc Da', N'Skincare', 4),                           -- 9
(N'Dụng Cụ Nhà Bếp', N'Kitchenware', 5);                    -- 10
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

-- 11. INSERT IMAGE
INSERT INTO [Image] (Product_id, Image_id, Duong_dan_anh) VALUES
(1, 1, 's24ultra_titan.jpg'), (2, 1, 'polo_excool_xanh.jpg'), (3, 1, 'cay_cam_ngot.jpg'),
(4, 1, 'anker_cable_pink.jpg'), (5, 1, 'b5_cream.jpg'), (6, 1, 'lock_fryer_black.jpg'),
(7, 1, 'hunter_x_white.jpg'), (8, 1, 'hades_wolf.jpg'), (9, 1, 'kho_ga.jpg'), (10, 1, 'guong_go.jpg');
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
(11, N'Đã Giao', N'12 Tôn Đản, Q4'),        -- Mua Samsung
(12, N'Đã Giao', N'S2.05 Vin Grand Park'),  -- Mua Coolmate
(13, N'Đã Giao', N'68 Cầu Giấy'),           -- Mua Sách
(14, N'Đã Giao', N'Thảo Điền Q2'),          -- Mua Anker
(15, N'Đã Giao', N'Landmark 81'),           -- Mua B5
(16, N'Đã Giao', N'KTX Khu A'),             -- Mua Nồi chiên
(17, N'Đã Giao', N'5 Láng Hạ'),             -- Mua Bitis
(18, N'Đã Giao', N'HAGL Đà Nẵng'),          -- Mua Hades
(19, N'Chờ Lấy Hàng', N'Trần Phú Nha Trang'), -- Mua Khô gà
(20, N'Đang Vận Chuyển', N'Ninh Kiều Cần Thơ'), -- Mua Gương
(11, N'Đã Hủy', N'12 Tôn Đản, Q4'),         -- Đổi ý
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

PRINT N'========================================';
PRINT N'========================================';
PRINT N'Hoàn thành tạo dữ liệu mẫu';
PRINT N'========================================';
PRINT N'========================================';
GO