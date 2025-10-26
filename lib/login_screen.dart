import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'share_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isCreatingPassword;
  const LoginScreen({super.key, required this.isCreatingPassword});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState(); // Fixed lint warning
}

class _LoginScreenState extends State<LoginScreen> {
  final _storage = const FlutterSecureStorage();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _message = '';

  @override
  void initState() {
    super.initState();
    // Set the initial message based on the mode
    if (widget.isCreatingPassword) {
      _message = 'Create a password to secure your app';
    } else {
      _message = 'Enter your password to unlock';
    }
  }

  Future<void> _handleButtonPress() async {
    if (widget.isCreatingPassword) {
      await _createPassword();
    } else {
      await _login();
    }
  }

  Future<void> _createPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _message = 'Fields cannot be empty';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _message = 'Passwords do not match';
      });
      return;
    }

    // Save the password securely
    await _storage.write(key: 'app_password', value: password);

    if (!context.mounted) return; // Added check here
    // Navigate to the main share screen
    _navigateToShareScreen();
  }

  Future<void> _login() async {
    final storedPassword = await _storage.read(key: 'app_password');
    final enteredPassword = _passwordController.text;

    if (enteredPassword.isEmpty) {
      setState(() {
        _message = 'Please enter your password';
      });
      return;
    }

    if (storedPassword == enteredPassword) {
      if (!context.mounted) return; // Added check here
      // Password is correct, navigate to the main share screen
      _navigateToShareScreen();
    } else {
      setState(() {
        _message = 'Incorrect password';
      });
    }
  }

  void _navigateToShareScreen() {
    // We use pushReplacement so the user can't press "back" to go to the login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ShareScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreatingPassword ? 'Set Up Password' : 'Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _message.contains('Incorrect') ||
                        _message.contains('match') ||
                        _message.contains('empty')
                    ? Colors.red
                    : Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.white, // Use theme color
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true, // Hides the password
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            // Only show the "Confirm Password" field if we are creating one
            if (widget.isCreatingPassword)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _handleButtonPress,
              child:
                  Text(widget.isCreatingPassword ? 'Create & Login' : 'Login'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
