import 'dart:convert' show utf8;
import 'dart:io' show HttpClient, HttpClientRequest, HttpClientResponse;

final HttpClient _httpClient = HttpClient();

Future<String> getResponseBody(String url) async {
  final HttpClientRequest request = await _httpClient.getUrl(Uri.parse(url));
  final HttpClientResponse response = await request.close();
  final String rawResponseBody = await response.transform(utf8.decoder).join();
  final String responseBody =
      rawResponseBody.replaceAll('\n', '').replaceAll('\r', '');

  return responseBody;
}
