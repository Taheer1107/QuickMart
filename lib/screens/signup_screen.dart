import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _message;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await AuthService.signUp(_emailController.text.trim(), _passwordController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Sign up failed. Try a different email or a longer password.');
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
    const coral = Color(0xFFF27A54);
    const peach = Color(0xFFFFE5D9);
    const lightPeach = Color(0xFFFFF5F2);
    final isWide = MediaQuery.of(context).size.width >= 760;

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
                    ? Row(children: [Expanded(child: _buildSignupCard(coral, lightPeach)), const Expanded(child: _SignupIllustration())])
                    : _buildSignupCard(coral, lightPeach),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupCard(Color coral, Color lightPeach) {
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
            Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: coral, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 21)), const SizedBox(width: 10), Text('QuickMart', style: TextStyle(color: coral, fontSize: 22, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 46),
            Text('Start shopping smarter', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Create account', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900)),
            const SizedBox(height: 28),
            const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(hintText: 'you@example.com', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12), fillColor: lightPeach, filled: true, prefixIcon: Icon(Icons.mail_outline_rounded, color: coral, size: 19), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 18),
            const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(hintText: 'At least 8 characters', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12), fillColor: lightPeach, filled: true, prefixIcon: Icon(Icons.lock_outline_rounded, color: coral, size: 19), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: coral, size: 19), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
              validator: (value) => value == null || value.length < 8 ? 'Use at least 8 characters' : null,
            ),
            if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: coral, fontSize: 12, fontWeight: FontWeight.w600))],
            if (_message != null) ...[const SizedBox(height: 12), Text(_message!, style: TextStyle(color: Color(0xFF176B45), fontSize: 12, fontWeight: FontWeight.w600))],
            const SizedBox(height: 28),
            Center(child: SizedBox(width: 190, height: 48, child: ElevatedButton(onPressed: _loading ? null : _signup, style: ElevatedButton.styleFrom(backgroundColor: coral, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_loading ? '...' : 'CREATE ACCOUNT', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.7)), const SizedBox(width: 7), const Icon(Icons.arrow_forward_rounded, size: 17)])))),
            const SizedBox(height: 26),
            Center(child: RichText(text: TextSpan(style: TextStyle(color: Colors.grey[400], fontSize: 12), children: [const TextSpan(text: 'Already have an account? '), WidgetSpan(alignment: PlaceholderAlignment.middle, child: GestureDetector(onTap: () => Navigator.pop(context), child: Text('Sign in', style: TextStyle(color: coral, fontWeight: FontWeight.w800))))]))),
          ],
        ),
      ),
    );
  }
}

class _SignupIllustration extends StatelessWidget {
  const _SignupIllustration();

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
          Positioned(top: 70, left: 80, child: Icon(Icons.add, color: coral.withOpacity(0.25), size: 30)),
          Positioned(top: 190, right: 55, child: Icon(Icons.add, color: coral.withOpacity(0.22), size: 24)),
          Positioned(bottom: 90, right: 70, child: Icon(Icons.circle, color: coral.withOpacity(0.18), size: 12)),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.person_add_rounded, color: Color(0xFF202033), size: 108),
            Transform.translate(offset: const Offset(18, -18), child: Icon(Icons.shopping_basket_rounded, color: coral, size: 125)),
            const SizedBox(height: 18),
            const Text('Fresh groceries and little\njoys for every day.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF202033), fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
          ]),
        ],
      ),
    );
  }
}
