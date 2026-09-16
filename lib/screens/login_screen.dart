import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  // Design colors
  final Color coral = const Color(0xFFF27A54);
  final Color peach = const Color(0xFFFFE5D9);
  final Color lightPeach = const Color(0xFFFFF5F2);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.signIn(_emailController.text.trim(), _passwordController.text.trim());
    } catch (e) {
      setState(() => _error = 'Login failed. Check your email and password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 760;

    return Scaffold(
      backgroundColor: peach,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 36 : 18, vertical: isWide ? 28 : 12),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(child: _buildLoginCard()),
                          const Expanded(child: _LoginIllustration()),
                        ],
                      )
                    : _buildLoginCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 560),
      padding: const EdgeInsets.fromLTRB(42, 42, 42, 34),
      color: Colors.white,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: coral, borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 21),
                ),
                const SizedBox(width: 10),
                Text('QuickMart', style: TextStyle(color: coral, fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 52),
            Text('Welcome back !!!', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Sign in', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 32),
            const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                fillColor: lightPeach,
                filled: true,
                prefixIcon: Icon(Icons.mail_outline_rounded, color: coral, size: 19),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                TextButton(onPressed: () {}, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), child: Text('Forgot password?', style: TextStyle(color: Colors.grey[500], fontSize: 11))),
              ],
            ),
            const SizedBox(height: 7),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Your password',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                fillColor: lightPeach,
                filled: true,
                prefixIcon: Icon(Icons.lock_outline_rounded, color: coral, size: 19),
                suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: coral, size: 19), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (value) => value == null || value.length < 6 ? 'Use at least 6 characters' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: coral, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 158,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(backgroundColor: coral, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_loading ? '...' : 'SIGN IN', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)), const SizedBox(width: 7), const Icon(Icons.arrow_forward_rounded, size: 17)]),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    WidgetSpan(alignment: PlaceholderAlignment.middle, child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())), child: Text('Sign up', style: TextStyle(color: coral, fontWeight: FontWeight.w800)))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginIllustration extends StatelessWidget {
  const _LoginIllustration();

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFF27A54);
    const peach = Color(0xFFFFE5D9);
    return Container(
      height: 620,
      color: peach,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 70, right: 80, child: Icon(Icons.add, color: coral.withOpacity(0.25), size: 30)),
          Positioned(top: 160, left: 55, child: Icon(Icons.add, color: coral.withOpacity(0.22), size: 24)),
          Positioned(bottom: 90, left: 80, child: Icon(Icons.circle, color: coral.withOpacity(0.18), size: 12)),
          Positioned(bottom: 82, right: 90, child: Icon(Icons.circle, color: coral.withOpacity(0.22), size: 8)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_rounded, color: Color(0xFF202033), size: 105),
              Transform.translate(
                offset: const Offset(-34, -22),
                child: Transform.rotate(angle: -0.12, child: Icon(Icons.shopping_cart_outlined, color: coral, size: 150)),
              ),
              const SizedBox(height: 18),
              const Text('Your everyday essentials,\njust a tap away.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF202033), fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
            ],
          ),
        ],
      ),
    );
  }
}
