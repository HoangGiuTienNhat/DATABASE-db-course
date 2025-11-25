# 

#PHAN 1.2
Cấp 1 (Không phụ thuộc ai): User, Category, Shipper.

Cấp 2 (Phụ thuộc Cấp 1): Seller, Buyer, Store.

Cấp 3 (Phụ thuộc Cấp 2): Product.

Cấp 4 (Phụ thuộc Cấp 3): Variant, Image, Thuoc_ve.

Cấp 5 (Giao dịch): Order, Order_item, Payment...


## 2.1. Ví dụ Minh Họa (Usage Examples)

Dưới đây là các câu lệnh mẫu để bạn chạy thử nghiệm (Test) các thủ tục đã tạo.

### a. Thêm hàng mới (INSERT)
Lưu ý: Sản phẩm mới tạo sẽ có trạng thái mặc định là `Hidden`.

```sql
EXEC Insert_Product
    @Store_id = 1,                  -- ID gian hàng
    @Ten_san_pham = N'Mũ phù thủy',
    @Mo_ta_chi_tiet = N'Tăng +100 Sức mạnh phép thuật (AP)',
    @Tinh_trang = 'New',
    @Trong_luong = 1.0;
```sql

### b. Thêm hàng mới (INSERT)
Lưu ý: Sản phẩm mới tạo sẽ có trạng thái mặc định là `Hidden`.

```sql
EXEC Insert_Product
    @Store_id = 1,                  -- ID gian hàng
    @Ten_san_pham = N'Mũ phù thủy',
    @Mo_ta_chi_tiet = N'Tăng +100 Sức mạnh phép thuật (AP)',
    @Tinh_trang = 'New',
    @Trong_luong = 1.0;
