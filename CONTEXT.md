# Hermona AI: Project Report & Technical Overview

Hermona AI is a premium, science-backed skincare application designed to analyze, predict, and monitor acne evolution through artificial intelligence.

## 1. Core Architecture
The project follows Clean Architecture principles to ensure scalability and maintainability:
- **Presentation Layer**: Flutter widgets, BLoC/Cubit for state management, and GoRouter for navigation.
- **Domain Layer**: Entities and business logic (Severity formulas, cycle calculations).
- **Data Layer**: Firestore repositories, Dio for API communication, and local storage (SharedPreferences).

## 2. Technology Stack
- **Frontend**: Flutter (Android/iOS/Web support).
- **Backend**: FastAPI (Python) for AI inference and data processing.
- **Database**: Cloud Firestore (Real-time data synchronization).
- **Authentication**: Firebase Auth (Email/Google Sign-in).
- **Visualization**: `fl_chart` for medical-grade trend analysis.

## 3. Key Feature Modules
### 🧪 AI Facial Analysis (5-Zone Pipeline)
- **Zones**: Forehead, Left Cheek, Right Cheek, Chin, and Nose.
- **Scoring**: Weighted severity formula based on lesion types (Blackheads, Papules, Pustules, Nodules).
- **Result**: Visual mapping of lesions with high-fidelity annotated images.

### 📉 Trends & Evolution (The "Mirror" Feature)
- **Relative Timeline**: Tracking progress from Week 1 (User's first analysis).
- **Weekly Averaging**: Combines multiple data points into a stable weekly trend.
- **Interactivity**: Tap-to-view historical photos and detailed analysis reports directly from the chart.

### 🔮 Prediction & Routine
- **Risk Assessment**: Predicts acne outbreaks by combining hormonal cycle data, lifestyle scores, and SHAP-based feature importance.
- **Dynamic Routine**: Personalized skincare recommendations that adapt to the current skin state and cycle phase.

### 👥 Community & Safety
- **Forum**: Categorized discussions (Routine, Hormones, etc.).
- **Anonymity**: Support for pseudonyms and custom avatars for user privacy.
- **Private Messaging**: Secure communication between community members.

## 4. Design Standards
- **Aesthetic**: Premium glassmorphism with soft cinematic lighting.
- **Typography**: Modern fonts (Outfit/Google Fonts).
- **UX**: Micro-animations using `flutter_animate` for a fluid, high-end experience.

## 5. Engineering Manifest
- **Strict Logic**: Formulas and scores are standardized (e.g., Severity Global = 0.25F + 0.25JG + 0.25JD + 0.15M + 0.10N).
- **No "Vibe Coding"**: Every UI change must be backed by a clear functional requirement.
- **Reliability**: Proactive error handling and localized strings for multi-language support (FR/EN).
