import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  static Future<AuthResponse> signUp(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() {
    return _client.auth.signOut();
  }

  static Future<bool> isAdmin() async {
    final uid = currentUser?.id;
    if (uid == null) return false;
    final data = await _client.from('profiles').select('is_admin').eq('id', uid).maybeSingle();
    return data?['is_admin'] == true;
  }
}
