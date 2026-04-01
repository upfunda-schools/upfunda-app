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
  bool _isPhoneMode = false;
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
    final size = MediaQuery.sizeOf(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).padding;
    final authState = ref.watch(authProvider);

    // ── Responsive scale tokens ──────────────────────────────────────────────
    final sh = size.height; // screen height shorthand
    final sw = size.width;  // screen width shorthand

    // Bottom illustration zone — proportional so it never dominates small screens
    final bottomZoneHeight = sh * 0.36;

    // Rocket decoration size
    final rocketSize = sw * 0.17;

    // Form field height — scales with screen, clamped between 40–50px
    final fieldH = (sh * 0.053).clamp(40.0, 50.0);

    // Toggle pill dimensions
    final toggleH = (sh * 0.046).clamp(32.0, 42.0);
    final toggleW = (sw * 0.56).clamp(180.0, 220.0);

    // Spacing tokens derived from screen height
    final spaceXS = sh * 0.008;   // ~5–7 px
    final spaceS  = sh * 0.015;   // ~10–14 px
    final spaceM  = sh * 0.022;   // ~15–20 px
    final spaceL  = sh * 0.032;   // ~21–30 px
    // ────────────────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── LAYER 1: Cloud decorations ────────────────────────────────────
          Positioned(
            top: sh * 0.02,
            left: sw * 0.75,
            child: Image.asset(
              'assets/images/signup/Vector-1.png',
              width: sw * 0.20,
              errorBuilder: (_, __, ___) =>
                  _buildCodeCloud(width: sw * 0.20),
            ),
          ),
          Positioned(
            top: sh * 0.05,
            left: -sw * 0.05,
            child: Image.asset(
              'assets/images/signup/Vector-2.png',
              width: sw * 0.18,
              errorBuilder: (_, __, ___) =>
                  _buildCodeCloud(width: sw * 0.18),
            ),
          ),
          Positioned(
            top: sh * 0.11,
            right: -sw * 0.05,
            child: Image.asset(
              'assets/images/signup/Vector.png',
              width: sw * 0.12,
              errorBuilder: (_, __, ___) =>
                  _buildCodeCloud(width: sw * 0.12),
            ),
          ),

          // ── LAYER 2: Bottom illustration — anchored to bottom ─────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomZoneHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Grass strip fills the full zone width
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/signup/Grass.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                // Illustration sits above the grass
                Positioned(
                  bottom: bottomZoneHeight * 0.08,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/signup/online education.png',
                        width: sw * 0.72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── LAYER 3: Main scrollable content ─────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: sh * 0.06),

                  // Welcome header image
                  Image.asset(
                    'assets/log in page/Welcome Back, Math Champion!.png',
                    height: (sh * 0.07).clamp(48.0, 70.0),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.montserrat(
                          fontSize: (sw * 0.055).clamp(16.0, 22.0),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                        children: [
                          const TextSpan(text: 'Welcome Back,\n'),
                          const TextSpan(
                            text: 'Math Champion!',
                            style: TextStyle(color: Color(0xFF7B66FF)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: spaceXS),

                  // Subtitle
                  Image.asset(
                    'assets/log in page/Unlock the Logic in math!.png',
                    height: (sh * 0.018).clamp(12.0, 16.0),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      'Unlock the Logic in math!',
                      style: GoogleFonts.montserrat(
                        fontSize: (sw * 0.03).clamp(10.0, 13.0),
                        color: AppColors.grey600,
                      ),
                    ),
                  ),

                  SizedBox(height: spaceS),

                  // ── Login Form Card ───────────────────────────────────────
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            sw * 0.06,
                            spaceS,
                            sw * 0.06,
                            spaceM,
                          ),
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
                                // Login title
                                Image.asset(
                                  'assets/log in page/Login.png',
                                  height: (sh * 0.03).clamp(20.0, 28.0),
                                  errorBuilder: (_, __, ___) => const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                SizedBox(height: spaceM),

                                // Email / Phone toggle
                                Container(
                                  height: toggleH,
                                  width: toggleW,
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

                                SizedBox(height: spaceM),

                                // Input fields
                                if (_isPhoneMode) ...[
                                  _fieldLabel('Phone Number *'),
                                  SizedBox(height: spaceXS),
                                  Row(
                                    children: [
                                      _buildFieldContainer(
                                        height: fieldH,
                                        width: sw * 0.18,
                                        child: DropdownButtonHideUnderline(
                                          child: Center(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: _countryCode,
                                              padding: const EdgeInsets.only(
                                                left: 8,
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
                                                () =>
                                                    _countryCode = v ?? '+91',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: spaceS),
                                      Expanded(
                                        child: _buildFieldContainer(
                                          height: fieldH,
                                          child: TextField(
                                            controller: _phoneController,
                                            focusNode: _phoneFocus,
                                            keyboardType:
                                                TextInputType.phone,
                                            decoration: InputDecoration(
                                              hintText: 'Enter Phone',
                                              hintStyle: const TextStyle(
                                                color: Color(0xFFC4C4C4),
                                                fontSize: 13,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.fromLTRB(
                                                16,
                                                0,
                                                16,
                                                fieldH * 0.28,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  _fieldLabel('Email *'),
                                  SizedBox(height: spaceXS),
                                  _buildFieldContainer(
                                    height: fieldH,
                                    child: TextField(
                                      controller: _emailController,
                                      focusNode: _emailFocus,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      decoration: InputDecoration(
                                        hintText: 'Enter Email',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFFC4C4C4),
                                          fontSize: 13,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          fieldH * 0.28,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                SizedBox(height: spaceM),

                                _fieldLabel('Password *'),
                                SizedBox(height: spaceXS),
                                _buildFieldContainer(
                                  height: fieldH,
                                  child: Stack(
                                    alignment: Alignment.centerRight,
                                    children: [
                                      TextField(
                                        controller: _passwordController,
                                        focusNode: _passFocus,
                                        obscureText: _obscurePassword,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        decoration: InputDecoration(
                                          hintText: '................',
                                          hintStyle: const TextStyle(
                                            color: Color(0xFFC4C4C4),
                                            fontSize: 18,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            40,
                                            fieldH * 0.3,
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
                                                ? Icons
                                                    .visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (authState.error != null) ...[
                                  SizedBox(height: spaceXS),
                                  Text(
                                    authState.error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],

                                SizedBox(height: spaceL),

                                // Sign In button
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
                                        height: fieldH,
                                        fit: BoxFit.fill,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          height: fieldH,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF7067),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      if (authState.isLoading)
                                        SizedBox(
                                          height: fieldH * 0.48,
                                          width: fieldH * 0.48,
                                          child:
                                              const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        Image.asset(
                                          'assets/log in page/Group 8.png',
                                          height: fieldH * 0.45,
                                          errorBuilder: (_, __, ___) => Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                'Sign In',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
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

                                SizedBox(height: spaceM),

                                // Join now link
                                GestureDetector(
                                  onTap: () => context.go('/signup'),
                                  child: Image.asset(
                                    "assets/log in page/Don't have an account_ Join now.png",
                                    height:
                                        (sh * 0.018).clamp(12.0, 16.0),
                                    errorBuilder: (_, __, ___) =>
                                        const Text(
                                      "Don't have an account? Join now",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: spaceS),

                                // Forgot password link
                                GestureDetector(
                                  onTap: _handleForgotPassword,
                                  child: Image.asset(
                                    'assets/log in page/Forget Password_.png',
                                    height:
                                        (sh * 0.018).clamp(12.0, 16.0),
                                    errorBuilder: (_, __, ___) =>
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
                          ),
                        ),

                        // Rocket decoration — proportional size, anchored to card corner
                        Positioned(
                          top: spaceM,
                          right: -rocketSize * 0.4,
                          child: Image.asset(
                            'assets/images/signup/Rocket.png',
                            width: rocketSize,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom spacer: enough room so the form never sits on top
                  // of the illustration, plus extra space for keyboard
                  SizedBox(
                    height: bottomZoneHeight + viewInsets.bottom + spaceM,
                  ),
                ],
              ),
            ),
          ),

          // ── Back button — uses safe area top ─────────────────────────────
          Positioned(
            top: padding.top + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.black,
              ),
              onPressed: () =>
                  Navigator.canPop(context) ? context.pop() : context.go('/'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ),
      );

  Widget _buildFieldContainer({
    required Widget child,
    required double height,
    double? width,
  }) {
    return Container(
      width: width,
      height: height,
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
