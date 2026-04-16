/// Global network service locator
import 'api_client.dart';
import 'api_config.dart';

/// Global API client instance
/// Initialized in main.dart before runApp
late ApiClient apiClient;

/// Initialize the global API client
void initializeApiClient({String? baseUrl}) {
  apiClient = ApiClient(baseUrl: baseUrl ?? ApiConfig.apiBaseUrl);
}

/// Get player ID from storage
/// Key: 'player_id'
String? getPlayerId() {
  // This is a placeholder - actual implementation uses SharedPreferences
  // which must be accessed asynchronously
  return null;
}
