import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/shared/widgets/app_icon.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppTopBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: AppIcon(size: 24, color: AppColors.primary),
        onPressed: () => context.go('/'),
        tooltip: 'Beranda',
      ),
      centerTitle: true,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      actions: [
        IconButton(
          icon: AppIcon(size: 24, color: AppColors.primary),
          onPressed: () => context.push('/settings'),
          tooltip: 'Pengaturan',
        ),
      ],
      backgroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.outlineVariant, height: 1),
      ),
    );
  }
}
