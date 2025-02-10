import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parakeet/dash.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the auth state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong!'));
        } else if (snapshot.hasData) {
          // If the user is logged in, go to the Dashboard
          return const DashboardScreen();
        } else {
          // If the user is not logged in, show the Login Screen
          return const LoginScreen();
        }
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
                ' 🍁 Made in Canada',
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
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method for handling login
  Future<void> _login() async {
    try {
      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If login is successful, show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful!')),
      );
      Navigator.pushReplacementNamed(context, '/dashboard');

      // You can navigate to the next screen here, for example:
      // Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      // Handle errors if login fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.message}')),
      );
    }
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Log In',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.normal,
                fontFamily: 'Roboto',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            // Email input field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Password input field
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Login Button
            ElevatedButton(
              onPressed: _login,  // Calls the login function
              child: const Text(
                'LOG IN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size(double.infinity, 60),
                side: const BorderSide(color: Colors.black, width: 3),
                shadowColor: Colors.black.withOpacity(0.4),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method for handling registration
  Future<void> _register() async {
    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      // Create a user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If registration is successful, show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful!')),
      );
      Navigator.pushReplacementNamed(context, '/dashboard');

      // Navigate to the next screen, e.g., Home screen:
      // Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      // Handle errors (e.g., weak password, email already in use)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Failed: ${e.message}')),
      );
    }
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Register',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.normal,
                fontFamily: 'Roboto',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            // Email input field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter your email',
                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password input field
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm password input field
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Confirm your password',
                hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: const BorderSide(color: Colors.black, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Register Button
            ElevatedButton(
              onPressed: _register,  // Calls the registration function
              child: const Text(
                'SIGN UP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size(double.infinity, 60),
                side: const BorderSide(color: Colors.black, width: 3),
                shadowColor: Colors.black.withOpacity(0.4),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}