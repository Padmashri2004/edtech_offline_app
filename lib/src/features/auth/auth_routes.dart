import 'presentation/login_screen.dart';
import 'presentation/signup_screen.dart';
import 'presentation/forgot_password_screen.dart';

final authRoutes = {
  '/login': (context) => LoginScreen(),
  '/signup': (context) => SignupScreen(),
  '/forgot': (context) => ForgotPasswordScreen(),
};
