import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:go_router/go_router.dart';

import 'package:acneia/core/theme/app_theme.dart';

import 'package:acneia/core/services/language_service.dart';




class LanguageSelectionScreen extends StatefulWidget {

  final bool isFromProfile;

  const LanguageSelectionScreen({super.key, this.isFromProfile = false});



  @override

  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();

}



class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {

  final _langService = LanguageService();

  String _selectedLang = 'fr';



  @override

  void initState() {

    super.initState();

    _loadCurrentLang();

  }



  void _loadCurrentLang() async {

    final lang = await _langService.getLanguage();

    setState(() => _selectedLang = lang);

  }



  void _selectLanguage(String code) async {

    await _langService.setLanguage(code);

    setState(() => _selectedLang = code);

    

    if (mounted) {

      if (widget.isFromProfile) {

        context.pop(); // Retour au profil

      } else {

        context.go('/welcome'); // Premier lancement -> Welcome

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,

        decoration: BoxDecoration(

          gradient: LinearGradient(

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

            colors: [AppTheme.primary.withValues(alpha: 0.05), Colors.white],

          ),

        ),

        child: SafeArea(

          child: Padding(

            padding: const EdgeInsets.symmetric(horizontal: 32),

            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                const Text('🌍', style: TextStyle(fontSize: 64)),

                const SizedBox(height: 24),

                Text(

                  'Choisissez votre langue',

                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),

                  textAlign: TextAlign.center,

                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

                const SizedBox(height: 8),

                const Text(

                  'Choose your preferred language',

                  style: TextStyle(color: Colors.grey, fontSize: 16),

                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 48),

                

                _buildLangButton(

                  title: 'Français',

                  subtitle: 'French',

                  code: 'fr',

                  flag: '🧴‡«🧴‡·',

                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

                

                const SizedBox(height: 16),

                

                _buildLangButton(

                  title: 'English',

                  subtitle: 'Anglais',

                  code: 'en',

                  flag: '🧴‡º🧴‡¸',

                ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),

              ],

            ),

          ),

        ),

      ),

    );

  }



  Widget _buildLangButton({required String title, required String subtitle, required String code, required String flag}) {

    final isSelected = _selectedLang == code;

    return InkWell(

      onTap: () => _selectLanguage(code),

      borderRadius: BorderRadius.circular(20),

      child: Container(

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(

            color: isSelected ? AppTheme.primary : Colors.grey.withValues(alpha: 0.2),

            width: isSelected ? 2 : 1,

          ),

          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.1), blurRadius: 15)] : [],

        ),

        child: Row(

          children: [

            Text(flag, style: const TextStyle(fontSize: 32)),

            const SizedBox(width: 20),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),

                ],

              ),

            ),

            if (isSelected)

              Icon(Icons.check_circle, color: AppTheme.primary),

          ],

        ),

      ),

    );

  }

}







































