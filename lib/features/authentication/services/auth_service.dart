import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_repository.dart';

// AuthService الآن مسؤول فقط عن المصادقة
class AuthService {
  final FirebaseAuth _auth;
  final UserRepository _userRepository;

  AuthService({
    required FirebaseAuth auth,
    required UserRepository userRepository,
  })  : _auth = auth,
        _userRepository = userRepository;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      // Create a new GoogleSignIn instance each time to avoid cached credentials issues
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      
      
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // نستدعي المستودع للقيام بعملية الحفظ
        await _userRepository.saveNewUser(userCredential.user!);
      }
      return userCredential.user;
    } catch (e) {
      print('خطأ في تسجيل الدخول باستخدام Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Firebase first
      await _auth.signOut();
    } catch (e) {
      print('Error signing out from Firebase: $e');
    }
    
    try {
      // Create a new GoogleSignIn instance for sign out
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      
      // Sign out from Google
      await googleSignIn.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
    
    try {
      // Create a new GoogleSignIn instance for disconnect
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      
      // Disconnect Google account to ensure complete logout
      await googleSignIn.disconnect();
    } catch (e) {
      print('Error disconnecting from Google: $e');
    }
  }
}

// --- Providers المحدثة ---
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: FirebaseAuth.instance,
    userRepository: ref.watch(userRepositoryProvider),
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
