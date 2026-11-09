import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:attendy_sqlite/admin/screens/AdminHome.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/UserDBHelper.dart';
import '../../shared/screens/login.dart';

class AdminUpdateProfileScreen extends StatefulWidget {
  const AdminUpdateProfileScreen({super.key});

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<AdminUpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  Uint8List? _profilePictureBytes;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');
    String? profilePictureUrl = prefs.getString('profilePictureUrl');

    if (email != null) {
      _usernameController.text = username ?? '';
      _passwordController.text = password ?? '';
      if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
        _profilePictureBytes = base64Decode(profilePictureUrl);
      }
      setState(() {});
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      File imageFile = File(pickedImage.path);
      Uint8List? imageBytes = await _convertImageToByteArray(imageFile);
      setState(() {
        _profilePictureBytes = imageBytes;
      });
    }
  }

  Future<Uint8List?> _convertImageToByteArray(File imageFile) async {
    return await imageFile.readAsBytes();
  }

  Future<bool> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await UserDBHelper.instance.updateUser(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          profilePicture: _profilePictureBytes,
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _usernameController.text.trim());
        await prefs.setString('password', _passwordController.text);

        if (_profilePictureBytes != null) {
          String base64ProfilePicture = base64Encode(_profilePictureBytes!);
          await prefs.setString('profilePictureUrl', base64ProfilePicture);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
        );
        return true;
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
        return false;
      }
    }
    return false;
  }

  String? _validatePassword(String? value) {
    const passwordPattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$';
    final regex = RegExp(passwordPattern);
    if (value == null || !regex.hasMatch(value)) {
      return 'Password must be at least 6 characters long, include an uppercase letter, a number, and a special character';
    }
    return null;
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GestureDetector(
                onTap: _uploadImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePictureBytes != null
                      ? MemoryImage(_profilePictureBytes!)
                      : null,
                  child: _profilePictureBytes == null
                      ? const Icon(Icons.account_circle, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Update Profile'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
