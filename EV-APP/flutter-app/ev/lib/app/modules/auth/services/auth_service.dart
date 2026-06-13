import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Listen to Auth State Changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Logs in a user using email & password
  Future<UserCredential> login(String email, String password) async {
    print('[AUTH] 🔐 Starting email/password login for: $email');
    
    try {
      final trimmedEmail = email.trim().toLowerCase();
      print('[AUTH] 📧 Trimmed email: $trimmedEmail');
      
      print('[AUTH] 🔄 Calling Firebase Auth signInWithEmailAndPassword...');
      final credential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      print('[AUTH] ✅ Firebase Auth login successful. User UID: ${credential.user?.uid}');
      
      // Verify user exists in Firestore, create if not
      final user = credential.user;
      if (user != null) {
        print('[AUTH] 📂 Checking Firestore for user profile...');
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          print('[AUTH] 📝 Creating new Firestore profile for user: ${user.uid}');
          // Create user profile if doesn't exist
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': trimmedEmail,
            'walletBalance': 100.0,
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('[AUTH] ✅ Firestore profile created');
        } else {
          print('[AUTH] ✅ Firestore profile exists');
        }
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      print('[AUTH] ❌ FirebaseAuthException: code=${e.code}, message=${e.message}');
      // Provide clearer error messages
      if (e.code == 'user-not-found') {
        print('[AUTH] ❌ User not found in Firebase Auth');
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found with this email. Please sign up first using the Sign up button below.',
        );
      } else if (e.code == 'wrong-password') {
        print('[AUTH] ❌ Wrong password provided');
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Incorrect password. Please try again.',
        );
      } else if (e.code == 'invalid-email') {
        print('[AUTH] ❌ Invalid email format');
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email address format.',
        );
      }
      print('[AUTH] ❌ Re-throwing FirebaseAuthException');
      rethrow;
    } catch (e) {
      print('[AUTH] ❌ Unexpected error during login: $e');
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Login failed. Please try again.',
      );
    }
  }
  
  /// Login with demo account for testing
  Future<UserCredential> loginWithDemoAccount() async {
    const demoEmail = 'demo@evapp.com';
    const demoPassword = 'demo123';
    
    try {
      // Try to login with demo account
      return await login(demoEmail, demoPassword);
    } catch (e) {
      // If demo account doesn't exist, create it
      try {
        await registerUser(
          name: 'Demo User',
          email: demoEmail,
          password: demoPassword,
        );
        return await login(demoEmail, demoPassword);
      } catch (e2) {
        rethrow;
      }
    }
  }

  /// Registers a new user and creates their Firestore profile
  Future<UserCredential> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    print('[AUTH] 📝 Starting user registration for: $email');
    print('[AUTH] 📝 Name: $name');
    
    try {
      print('[AUTH] 🔄 Calling Firebase Auth createUserWithEmailAndPassword...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      print('[AUTH] ✅ Firebase Auth user created. User UID: ${credential.user?.uid}');
      
      final user = credential.user;
      if (user != null) {
        // Update Firebase profile displayName
        print('[AUTH] 🔄 Updating Firebase displayName...');
        await user.updateDisplayName(name.trim());
        print('[AUTH] ✅ DisplayName updated');
        
        final isSuperAdmin = email.trim().toLowerCase() == 'admin-ev@gmail.com';
        print('[AUTH] 👤 User role: ${isSuperAdmin ? 'admin' : 'user'}');

        print('[AUTH] 📂 Creating Firestore user profile...');
        // Create user document matching database schema
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'walletBalance': isSuperAdmin ? 10000.0 : 100.0,
          'role': isSuperAdmin ? 'admin' : 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('[AUTH] ✅ Firestore profile created successfully');
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      print('[AUTH] ❌ FirebaseAuthException during registration: code=${e.code}, message=${e.message}');
      if (e.code == 'email-already-in-use') {
        print('[AUTH] ❌ Email already registered');
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'This email is already registered. Please login instead.',
        );
      } else if (e.code == 'weak-password') {
        print('[AUTH] ❌ Weak password');
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password is too weak. Please use a stronger password.',
        );
      }
      rethrow;
    } catch (e) {
      print('[AUTH] ❌ Unexpected error during registration: $e');
      rethrow;
    }
  }

  /// Checks if a user's details exist in Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Logs the user out
  Future<void> logout() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Sign in with Google and ensure Firestore profile existence
  Future<UserCredential?> signInWithGoogle() async {
    print('[AUTH] 🔐 Starting Google Sign-In...');
    
    try {
      print('[AUTH] 🔄 Opening Google Sign-In dialog...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('[AUTH] ⚠️ Google Sign-In cancelled by user');
        return null; // User cancelled the sign-in flow
      }
      
      print('[AUTH] ✅ Google user selected: ${googleUser.email}');
      print('[AUTH] 🔄 Getting Google authentication...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('[AUTH] 🔑 Google accessToken: ${googleAuth.accessToken?.substring(0, 20)}...');
      print('[AUTH] 🔑 Google idToken: ${googleAuth.idToken?.substring(0, 20)}...');

      print('[AUTH] 🔄 Creating Firebase credential...');
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('[AUTH] 🔄 Signing in to Firebase with credential...');
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      print('[AUTH] ✅ Firebase Auth login successful. User UID: ${user?.uid}');

      if (user != null) {
        print('[AUTH] 📂 Checking Firestore for user profile...');
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          print('[AUTH] 📝 Creating new Firestore profile for Google user: ${user.uid}');
          final isSuperAdmin = user.email?.trim().toLowerCase() == 'admin-ev@gmail.com';
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? 'Google User',
            'email': user.email?.trim().toLowerCase() ?? '',
            'walletBalance': isSuperAdmin ? 10000.0 : 100.0,
            'role': isSuperAdmin ? 'admin' : 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('[AUTH] ✅ Firestore profile created for Google user');
        } else {
          print('[AUTH] ✅ Firestore profile exists for Google user');
        }
      }

      return userCredential;
    } catch (e) {
      print('[AUTH] ❌ Google Sign-In failed with error: $e');
      print('[AUTH] ❌ Error type: ${e.runtimeType}');
      
      if (e is FirebaseAuthException) {
        print('[AUTH] ❌ Firebase Auth Exception code: ${e.code}');
        print('[AUTH] ❌ Firebase Auth Exception message: ${e.message}');
      }
      
      throw Exception('Google Sign-In failed: $e');
    }
  }
}

