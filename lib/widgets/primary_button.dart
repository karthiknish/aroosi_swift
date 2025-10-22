import 'package:flutter/cupertino.dart';

import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/theme/typography.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      onPressed: loading ? null : onPressed,
      disabledColor: AppColors.muted,
      child: loading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CupertinoActivityIndicator(),
            )
          : Text(
              label,
              style: AppTypography.bodySemiBold.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
    );
  }
}
