import 'package:flutter/material.dart';

enum AuthFieldType {
  email,
  password,
  confirmPassword,
  text,
  displayName,
}

class AuthFormField extends StatefulWidget {
  final TextEditingController controller;
  final AuthFieldType fieldType;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? helperText;
  final int? maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  const AuthFormField({
    super.key,
    required this.controller,
    required this.fieldType,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.keyboardType,
    this.helperText,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
  });

  @override
  State<AuthFormField> createState() => _AuthFormFieldState();
}

class _AuthFormFieldState extends State<AuthFormField> {
  bool _obscureText = false;
  late bool _isPasswordField;

  @override
  void initState() {
    super.initState();
    _isPasswordField = widget.fieldType == AuthFieldType.password ||
        widget.fieldType == AuthFieldType.confirmPassword;
    _obscureText = _isPasswordField;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  String get _defaultLabel {
    switch (widget.fieldType) {
      case AuthFieldType.email:
        return 'Email';
      case AuthFieldType.password:
        return 'Password';
      case AuthFieldType.confirmPassword:
        return 'Confirm Password';
      case AuthFieldType.displayName:
        return 'Display Name';
      case AuthFieldType.text:
        return 'Text';
    }
  }

  String get _defaultHint {
    switch (widget.fieldType) {
      case AuthFieldType.email:
        return 'Enter your email address';
      case AuthFieldType.password:
        return 'Enter your password';
      case AuthFieldType.confirmPassword:
        return 'Confirm your password';
      case AuthFieldType.displayName:
        return 'Enter your display name';
      case AuthFieldType.text:
        return 'Enter text';
    }
  }

  IconData get _defaultPrefixIcon {
    switch (widget.fieldType) {
      case AuthFieldType.email:
        return Icons.email_outlined;
      case AuthFieldType.password:
      case AuthFieldType.confirmPassword:
        return Icons.lock_outline;
      case AuthFieldType.displayName:
        return Icons.person_outline;
      case AuthFieldType.text:
        return Icons.text_fields_outlined;
    }
  }

  TextInputType get _defaultKeyboardType {
    switch (widget.fieldType) {
      case AuthFieldType.email:
        return TextInputType.emailAddress;
      case AuthFieldType.password:
      case AuthFieldType.confirmPassword:
        return TextInputType.visiblePassword;
      case AuthFieldType.displayName:
      case AuthFieldType.text:
        return TextInputType.text;
    }
  }

  TextCapitalization get _defaultTextCapitalization {
    switch (widget.fieldType) {
      case AuthFieldType.email:
        return TextCapitalization.none;
      case AuthFieldType.password:
      case AuthFieldType.confirmPassword:
        return TextCapitalization.none;
      case AuthFieldType.displayName:
        return TextCapitalization.words;
      case AuthFieldType.text:
        return TextCapitalization.sentences;
    }
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return '${widget.labelText ?? _defaultLabel} is required';
    }

    switch (widget.fieldType) {
      case AuthFieldType.email:
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Enter a valid email address';
        }
        break;
      case AuthFieldType.password:
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
          return 'Password must contain uppercase, lowercase, and number';
        }
        break;
      case AuthFieldType.confirmPassword:
        // Note: This would need the original password to compare
        // For now, just check if it's not empty
        break;
      case AuthFieldType.displayName:
        if (value.length < 2) {
          return 'Display name must be at least 2 characters';
        }
        if (value.length > 30) {
          return 'Display name must be less than 30 characters';
        }
        break;
      case AuthFieldType.text:
        // No specific validation for generic text
        break;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      validator: widget.validator ?? _defaultValidator,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType ?? _defaultKeyboardType,
      maxLines: _isPasswordField ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      textCapitalization: widget.textCapitalization != TextCapitalization.none
          ? widget.textCapitalization
          : _defaultTextCapitalization,
      autofocus: widget.autofocus,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText ?? _defaultLabel,
        hintText: widget.hintText ?? _defaultHint,
        helperText: widget.helperText,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        helperStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
        prefixIcon: Icon(
          widget.prefixIcon ?? _defaultPrefixIcon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        suffixIcon: _isPasswordField
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                onPressed: _toggleObscureText,
                splashRadius: 20,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        
        // Border styles - Normal state
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        
        // Border styles - Enabled state
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        
        // Border styles - Focused state
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.6),
            width: 2,
          ),
        ),
        
        // Border styles - Error state
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
        
        // Border styles - Focused error state
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
        
        // Border styles - Disabled state
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        
        // Error text styling
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        
        // Counter styling (for maxLength)
        counterStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 11,
        ),
      ),
    );
  }
}

// Helper class for creating common auth form fields
class AuthFormFields {
  static AuthFormField email({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    bool autofocus = false,
  }) {
    return AuthFormField(
      controller: controller,
      fieldType: AuthFieldType.email,
      labelText: labelText,
      hintText: hintText,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      autofocus: autofocus,
    );
  }

  static AuthFormField password({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    bool autofocus = false,
  }) {
    return AuthFormField(
      controller: controller,
      fieldType: AuthFieldType.password,
      labelText: labelText,
      hintText: hintText,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      autofocus: autofocus,
    );
  }

  static AuthFormField confirmPassword({
    required TextEditingController controller,
    required TextEditingController originalPasswordController,
    String? labelText,
    String? hintText,
    void Function(String)? onChanged,
    bool enabled = true,
  }) {
    return AuthFormField(
      controller: controller,
      fieldType: AuthFieldType.confirmPassword,
      labelText: labelText,
      hintText: hintText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != originalPasswordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      onChanged: onChanged,
      enabled: enabled,
    );
  }

  static AuthFormField displayName({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    bool autofocus = false,
  }) {
    return AuthFormField(
      controller: controller,
      fieldType: AuthFieldType.displayName,
      labelText: labelText,
      hintText: hintText,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      autofocus: autofocus,
    );
  }

  static AuthFormField text({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    TextInputType? keyboardType,
    int? maxLines,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    bool autofocus = false,
  }) {
    return AuthFormField(
      controller: controller,
      fieldType: AuthFieldType.text,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
    );
  }
}