import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:injectable/injectable.dart';
import 'package:shopping_app/core/constants/api_constants.dart';
import 'package:shopping_app/core/local_storage/cache_helper.dart';
import 'package:shopping_app/features/account/data/models/profile_model.dart';

@injectable
class UserRemoteDataSource {
  final http.Client client;

  UserRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = CacheHelper.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<ProfileModel> getUserData() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userData}');
    final response = await client.get(url, headers: _buildHeaders());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('message') && data['message'] is Map) {
        return ProfileModel.fromJson(data['message'] as Map<String, dynamic>);
      }
      throw Exception('Unexpected profile data format');
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  Future<String> editUserData({
    required String name,
    required String phone,
    required String address,
    String? image,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.editUserData}');
    final body = jsonEncode({
      'name': name,
      'phone': phone,
      'address': address,
      if (image != null && image.isNotEmpty) 'image': image,
    });

    final response = await client.post(url, headers: _buildHeaders(), body: body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      final msg = data is Map ? (data['message']?.toString() ?? 'Profile updated successfully!') : 'Profile updated successfully!';
      return msg;
    } else {
      final data = _safeDecodeBody(response.body);
      final errMsg = data is Map ? (data['message']?.toString() ?? 'Failed to update profile') : 'Failed to update profile';
      throw Exception(errMsg);
    }
  }

  /// Helper to determine image MIME type from byte signatures or file extension.
  static MediaType resolveMediaType({List<int>? bytes, String? nameOrPath}) {
    // 1. Check byte magic numbers if available
    if (bytes != null && bytes.length >= 4) {
      // PNG: 89 50 4E 47
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return MediaType('image', 'png');
      }
      // JPEG: FF D8 FF
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return MediaType('image', 'jpeg');
      }
      // GIF: 47 49 46
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return MediaType('image', 'gif');
      }
    }

    // 2. Check filename / path extension
    if (nameOrPath != null && nameOrPath.isNotEmpty) {
      final clean = nameOrPath.toLowerCase().split('?').first;
      if (clean.endsWith('.png')) {
        return MediaType('image', 'png');
      }
      if (clean.endsWith('.jpg') || clean.endsWith('.jpeg')) {
        return MediaType('image', 'jpeg');
      }
      if (clean.endsWith('.gif')) {
        return MediaType('image', 'gif');
      }
      if (clean.endsWith('.webp')) {
        return MediaType('image', 'webp');
      }
    }

    // 3. Fallback to image/jpeg
    return MediaType('image', 'jpeg');
  }

  /// Upload image file to the backend and return the resulting image URL.
  Future<String> uploadImage(String filePath, {List<int>? fileBytes, String? fileName}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.addImage}');
    final token = CacheHelper.getToken();

    final request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // The backend uses Multer expecting the field name 'file' with an image MIME type
    final mediaType = resolveMediaType(bytes: fileBytes, nameOrPath: fileName ?? filePath);
    final ext = mediaType.subtype == 'png' ? 'png' : 'jpg';
    final resolvedFileName = (fileName != null && fileName.isNotEmpty)
        ? fileName
        : 'profile.$ext';

    if (fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: resolvedFileName,
        contentType: mediaType,
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: mediaType,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map) {
        if (data['image'] != null && data['image'].toString().isNotEmpty) {
          return ProfileModel.formatImageUrl(data['image'].toString());
        }
        if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
          return ProfileModel.formatImageUrl(data['imageUrl'].toString());
        }
        if (data['url'] != null && data['url'].toString().isNotEmpty) {
          return ProfileModel.formatImageUrl(data['url'].toString());
        }
        // When backend returns {"message": "image added successfully"}, fetch the updated user profile
        try {
          final profile = await getUserData();
          if (profile.image.isNotEmpty) {
            return profile.image;
          }
        } catch (_) {}

        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty && !msg.toLowerCase().contains('success')) {
          return msg;
        }
      }
      final profile = await getUserData();
      return profile.image;
    } else {
      final data = _safeDecodeBody(response.body);
      final errMsg = data is Map ? (data['message']?.toString() ?? 'Failed to upload image') : 'Failed to upload image';
      throw Exception(errMsg);
    }
  }

  dynamic _safeDecodeBody(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
