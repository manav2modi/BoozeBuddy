// lib/models/citation.dart
class Citation {
  final String title;
  final String url;
  final String description;

  const Citation({
    required this.title,
    required this.url,
    required this.description,
  });
}

// Common health citations used in the app
class HealthCitations {
  static const Citation who = Citation(
      title: "World Health Organization (WHO)",
      url: "https://www.who.int/publications/i/item/9789240068254",
      description: "WHO guidelines on alcohol consumption (2024)"
  );

  static const Citation cdc = Citation(
      title: "Centers for Disease Control and Prevention (CDC)",
      url: "https://www.cdc.gov/alcohol/fact-sheets/moderate-drinking.htm",
      description: "CDC guidelines on moderate alcohol consumption"
  );

  static const Citation niaaa = Citation(
      title: "National Institute on Alcohol Abuse and Alcoholism (NIAAA)",
      url: "https://www.niaaa.nih.gov/alcohol-health/overview-alcohol-consumption/moderate-binge-drinking",
      description: "NIAAA guidelines on alcohol consumption limits"
  );

  static const Citation samhsa = Citation(
      title: "Substance Abuse and Mental Health Services Administration",
      url: "https://www.samhsa.gov/alcohol",
      description: "SAMHSA alcohol information and guidelines"
  );

  static const List<Citation> all = [who, cdc, niaaa, samhsa];
}