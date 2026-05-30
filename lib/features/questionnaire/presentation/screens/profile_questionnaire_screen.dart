import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/features/questionnaire/data/services/questionnaire_service.dart';
import 'package:acneia/core/localization/app_localizations.dart';
import 'package:acneia/features/questionnaire/domain/entities/user_profile.dart';

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
  bool isEditing = true;
  bool isNewProfile = true;

  // Data (Storing technical KEYS)
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController(text: '25');
  final TextEditingController _imcCtrl = TextEditingController(text: '22.0');
  final TextEditingController _pseudoCtrl = TextEditingController();
  
  String sopk = 'option_no'; // Keys: 'option_yes', 'option_no'
  bool acneFamilyHistory = false;
  bool smoker = false;
  String alcohol = 'freq_never'; // Keys: 'freq_never', 'freq_occasionally', 'freq_daily'
  String skinType = 'skin_mixte'; // Keys: 'skin_grasse', 'skin_mixte', etc.
  List<String> cosmeticAllergies = []; // Keys: 'allergy_none', 'allergy_perfume', etc.
  String hormonalTreatment = 'hormonal_none'; // Keys: 'hormonal_pill', etc.
  String acneTreatment = 'treat_none';       // Keys: 'treat_antibiotics', etc.
  List<String> routineMatin = [];            // Keys: 'prod_none', 'prod_cleanser', etc.
  List<String> routineSoir = [];
  DateTime lastPeriodsDate = DateTime.now();
  List<int> lastCycles = [28, 28, 28];
  int menstruationDuration = 5;

  final List<String> alcoholOptionKeys = ['freq_never', 'freq_occasionally', 'freq_daily'];
  final List<String> skinTypeOptionKeys = ['skin_grasse', 'skin_mixte', 'skin_seche', 'skin_sensible', 'skin_normale', 'skin_acneique'];
  final List<String> allergiesOptionKeys = ['allergy_none', 'allergy_perfume', 'allergy_preservatives', 'allergy_alcohol', 'allergy_nickel', 'allergy_sunscreen', 'allergy_retinol', 'allergy_aha_bha'];
  final List<String> hormonalOptionKeys = ['hormonal_pill', 'hormonal_implant', 'hormonal_iud', 'hormonal_none'];
  final List<String> acneTreatOptionKeys = ['treat_antibiotics', 'treat_isotretinoin', 'treat_topical', 'treat_none'];
  final List<String> routineMatinOptionKeys = ['prod_none', 'prod_cleanser', 'prod_tonic', 'prod_vit_c', 'prod_moisturizer', 'prod_spf'];
  final List<String> routineSoirOptionKeys = ['prod_none', 'prod_makeup_remover', 'prod_cleanser', 'prod_retinol', 'prod_hydrating_serum', 'prod_night_cream'];

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _populate(widget.initialProfile!);
      isEditing = false;
      isNewProfile = false;
    } else {
      _fetchExistingData();
    }
  }

  Future<void> _fetchExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final profile = await _service.fetchUserProfile(user.uid);
    if (profile != null && mounted) {
      _populate(profile);
      setState(() {
        isNewProfile = profile.skinType.isEmpty;
        isEditing = isNewProfile;
      });
      return;
    }
    
    final snap = await FirebaseFirestore.instance.collection('public_profiles').doc(user.uid).get();
    if (snap.exists && mounted) {
      setState(() {
        _pseudoCtrl.text = snap.data()?['pseudonym'] ?? '';
      });
    }
  }

  void _populate(UserProfile p) {
    _firstNameCtrl.text = p.firstName;
    _pseudoCtrl.text = p.pseudonym ?? '';
    _ageCtrl.text = p.age.toString();
    _imcCtrl.text = p.imc.toString();
    sopk = p.sopk ? 'option_yes' : 'option_no';
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
    menstruationDuration = p.menstruationDuration;
  }

  void _next() {
    final l = AppLocalizations.of(context);
    
    // VALIDATION PER STEP
    if (_currentStep == 0) {
      if (_firstNameCtrl.text.trim().isEmpty || 
          _pseudoCtrl.text.trim().isEmpty ||
          _ageCtrl.text.trim().isEmpty || 
          _imcCtrl.text.trim().isEmpty) {
        _showError(l.translate('personal_info_required'));
        return;
      }
    } else if (_currentStep == 1) {
      if (skinType.isEmpty) {
        _showError(l.translate('select_skin_type'));
        return;
      }
    } else if (_currentStep == 2) {
      if (acneTreatment.isEmpty || hormonalTreatment.isEmpty) {
        _showError(l.translate('select_treatments'));
        return;
      }
    } else if (_currentStep == 3) {
      if (routineMatin.isEmpty && routineSoir.isEmpty) {
        _showError(l.translate('select_routine'));
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
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
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
        sopk: sopk == 'option_yes',
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
        menstruationDuration: menstruationDuration,
        initialPhotos: widget.initialProfile?.initialPhotos ?? {},
        pseudonym: _pseudoCtrl.text.trim(),
      );

      await _service.saveUserProfile(profile);
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/daily-survey?onboarding=true');
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    debugPrint("DEBUG AUDIT: ProfileQuestionnaireScreen REBUILDING with locale = ${l.locale.languageCode}");
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.translate('initial_title')),
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
          if (!isEditing)
            TextButton.icon(
              icon: Icon(Iconsax.edit, size: 16, color: AppColors.primary),
              label: Text(l.translate('edit').toUpperCase(), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () => setState(() => isEditing = true),
            ),
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 20, left: 10),
            child: Text('${_currentStep + 1}/5', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.primary)),
          )),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: _Blob(size: 300, color: AppTheme.primary.withValues(alpha: 0.05)),
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
                  physics: isEditing ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                  onPageChanged: (idx) => setState(() => _currentStep = idx),
                  children: [
                    _buildStep(child: _step1(l), title: l.translate('personal_profile'), sub: l.translate('onboarding_desc')),
                    _buildStep(child: _step2(l), title: l.translate('skin_type_label'), sub: l.translate('skin_type_question')),
                    _buildStep(child: _step3(l), title: l.translate('medical_bilan'), sub: l.translate('acne_treatment_question')),
                    _buildStep(child: _step4(l), title: l.translate('current_routine'), sub: l.translate('routine_followed')),
                    _buildStep(child: _step5(l), title: l.translate('menstrual_cycle_label'), sub: l.translate('last_period_date')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: !isEditing
                  ? (_currentStep == 4 
                      ? PrimaryButton(label: l.translate('close'), onTap: () => context.pop())
                      : PrimaryButton(label: l.translate('continue'), onTap: () => _pageController.nextPage(duration: 500.ms, curve: Curves.easeOutQuart)))
                  : PrimaryButton(
                      label: _currentStep == 4 ? (!isNewProfile ? l.translate('save') : l.translate('finish')) : l.translate('continue'),
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
          AbsorbPointer(
            absorbing: !isEditing,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _step1(AppLocalizations l) {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(controller: _firstNameCtrl, readOnly: !isEditing, decoration: InputDecoration(labelText: l.translate('first_name'), prefixIcon: const Icon(Iconsax.user, size: 20))),
              const SizedBox(height: 20),
              TextField(
                controller: _pseudoCtrl,
                readOnly: !isEditing,
                decoration: InputDecoration(
                  labelText: l.translate('pseudonym_forum'),
                  prefixIcon: const Icon(Iconsax.mask, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TextField(controller: _ageCtrl, readOnly: !isEditing, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.translate('age_label')))),
                  const SizedBox(width: 20),
                  Expanded(child: TextField(controller: _imcCtrl, readOnly: !isEditing, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.translate('imc_label')))),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),
        _buildChoiceSection(l.translate('pcos_question'), ['option_yes', 'option_no'], sopk, (v) => setState(() => sopk = v)),
        const SizedBox(height: 20),
        _buildSwitch(l.translate('acne_family'), acneFamilyHistory, (v) => setState(() => acneFamilyHistory = v)),
        _buildSwitch(l.translate('smoker_label'), smoker, (v) => setState(() => smoker = v)),
      ],
    );
  }

  Widget _step2(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWrapChoice(l.translate('skin_type_question'), skinTypeOptionKeys, skinType, (v) => setState(() => skinType = v)),
        const SizedBox(height: 32),
        _buildWrapFilter(l.translate('cosmetic_allergies'), allergiesOptionKeys, cosmeticAllergies, (v, s) {
          setState(() {
            if (v == 'allergy_none') {
              s ? cosmeticAllergies = ['allergy_none'] : cosmeticAllergies.remove('allergy_none');
            } else {
              cosmeticAllergies.remove('allergy_none');
              s ? cosmeticAllergies.add(v) : cosmeticAllergies.remove(v);
            }
          });
        }),
      ],
    );
  }

  Widget _step3(AppLocalizations l) {
    return Column(
      children: [
        _buildRadioSection(l.translate('acne_treatment_question'), acneTreatOptionKeys, acneTreatment, (v) => setState(() => acneTreatment = v)),
        const SizedBox(height: 24),
        _buildRadioSection(l.translate('hormonal_treatment_question'), hormonalOptionKeys, hormonalTreatment, (v) => setState(() => hormonalTreatment = v)),
      ],
    );
  }

  Widget _step4(AppLocalizations l) {
    return Column(
      children: [
        _buildCheckSection(l.translate('morning_routine'), routineMatinOptionKeys, routineMatin, (v, s) {
          setState(() {
            if (v == 'prod_none') {
              s ? routineMatin = ['prod_none'] : routineMatin.remove('prod_none');
            } else {
              routineMatin.remove('prod_none');
              s ? routineMatin.add(v) : routineMatin.remove(v);
            }
          });
        }),
        const SizedBox(height: 24),
        _buildCheckSection(l.translate('evening_routine'), routineSoirOptionKeys, routineSoir, (v, s) {
          setState(() {
            if (v == 'prod_none') {
              s ? routineSoir = ['prod_none'] : routineSoir.remove('prod_none');
            } else {
              routineSoir.remove('prod_none');
              s ? routineSoir.add(v) : routineSoir.remove(v);
            }
          });
        }),
      ],
    );
  }

  Widget _step5(AppLocalizations l) {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.translate('last_period_date'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondaryDark)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: lastPeriodsDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                  if (picked != null) setState(() => lastPeriodsDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                  child: Row(
                    children: [
                      Icon(Iconsax.calendar, color: AppColors.primary, size: 20),
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
        Text(l.translate('menstruation_duration_label'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: menstruationDuration.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => menstruationDuration = v.toInt()),
              ),
            ),
            Text('$menstruationDuration', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
            const SizedBox(width: 8),
            Text(l.translate('days_label').toLowerCase(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
          ],
        ),
        const SizedBox(height: 32),
        Text(l.translate('cycle_duration_3'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) => SizedBox(
            width: 90,
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: TextField(
                textAlign: TextAlign.center,
                readOnly: !isEditing,
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

  Widget _buildChoiceSection(String title, List<String> optionKeys, String current, Function(String) onSel) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 12),
        Row(
          children: optionKeys.map((key) {
            final sel = current == key;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSel(key),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? Colors.transparent : Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Center(child: Text(l.translate(key).toUpperCase(), style: TextStyle(color: sel ? Colors.white : AppColors.textSecondaryDark, fontSize: 10, fontWeight: FontWeight.w900))),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool val, Function(bool) onCh) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: SwitchListTile.adaptive(
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          value: val,
          onChanged: onCh,
        ),
      ),
    );
  }

  Widget _buildWrapChoice(String title, List<String> optionKeys, String current, Function(String) onSel) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: optionKeys.map((key) {
            final sel = current == key;
            return GestureDetector(
              onTap: () => onSel(key),
              child: AnimatedContainer(
                duration: 300.ms,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? Colors.transparent : Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(l.translate(key).toUpperCase(), style: TextStyle(color: sel ? Colors.white : AppColors.textSecondaryDark, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWrapFilter(String title, List<String> optionKeys, List<String> current, Function(String, bool) onSel) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: optionKeys.map((key) {
            final sel = current.contains(key);
            return GestureDetector(
              onTap: () => onSel(key, !sel),
              child: AnimatedContainer(
                duration: 300.ms,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? Colors.transparent : Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(l.translate(key).toUpperCase(), style: TextStyle(color: sel ? Colors.white : AppColors.textSecondaryDark, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRadioSection(String title, List<String> optionKeys, String current, Function(String) onSel) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondaryDark)),
        RadioGroup<String>(
          groupValue: current,
          onChanged: (v) { if (v != null) onSel(v); },
          child: Column(
            children: optionKeys.map((key) => RadioListTile<String>(
              title: Text(l.translate(key)),
              value: key,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckSection(String title, List<String> optionKeys, List<String> current, Function(String, bool) onSel) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 12),
        ...optionKeys.map((key) => CheckboxListTile(
          title: Text(l.translate(key)),
          value: current.contains(key),
          onChanged: (v) => onSel(key, v!),
          activeColor: AppColors.primary,
          controlAffinity: ListTileControlAffinity.leading, // Fixed parameter name
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) => Expanded(
        child: Container(
          height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(color: i <= current ? AppColors.primary : Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)),
        ),
      )),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])));
  }
}
