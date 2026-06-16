import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A custom Neo-Brutalist Container card with thick black borders and flat offset drop shadows.
class NeoCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color shadowColor;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final double shadowOffset;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.shadowColor = const Color(0x0F000000),
    this.borderColor = const Color(0xFFE2E8F0),
    this.borderRadius = 16.0,
    this.borderWidth = 1.0,
    this.shadowOffset = 4.0,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadowOffset == 0.0
            ? null
            : [
                BoxShadow(
                  color: shadowColor == AppColors.border
                      ? const Color(0x0F000000)
                      : shadowColor,
                  offset: Offset(0, shadowOffset / 2),
                  blurRadius: shadowOffset * 1.5,
                  spreadRadius: 0.0,
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }
    return cardContent;
  }
}

/// A tactile Neo-Brutalist button that shifts slightly when pressed down.
class NeoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double shadowOffset;
  final double width;
  final double height;
  final TextStyle? textStyle;
  final Color? borderColor;

  const NeoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.textColor = Colors.white,
    this.icon,
    this.shadowOffset = 4.0,
    this.width = double.infinity,
    this.height = 50.0,
    this.textStyle,
    this.borderColor,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.width,
        height: widget.height,
        transform: _isPressed && isEnabled
            ? Matrix4.translationValues(
                widget.shadowOffset / 2,
                widget.shadowOffset / 2,
                0,
              )
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isEnabled ? widget.backgroundColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? (widget.borderColor ?? widget.backgroundColor)
                : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: _isPressed || !isEnabled || widget.shadowOffset == 0.0
              ? []
              : [
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.15),
                    offset: Offset(0, widget.shadowOffset),
                    blurRadius: widget.shadowOffset * 2,
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: (widget.textStyle?.fontSize ?? 16) + 2,
                  color: isEnabled ? widget.textColor : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: isEnabled ? widget.textColor : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ).merge(widget.textStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A structured Text Field following the Neo-Brutalist design language.
class NeoTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool enabled;

  const NeoTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            enabled: enabled,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.textMuted, size: 20)
                  : null,
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.0,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
