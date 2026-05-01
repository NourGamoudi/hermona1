import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/questionnaire_service.dart';
import '../../domain/entities/user_profile.dart';

class ProfileQuestionnaireScreen extends StatefulWidget {
  final UserProfile? initialProfile;
  const ProfileQuestionnaireScreen({super.key, this.initialProfile});

  @override
  State<ProfileQuestionnaireScreen> createState() => _ProfileQuestionnaireScreenState();
}

class _ProfileQuestionnaireScreenState extends State<ProfileQuestionnaireScreen> {
  final _pageController = PageController();
  final _service = QuestionnaireService();
  final _picker = ImagePicker();

  int _currentStep = 0;
  bool loading = false;
  String? error;

  // Data
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController(text: '25');
  final TextEditingController _imcCtrl = TextEditingController(text: '22.0');
  
  String sopk = 'inconnu'; // spec: oui/non/inconnu
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
  XFile? facePhoto;

  final List<String> alcoholOptions = ['jamais', 'occasionnel', 'régulier'];
  final List<String> skinTypeOptions = ['grasse', 'mixte', 'sèche', 'sensible', 'normale', 'acnéique'];
  final List<String> allergiesOptions = ['aucune', 'parfums', 'conservateurs', 'alcool cosmétique', 'nickel', 'filtres solaires', 'rétinol', 'AHA-BHA'];
  final List<String> hormonalOptions = ['pilule', 'implant', 'stérilet', 'aucun'];
  final List<String> acneTreatOptions = ['antibiotiques', 'isotrétinoïne', 'crème topique', 'aucun'];
  final List<String> routineMatinOptions = ['Aucun produit', 'Nettoyant doux', 'Tonique', 'Sérum Vitamine C', 'Crème hydratante', 'SPF (Indispensable)'];
  final List<String> routineSoirOptions = ['Aucun produit', 'Démaquillant/Huile', 'Nettoyant', 'Actif (Rétinol/AHA)', 'Sérum hydratant', 'Crème de nuit'];

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _populate(widget.initialProfile!);
    }
  }

  void _populate(UserProfile p) {
    _firstNameCtrl.text = p.firstName;
    _ageCtrl.text = p.age.toString();
    _imcCtrl.text = p.imc.toString();
    sopk = p.sopk ? 'oui' : 'non'; // Simplified mapping
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

  Future<void> _pickFace(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (xFile != null) setState(() => facePhoto = xFile);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(m), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_firstNameCtrl.text.trim().isEmpty) { _snack('Veuillez entrer votre prénom'); return false; }
        if (_ageCtrl.text.trim().isEmpty) { _snack('Veuillez entrer votre âge'); return false; }
        if (_imcCtrl.text.trim().isEmpty) { _snack('Veuillez entrer votre IMC'); return false; }
        return true;
      case 1:
        if (skinType.isEmpty) { _snack('Veuillez choisir votre type de peau'); return false; }
        if (cosmeticAllergies.isEmpty) { _snack('Veuillez choisir vos allergies ou "aucune"'); return false; }
        return true;
      case 2:
        return true; 
      case 3:
        if (routineMatin.isEmpty) { _snack('Veuillez choisir votre routine matin ou "Aucun produit"'); return false; }
        if (routineSoir.isEmpty) { _snack('Veuillez choisir votre routine soir ou "Aucun produit"'); return false; }
        return true;
      case 4:
        for(var c in lastCycles) if (c <= 0) { _snack('Veuillez remplir les durées de cycles'); return false; }
        return true;
      case 5:
        if (facePhoto == null) { _snack('La photo est obligatoire pour l\'analyse'); return false; }
        return true;
      default: return true;
    }
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: Icon(Iconsax.camera), title: const Text('Prendre une photo'), onTap: () { Navigator.pop(ctx); _pickFace(ImageSource.camera); }),
            ListTile(leading: Icon(Iconsax.gallery), title: const Text('Choisir dans la galerie'), onTap: () { Navigator.pop(ctx); _pickFace(ImageSource.gallery); }),
          ],
        ),
      ),
    );
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    
    if (_currentStep < 5) {
      _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _save();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: 400.ms, curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _save() async {
    if (!_validateCurrentStep()) return;

    setState(() { loading = true; error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      
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
        initialPhotos: facePhoto != null ? {'face': facePhoto!.path} : {},
      );
      
      await _service.saveUserProfile(profile);
      if (mounted) {
        if (widget.initialProfile != null) {
          context.pop();
        } else {
          context.go('/weekly-survey');
        }
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Hermona'),
        leading: _currentStep > 0 ? IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: _prev) : null,
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text('${_currentStep + 1}/6', style: theme.textTheme.labelLarge),
          )),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 6,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _step1(),
                _step2(),
                _step3(),
                _step4(),
                _step5(),
                _step6(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: GradientButton(
              text: _currentStep == 5 ? 'Terminer' : 'Suivant',
              isLoading: loading,
              onPressed: _next,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _step1() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _stepTitle('Profil Personnel', 'Parlons un peu de toi.'),
        AppCard(
          child: Column(
            children: [
              TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Iconsax.user))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextField(controller: _ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Âge'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _imcCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'IMC'))),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('SOPK (Syndrome des Ovaires Polykystiques)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'oui', label: Text('Oui')),
            ButtonSegment(value: 'non', label: Text('Non')),
            ButtonSegment(value: 'inconnu', label: Text('Inconnu')),
          ],
          selected: {sopk},
          onSelectionChanged: (v) => setState(() => sopk = v.first),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Antécédents familiaux d\'acné'),
          value: acneFamilyHistory,
          onChanged: (v) => setState(() => acneFamilyHistory = v),
        ),
        SwitchListTile(
          title: const Text('Fumeuse'),
          value: smoker,
          onChanged: (v) => setState(() => smoker = v),
        ),
        const SizedBox(height: 16),
        Text('Consommation d\'alcool', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: alcoholOptions.map((o) => ChoiceChip(
            label: Text(o),
            selected: alcohol == o,
            onSelected: (s) => setState(() => alcohol = o),
          )).toList(),
        ),
      ],
    );
  }

  Widget _step2() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _stepTitle('Profil Cutané', 'Ton type de peau et tes sensibilités.'),
        Text('Quel est ton type de peau ?', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skinTypeOptions.map((o) => ChoiceChip(
            label: Text(o),
            selected: skinType == o,
            onSelected: (s) => setState(() => skinType = o),
          )).toList(),
        ),
        const SizedBox(height: 32),
        Text('Allergies cosmétiques connues :', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allergiesOptions.map((o) => FilterChip(
            label: Text(o),
            selected: cosmeticAllergies.contains(o),
            onSelected: (s) => setState(() {
              if (o == 'aucune') {
                s ? cosmeticAllergies = ['aucune'] : cosmeticAllergies.remove('aucune');
              } else {
                cosmeticAllergies.remove('aucune');
                s ? cosmeticAllergies.add(o) : cosmeticAllergies.remove(o);
              }
            }),
          )).toList(),
        ),
      ],
    );
  }

  Widget _step3() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _stepTitle('Profil Médical', 'Tes traitements en cours.'),
        const Text('C\'est une priorité absolue pour nos recommandations.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Text('Traitement acné actuel', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        ...acneTreatOptions.map((o) => RadioListTile<String>(
          title: Text(o),
          value: o,
          groupValue: acneTreatment,
          onChanged: (v) => setState(() => acneTreatment = v!),
        )),
        const Divider(),
        Text('Traitement hormonal actuel', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        ...hormonalOptions.map((o) => RadioListTile<String>(
          title: Text(o),
          value: o,
          groupValue: hormonalTreatment,
          onChanged: (v) => setState(() => hormonalTreatment = v!),
        )),
      ],
    );
  }

  Widget _step4() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _stepTitle('Routine Actuelle', 'Quels produits utilises-tu ?'),
        Text('Le matin ☀️', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...routineMatinOptions.map((o) => CheckboxListTile(
          title: Text(o),
          value: routineMatin.contains(o),
          onChanged: (v) => setState(() {
            if (o == 'Aucun produit') {
              v! ? routineMatin = ['Aucun produit'] : routineMatin.remove('Aucun produit');
            } else {
              routineMatin.remove('Aucun produit');
              v! ? routineMatin.add(o) : routineMatin.remove(o);
            }
          }),
        )),
        const SizedBox(height: 24),
        Text('Le soir 🌙', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...routineSoirOptions.map((o) => CheckboxListTile(
          title: Text(o),
          value: routineSoir.contains(o),
          onChanged: (v) => setState(() {
            if (o == 'Aucun produit') {
              v! ? routineSoir = ['Aucun produit'] : routineSoir.remove('Aucun produit');
            } else {
              routineSoir.remove('Aucun produit');
              v! ? routineSoir.add(o) : routineSoir.remove(o);
            }
          }),
        )),
      ],
    );
  }

  Widget _step5() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _stepTitle('Cycle Menstruel', 'Pour calculer ta phase actuelle.'),
        AppCard(
          child: Column(
            children: [
              ListTile(
                title: const Text('Date des dernières règles'),
                subtitle: Text(DateFormat('dd MMMM yyyy', 'fr').format(lastPeriodsDate)),
                trailing: const Icon(Iconsax.calendar),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: lastPeriodsDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 90)),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => lastPeriodsDate = d);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Durée des 3 derniers cycles (jours)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) => SizedBox(
            width: 80,
            child: TextField(
              controller: TextEditingController(text: lastCycles[i].toString()),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(hintText: 'C${i+1}'),
              onChanged: (v) => lastCycles[i] = int.tryParse(v) ?? 28,
            ),
          )),
        ),
      ],
    );
  }

  Widget _step6() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _stepTitle('Photo Initiale', 'Une photo de face pour l\'analyse CNN.'),
          const Spacer(),
          GestureDetector(
            onTap: _showPhotoSourceDialog,
            child: Container(
              width: 240,
              height: 320,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
              ),
              child: facePhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28), 
                    child: kIsWeb 
                      ? Image.network(facePhoto!.path, fit: BoxFit.cover)
                      : Image.file(File(facePhoto!.path), fit: BoxFit.cover)
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.camera, size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text('Prendre une photo', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '⚠️ Vos photos sont traitées de manière sécurisée et ne sont utilisées que pour votre suivi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
