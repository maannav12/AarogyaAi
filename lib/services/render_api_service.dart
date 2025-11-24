import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RenderApiService {
  static const String _baseUrl = 'https://mri-model-b5oz.onrender.com';

  // Upload image and get prediction
  Future<Map<String, dynamic>?> uploadImage(File image, String modelType) async {
    try {
      // Found the correct endpoint: /api/predict
      var uri = Uri.parse('$_baseUrl/api/predict'); 
      
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      request.fields['model_type'] = modelType;

      // Send the request with a timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Connection timed out. Please check your internet connection.');
        },
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse the JSON response
        return json.decode(response.body);
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception calling Render API: $e');
      return null;
    }
  }
}
