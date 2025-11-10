import 'package:asset_it/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/config/routes/app_routes.dart';
import 'package:asset_it/core/utils/app_assets_manager.dart';
import 'package:asset_it/core/utils/app_strings.dart';
import 'package:asset_it/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState> _usernameKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _passwordKey = GlobalKey<FormFieldState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          backgroundColor: isDark? AppColors.darkBackground : AppColors.lightBackground,
          title: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              AppStrings.register.tr.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          )),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    AppImageAssets.signup,
                    height: MediaQuery.of(context).size.height * 0.25,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppStrings.username.tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              maxLength: 18,
                              key: _usernameKey,
                              controller: _usernameController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.grey.shade800,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: AppStrings.enterYourUsername.tr,
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F1329) : Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade400,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.red.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.red.shade400,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                counterText: '',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppStrings.validationUsernameRequired.tr;
                                }
                                if (value.trim().length < 3) {
                                  return AppStrings.validationUsernameMinLength.tr;
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _usernameKey.currentState?.validate();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppStrings.password.tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              maxLength: 22,
                              key: _passwordKey,
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.grey.shade800,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: AppStrings.enterPasswordHint.tr,
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F1329) : Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade400,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.red.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.red.shade400,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                counterText: '',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppStrings.validationPasswordRequired.tr;
                                }
                                if (value.trim().length < 4) {
                                  return AppStrings.validationPasswordMinLength.tr;
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _passwordKey.currentState?.validate();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Container(
                        width: double.infinity,
                        decoration: _isRegistering
                            ? null
                            : BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                        child: ElevatedButton(
                          onPressed: _isRegistering ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRegistering
                                ? null
                                : Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isRegistering
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  AppStrings.register.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isRegistering = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      await authProvider.login(_passwordController.text);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.accountCreationSuccess.tr)),
      );
      Navigator.pushReplacementNamed(context, Routes.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.accountCreationError.tr)),
      );
    }

    setState(() {
      _isRegistering = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
