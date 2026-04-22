import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  bool _agreedToTerms = false;

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

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
        ),
      );
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                      () => _isPhoneSelected =
                                                          false,
                                                    ),
                                                    child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color: !_isPhoneSelected
                                                            ? const Color(
                                                                0xFFFF7067,
                                                              )
                                                            : const Color(
                                                                0xFFF7F7F7,
                                                              ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.grey
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Email',
                                                        style: TextStyle(
                                                          color:
                                                              !_isPhoneSelected
                                                              ? Colors.white
                                                              : Colors
                                                                    .grey
                                                                    .shade400,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                                      () => _isPhoneSelected =
                                                          true,
                                                    ),
                                                    child: Container(
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color: _isPhoneSelected
                                                            ? const Color(
                                                                0xFFFF7067,
                                                              )
                                                            : const Color(
                                                                0xFFF7F7F7,
                                                              ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.grey
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Phone',
                                                        style: TextStyle(
                                                          color:
                                                              _isPhoneSelected
                                                              ? Colors.white
                                                              : Colors
                                                                    .grey
                                                                    .shade400,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                            padding: const EdgeInsets.only(
                                              left: 4,
                                            ),
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
                                            onCountryChanged: (prefix) =>
                                                setState(
                                                  () =>
                                                      _phonePrefix = '+$prefix',
                                                ),
                                          )
                                        else
                                          Container(
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF7F7F7),
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                            padding: const EdgeInsets.only(
                                              left: 4,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                decoration:
                                                    const InputDecoration(
                                                      hintText:
                                                          '................',
                                                      hintStyle: TextStyle(
                                                        color: Color(
                                                          0xFFC4C4C4,
                                                        ),
                                                        fontSize: 18,
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.only(
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
                                                  behavior:
                                                      HitTestBehavior.opaque,
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
                                            padding: const EdgeInsets.only(
                                              left: 4,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                obscureText:
                                                    _obscureConfirmPassword,
                                                textAlignVertical:
                                                    TextAlignVertical.center,
                                                decoration:
                                                    const InputDecoration(
                                                      hintText:
                                                          '................',
                                                      hintStyle: TextStyle(
                                                        color: Color(
                                                          0xFFC4C4C4,
                                                        ),
                                                        fontSize: 18,
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.only(
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
                                                  behavior:
                                                      HitTestBehavior.opaque,
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
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF9F9F9),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () => setState(
                                              () => _agreedToTerms =
                                                  !_agreedToTerms,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: _agreedToTerms,
                                                  onChanged: (val) => setState(
                                                    () => _agreedToTerms =
                                                        val ?? false,
                                                  ),
                                                  activeColor: const Color(
                                                    0xFF6C5CE7,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  side: BorderSide(
                                                    color: Colors.grey.shade400,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF555555,
                                                        ),
                                                        fontSize: 12,
                                                        fontFamily: 'Roboto',
                                                      ),
                                                      children: [
                                                        const TextSpan(
                                                          text: 'I agree with ',
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              'terms and conditions',
                                                          style: const TextStyle(
                                                            color: Color(
                                                              0xFF6C5CE7,
                                                            ),
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                          recognizer:
                                                              TapGestureRecognizer()
                                                                ..onTap =
                                                                    _showTermsDialog,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: authState.isLoading
                                              ? null
                                              : _signUp,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/signup/Rectangle 11.png',
                                                width: double.infinity,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) =>
                                                        const SizedBox.shrink(),
                                              ),
                                              if (authState.isLoading)
                                                const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              else
                                                Image.asset(
                                                  'assets/images/signup/Group 9.png',
                                                  height: 22,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
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
                                                  text:
                                                      'Already have an account? ',
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
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
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
                              right: -(size.width * 0.07),
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.gavel_rounded,
                        color: Color(0xFF6C5CE7),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF6C5CE7)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTermsSection(
                          'Acceptance of Terms',
                          'By accessing and using the services provided by Upfunda Edtech Private Limited ("Company," "we," "our," or "us"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
                        ),
                        _buildTermsSection(
                          'Description of Service',
                          'Upfunda Edtech Private Limited provides an educational technology platform offering interactive learning modules and educational content, assessment tools and progress tracking, math competitions including ILMC (International Logical Math Championship), online classes and educational resources, administrative tools for schools and educators, and personalized learning experiences.',
                        ),
                        _buildTermsSection(
                          'User Accounts',
                          'Registration\nTo access certain features of our platform, you must register for an account. You agree to provide accurate, current, and complete information during registration and to update such information to keep it accurate, current, and complete.\n\nAccount Security\nYou are responsible for safeguarding your account credentials and must immediately notify us of any unauthorized use of your account. We are not liable for any loss or damage arising from your failure to secure your account.',
                        ),
                        _buildTermsSection(
                          'Acceptable Use',
                          'You agree not to use the platform for any illegal or unauthorized purpose, violate any applicable local, state, national, or international law, transmit any harmful, threatening, abusive, or offensive content, attempt to gain unauthorized access to our systems or other users\' accounts, interfere with or disrupt the platform\'s functionality, use automated systems to access the platform without permission, or share account credentials with unauthorized users.',
                        ),
                        _buildTermsSection(
                          'Intellectual Property',
                          'Our Content\nAll content on our platform, including but not limited to text, graphics, logos, images, audio clips, video clips, digital downloads, data compilations, and software, is the property of Upfunda Edtech Private Limited and is protected by copyright and other intellectual property laws. Download of any material and distribution without prior permission from Upfunda Academy is considered as infringement of copyright law.\n\nUser Content\nBy submitting content to our platform, you grant us a non-exclusive, worldwide, royalty-free license to use, reproduce, modify, and distribute such content for the purpose of providing our services.',
                        ),
                        _buildTermsSection(
                          'Academic Integrity',
                          'Our platform is designed for legitimate educational purposes. Users must maintain academic integrity and honesty in all assessments. Cheating, plagiarism, or unauthorized collaboration is strictly prohibited. We reserve the right to invalidate results obtained through dishonest means.',
                        ),
                        _buildTermsSection(
                          'Payment & Privacy',
                          'Subscription fees are charged in advance and are non-refundable. Prices are subject to change with notice.\n\nYour privacy is important to us. Please review our Privacy Policy to understand our practices regarding your information.',
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upfunda Edtech Private Limited\nEmail: contact.upfunda@gmail.com\nPhone: +91 99941 80706',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF777777),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer Action
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _agreedToTerms = true);
                      Navigator.pop(context);
                    },
                    child: Image.asset(
                      'assets/images/signup/TC Button.png',
                      width: double.infinity,
                      height: 54,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'I Accept the Terms',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF333333),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
