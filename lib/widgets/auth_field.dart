import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Underlined text field with a small red label above it, matching the
/// approved "Classic Maroon" mockup. Shows a checkmark once the value
/// passes [validator], or an eye toggle when [obscurable] is true.
class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final bool obscurable;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final int? maxLength;
  final int maxLines;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.obscurable = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.maxLength,
    this.maxLines = 1,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isValid = widget.validator == null
        ? widget.controller.text.isNotEmpty
        : widget.validator!(widget.controller.text) == null &&
              widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.brand,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscurable && _obscured,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade400,
            ),
            counterText: '',
            contentPadding: const EdgeInsets.only(top: 2, bottom: 8),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.brand, width: 1.4),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            suffixIcon: widget.obscurable
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _obscured = !_obscured),
                    child: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  )
                : (isValid
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: AppColors.brand,
                        )
                      : null),
          ),
        ),
      ],
    );
  }
}
