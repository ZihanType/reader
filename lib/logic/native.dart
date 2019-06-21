import 'package:quiver/core.dart' show Optional;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

final Future<SharedPreferences> _preferences = SharedPreferences.getInstance();

Future<Optional<String>> getString(String key) async {
  return Optional.fromNullable(
    (await _preferences).getString(key),
  );
}

Future<bool> setString(String key, String value) async {
  return await (await _preferences).setString(key, value);
}
