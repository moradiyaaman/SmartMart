import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String cloudName = 'diezuelfi';
  static const String apiKey = '494137376494571';
  static const String apiSecret = 'pEZSEQNlgDs_HsauxrB2ajzGtDQ';
  
  static bool isConfigured() {
    return cloudName.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;
  }

  static Future<String?> uploadProductImage(File imageFile) async {
    print('CloudinaryService: Starting SIGNED upload');
    
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final paramsToSign = 'timestamp=$timestamp';
      final signature = sha1.convert('$paramsToSign$apiSecret'.codeUnits).toString();
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload')
      );
      
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp;
      request.fields['signature'] = signature;
      
      var fileBytes = await imageFile.readAsBytes();
      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      print('Response status: ${response.statusCode}');
      print('Response body: $responseData');
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Upload failed: $responseData');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to upload image: $e');
    }
  }
}