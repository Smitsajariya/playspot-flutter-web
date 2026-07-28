import 'package:url_launcher/url_launcher.dart';

class ShareUtils {
  static Future<void> shareGameOnWhatsApp({
    required String gameTitle,
    required String sport,
    required String location,
    String? gameId,
  }) async {
    final message = '''
🏆 $gameTitle
⚽ Sport: $sport
📍 Location: $location

Join now on PlaySpot!''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/?text=$encodedMessage';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    }
  }

  static Future<void> shareEventOnWhatsApp({
    required String eventTitle,
    required String category,
    required String location,
    required String date,
  }) async {
    final message = '''
🎉 $eventTitle
📅 Date: $date
📍 Location: $location

Don't miss it!''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/?text=$encodedMessage';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    }
  }
}
