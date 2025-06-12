import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


const String baseUrl = 'http://192.168.70.254:8000/api/'; // Base URL di sini

class UserService {
  //GET user detailakun
  static Future<User?> fetchUser(int id) async {
    try {
            final response = await http.get(
        Uri.parse('${baseUrl}user/$id'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success']) {
          return User.fromJson(jsonResponse['data']);
        } else {
          print('Gagal: ${jsonResponse['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception saat ambil user: $e');
    }
    return null;
  }

  //update_user
  static Future<bool> updateUser(
      int id, String nama, String email, String noHp) async {
    try {
            final response = await http.put(
        Uri.parse('${baseUrl}user/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'no_hp': noHp,
        }),
      );


      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success']) {
          return true;
        } else {
          print(jsonResponse['message']);
          return false;
        }
      } else {
        print('Server Error saat update');
        return false;
      }
    } catch (e) {
      print('Exception saat update user: $e');
      return false;
    }
  }

  // register
 static Future<Map<String, dynamic>> registerUser({
  required String nama,
  required String email,
  required String noHp,
  required String password,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${baseUrl}register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'no_hp': noHp,
        'password': password,
        'role': 'user',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'error': true, 'message': 'Server error'};
    }
  } catch (e) {
    print('Exception saat register: $e');
    return {'error': true, 'message': 'Terjadi kesalahan.'};
  }
}


  //login
  static Future<Map<String, dynamic>> login(
    String email, String password) async {
  String url = "${baseUrl}login";

  try {
    var response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
    

    var data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['error'] == false) {
  final userId = data['user']['id'];
  final userRole = data['user']['role'];

  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isLoggedIn', true);
  await prefs.setInt('user_id', userId);
  await prefs.setString('role', userRole); // jangan hardcoded
}


    return data;
  } catch (e) {
    throw Exception('Gagal login: $e');
  }
}


  // lupa_password
  static Future<Map<String, dynamic>> lupaPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}lupa_password.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': true, 'message': 'Server error'};
      }
    } catch (e) {
      print('Exception saat lupa password: $e');
      return {'error': true, 'message': 'Terjadi kesalahan.'};
    }
  }

  //cek_otp
  static Future<Map<String, dynamic>> cekOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}cek_otp.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': true, 'message': 'Server error'};
      }
    } catch (e) {
      print('Exception saat cek OTP: $e');
      return {'error': true, 'message': 'Terjadi kesalahan.'};
    }
  }

  // ganti_password
  static Future<Map<String, dynamic>> gantiPassword(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}ganti_password.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': true, 'message': 'Server error'};
      }
    } catch (e) {
      print('Exception saat ganti password: $e');
      return {'error': true, 'message': 'Terjadi kesalahan.'};
    }
  }

  // TOGGLE FAVORITE - Updated untuk Laravel endpoint
  static Future<bool> toggleFavorite(int userId, int productId) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}favorites/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'product_id': productId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['favorited'] ?? false;
        }
      } else if (response.statusCode == 422) {
        // Validation error
        final data = jsonDecode(response.body);
        print('Validation Error: ${data['errors']}');
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Exception saat toggle favorite: $e');
    }
    return false;
  }

  // GET FAVORITES
   static Future<Set<int>> getFavorites(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}favorites/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Convert List<dynamic> to Set<int>
          List<dynamic> favoritesList = data['favorites'];
          return favoritesList.map<int>((e) => int.parse(e.toString())).toSet();
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Exception saat get favorites: $e');
    }
    return <int>{};
  }

  static Future<List<int>> fetchadd_alamats(int userId) async {
    final response = await http.get(
      Uri.parse('${baseUrl}get_user.php?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        List favorites = data['favorites'];
        return favorites.cast<int>().toList();
      }
    }
    return [];
  }

  //fetch Favorites
  static Future<List<int>> fetchFavorites(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}favorites/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          List<dynamic> favorites = data['favorites'];
          return favorites.map<int>((e) => int.parse(e.toString())).toList();
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Exception saat fetch favorites: $e');
    }
    return <int>[];
  }
}
