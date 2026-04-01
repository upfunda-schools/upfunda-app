import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import 'widgets/custom_phone_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _isPhoneSelected = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _phonePrefix = '+91';

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_rebuild);
    _emailFocus.addListener(_rebuild);
    _passFocus.addListener(_rebuild);
    _confirmPassFocus.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final value = _isPhoneSelected
        ? _phoneController.text.trim()
        : _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (value.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your ${_isPhoneSelected ? 'phone number' : 'email'} and password',
          ),
        ),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    bool success;
    if (_isPhoneSelected) {
      success = await ref
          .read(authProvider.notifier)
          .phoneRegister(phone: '$_phonePrefix$value', password: password);
    } else {
      success = await ref
          .read(authProvider.notifier)
          .emailRegister(email: value, password: password);
    }

    if (success && mounted) {
      context.go('/student-home');
    } else if (mounted) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Registration failed')));
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
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      extendBody: true,
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
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Image.asset(
                  'assets/images/signup/Grass.png',
                  width: size.width,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Image.asset(
                    'assets/images/signup/online education.png',
                    width: size.width * 0.62,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),

          // LAYER 3: MAIN CONTENT
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.05),
                  Center(
                    child: Image.asset(
                      'assets/images/signup/Join Upfunda.png',
                      height: (size.height * 0.04).clamp(24.0, 40.0),
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  Center(
                    child: Text(
                      'Create your account to unlock the logic\nin math',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: (size.width * 0.035).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SizedBox(
                        width: size.width * 0.86,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 35,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.04),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  AbsorbPointer(
                                    absorbing: authState.isLoading,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                  Image.asset(
                                    'assets/images/3. SignUp-Email/Sign Up.png',
                                    height: 28,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF333333),
                                              ),
                                            ),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: SizedBox(
                                      height: 35,
                                      width: 220,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(
                                                () => _isPhoneSelected = false,
                                              ),
                                              child: Container(
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: !_isPhoneSelected
                                                      ? const Color(0xFFFF7067)
                                                      : const Color(0xFFF7F7F7),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color: Colors.grey
                                                        .withValues(alpha: 0.1),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Email',
                                                  style: TextStyle(
                                                    color: !_isPhoneSelected
                                                        ? Colors.white
                                                        : Colors.grey.shade400,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(
                                                () => _isPhoneSelected = true,
                                              ),
                                              child: Container(
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: _isPhoneSelected
                                                      ? const Color(0xFFFF7067)
                                                      : const Color(0xFFF7F7F7),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color: Colors.grey
                                                        .withValues(alpha: 0.1),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Phone',
                                                  style: TextStyle(
                                                    color: _isPhoneSelected
                                                        ? Colors.white
                                                        : Colors.grey.shade400,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        _isPhoneSelected
                                            ? 'Phone Number *'
                                            : 'Email *',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_isPhoneSelected)
                                    CustomPhoneField(
                                      controller: _phoneController,
                                      focusNode: _phoneFocus,
                                      onCountryChanged: (prefix) => setState(
                                        () => _phonePrefix = '+$prefix',
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F7F7),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _emailController,
                                        focusNode: _emailFocus,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter Email',
                                          hintStyle: TextStyle(
                                            color: Color(0xFFC4C4C4),
                                            fontSize: 13,
                                          ),
                                          contentPadding: EdgeInsets.only(
                                            left: 12,
                                            right: 12,
                                            bottom: 12,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: const Text(
                                        'Password *',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F7F7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
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
                                            contentPadding: EdgeInsets.only(
                                              left: 16,
                                              right: 50,
                                              bottom: 16,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                        ),
                                        Positioned(
                                          right: 15,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                            child: Image.asset(
                                              'assets/images/signup/Group 7.png',
                                              width: 22,
                                              height: 22,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.visibility_off,
                                                    size: 18,
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: const Text(
                                        'Confirm Password *',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F7F7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.centerRight,
                                      children: [
                                        TextField(
                                          controller:
                                              _confirmPasswordController,
                                          focusNode: _confirmPassFocus,
                                          obscureText: _obscureConfirmPassword,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          decoration: const InputDecoration(
                                            hintText: '................',
                                            hintStyle: TextStyle(
                                              color: Color(0xFFC4C4C4),
                                              fontSize: 18,
                                            ),
                                            contentPadding: EdgeInsets.only(
                                              left: 16,
                                              right: 50,
                                              bottom: 16,
                                            ),
                                            border: InputBorder.none,
                                          ),
                                        ),
                                        Positioned(
                                          right: 15,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => setState(
                                              () => _obscureConfirmPassword =
                                                  !_obscureConfirmPassword,
                                            ),
                                            child: Image.asset(
                                              'assets/images/signup/Group 7.png',
                                              width: 22,
                                              height: 22,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.visibility_off,
                                                    size: 18,
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  GestureDetector(
                                    onTap: authState.isLoading ? null : _signUp,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/signup/Rectangle 11.png',
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const SizedBox.shrink(),
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
                                            'assets/images/signup/Group 9.png',
                                            height: 22,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.arrow_forward,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Already have an account? ',
                                          ),
                                          TextSpan(
                                            text: 'Log In',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                      ],
                                    ),
                                  ),
                                  if (authState.isLoading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFFF7067),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: - (size.width * 0.07),
                              child: Image.asset(
                                'assets/images/signup/Rocket.png',
                                width: (size.width * 0.25).clamp(80.0, 110.0),
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
