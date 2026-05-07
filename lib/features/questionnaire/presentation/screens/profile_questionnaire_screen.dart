import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/questionnaire_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../core/localization/app_localizations.dart';

class ProfileQuestionnaireScreen extends StatefulWidget {
  final UserProfile? initialProfile;
  const ProfileQuestionnaireScreen({super.key, this.initialProfile});

  @override
  State<ProfileQuestionnaireScreen> createState() => _ProfileQuestionnaireScreenState();
}

class _ProfileQuestionnaireScreenState extends State<ProfileQuestionnaireScreen> {
  final _pageController = PageController();
  final _service = QuestionnaireService();

  int _currentStep = 0;
  bool loading = false;

  // Data
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController(text: '25');
  final TextEditingController _imcCtrl = TextEditingController(text: '22.0');
  final TextEditingController _pseudoCtrl = TextEditingController();
  
  String sopk = 'inconnu';
  bool acneFamilyHistory = false;
  bool smoker = false;
  String alcohol = 'jamais';
  String skinType = 'mixte';
  List<String> cosmeticAllergies = [];
  String hormonalTreatment = 'aucun';
  String acneTreatment = 'aucun';
  List<String> routineMatin = [];
  List<String> routineSoir = [];
  DateTime lastPeriodsDate = DateTime.now();
  List<int> lastCycles = [28, 28, 28];

  final List<String> alcoholOptions = ['jamais', 'occasionnel', 'régulier'];
  final List<String> skinTypeOptions = ['grasse', 'mixte', 'sèche', 'sensible', 'normale', 'acnéique'];
  final List<String> allergiesOptions = ['aucune', 'parfums', 'conservateurs', 'alcool cosmétique', 'nickel', 'filtres solaires', 'rétinol', 'AHA-BHA'];
  final List<String> hormonalOptions = ['pilule', 'implant', 'stérilet', 'aucun'];
  final List<String> acneTreatOptions = ['antibiotiques', 'isotrétinoïne', 'crème topique', 'aucun'];
  final List<String> routineMatinOptions = ['Aucun produit', 'Nettoyant doux', 'Tonique', 'Sérum Vitamine C', 'Crème hydratante', 'SPF'];
  final List<String> routineSoirOptions = ['Aucun produit', 'Démaquillant', 'Nettoyant', 'Actif (Rétinol)', 'Sérum hydratant', 'Crème de nuit'];

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) _populate(widget.initialProfile!);
  }

  void _populate(UserProfile p) {
    _firstNameCtrl.text = p.firstName;
    _pseudoCtrl.text = p.pseudonym ?? '';
    _ageCtrl.text = p.age.toString();
    _imcCtrl.text = p.imc.toString();
    sopk = p.sopk ? 'oui' : 'non';
    acneFamilyHistory = p.acneFamilyHistory;
    smoker = p.smoker;
    alcohol = p.alcohol;
    skinType = p.skinType;
    cosmeticAllergies = List.from(p.cosmeticAllergies);
    hormonalTreatment = p.hormonalTreatment;
    acneTreatment = p.acneTreatment;
    routineMatin = List.from(p.routineMatin);
    routineSoir = List.from(p.routineSoir);
    lastPeriodsDate = p.lastPeriodsDate;
    lastCycles = List.from(p.lastCyclesDuration);
  }

  void _next() {
    if (_currentStep == 0) {
      if (_firstNameCtrl.text.trim().isEmpty || 
          _pseudoCtrl.text.trim().isEmpty || 
          _ageCtrl.text.trim().isEmpty || 
          _imcCtrl.text.trim().isEmpty) {
        _showError('Veuillez remplir toutes vos informations personnelles.');
        return;
      }
    }

    if (_currentStep < 4) {
      _pageController.nextPage(duration: 500.ms, curve: Curves.easeOutQuart);
      setState(() => _currentStep++);
    } else {
      _save();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: 500.ms, curve: Curves.easeOutQuart);
      setState(() => _currentStep--);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  Future<void> _save() async {
    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final profile = UserProfile(
        id: user.uid,
        firstName: _firstNameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text) ?? 25,
        imc: double.tryParse(_imcCtrl.text) ?? 22.0,
        sopk: sopk == 'oui',
        acneFamilyHistory: acneFamilyHistory,
        smoker: smoker,
        cigarettesPerDay: 0,
        alcohol: alcohol,
        skinType: skinType,
        cosmeticAllergies: cosmeticAllergies,
        hormonalTreatment: hormonalTreatment,
        acneTreatment: acneTreatment,
        routineMatin: routineMatin,
        routineSoir: routineSoir,
        lastPeriodsDate: lastPeriodsDate,
        lastCyclesDuration: lastCycles,
        initialPhotos: const {},
        pseudonym: _pseudoCtrl.text.trim(),
      );
      
      await _service.saveUserProfile(profile);
      if (mounted) context.go('/daily-survey?onboarding=true');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Bilan Initial'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_1),
          onPressed: () {
            if (_currentStep > 0) {
              _prev();
            } else if (context.canPop()) {
              context.pop();
            }
          },
        ),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text('${_currentStep + 1}/5', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.primary)),
          )),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -100,
            left: -50,
            child: _Blob(size: 300, color: AppTheme.primary.withOpacity(0.05)),
          ),

          Column(
            children: [
              const SizedBox(height: 100),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _StepIndicator(current: _currentStep),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep(child: _step1(), title: 'Profil Personnel', sub: 'Commençons par faire connaissance.'),
                    _buildStep(child: _step2(), title: 'Type de Peau', sub: 'Identifions ta base dermatologique.'),
                    _buildStep(child: _step3(), title: 'Bilan Médical', sub: 'Tes antécédents et traitements.'),
                    _buildStep(child: _step4(), title: 'Routine Actuelle', sub: 'Quels produits utilises-tu déjà ?'),
                    _buildStep(child: _step5(), title: 'Cycle Menstruel', sub: 'Essentiel pour prédire les poussées.'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: PrimaryButton(
                  label: _currentStep == 4 ? 'TERMINER LE BILAN' : 'CONTINUER',
                  isLoading: loading,
                  onTap: _next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep({required Widget child, required String title, required String sub}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.displaySmall).animate().fadeIn().slideX(begin: -0.1),
          const SizedBox(height: 8),
          Text(sub, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _step1() {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Iconsax.user, size: 20))),
              const SizedBox(height: 20),
              TextField(controller: _pseudoCtrl, decoration: const InputDecoration(labelText: 'Pseudonyme (Forum)', prefixIcon: Icon(Iconsax.mask, size: 20))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TextField(controller: _ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Âge'))),
                  const SizedBox(width: 20),
                  Expanded(child: TextField(controller: _imcCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'IMC'))),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),
        _buildChoiceSection('Avez-vous le SOPK ?', ['oui', 'non', 'inconnu'], sopk, (v) => setState(() => sopk = v)),
        const SizedBox(height: 20),
        _buildSwitch('Antécédents familiaux d\'acné', acneFamilyHistory, (v) => setState(() => acneFamilyHistory = v)),
        _buildSwitch('Fumeuse', smoker, (v) => setState(() => smoker = v)),
      ],
    );
  }

  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWrapChoice('Quel est ton type de peau ?', skinTypeOptions, skinType, (v) => setState(() => skinType = v)),
        const SizedBox(height: 32),
        _buildWrapFilter('Allergies cosmétiques connues', allergiesOptions, cosmeticAllergies, (v, s) {
          setState(() {
            if (v == 'aucune') {
              s ? cosmeticAllergies = ['aucune'] : cosmeticAllergies.remove('aucune');
            } else {
              cosmeticAllergies.remove('aucune');
              s ? cosmeticAllergies.add(v) : cosmeticAllergies.remove(v);
            }
          });
        }),
      ],
    );
  }

  Widget _step3() {
    return Column(
      children: [
        _buildRadioSection('Traitement acné actuel', acneTreatOptions, acneTreatment, (v) => setState(() => acneTreatment = v)),
        const SizedBox(height: 24),
        _buildRadioSection('Contraception / Traitement hormonal', hormonalOptions, hormonalTreatment, (v) => setState(() => hormonalTreatment = v)),
      ],
    );
  }

  Widget _step4() {
    return Column(
      children: [
        _buildCheckSection('Routine Matin', routineMatinOptions, routineMatin, (v, s) {
          setState(() {
            if (v == 'Aucun produit') {
              s ? routineMatin = ['Aucun produit'] : routineMatin.remove('Aucun produit');
            } else {
              routineMatin.remove('Aucun produit');
              s ? routineMatin.add(v) : routineMatin.remove(v);
            }
          });
        }),
        const SizedBox(height: 24),
        _buildCheckSection('Routine Soir', routineSoirOptions, routineSoir, (v, s) {
          setState(() {
            if (v == 'Aucun produit') {
              s ? routineSoir = ['Aucun produit'] : routineSoir.remove('Aucun produit');
            } else {
              routineSoir.remove('Aucun produit');
              s ? routineSoir.add(v) : routineSoir.remove(v);
            }
          });
        }),
      ],
    );
  }

  Widget _step5() {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DATE DES DERNIÈRES RÈGLES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondaryDark)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: lastPeriodsDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                  if (picked != null) setState(() => lastPeriodsDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                  child: Row(
                    children: [
                      const Icon(Iconsax.calendar, color: AppColors.primary, size: 20),
                      const SizedBox(width: 16),
                      Text(DateFormat('dd MMMM yyyy').format(lastPeriodsDate), style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      const Icon(Iconsax.edit, size: 16, color: AppColors.textSecondaryDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('DURÉE DES 3 DERNIERS CYCLES (JOURS)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) => SizedBox(
            width: 90,
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'C${i+1}', border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
                onChanged: (v) => lastCycles[i] = int.tryParse(v) ?? 28,
              ),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildChoiceSection(String title, List<String> options, String current, Function(String) onSel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 12),
        Row(
          children: options.map((o) {
            final sel = current == o;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSel(o),
                child: AnimatedContainer(
                  duration: 300.ms,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sel ? Colors.transparent : Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(child: Text(o.toUpperCase(), style: TextStyle(color: sel ? Colors.white : AppColors.textSecondaryDark, fontSize: 10, fontWeight: FontWeight.w900))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWrapChoice(String title, List<String> options, String current, Function(String) onSel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((o) {
            final sel = current == o;
            return GestureDetector(
              onTap: () => onSel(o),
              child: AnimatedContainer(
                duration: 300.ms,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? Colors.transparent : Colors.white.withOpacity(0.1)),
                ),
                child: Text(o.toUpperCase(), style: TextStyle(color: sel ? Colors.white : AppColors.textSecondaryDark, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWrapFilter(String title, List<String> options, List<String> current, Function(String, bool) onSel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((o) {
            final sel = current.contains(o);
            return GestureDetector(
              onTap: () => onSel(o, !sel),
              child: AnimatedContainer(
                duration: 300.ms,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.surfaceLight),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? Colors.transparent : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : AppColors.dividerLight)),
                ),
                child: Text(o.toUpperCase(), style: TextStyle(color: sel ? Colors.white : AppColors.textMutedPink, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRadioSection(String title, List<String> options, String current, Function(String) onSel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: options.map((o) => RadioListTile<String>(
              activeColor: AppColors.primary,
              title: Text(o.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              value: o,
              groupValue: current,
              onChanged: (v) => onSel(v!),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckSection(String title, List<String> options, List<String> current, Function(String, bool) onSel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: options.map((o) => CheckboxListTile(
              activeColor: AppColors.primary,
              title: Text(o.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              value: current.contains(o),
              onChanged: (v) => onSel(o, v!),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool val, Function(bool) onCh) {
    return SwitchListTile.adaptive(
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      value: val,
      onChanged: onCh,
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final active = i <= current;
        return Expanded(
          child: AnimatedContainer(
            duration: 500.ms,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: active ? AppColors.primary : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
          ),
        );
      }),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])));
  }
}
