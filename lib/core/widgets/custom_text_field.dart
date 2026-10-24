import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool password;
  final String? Function(String?)? validator;
  const CustomTextField(
      {super.key,
      required this.label,
      required this.controller,
      this.prefixIcon,
      this.keyboardType = TextInputType.text,
      this.password = false,
      this.validator});
  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool obscure = true;
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: widget.password && obscure,
        validator: widget.validator,
        decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon:
                widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
            suffixIcon: widget.password
                ? IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined))
                : null),
      );
}
