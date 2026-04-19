import 'package:flutter/material.dart';

abstract final class ListingConstants {
  // ── Constantes d'upload ──────────────────────────────────────────────────
  static const int maxImages = 8;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  //toutes les categories qu'on affiche dans les menus de selection
  static const List<Map<String, dynamic>> categories = [
    {'label': 'Études', 'value': 'etudes', 'icon': Icons.menu_book},
    {'label': 'Mode', 'value': 'mode', 'icon': Icons.checkroom},
    {'label': 'Électronique', 'value': 'electronique', 'icon': Icons.devices},
    {'label': 'Maison', 'value': 'maison', 'icon': Icons.chair},
    {'label': 'Tricycle', 'value': 'tricycle', 'icon': Icons.electric_rickshaw},
    {'label': 'Loisirs', 'value': 'loisirs', 'icon': Icons.sports_esports},
    {'label': 'Sport', 'value': 'sport', 'icon': Icons.sports_soccer},
    {'label': 'Meubles', 'value': 'meubles', 'icon': Icons.bed},
    {'label': 'Livres', 'value': 'livres', 'icon': Icons.book},
    {'label': 'Autre', 'value': 'autre', 'icon': Icons.category},
  ];

  //les differents choix pour l'etat de l'article
  static const List<String> conditions = [
    'Neuf',
    'Très bon état',
    'Bon état',
    'État moyen',
  ];
}