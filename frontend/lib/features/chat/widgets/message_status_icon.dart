import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/message.dart';

class MessageStatusIcon extends StatelessWidget {
  final MessageStatus status;
  final double size;
  final Color? customColor;

  const MessageStatusIcon({
    super.key,
    required this.status,
    this.size = 16,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time_rounded,
          size: size,
          color: customColor ?? Colors.grey.shade500,
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: size,
          color: customColor ?? Colors.grey.shade500,
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: size,
          color: customColor ?? Colors.grey.shade500,
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: size,
          color: customColor ?? AppColors.readReceiptBlue,
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: size,
          color: AppColors.errorRed,
        );
    }
  }
}
