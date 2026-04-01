import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class CustomPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onCountryChanged;
  final String initialCountryCode;
  final String hintText;
  final double height;
  final FocusNode? focusNode;

  const CustomPhoneField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onCountryChanged,
    this.initialCountryCode = 'IN',
    this.hintText = 'Enter Phone Number',
    this.height = 38,
  });

  @override
  State<CustomPhoneField> createState() => _CustomPhoneFieldState();
}

class _CustomPhoneFieldState extends State<CustomPhoneField> {
  late String _dialCode;
  late String _isoCode;

  @override
  void initState() {
    super.initState();
    // Default values based on initial selection (assuming IN for +91)
    _isoCode = widget.initialCountryCode;
    _dialCode = _getInitialDialCode(widget.initialCountryCode);
  }

  String _getInitialDialCode(String code) {
    if (code == 'IN') return '+91';
    return '+1'; // Default fallback
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // LEFT BOX: COUNTRY CODE + ISO CODE
        Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Visible custom text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_dialCode $_isoCode',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 14, color: Colors.black54),
                ],
              ),
              // Hidden picker trigger
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: 80,
                  child: IntlPhoneField(
                    initialCountryCode: widget.initialCountryCode,
                    onCountryChanged: (country) {
                      setState(() {
                        _dialCode = '+${country.dialCode}';
                        _isoCode = country.code;
                      });
                      if (widget.onCountryChanged != null) {
                        widget.onCountryChanged!(country.dialCode);
                      }
                    },
                    showCountryFlag: false,
                    showDropdownIcon: false,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // RIGHT BOX: PHONE NUMBER
        Expanded(
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFC4C4C4),
                  fontSize: 13,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF7067), width: 1.2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
