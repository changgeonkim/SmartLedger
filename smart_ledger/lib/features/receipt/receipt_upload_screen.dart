import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'receipt_handler.dart';

class ReceiptUploadScreen extends StatelessWidget {
  const ReceiptUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text('영수증 입력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('영수증을 촬영하거나 갤러리에서 선택하세요',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _OptionButton(
                    icon: Icons.camera_alt_outlined,
                    label: '카메라 촬영',
                    onTap: () {
                      Navigator.pop(context);
                      ReceiptHandler.fromCamera(context);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _OptionButton(
                    icon: Icons.photo_library_outlined,
                    label: '갤러리 선택',
                    onTap: () {
                      Navigator.pop(context);
                      ReceiptHandler.fromGallery(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
