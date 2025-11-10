class PopularWebsite {
  final String name;
  final String domain;

  const PopularWebsite({
    required this.name,
    required this.domain,
  });

  String get url => 'https://www.$domain';
  
  String get faviconUrl => 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
}

class PopularWebsites {
  static const List<PopularWebsite> websites = [
    PopularWebsite(name: 'Google', domain: 'google.com'),
    PopularWebsite(name: 'Facebook', domain: 'facebook.com'),
    PopularWebsite(name: 'Twitter', domain: 'twitter.com'),
    PopularWebsite(name: 'LinkedIn', domain: 'linkedin.com'),
    PopularWebsite(name: 'Instagram', domain: 'instagram.com'),
    PopularWebsite(name: 'GitHub', domain: 'github.com'),
    PopularWebsite(name: 'Microsoft', domain: 'microsoft.com'),
    PopularWebsite(name: 'Amazon', domain: 'amazon.com'),
    PopularWebsite(name: 'Netflix', domain: 'netflix.com'),
    PopularWebsite(name: 'Spotify', domain: 'spotify.com'),
    PopularWebsite(name: 'Dropbox', domain: 'dropbox.com'),
    PopularWebsite(name: 'Reddit', domain: 'reddit.com'),
    PopularWebsite(name: 'Pinterest', domain: 'pinterest.com'),
    PopularWebsite(name: 'TikTok', domain: 'tiktok.com'),
    PopularWebsite(name: 'YouTube', domain: 'youtube.com'),
    PopularWebsite(name: 'Slack', domain: 'slack.com'),
    PopularWebsite(name: 'Discord', domain: 'discord.com'),
    PopularWebsite(name: 'Twitch', domain: 'twitch.tv'),
    PopularWebsite(name: 'PayPal', domain: 'paypal.com'),
    PopularWebsite(name: 'Apple', domain: 'apple.com'),
    PopularWebsite(name: 'WhatsApp', domain: 'whatsapp.com'),
    PopularWebsite(name: 'Telegram', domain: 'telegram.org'),
    PopularWebsite(name: 'Steam', domain: 'steampowered.com'),
    PopularWebsite(name: 'Epic Games', domain: 'epicgames.com'),
    PopularWebsite(name: 'Adobe', domain: 'adobe.com'),
    PopularWebsite(name: 'Zoom', domain: 'zoom.us'),
    PopularWebsite(name: 'Gmail', domain: 'gmail.com'),
    PopularWebsite(name: 'Outlook', domain: 'outlook.com'),
    PopularWebsite(name: 'Yahoo', domain: 'yahoo.com'),
    PopularWebsite(name: 'WordPress', domain: 'wordpress.com'),
  ];

  static List<PopularWebsite> search(String query) {
    if (query.isEmpty) return websites;
    
    final lowerQuery = query.toLowerCase();
    return websites.where((website) {
      return website.name.toLowerCase().contains(lowerQuery) ||
             website.domain.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  static PopularWebsite? getByName(String name) {
    try {
      return websites.firstWhere(
        (website) => website.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static PopularWebsite createCustom(String name) {
    final domain = _generateDomain(name);
    return PopularWebsite(name: name, domain: domain);
  }

  static String _generateDomain(String name) {
    final cleaned = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '');
    return '$cleaned.com';
  }

  static String getFaviconUrl(String nameOrDomain) {
    final existing = getByName(nameOrDomain);
    if (existing != null) {
      return existing.faviconUrl;
    }

    try {
      final uri = Uri.parse(nameOrDomain.contains('://') 
          ? nameOrDomain 
          : 'https://$nameOrDomain');
      final domain = uri.host.isNotEmpty ? uri.host : nameOrDomain;
      return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
    } catch (e) {
      final domain = nameOrDomain.contains('.')
          ? nameOrDomain 
          : '$nameOrDomain.com';
      return 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
    }
  }
}
