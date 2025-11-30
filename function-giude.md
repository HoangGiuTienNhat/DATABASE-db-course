# BÁO CÁO CHI TIẾT HIỆN THỰC VÀ KIỂM THỬ HÀM (FUNCTIONS)

**Lưu ý quan trọng:** Các hàm được hiện thực dưới đây hoạt động theo cơ chế chỉ **ĐỌC dữ liệu (SELECT)** để tính toán và trả về kết quả, hoàn toàn không thực hiện các thao tác làm thay đổi dữ liệu (INSERT, UPDATE, DELETE).

---

## II. CHI TIẾT CÁC HÀM ĐÃ HIỆN THỰC

### 1. Hàm 1: Tính doanh thu ròng của Cửa hàng (`fn_Tinh_Doanh_Thu_Rong_Store`)

#### A. Mục đích và Giải thuật
* **Mục đích:** Tính tổng doanh thu thực nhận của một cửa hàng trong một tháng cụ thể sau khi đã trừ đi phí sàn (Commission Fee). Mức phí sàn không cố định mà thay đổi tùy theo danh mục sản phẩm (Ví dụ: Điện tử 5%, Thời trang 8%, Khác 10%).
* **Giải thuật:**
    * **Validate:** Kiểm tra sự tồn tại của `Store_id` và tính hợp lệ của thời gian (tháng/năm).
    * **Cursor (Con trỏ):** Duyệt qua từng dòng sản phẩm trong các đơn hàng có trạng thái `Đã Giao` của tháng cần tính.
    * **Loop & IF:** Trong vòng lặp, hệ thống kiểm tra `Category_id` của từng sản phẩm để áp dụng mức phí sàn tương ứng, sau đó cộng dồn giá trị thực nhận vào tổng doanh thu ròng.

#### B. Phân tích dữ liệu nguồn (Data Dependency)
Hàm này thực hiện truy vấn liên kết qua 5 bảng để đảm bảo tính toán chính xác:
1.  **`Store`:** Kiểm tra sự tồn tại của cửa hàng.
2.  **`Product`:** Xác định sản phẩm nào thuộc về cửa hàng nào (`Store_id`).
3.  **`Thuoc_ve`:** Xác định sản phẩm thuộc danh mục (`Category`) nào, làm cơ sở tính % phí sàn.
4.  **`Order_item`:** Lấy thông tin về số lượng và đơn giá bán tại thời điểm giao dịch.
5.  **`[Order]`:** Lọc các đơn hàng theo trạng thái "Đã Giao" và theo thời gian (tháng/năm).

---

### 2. Hàm 2: Tính điểm uy tín Người mua (`fn_Tinh_Diem_Uy_Tin_Buyer`)

#### A. Mục đích và Giải thuật
* **Mục đích:** Xây dựng hệ thống xếp hạng người dùng (Gamification). Điểm uy tín sẽ tăng khi người dùng mua hàng thành công và có tương tác đánh giá sản phẩm; ngược lại điểm sẽ giảm nếu hủy đơn.
* **Giải thuật:**
    * **Validate:** Kiểm tra `Buyer_id` có tồn tại trong hệ thống hay không.
    * **Cursor (Con trỏ):** Duyệt qua toàn bộ lịch sử đơn hàng của người mua.
    * **Query Nested (Truy vấn lồng):** Ngay bên trong vòng lặp duyệt đơn hàng, thực hiện truy vấn kiểm tra bảng `Danh_gia` để xác định đơn hàng hiện tại đã được người dùng đánh giá hay chưa.
* **Logic tính điểm:**
    * Đơn hàng thành công: **+10 điểm**.
    * Đơn hàng giá trị cao (> 1 triệu VNĐ): **+5 điểm**.
    * Có thực hiện đánh giá (Query check): **+2 điểm**.
    * Đơn hàng Hủy/Hoàn trả: **-20 điểm**.

#### B. Phân tích dữ liệu nguồn (Data Dependency)
Hàm này tương tác chủ yếu với 3 bảng:
1.  **`Buyer`:** Kiểm tra sự tồn tại của người mua.
2.  **`[Order]`:** Bảng quan trọng nhất, dùng để xác định trạng thái đơn (Hoàn tất/Hủy) và tổng giá trị đơn hàng.
3.  **`Danh_gia`:** Kiểm tra hành vi đánh giá sản phẩm của người mua để cộng điểm thưởng.

---

## III. NHẬN XÉT VÀ ĐÁNH GIÁ KẾT QUẢ CHẠY THỬ (TESTING)

Quá trình chạy thử sử dụng Script Test gọi dữ liệu từ bảng `[User]` (để lấy hiển thị Họ tên), `Store` và `Buyer` (để lấy danh sách ID đầu vào).

### 1. Đánh giá Hàm 1: Tính Doanh Thu Ròng (`fn_Tinh_Doanh_Thu_Rong_Store`)
Dựa trên kết quả thực tế (3 bảng kết quả đầu tiên):

* **Tính đúng đắn của phép toán (Calculation Logic):**
    * Tại dòng 1 (Store 1 - Samsung), kết quả trả về là `24,217,875.00`. Đây là con số hợp lý cho doanh thu của một cửa hàng kinh doanh sản phẩm giá trị cao (Samsung S24 Ultra).
    * Hệ thống đã áp dụng đúng công thức: `(Đơn giá * Số lượng) * (1 - % Phí sàn)`.
    * Phần thập phân `.00` được bảo toàn chứng tỏ kiểu dữ liệu `DECIMAL` được sử dụng chính xác, tránh sai lệch làm tròn trong tiền tệ.
* **Khả năng duyệt dữ liệu (Cursor & Loop):**
    * Bảng danh sách Store (từ Store 1 đến Store 8) hiển thị các mức doanh thu rất khác nhau (Ví dụ: Store 2 ~467k, Store 6 ~2tr).
    * Điều này chứng minh **Con trỏ (Cursor)** đã hoạt động chính xác, duyệt qua từng sản phẩm của từng cửa hàng riêng biệt và **Vòng lặp (Loop)** đã cộng dồn số liệu mà không bị lặp vô hạn hay bỏ sót.
* **Kiểm tra tham số đầu vào (Validation):**
    * Tại bảng `Ket_Qua_Store_Ao`, khi truyền vào ID `999` (không tồn tại), hàm trả về `0.00` ngay lập tức.
    * Chứng tỏ lệnh `IF NOT EXISTS... RETURN 0` hoạt động hiệu quả, ngăn chặn lỗi hệ thống khi gặp dữ liệu không hợp lệ.

### 2. Đánh giá Hàm 2: Tính Điểm Uy Tín Buyer (`fn_Tinh_Diem_Uy_Tin_Buyer`)
Dựa trên kết quả thực tế (4 bảng kết quả cuối):

* **Logic tính điểm (Scoring Logic):**
    * **Buyer 11 (Nguyễn Thanh) - 117 điểm:** Phản ánh đúng kịch bản mua hàng thành công giá trị cao.
        * *Phân tích:* Điểm gốc (100) + Đơn thành công (>1tr) (+15 điểm) + Có đánh giá (+2 điểm) = 117.
    * **Buyer 12 (Lê Hoa) - 112 điểm:** Thấp hơn Buyer 11, phản ánh kịch bản đơn hàng giá trị thấp hơn (không được cộng 5 điểm bonus đơn to) nhưng vẫn có điểm cộng cơ bản và điểm đánh giá.
* **Xử lý ngoại lệ (Error Handling):**
    * Tại bảng `Ket_Qua_Buyer_Ao`, giá trị trả về là `-1` khi nhập ID rác. Điều này giúp phân biệt rõ ràng giữa trường hợp "Người dùng mới chưa có điểm (0 điểm)" và "Người dùng không tồn tại (-1)".
* **Phân loại xếp hạng (Classification):**
    * Cột `Xep_Hang` hiển thị kết quả "Silver" cho các User có điểm từ 100 đến dưới 120. Điều này chứng minh câu lệnh `SELECT ... CASE WHEN` (trong hoặc ngoài hàm) đã bắt đúng các mốc điểm số quy định.

---

## IV. KẾT LUẬN CHUNG
Qua quá trình hiện thực và kiểm thử (Testing), hai hàm `fn_Tinh_Doanh_Thu_Rong_Store` và `fn_Tinh_Diem_Uy_Tin_Buyer` đã đáp ứng đầy đủ và chính xác các yêu cầu kỹ thuật của đề bài bài tập lớn:

1.  Sử dụng thành công kỹ thuật **Cursor** để xử lý dữ liệu chi tiết theo từng dòng.
2.  Kết hợp hiệu quả các cấu trúc điều khiển **IF/ELSE** để giải quyết các nghiệp vụ phức tạp (tính phí sàn linh động theo danh mục, tính điểm thưởng/phạt theo hành vi).
3.  Có cơ chế **Validate** dữ liệu đầu vào chặt chẽ để đảm bảo tính toàn vẹn của hệ thống.
4.  Kết quả truy vấn trả về chính xác, phản ánh đúng logic nghiệp vụ trên dữ liệu mẫu đã nhập.