import uuid
import os
import logging
import math
import unicodedata
import hashlib
import random
from datetime import datetime, timezone
from typing import List, Dict, Any, Set, Optional, Tuple
from groq import Groq
from dotenv import load_dotenv

# --- Logger Setup ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("RecommendationEngine")

# Ensure .env is loaded
load_dotenv()

# --- GLOBAL UTILS ---

# In-process lightweight anti-repetition cache {userId: [lastStrategy1, lastStrategy2]}
_STRATEGY_HISTORY: Dict[str, List[str]] = {}

def get_variation_seed(user_id: str) -> int:
    """Deterministic seed based on userId + current UTC date. Stable within a day."""
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    seed_str = f"{user_id}_{today}"
    return int(hashlib.sha256(seed_str.encode()).hexdigest(), 16) % 100000

def softmax(scores: List[float], temperature: float = 1.0) -> List[float]:
    """Softmax with temperature control.
    temperature < 1 → more deterministic (safer for extreme profiles)
    temperature > 1 → more exploratory (for balanced profiles)
    """
    t = max(temperature, 0.01)
    scaled = [s / t for s in scores]
    max_s = max(scaled)  # numerical stability
    exps = [math.exp(s - max_s) for s in scaled]
    total = sum(exps)
    return [e / total for e in exps]

def score_entropy(probs: List[float]) -> float:
    """Shannon entropy of probability distribution. Higher = more balanced."""
    return -sum(p * math.log(p + 1e-9) for p in probs)

def normalize(t: str) -> str:
    """Centralized normalization for all IDs, inputs, and synonyms"""
    if not t: return ""
    t = str(t).lower().replace(" ", "_").strip()
    return ''.join(c for c in unicodedata.normalize('NFD', t) if unicodedata.category(c) != 'Mn')

# --- CONSTANTS ---
# --- CONSTANTS (IDs) ---
STRATEGY_PREVENTION = "strategy_prevention"
STRATEGY_EQUILIBRE = "strategy_equilibre"
STRATEGY_PROTECTION = "strategy_protection"
STRATEGY_MEDICAL = "strategy_medical"

# --- DATA LAYER ---
INGREDIENT_DB = {
    "retinol": {"display": {"fr": "Rétinol", "en": "Retinol"}, "type": "irritant", "strength": 5.0},
    "vitamine_c": {"display": {"fr": "Vitamine C", "en": "Vitamin C"}, "type": "antioxydant", "strength": 4.0},
    "aha": {"display": {"fr": "AHA (Acide Glycolique)", "en": "AHA (Glycolic Acid)"}, "type": "acide", "strength": 3.0},
    "bha": {"display": {"fr": "BHA (Acide Salicylique)", "en": "BHA (Salicylic Acid)"}, "type": "acide", "strength": 3.0},
    "niacinamide": {"display": {"fr": "Niacinamide", "en": "Niacinamide"}, "type": "apaisant", "strength": 2.5},
    "zinc": {"display": {"fr": "Zinc PCA", "en": "Zinc PCA"}, "type": "purifiant", "strength": 2.0},
    "acide_hyaluronique": {"display": {"fr": "Acide Hyaluronique", "en": "Hyaluronic Acid"}, "type": "hydratant", "strength": 1.5},
    "centella_asiatica": {"display": {"fr": "Centella Asiatica", "en": "Centella Asiatica"}, "type": "apaisant", "strength": 1.0},
    "panthenol": {"display": {"fr": "Panthénol (B5)", "en": "Panthenol (B5)"}, "type": "apaisant", "strength": 1.0},
    "aloe_vera": {"display": {"fr": "Aloe Vera", "en": "Aloe Vera"}, "type": "hydratant", "strength": 1.0},
    "acide_salicylique": {"display": {"fr": "Acide Salicylique (BHA)", "en": "Salicylic Acid (BHA)"}, "type": "acide", "strength": 3.0},
}

PRODUCT_EXAMPLES = {
    "gel_nettoyant_purifiant": ["CeraVe Gel Moussant", "La Roche-Posay Effaclar", "Avène Cleanance"],
    "nettoyant_doux_hydratant": ["CeraVe Hydratant", "La Roche-Posay Toleriane", "Avène Tolérance"],
    "serum_vitamine_c": ["La Roche-Posay Pure Vit C10", "Vichy Liftactiv Vit C", "SVR Ampoule [C]"],
    "serum_niacinamide": ["The Ordinary Niacinamide 10%", "La Roche-Posay Pure Niacinamide 10", "The Inkey List Niacinamide"],
    "serum_retinol": ["CeraVe Rétinol Anti-Marques", "La Roche-Posay Rétinol B3", "The Ordinary Rétinol 0.2%"],
    "serum_acide_salicylique": ["Paula's Choice 2% BHA", "The Ordinary Salicylic Acid 2%", "The Inkey List BHA"],
    "fluide_hydratant": ["La Roche-Posay Effaclar Mat", "SVR Sebiaclear Mat+Pores", "Vichy Normaderm Phytosolution"],
    "creme_riche": ["CeraVe Crème Hydratante", "La Roche-Posay Lipikar Baume AP+", "Avène Xeracalm AD"],
    "solaire_spf_50+": ["Anthelios UVmune 400", "Eucerin Sun Oil Control", "Vichy Capital Soleil UV-Clear"],
    "baume_nettoyant": ["Clinique Take The Day Off", "The Ordinary Squalane Cleanser", "Beauty of Joseon Radiance Cleansing Balm"],
    "creme_nuit": ["CeraVe Baume Hydratant", "La Roche-Posay Cicaplast Baume B5", "Avène Cicalfate+"],
    "baume_reparateur": ["La Roche-Posay Cicaplast Baume B5", "Avène Cicalfate+", "Uriage Bariéderm-Cica"],
}

# Synonyms for allergy detection
SYNONYM_INDEX = {
    "retinol": "retinol", "vitamine_a": "retinol",
    "aha": "aha", "glycolique": "aha", "lactique": "aha",
    "bha": "bha", "salicylique": "bha",
    "vitamine_c": "vitamine_c", "ascorbique": "vitamine_c",
    "parfums": "fragrance", "alcool": "alcohol", "nickel": "nickel",
    "conservateurs": "preservatives", "filtres_solaires": "sunscreen_filters"
}

ISOTRETINOIN_ALIASES = {"isotretinoine", "roaccutane", "curacne", "accutane", "procuta"}

CONFLICT_RULES = {
    "retinol": {"aha", "bha", "vitamine_c"},
    "aha": {"retinol", "bha", "vitamine_c"},
    "bha": {"retinol", "aha", "vitamine_c"},
    "vitamine_c": {"retinol", "aha", "bha"},
}

# --- LEGACY DATA MAPPING (FR -> Technical Keys) ---
LEGACY_MAPPING = {
    # Skin Type
    "peau grasse": "skin_grasse",
    "peau mixte": "skin_mixte",
    "peau sèche": "skin_seche",
    "peau sensible": "skin_sensible",
    "peau normale": "skin_normale",
    "mixte": "skin_mixte",
    "grasse": "skin_grasse",
    "sèche": "skin_seche",
    "sensible": "skin_sensible",
    
    # Phases
    "menstruelle": "phase_menstrual",
    "folliculaire": "phase_follicular",
    "ovulatoire": "phase_ovulatory",
    "lutéale": "phase_luteal",
    "menstrual": "phase_menstrual",
    "follicular": "phase_follicular",
    "ovulatory": "phase_ovulatory",
    "luteal": "phase_luteal",
    
    # Frequencies
    "tous les jours": "freq_daily",
    "jamais": "freq_never",
    "parfois": "freq_sometimes",
    "rarement": "freq_rarely",
    "2x/jour": "cleans_twice",
    "1x/jour": "cleans_once",
    
    # Treatments
    "aucun": "treat_none",
    "antibiotiques": "treat_antibiotics",
    "isotrétinoïne": "treat_isotretinoin",
    "local": "treat_topical",
    "none": "treat_none",
    "aucune": "hormonal_none",
}

def normalize_value(val: Any) -> str:
    """Maps legacy French strings to technical keys."""
    if not val: return ""
    v = str(val).lower().strip()
    # Normalize unicode (accents) for matching
    import unicodedata
    v_norm = "".join(c for c in unicodedata.normalize('NFD', v) if unicodedata.category(c) != 'Mn')
    return LEGACY_MAPPING.get(v, LEGACY_MAPPING.get(v_norm, normalize(v)))

# --- ENGINE ---

class RecommendationEngine:
    def __init__(self, req: Dict[str, Any]):
        self.req = req
        self.strategy = STRATEGY_PREVENTION
        self.is_medical_isotretinoin = False
        self.actives_pool: Set[str] = set()
        self.avoid_pool: Set[str] = set()
        self.lifestyle_tips: List[str] = []
        self.nutrition_tips: List[str] = []
        self.habits_tips: List[str] = []
        self.why_this: List[str] = []
        self.explanation = "✅ CONNEXION RÉUSSIE ! Votre routine est en cours de génération personnalisée..."
        self.message = ""
        self.debug_mode = os.getenv("DEBUG_MODE", "false").lower() == "true"
        self.level = "maintenance"
        self.zone_focus = {}
        
        # Deterministic seed per user per day
        self.user_id = str(self.req.get('userId', self.req.get('user_id', 'default_user')))
        self._seed = get_variation_seed(self.user_id)
        self._rng = random.Random(self._seed)  # isolated RNG — never touches global state
        self.variation_index = 0
        self.alternative_strategy = ""
        self.lang = self.req.get('lang', 'fr').lower()[:2]
        if self.lang not in ['fr', 'en']: self.lang = 'fr'

        # Localized active ingredient database
        self.actives_db = {
            "en": {
                "Rétinol": "Retinol",
                "Acide salicylique": "Salicylic Acid",
                "Acide Azélaïque": "Azelaic Acid",
                "Niacinamide": "Niacinamide",
                "Peroxyde de benzoyle": "Benzoyl Peroxide",
                "Vitamine C": "Vitamin C",
                "Zinc PCA": "Zinc PCA",
                "Acide Hyaluronique": "Hyaluronic Acid",
                "Huile de Jojoba": "Jojoba Oil",
                "Aloe Vera": "Aloe Vera",
                "Centella Asiatica": "Centella Asiatica"
            },
            "fr": {
                "Rétinol": "Rétinol",
                "Acide salicylique": "Acide Salicylique",
                "Acide Azélaïque": "Acide Azélaïque",
                "Niacinamide": "Niacinamide",
                "Peroxyde de benzoyle": "Peroxyde de Benzoyle",
                "Vitamine C": "Vitamine C",
                "Zinc PCA": "Zinc PCA",
                "Acide Hyaluronique": "Acide Hyaluronique",
                "Huile de Jojoba": "Huile de Jojoba",
                "Aloe Vera": "Aloe Vera",
                "Centella Asiatica": "Centella Asiatica"
            }
        }

        self.messages = {
            "en": {
                "allergy_warning": "⚠️ CAUTION: This routine has been adjusted because of your cosmetic allergies.",
                "fragrance_warning": "Avoid products with added fragrance (Parfum) to minimize sensitivity.",
                "explanation_header": "Based on your clinical data, I have designed an adaptative routine."
            },
            "fr": {
                "allergy_warning": "⚠️ ATTENTION : Cette routine a été ajustée en fonction de vos allergies cosmétiques.",
                "fragrance_warning": "Évitez les produits avec parfum ajouté pour minimiser la sensibilité.",
                "explanation_header": "Basé sur vos données cliniques, j'ai conçu une routine adaptative."
            }
        }

        # Translation Map
        self._translations = {
            "en": {
                "strategy_prevention": "PREVENTION",
                "strategy_equilibre": "BALANCE",
                "strategy_protection": "PROTECTION",
                "strategy_medical": "MEDICAL PROTOCOL (ISOTRETINOIN)",
                "msg_isotretinoin": "On isotretinoin — Absolute gentleness required. Consult your dermatologist.",
                "tip_pillow": "Change your pillowcase every 2 days",
                "tip_water": "Stay hydrated: at least 2L of water per day",
                "tip_scrub": "AVOID grain scrubs (e.g. St. Ives) which tear your skin barrier.",
                "tip_probiotics": "Add probiotics to support your gut flora",
                "tip_sun": "Mandatory SPF50 sun protection (photosensitization)",
                "msg_antibiotics": "Antibiotics detected — protect your skin from the sun.",
                "msg_protection": "Risk or inflammation — Priority to soothing and repairing.",
                "msg_equilibre": "Balance strategy — Maintenance and sebum regulation.",
                "msg_prevention": "Optimal score — Prevention routine and barrier maintenance.",
                "why_protection": "Your current profile requires a protective approach to avoid inflammation.",
                "why_niacinamide": "Niacinamide was chosen to regulate sebum without irritating your skin in the luteal phase.",
                "why_barrier": "Optimizing skin barrier",
                "why_sebum": "Sebum regulation",
                "tip_nutrition_luteal": [
                    "Anti-inflammatory foods: salmon, walnuts (Omega-3), blueberries.",
                    "Peppermint tea: reduces androgens and sebum.",
                    "AVOID sugar, dairy, and iced drinks."
                ],
                "tip_lifestyle_luteal": [
                    "Gentle exercise (Yoga, Pilates, Walking) to limit cortisol.",
                    "Sleep: 8h minimum to help skin regeneration.",
                    "Hygiene: Change your pillowcase every 2 days."
                ],
                "tip_nutrition_menstrual": [
                    "Iron-rich foods (lentils, dark chocolate >70%).",
                    "Turmeric/ginger tea for inflammation.",
                    "Avoid cold drinks and excessive caffeine."
                ],
                "tip_lifestyle_menstrual": "Priority rest. Hot water bottle and restorative sleep.",
                "tip_nutrition_follicular": "Ideal time for detox foods (lemon, cucumber, kefir).",
                "tip_lifestyle_follicular": "High energy: ideal for cardio or new treatments.",
                "tip_nutrition_ovulatory": "Cruciferous vegetables (broccoli) for estrogen balance.",
                "tip_lifestyle_ovulatory": "Stay hydrated, body temperature increases slightly.",
                "tip_fast_food": "Fast food saturates the liver and increases inflammation in the {} phase",
                "tip_sugar": "Reducing fast sugars helps calm inflammatory acne.",
                "tip_stress": "High stress level detected → add 10min of relaxation and reduce sugar/dairy.",
                "tip_sleep": "Lack of sleep → your skin barrier regeneration is slowed down.",
                "tip_sugar_igf1": "Sugar spikes IGF-1: avoid sodas and pastries this week.",
                "tip_dairy": "Dairy products contain growth hormones that stimulate acne.",
                "tip_cold_drinks": "Iced drinks: create a digestive shock that promotes inflammation.",
                "tip_alcohol": "Regular alcohol: dehydrates and increases cortisol (inflammation).",
                "tip_tobacco": "Tobacco: reduces skin oxygenation and delays healing.",
                "tip_cleansing": "COMPLETE makeup removal every night, without exception.",
                "tip_phone": "Clean your phone screen with a disinfectant wipe.",
                "tip_breathing": "High stress: try 'box breathing' (4-4-4-4).",
                "tip_sleep_hours": "Only {}h of sleep: no phone 1h before sleeping.",
                "tip_hydration": "Dehydration ({} glasses): drink water before your coffee.",
                "tip_hormonal": " | Hormonal anticipation required.",
                "tip_shap_stress": "SHAP Stress: reduce irritating actives this week.",
                "tip_chin": "Chin/jaw acne: often hormonal. Be gentle.",
                "tip_forehead": "Forehead: avoid bangs and check your shampoos.",
                "explanation_loading": "✅ CONNECTION SUCCESSFUL! Your personalized routine is being generated...",
                "disclaimer": "Hermona is not a medical tool. Consult a dermatologist.",
                "fallback_why": ["Skin barrier optimization", "Sebum regulation"],
                "fragrance_free": " | FRAGRANCE-FREE required."
            },
            "fr": {
                "strategy_prevention": "PRÉVENTION",
                "strategy_equilibre": "ÉQUILIBRE",
                "strategy_protection": "PROTECTION",
                "strategy_medical": "PROTOCOLE MÉDICAL (ISOTRÉTINOÏNE)",
                "msg_isotretinoin": "Sous isotrétinoïne — Douceur absolue requise. Consultez votre dermatologue.",
                "tip_pillow": "Changez votre taie d'oreiller tous les 2 jours",
                "tip_water": "Hydratez-vous : 2L d'eau par jour minimum",
                "tip_scrub": "ÉVITEZ le gommage à grains (ex: St. Ives) qui déchire votre barrière cutanée.",
                "tip_probiotics": "Ajoutez des probiotiques pour soutenir votre flore intestinale",
                "tip_sun": "Protection solaire SPF50 obligatoire (photosensibilisation)",
                "msg_antibiotics": "Antibiotiques détectés — protégez votre peau du soleil.",
                "msg_protection": "Risque ou inflammation — Priorité à l'apaisement et la réparation.",
                "msg_equilibre": "Stratégie d'équilibre — Maintenance et régulation du sébum.",
                "msg_prevention": "Score optimal — Routine de prévention et maintien de la barrière.",
                "why_protection": "Votre profil actuel nécessite une approche protectrice pour éviter l'inflammation.",
                "why_niacinamide": "La niacinamide a été choisie pour réguler le sébum sans irriter votre peau en phase lutéale.",
                "why_barrier": "Optimisation de la barrière cutanée",
                "why_sebum": "Régulation du sébum",
                "tip_nutrition_luteal": [
                    "Aliments anti-inflammatoires : saumon, noix (Omega-3), myrtilles.",
                    "Tisane de menthe poivrée : réduit les androgènes et le sébum.",
                    "ÉVITEZ le sucre, les produits laitiers et les boissons glacées."
                ],
                "tip_lifestyle_luteal": [
                    "Sport doux (Yoga, Pilates, Marche) pour limiter le cortisol.",
                    "Sommeil : 8h minimum pour aider la régénération cutanée.",
                    "Hygiène : Changez votre taie d'oreiller tous les 2 jours."
                ],
                "tip_nutrition_menstrual": [
                    "Aliments riches en fer (lentilles, chocolat noir >70%).",
                    "Tisane curcuma/gingembre pour l'inflammation.",
                    "Évitez les boissons froides et l'excès de caféine."
                ],
                "tip_lifestyle_menstrual": "Repos prioritaire. Bouillotte chaude et sommeil réparateur.",
                "tip_nutrition_follicular": "Moment idéal pour des aliments détox (citron, concombre, kéfir).",
                "tip_lifestyle_follicular": "Énergie haute : idéal pour cardio ou nouveaux soins.",
                "tip_nutrition_ovulatory": "Légumes crucifères (brocoli) pour l'équilibre des œstrogènes.",
                "tip_lifestyle_ovulatory": "Restez hydratée, la température corporelle augmente légèrement.",
                "tip_fast_food": "Le fast-food sature le foie et augmente l'inflammation en phase {}",
                "tip_sugar": "Réduire les sucres rapides aide à calmer l'acné inflammatoire.",
                "tip_stress": "Niveau de stress élevé détecté → ajoutez 10min de relaxation et réduisez sucres/produits laitiers.",
                "tip_sleep": "Manque de sommeil → la régénération de votre barrière cutanée est ralentie.",
                "tip_sugar_igf1": "Le sucre spike l'IGF-1 : évitez les sodas et pâtisseries cette semaine.",
                "tip_dairy": "Les produits laitiers contiennent des hormones de croissance qui stimulent l'acné.",
                "tip_cold_drinks": "Boissons glacées : créent un choc digestif qui favorise l'inflammation.",
                "tip_alcohol": "Alcool régulier : déshydrate et augmente le cortisol (inflammation).",
                "tip_tobacco": "Tabac : réduit l'oxygénation de la peau et retarde la cicatrisation.",
                "tip_cleansing": "Démaquillage COMPLET chaque soir, sans exception.",
                "tip_phone": "Nettoyez l'écran de votre téléphone avec une lingette désinfectante.",
                "tip_breathing": "Stress élevé : essayez la respiration 'box breathing' (4-4-4-4).",
                "tip_sleep_hours": "Seulement {}h de sommeil : pas de téléphone 1h avant de dormir.",
                "tip_hydration": "Déshydratation ({} verres) : buvez de l'eau avant votre café.",
                "tip_hormonal": " | Anticipation hormonale requise.",
                "tip_shap_stress": "SHAP Stress : réduisez les actifs irritants cette semaine.",
                "tip_chin": "Acné menton/mâchoire : souvent hormonale. Soyez douce.",
                "tip_forehead": "Front : évitez les franges et vérifiez vos shampooings.",
                "explanation_loading": "✅ CONNEXION RÉUSSIE ! Votre routine est en cours de génération personnalisée...",
                "disclaimer": "Hermona n'est pas un outil médical. Consultez un dermatologue.",
                "fallback_why": ["Optimisation de la barrière cutanée", "Régulation du sébum"],
                "fragrance_free": " | SANS PARFUM requis."
            }
        }
        self.explanation = self._t("explanation_loading")

    def _t(self, key: str) -> Any:
        return self._translations.get(self.lang, self._translations["fr"]).get(key, self._translations["fr"].get(key, key))

    def _norm(self, v: Any) -> float:
        try:
            val = float(v)
            return val / 100.0 if val > 1.0 else val
        except: return 0.0

    def get_recommendations(self):
        # 1. MEDICAL SAFETY & ALLERGIES (Step 1 & 2)
        if self._check_medical_safety():
            return self._build_response()
            
        # 2. RISK STRATEGY (Step 3 & 4)
        self._check_risk_strategy()
        
        # 3. PHASE ACTIVES (Step 5)
        self._apply_phase_rules()
        
        # 4. SKIN TYPE ADAPTATION (Step 6)
        self._apply_skin_type_rules()
        
        # 5. SHAP & LIFESTYLE (Step 7 + Section 4)
        self._apply_lifestyle_nutrition_rules()
        
        # 6. ALLERGY FINAL FILTER (Step 2 Priority)
        self._apply_allergy_filter()
        
        # 7. AI NARRATIVE (Phase 5)
        self._engine_narrative()
        
        return self._build_response()

    def _check_medical_safety(self) -> bool:
        treat = normalize(self.req.get('acne_treatment', ''))
        
        
        # ISOTRETINOIN - ABSOLUTE PRIORITY
        if any(alias in treat for alias in ISOTRETINOIN_ALIASES):
            self.strategy = STRATEGY_MEDICAL
            self.is_medical_isotretinoin = True
            self.actives_pool = {"acide_hyaluronique", "panthenol", "centella_asiatica"}
            self.avoid_pool = {"retinol", "aha", "bha", "vitamine_c"}
            self.message = self._t("msg_isotretinoin")
            self.lifestyle_tips.append(self._t("tip_pillow"))
            self.nutrition_tips.append(self._t("tip_water"))
            self.habits_tips.append(self._t("tip_scrub"))
            return True

        # ANTIBIOTICS
        if "antibio" in treat:
            self.nutrition_tips.append(self._t("tip_probiotics"))
            self.lifestyle_tips.append(self._t("tip_sun"))
            self.message = self._t("msg_antibiotics")

        return False

    def _check_risk_strategy(self):
        try:
            risk = float(self.req.get('risk_j3', 0.0))
        except (TypeError, ValueError):
            risk = 0.0
        try:
            severity = float(self.req.get('severity', 0.0))
        except (TypeError, ValueError):
            severity = 0.0

        if risk > 1.0: risk = risk / 100.0
        if severity > 1.0: severity = severity / 100.0

        hygiene = int(self.req.get('hygiene_score', 50))
        stress = int(self.req.get('stress', 5))
        phase = normalize(self.req.get('phase', ''))
        skin = normalize(self.req.get('skin_type', 'mixte'))

        # ── STEP 1 : CLINICAL BASE SCORES ────────────────────────────────────
        # These encode the medical logic — never overridden by noise
        repair_score  = 10.0 + (severity * 55) + (risk * 55) + (((100 - hygiene) / 100) * 45)
        balance_score = 15.0
        prevent_score = 10.0 + ((1 - severity) * 30) + ((1 - risk) * 30) + ((hygiene / 100) * 40)

        if stress > 6:
            repair_score  += 20; balance_score += 15
        else:
            prevent_score += 15

        if "menstruelle" in phase or "luteale" in phase:
            balance_score += 35; repair_score += 15
        else:
            prevent_score += 20

        if "sensible" in skin or "acneique" in skin:
            repair_score += 25; balance_score += 10

        raw_scores = [repair_score, balance_score, prevent_score]

        # ── STEP 2 : ADAPTIVE NOISE  ─────────────────────────────────────────
        # noise is stable per user per day (hash-based), but amplitude adapts
        # to how close the scores are — high sensitivity when near a tie.
        noise_raw = (self._seed % 10000) / 10000.0   # 0.0 → 0.9999, stable today
        top2_diff = sorted(raw_scores, reverse=True)[0] - sorted(raw_scores, reverse=True)[1]

        if top2_diff < 8:
            # Scores close → inject significant noise to force diversity
            sensitivity = 12.0
        elif top2_diff < 20:
            sensitivity = 5.0
        else:
            # Clear winner → tiny noise, preserve clinical signal
            sensitivity = 1.5

        repair_score  += noise_raw * sensitivity
        balance_score += noise_raw * sensitivity * 0.6
        prevent_score += noise_raw * sensitivity * 0.3

        # ── STEP 3 : TIE BREAKING ────────────────────────────────────────────
        if abs(repair_score - balance_score) < 2:
            repair_score  += self._rng.uniform(0, 4)
        if abs(balance_score - prevent_score) < 2:
            balance_score += self._rng.uniform(0, 4)
        if abs(repair_score - prevent_score) < 2:
            prevent_score += self._rng.uniform(0, 4)

        logger.info(
            f"RECO | user={self.user_id} | hygiene={hygiene} risk={risk:.2f} "
            f"severity={severity:.2f} stress={stress} phase={phase} skin={skin}"
        )
        logger.info(
            f"SCORES | repair={repair_score:.2f} balance={balance_score:.2f} "
            f"prevent={prevent_score:.2f} | diff_top2={top2_diff:.2f} sensitivity={sensitivity}"
        )

        # ── STEP 4 : TEMPERATURE → SOFTMAX → PROBABILISTIC SAMPLING ─────────
        # temperature: lower = safer/more clinical, higher = more exploratory
        if severity > 0.6 or risk > 0.65:
            temperature = 0.6   # high risk → tighter, safer distribution
        elif top2_diff > 20:
            temperature = 0.8   # clear winner → slightly deterministic
        else:
            temperature = 1.1   # balanced profile → exploratory

        strat_keys   = [STRATEGY_PROTECTION, STRATEGY_EQUILIBRE, STRATEGY_PREVENTION]
        strat_scores = [max(0.1, repair_score), max(0.1, balance_score), max(0.1, prevent_score)]
        strat_probs  = softmax(strat_scores, temperature=temperature)

        # ── STEP 5 : ANTI-REPETITION CHECK ───────────────────────────────────
        # If the probable winner was used the last 2 calls, shift probability
        # 25% toward the alternative — never forces a clinically wrong choice.
        history = _STRATEGY_HISTORY.get(self.user_id, [])
        tentative_winner = self._rng.choices(strat_keys, weights=strat_probs)[0]

        if len(history) >= 2 and history[-1] == tentative_winner and history[-2] == tentative_winner:
            # Redistribute 25% from winner to runner-up
            winner_idx = strat_keys.index(tentative_winner)
            penalty = strat_probs[winner_idx] * 0.25
            strat_probs[winner_idx] -= penalty
            # Add penalty to the 2nd highest
            runner_idx = sorted(
                [i for i in range(3) if i != winner_idx],
                key=lambda i: strat_probs[i], reverse=True
            )[0]
            strat_probs[runner_idx] += penalty
            logger.info(f"ANTI-REPEAT | redistributing 25% away from {tentative_winner}")

        selected_key = self._rng.choices(strat_keys, weights=strat_probs)[0]

        # Update history (keep last 3)
        history.append(selected_key)
        _STRATEGY_HISTORY[self.user_id] = history[-3:]

        # ── STEP 6 : VARIATION INDEX + ALTERNATIVE ───────────────────────────
        entropy = score_entropy(strat_probs)
        max_entropy = math.log(3)   # uniform 3-class = ~1.099
        normalized_entropy = min(100, int((entropy / max_entropy) * 100))
        self.variation_index = normalized_entropy

        remaining_sorted = sorted(
            [(k, p) for k, p in zip(strat_keys, strat_probs) if k != selected_key],
            key=lambda x: x[1], reverse=True
        )

        strat_meta = {
            STRATEGY_PROTECTION: {"level": "intensive",    "msg": self._t("msg_protection")},
            STRATEGY_EQUILIBRE:  {"level": "moderate",     "msg": self._t("msg_equilibre")},
            STRATEGY_PREVENTION: {"level": "maintenance",  "msg": self._t("msg_prevention")},
        }

        self.strategy            = selected_key
        self.level               = strat_meta[selected_key]["level"]
        self.message             = strat_meta[selected_key]["msg"]
        self.alternative_strategy = remaining_sorted[0][0]

        logger.info(
            f"SELECTED: {self.strategy} | alt={self.alternative_strategy} "
            f"| temp={temperature} | entropy={entropy:.3f} | variation_index={self.variation_index}"
        )

        if self.strategy == STRATEGY_PROTECTION:
            self.avoid_pool.update({"retinol", "aha", "bha", "vitamine_c"})
            self.why_this.append(self._t("why_protection"))

    def _apply_phase_rules(self):
        if self.strategy == STRATEGY_PROTECTION: return
        
        phase = normalize(self.req.get('phase', ''))
        risk = self._norm(self.req.get('risk_j3', 0.0))

        if "folliculaire" in phase:
            self.actives_pool.update({"retinol", "vitamine_c", "aha"})
        elif "ovulatoire" in phase:
            self.actives_pool.update({"niacinamide", "zinc"})
        elif "luteale" in phase:
            if risk < 0.60:
                self.actives_pool.update({"bha", "niacinamide"})
            else:
                self.actives_pool.add("niacinamide") # Risk rule wins over phase
                self.why_this.append(self._t("why_niacinamide"))
        elif "menstruelle" in phase:
            self.actives_pool.update({"centella_asiatica", "aloe_vera", "acide_hyaluronique"})
            self.avoid_pool.update({"retinol", "aha", "bha"})

    def _apply_skin_type_rules(self):
        skin = normalize(self.req.get('skin_type', 'mixte'))
        if "grasse" in skin or "acneique" in skin:
            self.actives_pool.add("zinc")
        elif "seche" in skin or "deshydratee" in skin:
            self.actives_pool.add("acide_hyaluronique")
        elif "sensible" in skin:
            self.actives_pool.add("centella_asiatica")
            self.avoid_pool.update({"retinol", "aha", "bha"})

    def _apply_lifestyle_nutrition_rules(self):
        # 1. NUTRITION & LIFESTYLE BY PHASE (Section 4.A & C)
        phase = normalize(self.req.get('phase', ''))
        
        if "luteale" in phase:
            self.nutrition_tips.extend(self._t("tip_nutrition_luteal"))
            self.lifestyle_tips.extend(self._t("tip_lifestyle_luteal"))
        elif "menstruelle" in phase:
            self.nutrition_tips.extend(self._t("tip_nutrition_menstrual"))
            self.lifestyle_tips.append(self._t("tip_lifestyle_menstrual"))
        elif "folliculaire" in phase:
            self.nutrition_tips.append(self._t("tip_nutrition_follicular"))
            self.lifestyle_tips.append(self._t("tip_lifestyle_follicular"))
        elif "ovulatoire" in phase:
            self.nutrition_tips.append(self._t("tip_nutrition_ovulatory"))
            self.lifestyle_tips.append(self._t("tip_lifestyle_ovulatory"))

        # 2. PERSONALIZED ADVICE BASED ON PROFILE & DIET (Section 4.B)
        diet = self.req.get('diet', [])
        if "fast_food" in diet or "fastfood" in diet:
            self.nutrition_tips.append(self._t("tip_fast_food").format(phase))
        if "sugar" in diet or "sucre" in diet:
            self.nutrition_tips.append(self._t("tip_sugar"))
            
        stress = self.req.get('stress', 5)
        if stress > 7:
            self.lifestyle_tips.append(self._t("tip_stress"))
            
        sleep = self.req.get('sleep', 7)
        if sleep < 6:
            self.lifestyle_tips.append(self._t("tip_sleep"))
            self.nutrition_tips.append(self._t("tip_sugar_igf1"))
        if "dairy" in diet:
            self.nutrition_tips.append(self._t("tip_dairy"))
        if "cold_drinks" in diet:
            self.nutrition_tips.append(self._t("tip_cold_drinks"))
            
        if self.req.get('alcohol') == "regular":
            self.nutrition_tips.append(self._t("tip_alcohol"))
        if self.req.get('smoker') is True:
            self.lifestyle_tips.append(self._t("tip_tobacco"))

        # 3. HYGIENE & HABITS (Section 4.F)
        self.habits_tips.append(self._t("tip_cleansing"))
        self.habits_tips.append(self._t("tip_phone"))
        
        stress = int(self.req.get('stress', 5))
        if stress > 7:
            self.lifestyle_tips.append(self._t("tip_breathing"))
            self.actives_pool.add("centella_asiatica")
            
        sleep = float(self.req.get('sleep', 8))
        if sleep < 7:
            self.lifestyle_tips.append(self._t("tip_sleep_hours").format(sleep))
            
        hydration = int(self.req.get('hydration', 6))
        if hydration < 5:
            self.nutrition_tips.append(self._t("tip_hydration").format(hydration))

        # 4. SHAP FINE-TUNING (Step 7)
        shaps = self.req.get('top3_shap', [])
        if any(word in str(shaps).lower() for word in ["hormon", "progesteron"]):
            self.message += self._t("tip_hormonal")
        if any("stress" in str(s).lower() for s in shaps):
            self.lifestyle_tips.append(self._t("tip_shap_stress"))
            
        # 5. ZONES SPECIFIC
        zones = self.req.get('zones', [])
        if "chin" in zones or "jaw" in zones:
            self.habits_tips.append(self._t("tip_chin"))
        if "forehead" in zones:
            self.habits_tips.append(self._t("tip_forehead"))


    def _apply_allergy_filter(self):
        allergies = self.req.get('allergies', [])
        for a in allergies:
            norm_a = normalize(a)
            cid = SYNONYM_INDEX.get(norm_a)
            if cid:
                self.avoid_pool.add(cid)
            if "parfum" in norm_a:
                self.message += self._t("fragrance_free")
            if "alcool" in norm_a:
                self.avoid_pool.add("alcohol")

    def _engine_narrative(self):
        key = os.getenv("GROQ_API_KEY")
        if not key: return
        try:
            client = Groq(api_key=key)
            
            # 1. Normalize Context for AI (Translation layer)
            # This ensures that even if inputs were legacy French, the AI gets the correct terms in the target language.
            phase_key = normalize_value(self.req.get('phase', 'inconnue'))
            skin_key = normalize_value(self.req.get('skin_type', 'mixte'))
            
            # Localized descriptors for the prompt
            localized_data = {
                "en": {
                    "phase": self._t(phase_key) if "phase_" in phase_key else phase_key,
                    "skin": self._t(skin_key) if "skin_" in skin_key else skin_key,
                    "lifestyle": f"Stress: {self.req.get('stress')}/10, Sleep: {self.req.get('sleep')}h, Hydration: {self.req.get('hydration')} glasses",
                },
                "fr": {
                    "phase": self._t(phase_key) if "phase_" in phase_key else phase_key,
                    "skin": self._t(skin_key) if "skin_" in skin_key else skin_key,
                    "lifestyle": f"Stress: {self.req.get('stress')}/10, Sommeil: {self.req.get('sleep')}h, Hydratation: {self.req.get('hydration')} verres",
                }
            }
            
            ctx = localized_data.get(self.lang, localized_data["fr"])
            
            # 2. Build strict language prompt
            target_lang_name = "ENGLISH" if self.lang == "en" else "FRENCH"
            
            prompt = f"""
            STRICT INSTRUCTION: YOU MUST RESPOND ENTIRELY IN {target_lang_name}. 
            DO NOT USE ANY OTHER LANGUAGE. IGNORE ANY FRENCH WORDS IN THE INPUT CONTEXT BELOW.

            TU ES HERMONA AI — TON RÔLE : COACH PERSONNEL EN SOINS DE LA PEAU (HUMAN SKINCARE COACH).
            Tu n'es pas un système clinique, mais une voix experte, douce et empathique.

            CONTEXTE UTILISATRICE (IN {target_lang_name}) :
            - Risque aujourd'hui : {self._norm(self.req.get('risk_j3', 0.0))}/1
            - Sévérité visuelle : {self._norm(self.req.get('severity', 0.0))}/1
            - Facteurs SHAP (Causes) : {self.req.get('top3_shap', [])}
            - Phase du cycle : {ctx['phase']}
            - Type de peau : {ctx['skin']}
            - Lifestyle : {ctx['lifestyle']}
            - Allergies : {self.req.get('allergies', [])}
            - Traitement actuel : {self.req.get('acne_treatment', 'none')}

            TES MISSIONS :
            1. EXPLIQUE LA ROUTINE ÉTAPE PAR ÉTAPE comme un tuteur humain.
            2. DÉCRIS LE "COMMENT" : gestuelle, pression des doigts, timing.
            3. ADAPTE TON TON : Calme et rassurant si la peau est enflammée, encourageant si la peau est stable.
            4. INTERPRÈTE LES CAUSES (SHAP) : Explique l'impact du stress ou du sommeil sur sa peau.
            5. EXPLIQUE LE "POURQUOI" : Pourquoi cet actif ? Pourquoi cette étape ?
            6. CONSEILS LIFESTYLE : Explique l'impact de son alimentation/sommeil.

            STYLE DE RÉPONSE :
            - Langage humain simple.
            - Ton chaleureux et protecteur.
            - Utilise "Je" pour parler en tant que coach.
            - Structure par 🌅 Routine Matin, 🌙 Routine Soir, et 🌿 Conseils de Coach.
            - TERMINE TOUJOURS par cette phrase exacte : "{self._t('disclaimer')}"

            RÈGLE D'OR : Fais en sorte que l'utilisatrice se sente guidée, en sécurité et comprise.
            """

            chat_completion = client.chat.completions.create(
                messages=[{"role": "user", "content": prompt}], 
                model="llama-3.3-70b-versatile",
                temperature=0.7
            )
            self.explanation = chat_completion.choices[0].message.content
        except Exception as e:
            logger.error(f"Groq narrative error: {e}")
            pass

    def _build_response(self) -> Dict[str, Any]:
        # Filter actives by avoid pool
        final_actives = [cid for cid in self.actives_pool if cid not in self.avoid_pool]
        display_actives = [
            INGREDIENT_DB[a]["display"].get(self.lang, INGREDIENT_DB[a]["display"]["fr"]) 
            for a in final_actives if a in INGREDIENT_DB
        ]
        
        # Build routines based on skin type and strategy
        morning, evening = self._generate_routines(final_actives)
        
        return {
            "id": f"rec_{uuid.uuid4().hex[:8]}",
            "routine_morning": morning,
            "routine_evening": evening,
            "actives": display_actives,
            "avoid": [SYNONYM_INDEX.get(a, a) for a in self.avoid_pool],
            "lifestyle": list(set(self.lifestyle_tips))[:3],
            "nutrition": list(set(self.nutrition_tips))[:3],
            "habits": list(set(self.habits_tips))[:3],
            "diet_tips": self.nutrition_tips,
            "strategy": self._t(self.strategy),
            "alternative_strategy": self._t(self.alternative_strategy),
            "variation_index": self.variation_index,
            "explanation": self.explanation or self.message,
            "why_this": self.why_this if self.why_this else self._t("fallback_why"),
            "brands": "CeraVe, La Roche-Posay, Avène, The Ordinary",
            "disclaimer": self._t("disclaimer"),
            "riskJ3": self._norm(self.req.get('risk_j3', 0.0)),
            "hygieneScore": self.req.get('hygiene_score', 70),
            "severity": self._norm(self.req.get('severity', 0.0)),
            "createdAt": datetime.now(timezone.utc).isoformat(),
            "debug": {
                "recommendation_reasoning": {
                    "assigned_level": self.level,
                    "assigned_strategy": self.strategy,
                    "actives_chosen": list(final_actives),
                    "actives_avoided": list(self.avoid_pool),
                    "zone_focus": self.zone_focus
                }
            }
        }

    def _generate_routines(self, actives: List[str]) -> Tuple[List[Dict], List[Dict]]:
        skin = normalize(self.req.get('skin_type', 'mixte'))
        is_oily = "grasse" in skin or "acneique" in skin
        is_dry = "seche" in skin or "deshydratee" in skin
        
        # Default Cleansers
        if self.lang == "en":
            m_cleanser = "Purifying Cleansing Gel" if is_oily else "Gentle Hydrating Cleanser"
            e_cleanser = "Purifying Cleansing Gel" if is_oily else "Cleansing Balm"
            if self.is_medical_isotretinoin:
                m_cleanser = "Gentle Hydrating Cleanser"
                e_cleanser = "Cleansing Balm"
        else:
            m_cleanser = "Gel Nettoyant Purifiant" if is_oily else "Nettoyant Doux Hydratant"
            e_cleanser = "Gel Nettoyant Purifiant" if is_oily else "Baume Nettoyant"
            if self.is_medical_isotretinoin:
                m_cleanser = "Nettoyant Doux Hydratant"
                e_cleanser = "Baume Nettoyant"

        def get_ex(k): 
            # We map some common keys to PRODUCT_EXAMPLES
            key_map = {
                "Purifying Cleansing Gel": "gel_nettoyant_purifiant",
                "Gentle Hydrating Cleanser": "nettoyant_doux_hydratant",
                "Cleansing Balm": "baume_nettoyant",
                "Gel Nettoyant Purifiant": "gel_nettoyant_purifiant",
                "Nettoyant Doux Hydratant": "nettoyant_doux_hydratant",
                "Baume Nettoyant": "baume_nettoyant",
                "Sérum Vitamine C": "serum_vitamine_c",
                "Vitamin C Serum": "serum_vitamine_c",
                "Sérum Niacinamide": "serum_niacinamide",
                "Niacinamide Serum": "serum_niacinamide",
                "Hydratant Adapté": "fluide_hydratant" if is_oily else "creme_riche",
                "Suitable Moisturizer": "fluide_hydratant" if is_oily else "creme_riche",
                "Solaire SPF 50+": "solaire_spf_50+",
                "Sunscreen SPF 50+": "solaire_spf_50+",
                "Baume/Huile Démaquillante": "baume_nettoyant",
                "Cleansing Balm/Oil": "baume_nettoyant",
                "Sérum Rétinol": "serum_retinol",
                "Retinol Serum": "serum_retinol",
                "Sérum Acide Salicylique": "serum_acide_salicylique",
                "Salicylic Acid Serum": "serum_acide_salicylique",
                "Crème de Nuit Réparatrice": "creme_nuit",
                "Repairing Night Cream": "creme_nuit"
            }
            mapped_key = key_map.get(k, normalize(k))
            items = PRODUCT_EXAMPLES.get(mapped_key, [])
            if items:
                return self._rng.sample(items, min(2, len(items)))
            return []
        
        # Zone Focus Logic
        zones = self.req.get("zones", [])
        for z in zones:
            if z.lower() == "front":
                self.zone_focus[z] = "Focus on oil control and forehead cleansing" if self.lang == "en" else "Focus sur le contrôle du sébum et le nettoyage du front"
            elif z.lower() == "chin" or z.lower() == "menton":
                self.zone_focus[z] = "Hormonal acne suspected → monitor closely" if self.lang == "en" else "Acné hormonale suspectée → surveillance accrue"
            else:
                self.zone_focus[z] = "Standard care" if self.lang == "en" else "Soins standards"

        if self.lang == "en":
            m_instruction = "Wash your face with lukewarm water using gentle circular motions for 60 seconds."
            if self.level == "maintenance":
                m_instruction = "Light cleansing once per day is enough (or just warm water in the morning)."
        else:
            m_instruction = "Lavez votre visage à l'eau tiède avec des mouvements circulaires doux pendant 60 secondes."
            if self.level == "maintenance":
                m_instruction = "Un nettoyage léger une fois par jour suffit (ou juste de l'eau tiède le matin)."

        m = [{
            "step": "1", 
            "product": m_cleanser, 
            "instruction": m_instruction, 
            "icon": "🧼", 
            "productExamples": get_ex(m_cleanser),
            "reason": "Removes night impurities without attacking the hydrolipidic film." if self.lang == "en" else "Élimine les impuretés de la nuit sans agresser le film hydrolipidique."
        }]
        if "vitamine_c" in actives:
            m.append({
                "step": "2", 
                "product": "Vitamin C Serum" if self.lang == "en" else "Sérum Vitamine C", 
                "instruction": "Apply 3 drops to dry skin. Gently pat." if self.lang == "en" else "Appliquez 3 gouttes sur peau sèche. Tapotez légèrement.", 
                "icon": "✨", 
                "productExamples": get_ex("Vitamin C Serum" if self.lang == "en" else "Sérum Vitamine C"),
                "reason": "Protects from free radicals and boosts radiance." if self.lang == "en" else "Protège des radicaux libres et booste l'éclat."
            })
        elif "niacinamide" in actives:
            m.append({
                "step": "2", 
                "product": "Niacinamide Serum" if self.lang == "en" else "Sérum Niacinamide", 
                "instruction": "Apply to areas with enlarged pores or redness." if self.lang == "en" else "Appliquez sur les zones à pores dilatés ou à rougeurs.", 
                "icon": "🧪", 
                "productExamples": get_ex("Niacinamide Serum" if self.lang == "en" else "Sérum Niacinamide"),
                "reason": "Regulates sebum and soothes inflammation." if self.lang == "en" else "Régule le sébum et apaise les inflammations."
            })
        
        m.append({
            "step": "3", 
            "product": "Suitable Moisturizer" if self.lang == "en" else "Hydratant Adapté", 
            "instruction": "Massage from the center to the outside of the face." if self.lang == "en" else "Massez du centre vers l'extérieur du visage.", 
            "icon": "💧", 
            "productExamples": get_ex("Suitable Moisturizer" if self.lang == "en" else "Hydratant Adapté"),
            "reason": "Keeps the skin barrier sealed and avoids dehydration." if self.lang == "en" else "Maintient la barrière cutanée scellée et évite la déshydratation."
        })
        m.append({
            "step": "4", 
            "product": "Sunscreen SPF 50+" if self.lang == "en" else "Solaire SPF 50+", 
            "instruction": "Two fingers worth for the whole face." if self.lang == "en" else "La quantité de deux doigts pour tout le visage.", 
            "icon": "☀️", 
            "productExamples": get_ex("Sunscreen SPF 50+" if self.lang == "en" else "Solaire SPF 50+"),
            "reason": "Avoids sebum oxidation and post-acne spots." if self.lang == "en" else "Évite l'oxydation du sébum et les taches post-acné."
        })

        e = [{
            "step": "1", 
            "product": "Cleansing Balm/Oil" if self.lang == "en" else "Baume/Huile Démaquillante", 
            "instruction": "Massage onto dry skin to dissolve makeup and SPF, then rinse." if self.lang == "en" else "Massez sur peau sèche pour dissoudre le maquillage et le SPF, puis rincez.", 
            "icon": "🌙", 
            "productExamples": get_ex("Cleansing Balm/Oil" if self.lang == "en" else "Baume/Huile Démaquillante"),
            "reason": "Oil dissolves oil (makeup, oxidized sebum)." if self.lang == "en" else "Le gras dissout le gras (maquillage, sébum oxydé)."
        }]
        e.append({
            "step": "2", 
            "product": e_cleanser, 
            "instruction": "Use your water-based cleanser to complete the cleansing." if self.lang == "en" else "Utilisez votre nettoyant à base d'eau pour parfaire le nettoyage.", 
            "icon": "🧼", 
            "productExamples": get_ex(e_cleanser),
            "reason": "Removes last residues for perfectly clean skin." if self.lang == "en" else "Élimine les derniers résidus pour une peau parfaitement propre."
        })
        
        if "retinol" in actives and "luteale" not in normalize(self.req.get('phase', '')):
            e.append({
                "step": "3", 
                "product": "Retinol Serum" if self.lang == "en" else "Sérum Rétinol", 
                "instruction": "A pea-sized amount on perfectly dry skin. Avoid the eye area." if self.lang == "en" else "Une noisette sur peau parfaitement sèche. Évitez le contour des yeux.", 
                "icon": "🧪", 
                "productExamples": get_ex("Retinol Serum" if self.lang == "en" else "Sérum Rétinol"),
                "reason": "Accelerates cell renewal to treat acne deeply." if self.lang == "en" else "Accélère le renouvellement cellulaire pour traiter l'acné en profondeur."
            })
        elif "bha" in actives:
            e.append({
                "step": "3", 
                "product": "Salicylic Acid Serum" if self.lang == "en" else "Sérum Acide Salicylique", 
                "instruction": "Apply only to congested areas." if self.lang == "en" else "Appliquez uniquement sur les zones congestionnées.", 
                "icon": "🧪", 
                "productExamples": get_ex("Salicylic Acid Serum" if self.lang == "en" else "Sérum Acide Salicylique"),
                "reason": "Unclogs pores and removes blackheads." if self.lang == "en" else "Débouche les pores et élimine les points noirs."
            })
            
        e.append({
            "step": "4", 
            "product": "Repairing Night Cream" if self.lang == "en" else "Crème de nuit", 
            "instruction": "Apply generously to help the skin regenerate." if self.lang == "en" else "Appliquez généreusement pour aider la peau à se régénérer.", 
            "icon": "🌙", 
            "productExamples": get_ex("Repairing Night Cream" if self.lang == "en" else "Crème de nuit"),
            "reason": "Supports the skin barrier during the peak of nocturnal regeneration." if self.lang == "en" else "Soutient la barrière cutanée pendant le pic de régénération nocturne."
        })
        
        return m, e
        
        return m, e
