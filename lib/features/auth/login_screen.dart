import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPhoneMode = true;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _countryCode = '+91';

  final _countryCodes = [
    ('+91', 'India'),
    ('+1', 'US'),
    ('+44', 'UK'),
    ('+971', 'UAE'),
    ('+966', 'Saudi Arabia'),
    ('+65', 'Singapore'),
    ('+61', 'Australia'),
    ('+1', 'Canada'),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _isPhoneMode
        ? '${_phoneController.text}@phone.upfunda.com'
        : _emailController.text;
    final password = _passwordController.text;

    final success = await ref
        .read(authProvider.notifier)
        .login(email: email, password: password);

    if (success && mounted) {
      context.go('/student-home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: isTablet ? _buildTabletLayout(authState) : _buildPhoneLayout(authState),
    );
  }

  Widget _buildTabletLayout(AuthState authState) {
    return Row(
      children: [
        // Left branding panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.loginBg, Color(0xFF1A0845)],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'UPFUNDA',
                      style: GoogleFonts.montserrat(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFE4B500), AppColors.accent],
                      ).createShader(bounds),
                      child: Text(
                        'UNLOCK THE LOGIC IN MATH',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Icon(
                      Icons.school_rounded,
                      size: 120,
                      color: AppColors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right form panel
        Expanded(
          flex: 5,
          child: _buildForm(authState),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(AuthState authState) {
    return SafeArea(child: _buildForm(authState));
  }

  Widget _buildForm(AuthState authState) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue learning',
                  style: TextStyle(
                    color: AppColors.grey600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),

                // Login type toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ToggleButton(
                          label: 'Phone',
                          isActive: _isPhoneMode,
                          onTap: () => setState(() => _isPhoneMode = true),
                        ),
                      ),
                      Expanded(
                        child: _ToggleButton(
                          label: 'Email',
                          isActive: !_isPhoneMode,
                          onTap: () => setState(() => _isPhoneMode = false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Email or Phone input
                if (_isPhoneMode) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<String>(
                          initialValue: _countryCode,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          items: _countryCodes
                              .map((c) => DropdownMenuItem(
                                    value: c.$1,
                                    child: Text(c.$1, style: const TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _countryCode = v ?? '+91'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: Validators.phone,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: Validators.email,
                  ),
                ],
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 8),

                if (authState.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    authState.error!,
                    style: const TextStyle(color: AppColors.incorrect, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 24),

                AppButton(
                  label: 'Sign In',
                  isLoading: authState.isLoading,
                  onPressed: _handleLogin,
                  width: double.infinity,
                ),

                const SizedBox(height: 20),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: const TextStyle(color: AppColors.grey600),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? AppColors.white : AppColors.grey600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
