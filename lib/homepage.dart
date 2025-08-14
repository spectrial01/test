import 'package:flutter/material.dart';
import 'devicecheck.dart'; // Import your DeviceCheck page

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});

  void _login(BuildContext context) {
    // Example login logic
    String email = emailController.text;
    String password = passwordController.text;

    if (email == "test@example.com" && password == "1234") {
      // Navigate to DeviceCheck page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DeviceCheckPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid credentials")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
