BIGFIT – TECH TASKLIST THEO 6 MODULE
Ứng dụng thời trang Big Size – Flutter / Android
Phân chia theo yêu cầu thuyết trình và demo. Các chức năng cũ được tái phân nhóm; các chức năng mới được bổ sung.
1. Database – Module 8, 9
Thiết kế và kết nối cơ sở dữ liệu; xây dựng API; demo
ID	Task Tech	Đầu ra	Phụ trách
TECH-01	Thiết kế ERD cho Users, Products, Variants, Cart, Orders, Payments, Notifications	Sơ đồ ERD và quan hệ	
TECH-02	Tạo database MySQL hoặc SQL Server, khóa và ràng buộc	Database có dữ liệu mẫu	
TECH-03	Khởi tạo Backend REST API và cấu hình ORM	Backend chạy được	
TECH-04	Kết nối Backend với database và kiểm thử CRUD	API truy xuất dữ liệu thành công	
TECH-05	Xây dựng API sản phẩm, danh mục, tìm kiếm, lọc, size/màu	Catalogue API	
TECH-06	Xây dựng API giỏ hàng, yêu thích, đơn hàng và lịch sử	Shopping/Order API	
TECH-07	Xây dựng API hồ sơ, đánh giá, quản lý sản phẩm và tồn kho	Profile/Admin API	
TECH-08	Kết nối Flutter với API; demo các luồng dữ liệu	Demo end-to-end	
2. Map – Module 6, 8
Khái niệm, ứng dụng bản đồ trên mobile và demo
ID	Task Tech	Đầu ra	Phụ trách
TECH-09	Tìm hiểu Google Maps và lựa chọn thư viện Flutter	Tài liệu công nghệ	
TECH-10	Cấu hình Google Maps SDK, API key và quyền vị trí	Bản đồ hiển thị trên Android	
TECH-11	Xây dựng màn hình chọn vị trí/địa chỉ giao hàng	UI bản đồ và marker	
TECH-12	Lưu địa chỉ và tọa độ giao hàng vào database qua API	Địa chỉ được lưu và truy xuất	
TECH-13	Demo chọn địa điểm giao hàng trên bản đồ	Demo Map	
3. Payment – Module 7, 8, 10
Phương thức thanh toán online, quy trình triển khai và demo
ID	Task Tech	Đầu ra	Phụ trách
TECH-14	Khảo sát COD, chuyển khoản, VNPay/MoMo hoặc cổng phù hợp	Bảng so sánh phương thức	
TECH-15	Thiết kế bảng Payment, trạng thái và quan hệ Order	Schema Payment	
TECH-16	Xây dựng API tạo yêu cầu thanh toán	Payment API	
TECH-17	Tích hợp sandbox của cổng thanh toán được chọn	Luồng thanh toán thử nghiệm	
TECH-18	Xử lý callback/webhook, xác minh chữ ký và cập nhật đơn hàng	Trạng thái thanh toán chính xác	
TECH-19	Xây dựng màn hình chọn phương thức, kết quả thanh toán	Flutter Payment UI	
TECH-20	Demo thanh toán thành công/thất bại	Demo Payment	
4. Bảo mật tài khoản – Module 10
Bảo mật hệ thống, xác thực email và OTP
ID	Task Tech	Đầu ra	Phụ trách
TECH-21	Xây dựng API đăng ký, đăng nhập và cấp JWT	Authentication API	
TECH-22	Băm mật khẩu, phân quyền Customer/Admin và bảo vệ API	Role-based authorization	
TECH-23	Xây dựng giao diện Login/Register và quản lý token an toàn	Flutter Auth UI	
TECH-24	Xác minh email khi đăng ký và gửi email đặt lại mật khẩu	Email verification/reset	
TECH-25	Sinh, gửi, kiểm tra OTP có thời hạn và giới hạn thử lại	OTP API	
TECH-26	Xây dựng giao diện nhập OTP và demo bảo mật	Demo Security	
5. Notifications screen – Module 10
Khái niệm, các bước thực hiện và demo
ID	Task Tech	Đầu ra	Phụ trách
TECH-27	Thiết kế bảng Notification, trạng thái đã đọc/chưa đọc	Notification schema	
TECH-28	Xây dựng API lấy danh sách, đánh dấu đã đọc	Notification API	
TECH-29	Tích hợp Firebase Cloud Messaging hoặc giải pháp phù hợp	Push notification	
TECH-30	Xây dựng màn hình thông báo Flutter	Notification Screen	
TECH-31	Gửi thông báo khi đơn hàng đổi trạng thái	Thông báo theo sự kiện	
TECH-32	Demo nhận và xem thông báo	Demo Notifications	
6. Chat AI – Module 8, 10
Phương pháp tích hợp chat AI, các bước thực hiện và demo
ID	Task Tech	Đầu ra	Phụ trách
TECH-33	Khảo sát cách tích hợp chatbot AI và chọn nhà cung cấp	Phương án tích hợp	
TECH-34	Thiết kế giao diện Chat AI trong Flutter	Chat UI	
TECH-35	Xây dựng backend proxy gọi AI API, bảo vệ API key	Chat API	
TECH-36	Cung cấp ngữ cảnh sản phẩm, size và chính sách BigFit cho AI	Trả lời theo dữ liệu BigFit	
TECH-37	Lưu lịch sử chat nếu cần và xử lý lỗi/giới hạn request	Chat ổn định	
TECH-38	Demo hỏi đáp sản phẩm và tư vấn size	Demo Chat AI	
Công việc chung – Setup, Integration, Testing & Release
ID	Task Tech	Đầu ra	Phụ trách
TECH-39	Khởi tạo Flutter project, cấu trúc thư mục và Git branches	Flutter project và repository	
TECH-40	Tích hợp các module vào ứng dụng BigFit	Ứng dụng chạy end-to-end	
TECH-41	Kiểm thử API với Swagger/Postman và Flutter functional testing	Báo cáo kiểm thử	
TECH-42	Sửa lỗi, kiểm tra bảo mật và build Android APK	APK cài đặt được	
Lưu ý: Tích hợp thanh toán cần dùng sandbox khi demo; không lưu khóa bí mật trực tiếp trong Flutter.
