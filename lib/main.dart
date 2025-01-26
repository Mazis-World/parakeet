import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  // Remove debug banner
      title: 'Parakeet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // White background for entire app
      ),
      home: const MainPage(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
      },
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(), // Pushes the row to the bottom
              Image.asset(
                'assets/perakeet_legacy.png',  // Ensure the path matches what you added in pubspec.yaml
                width: 330,
                height: 330,
              ),
              const Text(
                'Find your perfect pet-friendly companion.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),  // Pushes the row to the bottom
              const Text(
                '🇨🇦 Made in Canada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),  // Space between the flag text and the buttons

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Login'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: Colors.white, side: const BorderSide(color: Colors.black, width: 2),  // Black text
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      textStyle: const TextStyle(fontSize: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(200, 60),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Register'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.black, // White text
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      textStyle: const TextStyle(fontSize: 22),
                      minimumSize: const Size(200, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Login",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,  // Align to the left for the heading
          children: [
            // "Login" heading with clean font, big size, and separate words
            const Text(
              'Log In',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.normal,
                fontFamily: 'Roboto',  // Clean modern font
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            // Email input field with thick border and slight radius
            TextField(
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,  // Slight radius for a soft look
                  borderSide: const BorderSide(color: Colors.black, width: 4), // Thicker border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 3), // Thicker on focus
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password input field with thick border and slight radius
            TextField(
              obscureText: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,  // Slight radius
                  borderSide: const BorderSide(color: Colors.black, width: 4), // Thicker border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 3), // Thicker on focus
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login Button with glowing effect and square corners
            ElevatedButton(
              onPressed: () {
                // Handle login logic here
              },
              child: const Text(
                'LOG IN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18), // White text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),  // Slight radius
                ),
                minimumSize: const Size(double.infinity, 60), // Button spans across the screen
                side: const BorderSide(color: Colors.black, width: 3), // Thicker border
                shadowColor: Colors.black.withOpacity(0.4), // Soft shadow for a glowing effect
                elevation: 5, // Makes the button pop
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Register",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,  // Align to the left for the heading
          children: [
            // "Register" heading with clean font, big size, and separate words
            const Text(
              'Register',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.normal,
                fontFamily: 'Roboto',  // Clean modern font
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            // Email input field with thick border and slight radius
            TextField(
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,  // Slight radius for a soft look
                  borderSide: const BorderSide(color: Colors.black, width: 4), // Thicker border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 3), // Thicker on focus
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password input field with thick border and slight radius
            TextField(
              obscureText: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,  // Slight radius
                  borderSide: const BorderSide(color: Colors.black, width: 4), // Thicker border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 3), // Thicker on focus
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm password input field with thick border and slight radius
            TextField(
              obscureText: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Confirm your password',
                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,  // Slight radius
                  borderSide: const BorderSide(color: Colors.black, width: 4), // Thicker border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 3), // Thicker on focus
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Register Button with glowing effect and square corners
            ElevatedButton(
              onPressed: () {
                // Handle registration logic here
              },
              child: const Text(
                'SIGN UP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18), // White text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),  // Slight radius
                ),
                minimumSize: const Size(double.infinity, 60), // Button spans across the screen
                side: const BorderSide(color: Colors.black, width: 3), // Thicker border
                shadowColor: Colors.black.withOpacity(0.4), // Soft shadow for a glowing effect
                elevation: 5, // Makes the button pop
              ),
            ),
          ],
        ),
      ),
    );
  }
}