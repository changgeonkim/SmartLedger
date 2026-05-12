import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ReceiptUploadScreen extends StatelessWidget {
  final VoidCallback onManualEntry;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const ReceiptUploadScreen({
    super.key,
    required this.onManualEntry,
    required this.onCamera,
    required this.onGallery,
  });

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
            const Text('내역 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _OptionButton(
                    icon: Icons.camera_alt_outlined,
                    label: '카메라 촬영',
                    onTap: () {
                      Navigator.pop(context);
                      onCamera();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionButton(
                    icon: Icons.photo_library_outlined,
                    label: '갤러리 선택',
                    onTap: () {
                      Navigator.pop(context);
                      onGallery();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionButton(
                    icon: Icons.edit_outlined,
                    label: '수동 입력',
                    onTap: () {
                      Navigator.pop(context);
                      onManualEntry();
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
