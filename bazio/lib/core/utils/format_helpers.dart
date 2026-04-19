//date lisible genre il y a 5mn
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}mn';
  if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
  return 'il y a ${diff.inDays}j';
}

//prix avec espaces genre 1 000 000
String formatPrice(double price) {
  final int p = price.toInt();
  return p.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]} ',
  );
}