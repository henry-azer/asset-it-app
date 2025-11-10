class PersonalLink {
  final String name;
  final String link;

  const PersonalLink({
    required this.name,
    required this.link,
  });
}

class PersonalLinks {
  static const List<PersonalLink> links = [
    PersonalLink(name: 'mail', link: 'mailto:henryazer@outlook.com'),
    PersonalLink(name: 'linkedin', link: 'https://www.linkedin.com/in/henry-azer'),
    PersonalLink(name: 'gitHub', link: 'https://github.com/henry-azer'),
    PersonalLink(name: 'facebook', link: 'https://www.facebook.com/henry.azer0'),
    PersonalLink(name: 'whatsApp', link: 'https://wa.me/201207885279'),
    PersonalLink(name: 'instagram', link: 'https://www.instagram.com/henry_azer'),

    PersonalLink(name: 'support-url', link: 'https://docs.google.com/forms/d/e/1FAIpQLSd0O2cl3-oreDnkc0TCqxjYL-y_mBCZnLTgIwg8wRKmCBvkuA/formResponse'),
    PersonalLink(name: 'support-name-entry', link: 'entry.485428648'),
    PersonalLink(name: 'support-subject-entry', link: 'entry.879531967'),
    PersonalLink(name: 'support-description-entry', link: 'entry.326955045'),

    PersonalLink(name: 'bug-reporting-url', link: 'https://docs.google.com/forms/d/e/1FAIpQLSdF9tzd8VD0V8cDeMFCkaOGgguIw5oiWSvFT4EZQjClzKn5_A/formResponse'),
    PersonalLink(name: 'bug-reporting-name-entry', link: 'entry.1263596795'),
    PersonalLink(name: 'bug-reporting-subject-entry', link: 'entry.1386997470'),
    PersonalLink(name: 'bug-reporting-description-entry', link: 'entry.326955045'),

    PersonalLink(name: 'rating-url', link: 'https://docs.google.com/forms/d/e/1FAIpQLSc30DiuLt9yw8Eo5vmBWOA3DQXt3cFQsgVpKBrNmddKv-SmMg/formResponse'),
    PersonalLink(name: 'rating-name-entry', link: 'entry.485428648'),
    PersonalLink(name: 'rating-rate-entry', link: 'entry.1696159737'),
    PersonalLink(name: 'rating-description-entry', link: 'entry.326955045'),
  ];

  static String? getByName(String name) {
    try {
      return links.firstWhere(
            (website) => website.name.toLowerCase() == name.toLowerCase(),
      ).link;
    } catch (e) {
      return null;
    }
  }
}
