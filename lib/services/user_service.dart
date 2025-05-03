import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


const String baseUrl = 'http://localhost/umkm_batik/API/'; // Base URL di sini

class UserService {
  //GET user detailakun
  static Future<User?> fetchUser(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}get_user.php?id=$id'),
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
  static Future<bool> updateUser(int id, String nama, String email, String noHp) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}update_user.php'),
        body: {
          'id': id.toString(),
          'nama': nama,
          'email': email,
          'no_hp': noHp,
        },
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
      Uri.parse('${baseUrl}register.php'),
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
  static Future<Map<String, dynamic>> login(String email, String password) async {
    String url = "${baseUrl}login.php";

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
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('role', 'user');
        await prefs.setInt('user_id', userId);
      }

      return data; // kembalikan responsenya
    } catch (e) {
      throw Exception('Gagal login: $e');
    }
  }
  
  
 static Future<void> toggleFavorite(int userId, int productId) async {
  try {
    final response = await http.post(
      Uri.parse('${baseUrl}toggle_favorite.php'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'product_id': productId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        print("Toggle favorite success. Favorited: ${data['favorited']}");
      } else {
        print("Gagal toggle favorite: ${data['message']}");
      }
    } else {
      print('HTTP error: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception saat toggle favorite: $e');
  }
}


  // GET FAVORITES
  static Future<Set<int>> getFavorites(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}get_favorite.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return Set<int>.from(data['favorites']);
        }
      }
    } catch (e) {
      print('Exception saat get favorites: $e');
    }
    return {};
  }

  static Future<List<int>> fetchFavorites(int userId) async {
  final response = await http.get(
    Uri.parse('${baseUrl}get_favorite.php?user_id=$userId'),
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

}
