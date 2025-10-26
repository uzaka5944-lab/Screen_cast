import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
// import 'share_screen.dart'; // We will use this file later

void main() {
  // Ensure that Flutter is ready before we run the app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Sharer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const CheckAuthScreen(),
    );
  }
}

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CheckAuthScreenState createState() =>
      _CheckAuthScreenState(); // Fixed lint warning
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Check if we have a password saved
    final password = await _storage.read(key: 'app_password');

    // We use context.mounted to make sure the widget is still on screen
    if (!context.mounted) return; // Added check here

    if (password == null) {
      // No password exists, go to LoginScreen in "create" mode
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(isCreatingPassword: true),
        ),
      );
    } else {
      // Password exists, go to LoginScreen in "login" mode
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(isCreatingPassword: false),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading circle while we check for the password
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
