import 'dart:typed_data';

/// Shared input checks for every form in the app, so untrusted input is
/// validated the same way everywhere (MASVS-CODE: validate untrusted input).
class InputValidation {
  InputValidation._();

  static const maxNameLength = 100;
  static const maxEmailLength = 254;
  static const maxPhoneLength = 20;
  static const maxNotesLength = 1000;

  static final _email = RegExp(r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$");
  // Letters (any language), spaces, and the punctuation real names use.
  static final _name = RegExp(r"^[\p{L}\p{M} .'\-]+$", unicode: true);
  // Digits with optional +, spaces, dashes and parentheses, e.g.
  // 09171234567, +63 917 123 4567, (042) 545-9244.
  static final _phone = RegExp(r'^\+?[0-9 ()\-]{7,20}$');

  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Please enter your email.';
    if (s.length > maxEmailLength || !_email.hasMatch(s)) {
      return 'Please enter a valid email.';
    }
    return null;
  }

  static String? phone(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Please enter your contact number.';
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (!_phone.hasMatch(s) || digits.length < 7 || digits.length > 15) {
      return 'Please enter a valid contact number.';
    }
    return null;
  }

  /// [required] false lets an empty value through (e.g. suffix).
  static String? name(String? v, {bool required = true}) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return required ? 'Required' : null;
    if (s.length > maxNameLength) return 'Too long';
    if (!_name.hasMatch(s)) return 'Letters only';
    return null;
  }

  static const maxAddressLength = 500; // church-web: address max:500
  static const maxPasswordLength = 128;

  /// For new passwords (register / reset). church-web only requires 8+
  /// characters; the app also asks for a letter and a number.
  static String? newPassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'At least 8 characters';
    if (s.length > maxPasswordLength) return 'Too long';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'[0-9]').hasMatch(s)) {
      return 'Use at least one letter and one number';
    }
    return null;
  }

  static String? address(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Address is required';
    if (s.length > maxAddressLength) return 'Too long';
    return null;
  }

  static String? message(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Please enter a message.';
    if (s.length > maxNotesLength) return 'Please keep this under $maxNotesLength characters.';
    return null;
  }

  static String? notes(String? v) {
    final s = v?.trim() ?? '';
    if (s.length > maxNotesLength) return 'Please keep this under $maxNotesLength characters.';
    return null;
  }

  // -- Uploaded documents -------------------------------------------------

  static const maxUploadBytes = 5 * 1024 * 1024; // 5MB, same as church-web
  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  /// Checks an uploaded document by its actual contents, not just its file
  /// extension (a renamed .exe is still rejected). Returns an error message,
  /// or null if the file is acceptable.
  static String? document(String name, Uint8List bytes) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (!allowedExtensions.contains(ext)) {
      return 'Only PDF, JPG or PNG files are allowed.';
    }
    if (bytes.isEmpty) return 'That file is empty.';
    if (bytes.length > maxUploadBytes) return 'Files must be 5MB or smaller.';
    final ok = switch (ext) {
      'pdf' => _startsWith(bytes, const [0x25, 0x50, 0x44, 0x46]), // %PDF
      'png' => _startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47]),
      _ => _startsWith(bytes, const [0xFF, 0xD8, 0xFF]), // jpg / jpeg
    };
    return ok ? null : "That file doesn't look like a real PDF, JPG or PNG.";
  }

  /// Storage object names: keeps letters, digits, dot, dash and underscore
  /// only, so a crafted file name can't inject path segments.
  static String safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._\-]'), '_');
    final trimmed = cleaned.length > 80 ? cleaned.substring(cleaned.length - 80) : cleaned;
    return trimmed.isEmpty ? 'document' : trimmed;
  }

  static bool _startsWith(Uint8List bytes, List<int> magic) {
    if (bytes.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }
}
