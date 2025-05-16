import 'package:flutter/material.dart';

class CustomAlertDialog extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final VoidCallback? onConfirm;
  final bool autoDismiss;
  final Duration autoDismissDuration;

  const CustomAlertDialog({
    required this.isSuccess,
    required this.title,
    required this.message,
    this.onConfirm,
    this.autoDismiss = false,
    this.autoDismissDuration = const Duration(seconds: 3),
    super.key,
  });

  @override
  _CustomAlertDialogState createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<CustomAlertDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.forward();

    // Tự động đóng dialog nếu autoDismiss được bật
    if (widget.autoDismiss) {
      Future.delayed(widget.autoDismissDuration, () {
        if (mounted) {
          Navigator.pop(context);
          if (widget.onConfirm != null) widget.onConfirm!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(screenHeight * 0.03),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: screenHeight * 0.1,
                height: screenHeight * 0.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  widget.isSuccess ? Icons.check_circle : Icons.error,
                  color: widget.isSuccess ? Colors.green : Colors.red,
                  size: screenHeight * 0.06,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: screenHeight * 0.025,
                  fontWeight: FontWeight.bold,
                  color: widget.isSuccess ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                widget.message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: screenHeight * 0.02,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.03),
              if (!widget.autoDismiss) // Chỉ hiển thị nút "OK" nếu không tự động tắt
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onConfirm != null) widget.onConfirm!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isSuccess ? Colors.green : Colors.red,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.015,
                      horizontal: screenHeight * 0.05,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: screenHeight * 0.02,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}