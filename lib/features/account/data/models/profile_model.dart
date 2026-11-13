import 'package:shopping_app/core/constants/api_constants.dart';

class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String image;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.image,
  });

  static String formatImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    var url = rawUrl.trim();
    if (url.toLowerCase().contains('simple.jpg')) return '';
    if (url.startsWith('http://supermarket-dan1.onrender.com')) {
      url = url.replaceFirst('http://', 'https://');
    }
    // If the URL has /api/v1/images/, remove /api/v1 because static files are mounted at the root
    if (url.contains('/api/v1/images/')) {
      url = url.replaceFirst('/api/v1/images/', '/images/');
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final cleanPath = url.startsWith('/') ? url.substring(1) : url;
    if (cleanPath.startsWith('images/')) {
      final baseHost = ApiConstants.baseUrl.replaceAll('/api/v1', '');
      return '$baseHost/$cleanPath';
    }
    return '${ApiConstants.baseUrl}/$cleanPath';
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      image: formatImageUrl(json['image']?.toString()),
    );
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      image: formatImageUrl(map['image']?.toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'image': image,
    };
  }

  ProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? image,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      image: image ?? this.image,
    );
  }
}

