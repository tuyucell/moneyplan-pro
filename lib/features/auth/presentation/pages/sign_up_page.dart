import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/core/router/app_router.dart';
import 'package:moneyplan_pro/features/auth/data/models/user_model.dart';
import 'package:moneyplan_pro/features/auth/presentation/providers/auth_providers.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp(String lc) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );

      if (mounted) {
        _navigateAfterSignUp();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateAfterSignUp() {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      context.go(AppRouter.userDetails);
    } else {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary(context)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  lc == 'tr' ? 'Yeni Hesap Oluştur' : 'Create New Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  lc == 'tr'
                      ? 'Finansal yolculuğuna bugün başla.'
                      : 'Start your financial journey today.',
                  style: TextStyle(
                      color: AppColors.textSecondary(context), fontSize: 16),
                ),
                const SizedBox(height: 40),

                // Name Field
                _buildTextField(
                  controller: _nameController,
                  label: lc == 'tr' ? 'Ad Soyad' : 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty
                      ? (lc == 'tr' ? 'Ad gerekli' : 'Name required')
                      : null,
                ),
                const SizedBox(height: 20),

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: AppStrings.tr(AppStrings.email, lc),
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (!v!.contains('@'))
                      ? AppStrings.tr(AppStrings.invalidEmail, lc)
                      : null,
                ),
                const SizedBox(height: 20),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  label: AppStrings.tr(AppStrings.passwordLabel, lc),
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) => v!.length < 6
                      ? AppStrings.tr(AppStrings.passwordTooShort, lc)
                      : null,
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleSignUp(lc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(lc == 'tr' ? 'Hesap Oluştur' : 'Sign Up',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(lc == 'tr'
                        ? 'Zaten hesabın var mı?'
                        : 'Already have an account?'),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(AppStrings.tr(AppStrings.loginBtn, lc),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
