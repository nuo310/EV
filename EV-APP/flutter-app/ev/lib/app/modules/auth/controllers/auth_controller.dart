import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final RxBool isAuthenticated = false.obs;
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userRole = 'user'.obs;
  final RxString authError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase auth changes to auto-update state
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        userEmail.value = user.email ?? '';
        isAuthenticated.value = true;
        
        // Fetch custom profile data from Firestore (like name & role)
        final profile = await _authService.getUserProfile(user.uid);
        if (profile != null) {
          userName.value = profile['name'] ?? user.displayName ?? 'User';
          userRole.value = profile['role'] ?? 'user';
        } else {
          userName.value = user.displayName ?? 'User';
          userRole.value = 'user';
        }
      } else {
        isAuthenticated.value = false;
        userName.value = '';
        userEmail.value = '';
        userRole.value = 'user';
      }
    });
  }

  // Sign In
  Future<bool> login(String email, String password) async {
    print('[AUTH CONTROLLER] 🚀 login() called with email: $email');
    authError.value = '';
    try {
      print('[AUTH CONTROLLER] 🔄 Calling _authService.login()...');
      final credential = await _authService.login(email, password);
      print('[AUTH CONTROLLER] ✅ login() successful');
      final user = credential.user;
      if (user != null) {
        userEmail.value = user.email ?? '';
        isAuthenticated.value = true;
        print('[AUTH CONTROLLER] 📧 User email set: ${user.email}');

        final profile = await _authService.getUserProfile(user.uid);
        if (profile != null) {
          userName.value = profile['name'] ?? user.displayName ?? 'User';
          userRole.value = profile['role'] ?? 'user';
        } else {
          userName.value = user.displayName ?? 'User';
          userRole.value = 'user';
        }
        print('[AUTH CONTROLLER] 👤 User name set: ${userName.value}, role: ${userRole.value}');
        
        print('[AUTH CONTROLLER] 🔄 Navigating to DASHBOARD...');
        Get.offAllNamed(Routes.DASHBOARD);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('[AUTH CONTROLLER] ❌ FirebaseAuthException: ${e.message}');
      authError.value = e.message ?? 'An error occurred during authentication';
      return false;
    } catch (e) {
      print('[AUTH CONTROLLER] ❌ Exception: $e');
      authError.value = e.toString();
      return false;
    }
  }

  // Sign Up
  Future<bool> signup(String name, String email, String password) async {
    print('[AUTH CONTROLLER] 🚀 signup() called with email: $email, name: $name');
    authError.value = '';
    final trimmedEmail = email.trim().toLowerCase();

    if (name.trim().isEmpty) {
      authError.value = 'Name cannot be empty';
      return false;
    }

    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      authError.value = 'Enter a valid email address';
      return false;
    }

    if (password.length < 6) {
      authError.value = 'Password must be at least 6 characters';
      return false;
    }

    try {
      print('[AUTH CONTROLLER] 🔄 Calling _authService.registerUser()...');
      final credential = await _authService.registerUser(
        name: name,
        email: email,
        password: password,
      );
      print('[AUTH CONTROLLER] ✅ signup() successful');
      
      final user = credential.user;
      if (user != null) {
        userName.value = name.trim();
        userEmail.value = user.email ?? trimmedEmail;
        isAuthenticated.value = true;
        userRole.value = email.trim().toLowerCase() == 'admin-ev@gmail.com' ? 'admin' : 'user';
        print('[AUTH CONTROLLER] 👤 User registered - name: ${userName.value}, email: ${userEmail.value}, role: ${userRole.value}');
        
        print('[AUTH CONTROLLER] 🔄 Navigating to DASHBOARD...');
        Get.offAllNamed(Routes.DASHBOARD);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('[AUTH CONTROLLER] ❌ FirebaseAuthException during signup: ${e.message}');
      authError.value = e.message ?? 'An error occurred during registration';
      return false;
    } catch (e) {
      print('[AUTH CONTROLLER] ❌ Exception during signup: $e');
      authError.value = e.toString();
      return false;
    }
  }

  // Sign In with Google
  Future<bool> loginWithGoogle() async {
    print('[AUTH CONTROLLER] 🚀 loginWithGoogle() called');
    authError.value = '';
    try {
      print('[AUTH CONTROLLER] 🔄 Calling _authService.signInWithGoogle()...');
      final credential = await _authService.signInWithGoogle();
      if (credential != null) {
        print('[AUTH CONTROLLER] ✅ Google login successful');
        final user = credential.user;
        if (user != null) {
          userEmail.value = user.email ?? '';
          isAuthenticated.value = true;
          print('[AUTH CONTROLLER] 📧 Google user email: ${user.email}');

          final profile = await _authService.getUserProfile(user.uid);
          if (profile != null) {
            userName.value = profile['name'] ?? user.displayName ?? 'Google User';
            userRole.value = profile['role'] ?? 'user';
          } else {
            userName.value = user.displayName ?? 'Google User';
            userRole.value = 'user';
          }
          print('[AUTH CONTROLLER] 👤 Google user name: ${userName.value}, role: ${userRole.value}');
          
          print('[AUTH CONTROLLER] 🔄 Navigating to DASHBOARD...');
          Get.offAllNamed(Routes.DASHBOARD);
          return true;
        }
      } else {
        print('[AUTH CONTROLLER] ⚠️ Google login returned null (user cancelled)');
      }
      return false;
    } catch (e) {
      print('[AUTH CONTROLLER] ❌ Exception during Google login: $e');
      authError.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    isAuthenticated.value = false;
    userName.value = '';
    userEmail.value = '';
    userRole.value = 'user';
    authError.value = '';
    Get.offAllNamed(Routes.LANDING);
  }
}

