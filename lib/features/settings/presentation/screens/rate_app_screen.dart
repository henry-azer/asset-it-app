import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:asset_it/config/localization/app_localization.dart';
import 'package:asset_it/core/constants/personal_links.dart';
import 'package:asset_it/core/utils/app_colors.dart';
import 'package:asset_it/core/utils/app_strings.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameFieldKey = GlobalKey<FormFieldState>();
  final _descriptionFieldKey = GlobalKey<FormFieldState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;



  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.selectRating.tr)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final url = PersonalLinks.getByName('rating-url');
    final nameKey = PersonalLinks.getByName('rating-name-entry');
    final rateKey = PersonalLinks.getByName('rating-rate-entry');
    final descriptionKey = PersonalLinks.getByName('rating-description-entry');

    try {
      await http.post(
        Uri.parse(url!),
        body: {
          nameKey: _nameController.text,
          rateKey: _rating.toString(),
          descriptionKey: _descriptionController.text,
        },
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.thankYouFeedback.tr)),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.submitError.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.rateAppSubtitle.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildFieldLabel(AppStrings.yourName.tr, isDark),
                      const SizedBox(height: 8),
                      _buildTextField(
                        fieldKey: _nameFieldKey,
                        controller: _nameController,
                        hintText: AppStrings.enterYourName.tr,
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.nameRequired.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      _buildFieldLabel(AppStrings.ratingLabel.tr, isDark),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              AppStrings.howWouldYouRate.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRatingStars(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildFieldLabel(AppStrings.description.tr, isDark),
                      const SizedBox(height: 8),
                      _buildTextField(
                        fieldKey: _descriptionFieldKey,
                        controller: _descriptionController,
                        hintText: AppStrings.enterDescription.tr,
                        icon: Icons.chat_bubble_outline_rounded,
                        isDark: isDark,
                        maxLines: 6,
                      ),
                      const SizedBox(height: 32),

                      _buildSubmitButton(isDark),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.rateApp.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.rateAppDescription.tr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = starNumber;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starNumber <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
              size: 40,
              color: starNumber <= _rating
                  ? Colors.amber
                  : Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextDisabled
                      : AppColors.lightTextDisabled,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFieldLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildTextField({
    GlobalKey<FormFieldState>? fieldKey,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkSnackbarError : AppColors.lightSnackbarError,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkSnackbarError : AppColors.lightSnackbarError,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
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
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                AppStrings.submit.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
