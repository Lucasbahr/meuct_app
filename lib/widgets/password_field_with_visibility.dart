import 'package:flutter/material.dart';

/// Campo de senha com ícone para alternar texto oculto/visível.
class PasswordFieldWithVisibility extends StatefulWidget {
  const PasswordFieldWithVisibility({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.style,
    this.decoration,
    this.textInputAction,
    this.onSubmitted,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final TextStyle? style;
  final InputDecoration? decoration;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final int? maxLines;

  @override
  State<PasswordFieldWithVisibility> createState() =>
      _PasswordFieldWithVisibilityState();
}

class _PasswordFieldWithVisibilityState
    extends State<PasswordFieldWithVisibility> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final base = widget.decoration ?? const InputDecoration();
    final expandedLines = widget.maxLines ?? 1;
    // TextField: obscureText exige maxLines == 1 (assert no SDK).
    final effectiveMaxLines = _obscure ? 1 : expandedLines;
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: widget.style,
      maxLines: effectiveMaxLines,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: base.copyWith(
        hintText: widget.hintText ?? base.hintText,
        labelText: widget.labelText ?? base.labelText,
        suffixIcon: IconButton(
          tooltip: _obscure ? "Mostrar senha" : "Ocultar senha",
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        ),
      ),
    );
  }
}
