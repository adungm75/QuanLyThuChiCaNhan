import 'package:flutter/material.dart';
import 'centralized_error_handler.dart';

/// [ErrorBoundary] - Widget bắt ngoại lệ giao diện (Error Boundary)
/// Ngăn chặn ứng dụng bị sập ("Red Screen of Death"), ghi log tập trung
/// và cung cấp giao diện thay thế (fallback UI) thân thiện với người dùng.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, FlutterErrorDetails errorDetails)? fallbackBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;
  late final ErrorWidgetBuilder _originalErrorWidgetBuilder;

  @override
  void initState() {
    super.initState();
    // Thay thế ErrorWidget.builder để bắt các lỗi render nội bộ
    _originalErrorWidgetBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      CentralizedErrorHandler.instance.process(details.exception, details.stack);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _errorDetails == null) {
            setState(() {
              _errorDetails = details;
            });
          }
        });
      }
      return widget.fallbackBuilder?.call(context, details) ?? _buildDefaultFallbackUI(context, details);
    };
  }

  @override
  void dispose() {
    ErrorWidget.builder = _originalErrorWidgetBuilder;
    super.dispose();
  }

  void _resetError() {
    setState(() {
      _errorDetails = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(context, _errorDetails!);
      }
      return _buildDefaultFallbackUI(context, _errorDetails!);
    }

    return widget.child;
  }

  Widget _buildDefaultFallbackUI(BuildContext context, [FlutterErrorDetails? details]) {
    final err = details ?? _errorDetails;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bug_report_rounded, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Đã xảy ra sự cố giao diện!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err?.exceptionAsString() ?? 'Không rõ chi tiết lỗi.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _resetError,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử khôi phục'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
