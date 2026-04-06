class Validators {
  static bool isValidName(String name) {
    return name.length >= 3 && RegExp(r"^[a-zA-ZÀ-ÿ\s]+$").hasMatch(name);
  }

  static bool isValidEmail(String email) {
    return RegExp(r"^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  static String? passwordError(String password) {
    if (password.length < 8) return 'Min 8 caractères';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Une majuscule requise';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Une minuscule requise';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Un chiffre requis';
    // Utilisation d'une classe de caractères plus simple pour les symboles
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Un symbole requis';
    return null;
  }

  static bool isValidPassword(String password) => passwordError(password) == null;

}