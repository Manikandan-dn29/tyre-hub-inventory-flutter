import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../api.dart';

class UploadApi {
  static Future<String?> uploadImage(XFile image) async {
    final token = await Api.getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(Api.upload),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final res = await response.stream.bytesToString();
      return jsonDecode(res)['imagePath'];
    }
    return null;
  }
}
