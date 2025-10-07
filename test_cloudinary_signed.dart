import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'lib/services/cloudinary_service.dart';

void main() async {
  print('=== Testing SIGNED Cloudinary Upload ===');

  final String cloudName = CloudinaryService.cloudName;
  final String apiKey = CloudinaryService.apiKey;
  final String apiSecret = CloudinaryService.apiSecret;

  // Build a 1x1 PNG
  final png = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
    0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C,
    0x63, 0x60, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01,
    0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00,
    0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  try {
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    final paramsToSign = 'timestamp=$timestamp';
    final signature = sha1.convert('$paramsToSign$apiSecret'.codeUnits).toString();

    // IOClient that accepts intercepted/self-signed certs (local dev only)
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final io = IOClient(httpClient);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    );

    request.fields['api_key'] = apiKey;
    request.fields['timestamp'] = timestamp;
    request.fields['signature'] = signature;

    request.files.add(http.MultipartFile.fromBytes('file', png, filename: 'unit.png'));

    print('POST https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    print('Fields: ' + request.fields.toString());

  final resp = await io.send(request);
    final body = await resp.stream.bytesToString();

    print('Status: ${resp.statusCode}');
    print('Body: $body');

    if (resp.statusCode == 200) {
      final jsonResp = json.decode(body);
      print('SUCCESS URL: ${jsonResp['secure_url']}');
    }
  } catch (e, st) {
    print('Error: $e');
    print(st);
  }
}
