import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:warung_pintar_cimahi/core/constant/app_colors.dart';
import 'package:warung_pintar_cimahi/core/theme/app_theme.dart';
import 'package:warung_pintar_cimahi/features/onboarding/presentation/providers/onboarding_provider.dart';

class OnboardingProfilePage extends ConsumerWidget {
  const OnboardingProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _TopAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.marginPage,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.stackLg),
                    _HeaderSection(),
                    const SizedBox(height: AppTheme.stackLg),
                    _AiGuideBubble(),
                    const SizedBox(height: AppTheme.stackLg),
                    _NameField(
                      label: 'Nama Warung',
                      required: true,
                      hint: 'Contoh: Warung Berkah',
                      helperText: 'Nama ini akan tercetak di struk pelanggan.',
                      value: state.shopName,
                      onChanged: (v) {
                        ref.read(onboardingProvider.notifier).setShopName(v);
                      },
                    ),
                    const SizedBox(height: AppTheme.stackMd),
                    _ContextualHint(),
                    const SizedBox(height: AppTheme.stackLg),
                    _NameField(
                      label: 'Nama Pemilik',
                      required: false,
                      hint: 'Nama Ibu/Bapak',
                      helperText: null,
                      value: state.ownerName,
                      onChanged: (v) {
                        ref.read(onboardingProvider.notifier).setOwnerName(v);
                      },
                    ),
                    const SizedBox(height: AppTheme.stackLg),
                  ],
                ),
              ),
            ),
            _BottomBar(ref),
          ],
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.touchTargetMin,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.onSurfaceVariant,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'Langkah 1 dari 4',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ),
          const SizedBox(width: AppTheme.touchTargetMin),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil Usaha',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        const SizedBox(height: AppTheme.stackSm),
        Text(
          'Lengkapi data dasar warung Ibu untuk memulai sistem kasir digital.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _AiGuideBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.marginPage),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.primaryFixedDim),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: AppColors.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.stackMd),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '"Sebelum mulai, saya perlu tahu sedikit tentang warung Ibu."',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onPrimaryFixed,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final String label;
  final bool required;
  final String hint;
  final String? helperText;
  final String value;
  final ValueChanged<String> onChanged;

  const _NameField({
    required this.label,
    required this.required,
    required this.hint,
    this.helperText,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: AppColors.error),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.stackSm),
        SizedBox(
          height: AppTheme.touchTargetMin,
          child: TextField(
            onChanged: onChanged,
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              ),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.marginPage,
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: AppTheme.stackSm),
          Text(
            helperText!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _ContextualHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb,
            color: AppColors.tertiary,
            size: 20,
          ),
          const SizedBox(width: AppTheme.stackSm),
          Expanded(
            child: Text(
              'Tips: Gunakan nama yang mudah diingat warga sekitar.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  final WidgetRef ref;

  const _BottomBar(this.ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final isValid = state.shopName.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTheme.marginPage),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: AppTheme.touchTargetMin,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.outline),
                  foregroundColor: AppColors.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
                  ),
                ),
                child: const Text('Kembali'),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.stackMd),
          Expanded(
            child: SizedBox(
              height: AppTheme.touchTargetMin,
              child: ElevatedButton(
                onPressed: isValid
                    ? () {
                        ref.read(onboardingProvider.notifier).nextStep();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  foregroundColor:
                      isValid ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                  disabledForegroundColor: AppColors.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
                  ),
                ),
                child: const Text('Lanjut'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
