class Validators {
  //verifie le nom (min 3 lettres et symboles simples)
  static String? nameError(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Le nom est requis';
    if (clean.length < 3) return 'Min 3 caractères';
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-\']+$").hasMatch(clean)) {
      return 'Caractères invalides (lettres, espaces, tirets uniquement)';
    }
    return null;
  }

  static bool isValidName(String name) => nameError(name) == null;

  //format email standard
  static bool isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email.trim());
  }

  //force un mdp costaud (maj, min, chiffre, symbole)
  static String? passwordError(String password) {
    if (password.length < 8) return 'Min 8 caractères';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Une majuscule requise';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Une minuscule requise';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Un chiffre requis';
    if (!password.contains(RegExp(r'[^a-zA-Z0-9]'))) return 'Un symbole requis';
    return null;
  }

  static bool isValidPassword(String password) => passwordError(password) == null;

  //nettoie et verifie les numéros Madagascar
  static String? phoneError(String phone) {
    if (phone.trim().isEmpty) return null;
    final digits = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    String local = digits;
    if (local.startsWith('+261')) {
      local = '0${local.substring(4)}';
    } else if (local.startsWith('261') && local.length == 12) {
      local = '0${local.substring(3)}';
    }

    if (!RegExp(r'^\d+$').hasMatch(local)) {
      return 'Numéro invalide (chiffres uniquement)';
    }
    if (local.length != 10) {
      return 'Le numéro doit contenir 10 chiffres (ex: 034 XX XXX XX)';
    }
    
    //verifie les prefixes malgaches (032, 034, 020...)
    if (!RegExp(r'^0(3[2-9]|20)\d{7}$').hasMatch(local)) {
      return 'Indicatif invalide (032, 033, 034, 038…)';
    }
    return null;
  }

  static bool isValidPhone(String phone) => phoneError(phone) == null;
}