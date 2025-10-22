import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:aroosi_flutter/theme/colors.dart';
import 'package:aroosi_flutter/theme/typography.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;

  const InputField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.muted,
            ),
          ),
        ),
        CupertinoTextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: AppTypography.body,
          placeholder: label,
          placeholderStyle: AppTypography.body.copyWith(
            color: AppColors.muted,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderPrimary,
              width: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Enhanced input field with real-time validation feedback
class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.maxLength,
    this.minLines,
    this.maxLines,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  String? _errorText;
  bool _hasBeenEdited = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_hasBeenEdited && widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }
    widget.onChanged?.call(widget.controller.text);
  }

  void _onFocusLost() {
    if (!_hasBeenEdited && widget.controller.text.isNotEmpty) {
      setState(() {
        _hasBeenEdited = true;
        _errorText = widget.validator?.call(widget.controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            widget.label,
            style: AppTypography.caption.copyWith(
              color: AppColors.muted,
            ),
          ),
        ),
        CupertinoTextField(
          controller: widget.controller,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines ?? 1,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          style: AppTypography.body,
          placeholder: widget.hintText ?? widget.label,
          placeholderStyle: AppTypography.body.copyWith(
            color: AppColors.muted,
          ),
          padding: widget.contentPadding ?? const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.surfaceSecondary
                : AppColors.surfaceSecondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _errorText != null
                  ? AppColors.error
                  : AppColors.borderPrimary,
              width: _errorText != null ? 2 : 1,
            ),
          ),
          onChanged: (value) {
            if (!_hasBeenEdited && value.isNotEmpty) {
              setState(() => _hasBeenEdited = true);
            }
            _onTextChanged();
          },
          onSubmitted: widget.onSaved,
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorText!,
            style: AppTypography.caption.copyWith(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
