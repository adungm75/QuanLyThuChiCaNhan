import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// [EnvConfig] - Quản lý tập trung các biến môi trường từ file .env
/// 
/// Đảm bảo tính bảo mật và cung cấp API type-safe (an toàn kiểu dữ liệu).
/// Có cơ chế fallback về giá trị mặc định an toàn nếu file .env chưa được nạp hoặc chưa tồn tại.
class EnvConfig {
  EnvConfig._();

  static bool _isLoaded = false;

  /// Helper lấy giá trị an toàn, không ném NotInitializedError khi chưa load
  static String? _get(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.maybeGet(key);
  }

  /// Khởi tạo và nạp file .env một cách an toàn
  static Future<void> init({String fileName = '.env'}) async {
    if (_isLoaded && dotenv.isInitialized) return;

    try {
      await dotenv.load(fileName: fileName);
      _isLoaded = true;
      if (kDebugMode) {
        debugPrint('[EnvConfig] Nạp thành công biến môi trường từ $fileName (Môi trường: $appEnv)');
      }
    } catch (e) {
      // Khi clone từ repo mà chưa tạo .env, app sẽ không bị crash mà dùng fallback defaults
      _isLoaded = false;
      if (kDebugMode) {
        debugPrint('[EnvConfig] Cảnh báo: Không tìm thấy file $fileName, chuyển sang sử dụng cấu hình mặc định an toàn: $e');
      }
    }
  }

  /// Nạp chuỗi giả lập biến môi trường phục vụ Unit Test
  static void loadForTesting(Map<String, String> values) {
    dotenv.testLoad(fileInput: values.entries.map((e) => '${e.key}=${e.value}').join('\n'));
    _isLoaded = true;
  }

  // --- Các biến cấu hình hệ thống ---

  /// Môi trường thực thi: 'development' | 'staging' | 'production'
  static String get appEnv => _get('APP_ENV') ?? 'development';

  static bool get isProduction => appEnv.toLowerCase() == 'production';
  static bool get isDevelopment => appEnv.toLowerCase() == 'development';

  /// Tên hiển thị của ứng dụng
  static String get appTitle => _get('APP_TITLE') ?? 'Quản Lý Chi Tiêu Cá Nhân';

  /// URL máy chủ Backend API (khi đồng bộ)
  static String get apiBaseUrl => _get('API_BASE_URL') ?? 'https://api.expensetracker.local/v1';

  /// Thời gian chờ kết nối mạng (milliseconds)
  static int get apiTimeoutMs {
    final raw = _get('API_TIMEOUT_MS');
    return raw != null ? int.tryParse(raw) ?? 5000 : 5000;
  }

  /// Khóa bảo mật API (Secret Key)
  /// TUYỆT ĐỐI BẢO MẬT: Không in đầy đủ key này ra log công khai
  static String get apiSecretKey => _get('API_SECRET_KEY') ?? '';

  /// Trả về chuỗi khóa bảo mật đã được che giấu (masking) để hiển thị an toàn trong log/UI
  static String get maskedSecretKey {
    final key = apiSecretKey;
    if (key.isEmpty) return '(Chưa thiết lập)';
    if (key.length <= 6) return '******';
    return '${key.substring(0, 3)}***${key.substring(key.length - 3)}';
  }

  /// Cờ bật/tắt tính năng màn hình thử nghiệm ngoại lệ OOP Playground
  static bool get enableMockErrorPlayground {
    final raw = _get('ENABLE_MOCK_ERROR_PLAYGROUND');
    return raw != null ? raw.toLowerCase() == 'true' : true;
  }

  /// Cờ bật/tắt ghi nhật ký chi tiết
  static bool get enableDebugLogging {
    final raw = _get('ENABLE_DEBUG_LOGGING');
    return raw != null ? raw.toLowerCase() == 'true' : true;
  }
}
