import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../medicine/medicine_model.dart';

class MedicineApiService {
  static const String _baseUrl = 'https://medicine-analyzer-gzi6.onrender.com';

  Future<MedicineModel?> analyzeMedicine(File image) async {
    try {
      // The deployed medicine analyzer API uses /analyze endpoint
      var uri = Uri.parse('$_baseUrl/analyze'); 
      
      var request = http.MultipartRequest('POST', uri);      
      request.files.add(await http.MultipartFile.fromPath('file', image.path)); 

      // Send the request with a timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Connection timed out. Please check your internet connection.');
        },
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return MedicineModel.fromMap(data);
      } else {
        print('Medicine API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception calling Medicine API: $e');
      return null;
    }
  }
}
