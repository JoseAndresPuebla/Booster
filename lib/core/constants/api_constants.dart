class ApiConstants {
  // Supabase Credentials
  static const String supabaseUrl = 'https://fqjmnuspqywhrqklrqnh.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFram1udXNwcXl3aHJxa2xycW5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwMTkzOTMsImV4cCI6MjEwODU5NTM5M30.NFeFqYN4g42drLkSdQFAq3BLbsWgSjcnJ3cFVSMKvIw';

  // Card APIs
  static const String scryfallBaseUrl = 'https://api.scryfall.com';
  static const String tcgdexBaseUrl = 'https://api.tcgdex.net/v2/en';
  static const String optcgApiBaseUrl = 'https://api.onepiece-cardgame.dev/api/v1';
  static const String riftboundDbBaseUrl = 'https://www.riftbound-db.com/api';

  // GitHub Auto-Updates
  static const String githubOwner = 'byjos';
  static const String githubRepo = 'Booster';
  static const String githubLatestReleaseUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  // Rules
  static const int dailyPacksPerGame = 2; // 2 free boosters per day per TCG
}
