import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart'; // Make sure this points to your Navigation Hub!

// This enum tracks exactly what screen the user is looking at
enum AuthMode { login, signup, forgotPassword, verifyOtp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;
  bool _isLoading = false;

  // Controllers for all our text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // NEW: Username
  final _otpController = TextEditingController(); // NEW: 6-Digit Code

  final Color _darkGreen = const Color.fromARGB(255, 18, 54, 45);
  final Color _brown = const Color.fromARGB(255, 91, 45, 23);
  final supabase = Supabase.instance.client;

  String? _validateAuthInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if ((_mode == AuthMode.login || _mode == AuthMode.signup) &&
        email.isEmpty) {
      return 'Email is required.';
    }

    if ((_mode == AuthMode.login || _mode == AuthMode.signup) &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    if (_mode == AuthMode.signup && name.isEmpty) {
      return 'Full name is required for sign up.';
    }

    if ((_mode == AuthMode.login ||
            _mode == AuthMode.signup ||
            _mode == AuthMode.verifyOtp) &&
        password.isEmpty) {
      return 'Password is required.';
    }

    if ((_mode == AuthMode.signup || _mode == AuthMode.verifyOtp) &&
        password.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before logging in.';
    }
    if (msg.contains('user already registered')) {
      return 'This email is already registered. Please log in.';
    }
    return e.message;
  }

  // --- LOGIC: Sign Up & Login ---
  Future<void> _submitAuth() async {
    if (_isLoading) return;

    final validationError = _validateAuthInputs();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_mode == AuthMode.login) {
        final response = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (response.session == null) {
          _showError(
              'Login failed. Please check your credentials and try again.');
          return;
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else if (_mode == AuthMode.signup) {
        final response = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {'name': _nameController.text.trim()},
        );

        if (response.session != null) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Sign up successful. Please check your email to confirm your account.'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() => _mode = AuthMode.login);
          }
        }
      }
    } on AuthException catch (e) {
      _showError(_mapAuthError(e));
    } catch (e) {
      _showError('Authentication failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: Send OTP to Email ---
  Future<void> _sendPasswordReset() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Email is required.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase.auth.resetPasswordForEmail(email);
      setState(() {
        _mode = AuthMode.verifyOtp; // Switch UI to ask for the 6-digit code
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('6-digit code sent to your email!'),
            backgroundColor: Colors.green),
      );
    } on AuthException catch (e) {
      _showError(_mapAuthError(e));
    } catch (e) {
      _showError('Could not send recovery code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: Verify OTP & Save New Password ---
  Future<void> _verifyOtpAndReset() async {
    if (_isLoading) return;

    final validationError = _validateAuthInputs();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    if (_otpController.text.trim().length != 6) {
      _showError('Please enter the 6-digit OTP code.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Verify the 6-digit code
      await supabase.auth.verifyOTP(
        type: OtpType.recovery,
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
      );

      // 2. If successful, update to the new password
      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      setState(() {
        _mode = AuthMode.login; // Send them back to login
        _passwordController.clear();
        _otpController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset successful! Please log in.'),
            backgroundColor: Colors.green),
      );
    } on AuthException catch (e) {
      _showError(_mapAuthError(e));
    } catch (e) {
      _showError('Invalid recovery code or password reset failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, size: 80, color: _darkGreen),
              const SizedBox(height: 16),
              Text(
                'Mitidawa',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: _brown),
              ),
              const SizedBox(height: 10),

              // Dynamic Title based on mode
              Text(
                _mode == AuthMode.login
                    ? "Welcome Back"
                    : _mode == AuthMode.signup
                        ? "Create an Account"
                        : _mode == AuthMode.forgotPassword
                            ? "Reset Password"
                            : "Enter Recovery Code",
                style: TextStyle(fontSize: 18, color: _darkGreen),
              ),
              const SizedBox(height: 30),

              // USERNAME FIELD (Only shows on Sign Up)
              if (_mode == AuthMode.signup) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
              ],

              // EMAIL FIELD (Shows on all screens EXCEPT Verify OTP)
              if (_mode != AuthMode.verifyOtp) ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
              ],

              // OTP FIELD (Only shows on Verify OTP)
              if (_mode == AuthMode.verifyOtp) ...[
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                      labelText: '6-Digit OTP Code',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 16),
              ],

              // PASSWORD FIELD (Shows on Login, Sign Up, and Verify OTP as the "New Password")
              if (_mode != AuthMode.forgotPassword) ...[
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                      labelText: _mode == AuthMode.verifyOtp
                          ? 'Enter New Password'
                          : 'Password',
                      border: const OutlineInputBorder()),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
              ],

              // FORGOT PASSWORD BUTTON (Only on Login screen)
              if (_mode == AuthMode.login)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _mode = AuthMode.forgotPassword),
                    child: Text('Forgot Password?',
                        style: TextStyle(color: _brown)),
                  ),
                ),

              const SizedBox(height: 16),

              // MAIN ACTION BUTTON
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkGreen,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    if (_mode == AuthMode.login || _mode == AuthMode.signup) {
                      _submitAuth();
                    }
                    if (_mode == AuthMode.forgotPassword) _sendPasswordReset();
                    if (_mode == AuthMode.verifyOtp) _verifyOtpAndReset();
                  },
                  child: Text(
                    _mode == AuthMode.login
                        ? 'Login'
                        : _mode == AuthMode.signup
                            ? 'Sign Up'
                            : _mode == AuthMode.forgotPassword
                                ? 'Send Recovery Code'
                                : 'Save New Password',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),

              // BOTTOM TOGGLE TEXT
              if (_mode == AuthMode.login || _mode == AuthMode.signup)
                TextButton(
                  onPressed: () => setState(() => _mode =
                      _mode == AuthMode.login
                          ? AuthMode.signup
                          : AuthMode.login),
                  child: Text(
                    _mode == AuthMode.login
                        ? 'Need an account? Sign up'
                        : 'Already have an account? Login',
                    style: TextStyle(color: _brown),
                  ),
                ),

              if (_mode == AuthMode.forgotPassword ||
                  _mode == AuthMode.verifyOtp)
                TextButton(
                  onPressed: () => setState(() => _mode = AuthMode.login),
                  child: Text('Back to Login', style: TextStyle(color: _brown)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
