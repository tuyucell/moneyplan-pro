import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/core/router/app_router.dart';
import 'package:moneyplan_pro/features/auth/presentation/providers/auth_providers.dart';
import 'package:moneyplan_pro/features/auth/data/models/user_model.dart';

class UserDetailsPage extends ConsumerStatefulWidget {
  const UserDetailsPage({super.key});

  @override
  ConsumerState<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends ConsumerState<UserDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _birthYearController = TextEditingController();
  final _occupationController = TextEditingController();

  String? _selectedGender;
  String? _selectedGoal;
  String? _selectedRisk;
  bool _isLoading = false;

  @override
  void dispose() {
    _birthYearController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(String lc) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        final updatedUser = UserModel(
          id: user.id,
          email: user.email,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
          createdAt: user.createdAt,
          lastLoginAt: user.lastLoginAt,
          authProvider: user.authProvider,
          birthYear: int.tryParse(_birthYearController.text),
          gender: _selectedGender,
          occupation: _occupationController.text,
          financialGoal: _selectedGoal,
          riskTolerance: _selectedRisk,
          isProfileCompleted: true,
        );

        await ref
            .read(authNotifierProvider.notifier)
            .updateProfile(updatedUser);

        if (mounted) {
          context.go(AppRouter.home);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.tr(AppStrings.error, lc)}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppStrings.tr(AppStrings.onboardingFinishTitle, lc)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.grey900,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.tr(AppStrings.onboardingFinishDesc, lc),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.grey600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Birth Year
                TextFormField(
                  controller: _birthYearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr(AppStrings.birthYear, lc),
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final year = int.tryParse(value);
                    if (year == null ||
                        year < 1900 ||
                        year > DateTime.now().year) {
                      return AppStrings.tr(AppStrings.error, lc);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Gender
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppStrings.tr(AppStrings.gender, lc),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  initialValue: _selectedGender,
                  items: [
                    DropdownMenuItem(
                        value: 'male',
                        child: Text(AppStrings.tr(AppStrings.genderMale, lc))),
                    DropdownMenuItem(
                        value: 'female',
                        child:
                            Text(AppStrings.tr(AppStrings.genderFemale, lc))),
                    DropdownMenuItem(
                        value: 'other',
                        child: Text(AppStrings.tr(AppStrings.genderOther, lc))),
                  ],
                  onChanged: (val) => setState(() => _selectedGender = val),
                ),
                const SizedBox(height: 16),

                // Occupation
                TextFormField(
                  controller: _occupationController,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr(AppStrings.occupation, lc),
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Goal
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppStrings.tr(AppStrings.financialGoalLabel, lc),
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                  initialValue: _selectedGoal,
                  items: [
                    DropdownMenuItem(
                        value: 'savings',
                        child: Text(AppStrings.tr(AppStrings.goalSavings, lc))),
                    DropdownMenuItem(
                        value: 'investment',
                        child:
                            Text(AppStrings.tr(AppStrings.goalInvestment, lc))),
                    DropdownMenuItem(
                        value: 'retirement',
                        child:
                            Text(AppStrings.tr(AppStrings.goalRetirement, lc))),
                    DropdownMenuItem(
                        value: 'debt',
                        child: Text(AppStrings.tr(AppStrings.goalDebt, lc))),
                  ],
                  onChanged: (val) => setState(() => _selectedGoal = val),
                ),
                const SizedBox(height: 16),

                // Risk Tolerance
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: AppStrings.tr(AppStrings.riskToleranceLabel, lc),
                    prefixIcon: const Icon(Icons.speed_outlined),
                  ),
                  initialValue: _selectedRisk,
                  items: [
                    DropdownMenuItem(
                        value: 'low',
                        child: Text(AppStrings.tr(AppStrings.riskLow, lc))),
                    DropdownMenuItem(
                        value: 'medium',
                        child: Text(AppStrings.tr(AppStrings.riskMedium, lc))),
                    DropdownMenuItem(
                        value: 'high',
                        child: Text(AppStrings.tr(AppStrings.riskHigh, lc))),
                  ],
                  onChanged: (val) => setState(() => _selectedRisk = val),
                ),
                const SizedBox(height: 48),

                ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleSave(lc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          AppStrings.tr(AppStrings.saveProfile, lc),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),

                TextButton(
                  onPressed: () => context.go(AppRouter.home),
                  child: Text(AppStrings.tr(AppStrings.btnSkip, lc),
                      style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
