import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    Key? key,
    required this.status,
    this.fontSize = 11,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'DELIVERED':
      case 'APPROVED':
      case 'FULLY_PAID':
      case 'PRESENT':
        bg = AppColors.success.withOpacity(0.12);
        text = AppColors.success;
        break;
      case 'IN_PROGRESS':
      case 'PRINTING':
      case 'FABRICATION':
      case 'INSTALLATION':
      case 'PARTIALLY_PAID':
      case 'ACCEPTED':
        bg = AppColors.info.withOpacity(0.12);
        text = AppColors.info;
        break;
      case 'ASSIGNED':
      case 'SUBMITTED':
      case 'PENDING':
      case 'LATE':
      case 'DRAFT':
        bg = AppColors.warning.withOpacity(0.15);
        text = const Color(0xFFD97706);
        break;
      case 'REJECTED':
      case 'CANCELLED':
      case 'ABSENT':
      case 'UNPAID':
        bg = AppColors.error.withOpacity(0.12);
        text = AppColors.error;
        break;
      default:
        bg = AppColors.border;
        text = AppColors.textSecondary;
    }

    final formattedText = status.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        formattedText,
        style: TextStyle(
          color: text,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
