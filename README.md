# Quản Lý Chi Tiêu Cá Nhân - Personal Expense Tracker

Ứng dụng quản lý tài chính và chi tiêu cá nhân thông minh dành cho người dùng muốn theo dõi thu chi, kiểm soát ngân sách hàng tháng và phân tích thói quen tiêu dùng một cách trực quan, chính xác. Dự án giải quyết triệt để bài toán mất cân đối tài chính cá nhân với các tính năng cốt lõi: ghi nhận thu/chi đa danh mục, thiết lập hạn mức ngân sách kèm cảnh báo chi tiêu vượt ngưỡng, thống kê trực quan dòng tiền theo từng tháng và lưu trữ dữ liệu ngoại tuyến bền vững. Đặc biệt, ứng dụng được thiết kế phân tầng chuẩn Clean Architecture kết hợp hệ thống xử lý ngoại lệ tập trung (Centralized Error Handling Pipeline) và phòng thử nghiệm lỗi tương tác (Error Playground).

---

## 1. Công Nghệ Sử Dụng (Tech Stack)

- **Framework**: Flutter (v3.x / Dart 3.x) - Xây dựng giao diện đa nền tảng hiện đại theo phong cách Material Design 3.
- **Ngôn ngữ**: Dart (Sound Null Safety, Hướng đối tượng OOP, Mixins, Generics, Pattern Matching).
- **Quản lý trạng thái (State Management)**: `ChangeNotifier` kết hợp `ListenableBuilder` (Native Flutter State Management, nhẹ nhàng và tối ưu hiệu năng).
- **Kiến trúc phần mềm (Architecture)**: Clean Architecture / Layered Architecture phân tách 4 tầng độc lập (`core`, `domain`, `data`, `presentation`).
- **Design Patterns**:
  - **Factory Pattern**: `TransactionFactory` đóng gói khởi tạo và kiểm tra nghiệp vụ toàn vẹn dữ liệu.
  - **Generic Repository Pattern**: `Repository<T>` chuẩn hóa các thao tác CRUD trừu tượng.
  - **Mixin**: `LoggingMixin` hỗ trợ tự động ghi log phân cấp (INFO, WARNING, ERROR, DEBUG).
  - **Singleton Pattern**: Áp dụng cho `InMemoryDatabase` và `CentralizedErrorHandler`.
- **Cơ sở dữ liệu & Lưu trữ (Storage)**: `SharedPreferences` (Lưu trữ cục bộ bền vững Offline-first dưới định dạng JSON).
- **Thư viện hỗ trợ (Utilities)**:
  - `intl`: Định dạng tiền tệ Việt Nam Đồng (₫) và định dạng ngày tháng theo tiêu chuẩn Việt Nam.
  - `cupertino_icons`: Hỗ trợ hệ thống biểu tượng phong phú.
- **Kiểm thử (Testing)**: `flutter_test` (Bộ kiểm thử tự động cho Validation, Generic Repository và Error Pipeline).

---

## 2. Yêu Cầu Hệ Thống (Prerequisites)

Trước khi cài đặt và chạy ứng dụng, hãy đảm bảo máy tính đã cài đặt các công cụ sau:

- **Flutter SDK**: Phiên bản `3.19.0` hoặc mới hơn.
- **Dart SDK**: Phiên bản `3.3.0` hoặc mới hơn (đi kèm sẵn trong Flutter SDK).
- **Hệ điều hành**: Windows 10/11, macOS, hoặc Linux.
- **Môi trường phát triển (IDE)**:
  - [Visual Studio Code](https://code.visualstudio.com/) (Khuyên dùng, cài kèm Extension *Flutter* và *Dart*).
  - Hoặc [Android Studio](https://developer.android.com/studio) (Cài đặt Android SDK và máy ảo Emulator API 24+).
- **Git**: Đã được cài đặt và cấu hình biến môi trường (`git --version`).

---

## 3. Hướng Dẫn Cài Đặt (Installation)

Thực hiện lần lượt các bước sau trên cửa sổ dòng lệnh (Terminal / PowerShell):

### Bước 1: Sao chép mã nguồn (Clone repository)
```bash
git clone https://github.com/adungm75/QuanLyThuChiCaNhan.git
```

### Bước 2: Di chuyển vào thư mục dự án
```bash
cd QuanLyThuChiCaNhan
```

### Bước 3: Cài đặt các thư viện phụ thuộc (Dependencies)
```bash
flutter pub get
```

### Bước 4: Kiểm tra trạng thái môi trường
```bash
flutter doctor
```
*(Đảm bảo không còn dấu gạch chéo đỏ ở mục Flutter và Android toolchain / Chrome).*

---

## 4. Hướng Dẫn Cấu Hình Biến Môi Trường (Configuration)

- **Cấu hình hiện tại**: Dự án hoạt động hoàn toàn theo cơ chế **Offline-First**, lưu trữ dữ liệu trực tiếp trong bộ nhớ cục bộ của thiết bị thông qua `SharedPreferences`. Do đó, ứng dụng **không yêu cầu** bất kỳ file `.env`, Database Server hay cấu hình Firebase (`google-services.json`) nào để chạy bản cơ bản.
- **Cấu hình mở rộng (Dành cho việc tích hợp Backend / Cloud Sync trong tương lai)**:
  - Nếu bạn mở rộng kết nối API từ xa, hãy sao chép file `.env.example` thành `.env` tại thư mục gốc:
    ```bash
    cp .env.example .env
    ```
  - Các tham số cấu hình mẫu:
    - `API_BASE_URL`: Địa chỉ máy chủ API backend (ví dụ: `https://api.expensetracker.local/v1`).
    - `REQUEST_TIMEOUT_MS`: Thời gian chờ tối đa cho các yêu cầu mạng (mặc định: `5000`).
  - Nếu kết nối dịch vụ Firebase:
    - Android: Đặt file `google-services.json` vào thư mục `android/app/`.
    - iOS: Đặt file `GoogleService-Info.plist` vào thư mục `ios/Runner/`.

---

## 5. Hướng Dẫn Khởi Chạy (Usage / Execution)

### 5.1. Chạy ở chế độ phát triển (Development Mode)
Kết nối thiết bị thật qua USB hoặc khởi động máy ảo (Android Emulator / Windows / Chrome), sau đó thực thi:
```bash
flutter run
```
*Mẹo: Nhấn phím `r` trên Terminal để Hot Reload, hoặc `R` để Hot Restart ứng dụng trong giây lát.*

### 5.2. Chạy trên thiết bị hoặc nền tảng cụ thể
```bash
# Chạy trên trình duyệt Google Chrome
flutter run -d chrome

# Chạy trực tiếp dưới dạng ứng dụng Desktop Windows
flutter run -d windows
```

### 5.3. Kiểm tra phân tích tĩnh mã nguồn (Code Linter)
```bash
flutter analyze
```

### 5.4. Chạy bộ kiểm thử tự động (Unit Tests)
Dự án đã tích hợp sẵn các bài test bao phủ Factory Pattern, Invariant Validation, Repository và Centralized Error Pipeline:
```bash
flutter test
```

### 5.5. Biên dịch và đóng gói ứng dụng (Production Build)
```bash
# Đóng gói file APK phát hành cho Android
flutter build apk --release

# Đóng gói tệp Android App Bundle (.aab) tải lên Google Play
flutter build appbundle --release

# Đóng gói ứng dụng desktop Windows
flutter build windows --release
```

---

*Dự án được xây dựng với mục tiêu học tập, thực hành lập trình hướng đối tượng (OOP) nâng cao, thiết kế phần mềm theo kiến trúc Clean Architecture và kiểm soát ngoại lệ chặt chẽ trên nền tảng Flutter & Dart.*
