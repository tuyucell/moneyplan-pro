import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invest_guide/core/router/app_router.dart';
import 'package:invest_guide/features/auth/presentation/providers/auth_providers.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/features/auth/data/models/user_model.dart';
import 'package:invest_guide/core/services/security/audit_service.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/services/security/biometric_service.dart';
import 'package:invest_guide/core/services/security/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invest_guide/core/providers/common_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveEmailIfRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailController.text.trim());
    } else {
      await prefs.remove('remembered_email');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin(String lc) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (mounted) {
        await _saveEmailIfRememberMe();
        // Audit Log
        await ref
            .read(auditServiceProvider)
            .logAction(action: 'LOGIN_EMAIL', details: {'method': 'email'});
        await _navigateAfterLogin();
      }
    } catch (e) {
      debugPrint('SIGN_IN_ERROR: $e');
      messenger.showSnackBar(
        SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text(
                '${AppStrings.tr(AppStrings.loginFailed, lc)}: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin(String lc) async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();

      if (mounted) {
        // Audit Log
        await ref.read(auditServiceProvider).logAction(
          action: 'LOGIN_GOOGLE',
          details: {'method': 'google'},
        );
        await _navigateAfterLogin();
      }
    } catch (e) {
      debugPrint('GOOGLE_AUTH_ERROR: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.tr(AppStrings.googleLoginFailed, lc)}: ${e.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateAfterLogin() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      final user = authState.user;

      // Offer biometrics if not yet enabled, available and using email provider
      if (user.authProvider == 'email') {
        await _checkAndOfferBiometrics(user.email);
      }

      if (mounted) {
        if (!user.isProfileCompleted) {
          GoRouter.of(context).go(AppRouter.userDetails);
        } else {
          GoRouter.of(context).go(AppRouter.home);
        }
      }
    } else {
      if (mounted) GoRouter.of(context).go(AppRouter.home);
    }
  }

  Future<void> _checkAndOfferBiometrics(String email) async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final biometricService = ref.read(biometricServiceProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    // Don't ask if already asked in this device or if it's already enabled
    final hasBeenAsked = prefs.getBool('biometric_asked_$email') ?? false;
    if (hasBeenAsked) return;

    final isEnabled = await secureStorage.isBiometricEnabled();
    final isAvailable = await biometricService.isBiometricAvailable();

    if (!isEnabled && isAvailable && mounted) {
      await _showBiometricOfferDialog(email);
    }
  }

  Future<void> _showBiometricOfferDialog(String email) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title:
            Text(_rememberMe ? 'Hızlı Giriş' : 'Hızlı Giriş Aktif Edilsin mi?'),
        content: const Text(
            'Bir sonraki girişinizde şifre yazmak yerine biometrik verinizi kullanmak ister misiniz?'),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setBool('biometric_asked_$email', true);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Daha Sonra'),
          ),
          ElevatedButton(
            onPressed: () async {
              await prefs.setBool('biometric_asked_$email', true);
              final password = _passwordController.text.trim();
              if (password.isNotEmpty) {
                await ref
                    .read(authNotifierProvider.notifier)
                    .registerBiometrics(email, password);
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Biometrik giriş aktif edildi!')),
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Evet, Aktif Et'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBiometricLogin(String lc) async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithBiometrics(
            localizedReason: lc == 'tr'
                ? 'Giriş yapmak için doğrulama yapın'
                : 'Authenticate to sign in',
          );
      if (mounted) await _navigateAfterLogin();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Biometrik Giriş Hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword(String lc) async {
    final email = _emailController.text.trim();
    final emailController = TextEditingController(text: email);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.tr(AppStrings.forgotPassword, lc)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lc == 'tr'
                ? 'Şifre sıfırlama bağlantısı gönderilecek e-posta adresini girin:'
                : 'Enter the email address to send the password reset link:'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: AppStrings.tr(AppStrings.email, lc),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lc == 'tr' ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final emailToReset = emailController.text.trim();
              if (emailToReset.isEmpty) return;

              Navigator.pop(context);
              setState(() => _isLoading = true);

              final messenger = ScaffoldMessenger.of(context);

              try {
                await ref
                    .read(authNotifierProvider.notifier)
                    .sendPasswordResetEmail(emailToReset);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(lc == 'tr'
                        ? 'Sıfırlama e-postası gönderildi!'
                        : 'Reset email sent!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: Text(lc == 'tr' ? 'Gönder' : 'Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/logo_premium.png',
                        height: 70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MoneyPlan Pro',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                          color: AppColors.textPrimary(context),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lc == 'tr'
                        ? 'Finansal özgürlüğünü yönet'
                        : 'Master your financial freedom',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary(context), fontSize: 15),
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  _buildInputField(
                    controller: _emailController,
                    label: AppStrings.tr(AppStrings.email, lc),
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? 'Email required' : null,
                  ),
                  const SizedBox(height: 18),

                  // Password Field
                  _buildInputField(
                    controller: _passwordController,
                    label: AppStrings.tr(AppStrings.passwordLabel, lc),
                    icon: Icons.lock_open_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) =>
                        v!.length < 6 ? 'Password too short' : null,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v!),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Text(
                          lc == 'tr' ? 'Beni Hatırla' : 'Remember Me',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary(context)),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _handleForgotPassword(lc),
                        child: Text(
                          AppStrings.tr(AppStrings.forgotPassword, lc),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleEmailLogin(lc),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(AppStrings.tr(AppStrings.loginBtn, lc),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppStrings.tr(AppStrings.orLabel, lc),
                          style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 13),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Google Login Button
                  SizedBox(
                    height: 54, // Fixed height to prevent pixel errors
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => _handleGoogleLogin(lc),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border(context)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg', // More reliable CDN or SVG
                            height: 20,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.login, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            lc == 'tr'
                                ? 'Google ile Devam Et'
                                : 'Continue with Google',
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Biometric Login Button (Only if supported)
                  Consumer(
                    builder: (context, ref, child) {
                      final biometricService =
                          ref.watch(biometricServiceProvider);
                      return FutureBuilder<bool>(
                        future: biometricService.isBiometricAvailable(),
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () => _handleBiometricLogin(lc),
                              icon: const Icon(Icons.face_unlock_rounded,
                                  color: AppColors.primary),
                              label: Text(
                                  lc == 'tr'
                                      ? 'Yüz / Parmak İzi'
                                      : 'Face / Touch ID',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side:
                                    const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppStrings.tr(AppStrings.noAccount, lc)),
                      TextButton(
                        onPressed: () => context.push(AppRouter.signup),
                        child: Text(
                          AppStrings.tr(AppStrings.signUp, lc),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
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
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface(context),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
