import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPhoneMode = false; // Figma shows Email first
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _countryCode = '+91';

  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passFocus = FocusNode();

  final _countryCodes = [('+91', 'India'), ('+1', 'US'), ('+44', 'UK')];

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_rebuild);
    _phoneFocus.addListener(_rebuild);
    _passFocus.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authState = ref.read(authProvider.notifier);
    final value = _isPhoneMode
        ? _phoneController.text.trim()
        : _emailController.text.trim();
    final password = _passwordController.text;

    if (value.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your ${_isPhoneMode ? 'phone' : 'email'} and password',
          ),
        ),
      );
      return;
    }

    final bool success;
    if (_isPhoneMode) {
      success = await authState.phoneLogin(
        phone: '$_countryCode$value',
        password: password,
      );
    } else {
      success = await authState.login(email: value, password: password);
    }

    if (success && mounted) {
      context.go('/student-home');
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_isPhoneMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset is only available for Email login'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email above to reset password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).resetPassword(
      email: email,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Password reset email sent to $email'
                : ref.read(authProvider).error ?? 'Reset failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildCodeCloud({required double width}) {
    return Container(
      width: width,
      height: width * 0.6,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.all(Radius.elliptical(width, width * 0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8EEFF).withValues(alpha: 0.8),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // LAYER 1: CLOUD ASSETS
          Positioned(
            top: size.height * 0.02,
            left: size.width * 0.75,
            child: Image.asset(
              'assets/images/signup/Vector-1.png',
              width: size.width * 0.20,
              errorBuilder: (context, error, stackTrace) =>
                  _buildCodeCloud(width: size.width * 0.20),
            ),
          ),
          Positioned(
            top: size.height * 0.05,
            left: -size.width * 0.05,
            child: Image.asset(
              'assets/images/signup/Vector-2.png',
              width: size.width * 0.18,
              errorBuilder: (context, error, stackTrace) =>
                  _buildCodeCloud(width: size.width * 0.18),
            ),
          ),
          Positioned(
            top: size.height * 0.11,
            right: -size.width * 0.05,
            child: Image.asset(
              'assets/images/signup/Vector.png',
              width: size.width * 0.12,
              errorBuilder: (context, error, stackTrace) =>
                  _buildCodeCloud(width: size.width * 0.12),
            ),
          ),

          // LAYER 2: BOTTOM ASSETS
          Positioned(
            bottom: -20,
            left: 0,
            right: 0,
            height: 350,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Grass Background
                Image.asset(
                  'assets/images/signup/Grass.png',
                  width: size.width,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
                // Illustration (Behind the form)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/signup/online education.png',
                        width: MediaQuery.of(context).size.width * 0.75,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // LAYER 3: MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.08),
                  // Welcome Header
                  Image.asset(
                    'assets/log in page/Welcome Back, Math Champion!.png',
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                        children: [
                          const TextSpan(text: 'Welcome Back,\n'),
                          TextSpan(
                            text: 'Math Champion!',
                            style: TextStyle(
                              color: const Color(0xFF7B66FF),
                            ), // Purple
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Image.asset(
                    'assets/log in page/Unlock the Logic in math!.png',
                    height: 14,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'Unlock the Logic in math!',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Login Form Card
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 40,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/log in page/Login.png',
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 20),

                                // Toggle (Email/Phone)
                                Container(
                                  height: 35,
                                  width: 220,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F7F7),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _ToggleButton(
                                          label: 'Email',
                                          isActive: !_isPhoneMode,
                                          onTap: () => setState(
                                            () => _isPhoneMode = false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: _ToggleButton(
                                          label: 'Phone',
                                          isActive: _isPhoneMode,
                                          onTap: () => setState(
                                            () => _isPhoneMode = true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Inputs
                                if (_isPhoneMode) ...[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        bottom: 8,
                                      ),
                                      child: const Text(
                                        'Phone Number *',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _buildFieldContainer(
                                        width: 75,
                                        child: DropdownButtonHideUnderline(
                                          child: Center(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: _countryCode,
                                              padding: const EdgeInsets.only(
                                                left: 10,
                                              ),
                                              items: _countryCodes
                                                  .map(
                                                    (c) => DropdownMenuItem(
                                                      value: c.$1,
                                                      child: Text(
                                                        c.$1,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (v) => setState(
                                                () => _countryCode = v ?? '+91',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildFieldContainer(
                                          child: TextField(
                                            controller: _phoneController,
                                            focusNode: _phoneFocus,
                                            keyboardType: TextInputType.phone,

                                            decoration: const InputDecoration(
                                              hintText: 'Enter Phone',
                                              hintStyle: TextStyle(
                                                color: Color(0xFFC4C4C4),
                                                fontSize: 13,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.fromLTRB(
                                                    16,
                                                    0,
                                                    16,
                                                    12,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        bottom: 8,
                                      ),
                                      child: const Text(
                                        'Email *',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildFieldContainer(
                                    child: TextField(
                                      controller: _emailController,
                                      focusNode: _emailFocus,
                                      keyboardType: TextInputType.emailAddress,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter Email',
                                        hintStyle: TextStyle(
                                          color: Color(0xFFC4C4C4),
                                          fontSize: 13,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 8,
                                    ),
                                    child: const Text(
                                      'Password *',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                _buildFieldContainer(
                                  child: Stack(
                                    alignment: Alignment.centerRight,
                                    children: [
                                      TextField(
                                        controller: _passwordController,
                                        focusNode: _passFocus,
                                        obscureText: _obscurePassword,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        decoration: const InputDecoration(
                                          hintText: '................',
                                          hintStyle: TextStyle(
                                            color: Color(0xFFC4C4C4),
                                            fontSize: 18,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            16,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 12,
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          child: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),
                                if (authState.error != null)
                                  Text(
                                    authState.error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),

                                const SizedBox(height: 32),

                                // Sign In Button
                                GestureDetector(
                                  onTap: authState.isLoading
                                      ? null
                                      : _handleLogin,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/log in page/Rectangle 11.png',
                                        width: double.infinity,
                                        height: 42,
                                        fit: BoxFit.fill,
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => Container(
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF7067),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                      ),
                                      if (authState.isLoading)
                                        const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        Image.asset(
                                          'assets/log in page/Group 8.png',
                                          height: 18,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Text(
                                                    'Sign In',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons.arrow_forward,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),
                                // Bottom info/links
                                GestureDetector(
                                  onTap: () => context.go('/signup'),
                                  child: Image.asset(
                                    "assets/log in page/Don't have an account_ Join now.png",
                                    height: 14,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Text(
                                              "Don't have an account? Join now",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Bottom info/links
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: _handleForgotPassword,
                                      child: Image.asset(
                                        'assets/log in page/Forget Password_.png',
                                        height: 14,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Text(
                                                  'Forget Password?',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Rocket Decoration
                        Positioned(
                          top: 20,
                          right: -30,
                          child: Image.asset(
                            'assets/images/signup/Rocket.png',
                            width: 70,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 150,
                  ),
                ],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
              onPressed: () => Navigator.canPop(context) ? context.pop() : context.go('/'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldContainer({required Widget child, double? width}) {
    return Container(
      width: width,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF7067) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
