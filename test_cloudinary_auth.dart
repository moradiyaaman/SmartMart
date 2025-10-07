import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'lib/services/cloudinary_service.dart';

void main() async {
  final cloudName = CloudinaryService.cloudName;
  final apiKey = CloudinaryService.apiKey;
  final apiSecret = CloudinaryService.apiSecret;

  print('Using cloudName: ' + cloudName);
  print('Using apiKey: ' + (apiKey.length > 6 ? apiKey.substring(0,6) + '...' : apiKey));
  print('apiSecret length: ' + apiSecret.length.toString());

  final auth = base64.encode(utf8.encode('$apiKey:$apiSecret'));
  final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/ping');

  // Create an IOClient that accepts intercepted/self-signed certs (local dev only)
  final httpClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;
  final client = IOClient(httpClient);

  print('GET $url');
  final resp = await client.get(url, headers: {
    'Authorization': 'Basic $auth',
  });
  print('Status: ${resp.statusCode}');
  print('Body: ${resp.body}');
}