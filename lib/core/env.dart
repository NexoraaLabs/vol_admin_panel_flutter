// Live Railway API by default. Pass --dart-define=API_URL=http://localhost:4000 to use a local API.
const _apiUrl = String.fromEnvironment('API_URL');

final String apiUrl = _apiUrl.isNotEmpty ? _apiUrl : 'https://volwebapp-production.up.railway.app';
