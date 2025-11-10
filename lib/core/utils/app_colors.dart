import 'package:flutter/material.dart';

class AppColors {
  // Modern Fintech Light Theme - Sleek Blues & Purples
  static const Color lightPrimary = Color(0xFF6366F1); // Indigo - Modern fintech
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFF8B5CF6); // Purple accent
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate gray-blue
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF0F172A); // Deep navy text
  static const Color lightOnSurface = Color(0xFF0F172A);
  static const Color lightOutline = Color(0xFFE2E8F0); // Light slate
  static const Color lightError = Color(0xFFEF4444);
  static const Color lightOnError = Color(0xFFFFFFFF);
  
  // Light Theme - Text Colors (Professional)
  static const Color lightTextPrimary = Color(0xFF0F172A); // Deep navy
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate
  static const Color lightTextDisabled = Color(0xFF94A3B8); // Light slate

  // Modern Fintech Dark Theme - Deep Blues & Vibrant Accents
  static const Color darkPrimary = Color(0xFF818CF8); // Lighter indigo for dark
  static const Color darkOnPrimary = Color(0xFF0F172A);
  static const Color darkSecondary = Color(0xFFA78BFA); // Lighter purple
  static const Color darkOnSecondary = Color(0xFF0F172A);
  static const Color darkBackground = Color(0xFF0F172A); // Deep navy background
  static const Color darkSurface = Color(0xFF1E293B); // Slate card background
  static const Color darkOnBackground = Color(0xFFF8FAFC);
  static const Color darkOnSurface = Color(0xFFF8FAFC);
  static const Color darkOutline = Color(0xFF334155); // Slate border
  static const Color darkError = Color(0xFFF87171);
  static const Color darkOnError = Color(0xFF0F172A);
  
  // Dark Theme - Text Colors
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Off-white
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate
  static const Color darkTextDisabled = Color(0xFF64748B); // Dark slate

  // Modern Fintech Header & Card Colors
  static const Color darkHeaderStart = Color(0xFF0F172A); // Deep navy start
  static const Color darkHeaderEnd = Color(0xFF1E293B); // Slate end
  static const Color darkCardBackground = Color(0xFF1E293B); // Slate cards
  static const Color darkCardBorder = Color(0xFF334155); // Slate borders
  
  static const Color lightHeaderStart = Color(0xFFF8FAFC); // Slate gray-blue
  static const Color lightHeaderEnd = Color(0xFFFFFFFF); // White
  static const Color lightCardBackground = Color(0xFFFFFFFF); // White cards
  static const Color lightCardBorder = Color(0xFFE2E8F0); // Light slate borders

  // Status Colors (Universal)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Asset Type Colors - Modern Fintech Palette
  static const Color currencyColor = Color(0xFF3B82F6); // Blue
  static const Color goldColor = Color(0xFFFBBF24); // Bright gold
  static const Color bankColor = Color(0xFF8B5CF6); // Purple
  static const Color cashColor = Color(0xFF10B981); // Emerald
  static const Color stockColor = Color(0xFFEC4899); // Pink
  static const Color creditCardColor = Color(0xFFEF4444); // Red
  static const Color loanColor = Color(0xFFF59E0B); // Amber
  static const Color realEstateColor = Color(0xFF14B8A6); // Teal
  
  // Gradient Colors for Modern UI
  static const Color gradientStart = Color(0xFF6366F1); // Indigo
  static const Color gradientMid = Color(0xFF8B5CF6); // Purple
  static const Color gradientEnd = Color(0xFFEC4899); // Pink
  
  // Accent Colors
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan
  static const Color accentTeal = Color(0xFF14B8A6); // Teal
  static const Color accentLime = Color(0xFF84CC16); // Lime

  // Snackbar Colors (Theme-Aware)
  // Light Theme Snackbars
  static const Color lightSnackbarError = Color(0xFFDC2626);
  static const Color lightSnackbarSuccess = Color(0xFF059669);
  static const Color lightSnackbarWarning = Color(0xFFD97706);
  static const Color lightSnackbarInfo = Color(0xFF2563EB);
  
  // Dark Theme Snackbars
  static const Color darkSnackbarError = Color(0xFFF87171);
  static const Color darkSnackbarSuccess = Color(0xFF34D399);
  static const Color darkSnackbarWarning = Color(0xFFFBBF24);
  static const Color darkSnackbarInfo = Color(0xFF60A5FA);
  
  // Legacy support
  static const Color snackbarError = darkSnackbarError;
  static const Color snackbarSuccess = darkSnackbarSuccess;
  static const Color snackbarWarning = darkSnackbarWarning;
  static const Color snackbarInfo = darkSnackbarInfo;
}
