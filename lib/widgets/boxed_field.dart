import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Rounded, fully-bordered text field with a bold label above it —
/// matches church-web's `.form-control` inputs (contact and reservation
/// forms), as opposed to [AuthField]'s underlined login/register style.
class BoxedField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final String? hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final int maxLines;
  final bool obscureText;

  const BoxedField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.obscureText = false,
  });

  @override
  State<BoxedField> createState() => _BoxedFieldState();
}

class _BoxedFieldState extends State<BoxedField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final label = widget.label;
    final required = widget.required;
    final hint = widget.hint;
    final keyboardType = widget.keyboardType;
    final validator = widget.validator;
    final textInputAction = widget.textInputAction;
    final maxLines = widget.maxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: 0.6,
            ),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.brand),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: widget.obscureText && _obscured,
          validator: validator,
          textInputAction: textInputAction,
          maxLines: widget.obscureText ? 1 : maxLines,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: widget.obscureText
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
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
