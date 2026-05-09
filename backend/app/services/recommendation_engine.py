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
STRATEGY_PREVENTION = "PRÉVENTION"
STRATEGY_EQUILIBRE = "ÉQUILIBRE"
STRATEGY_PROTECTION = "PROTECTION"
STRATEGY_MEDICAL = "PROTOCOLE MÉDICAL (ISOTRÉTINOÏNE)"

# --- DATA LAYER ---
INGREDIENT_DB = {
    "retinol": {"display": "Rétinol", "type": "irritant", "strength": 5.0},
    "vitamine_c": {"display": "Vitamine C", "type": "antioxydant", "strength": 4.0},
    "aha": {"display": "AHA (Acide Glycolique)", "type": "acide", "strength": 3.0},
    "bha": {"display": "BHA (Acide Salicylique)", "type": "acide", "strength": 3.0},
    "niacinamide": {"display": "Niacinamide", "type": "apaisant", "strength": 2.5},
    "zinc": {"display": "Zinc PCA", "type": "purifiant", "strength": 2.0},
    "acide_hyaluronique": {"display": "Acide Hyaluronique", "type": "hydratant", "strength": 1.5},
    "centella_asiatica": {"display": "Centella Asiatica", "type": "apaisant", "strength": 1.0},
    "panthenol": {"display": "Panthénol (B5)", "type": "apaisant", "strength": 1.0},
    "aloe_vera": {"display": "Aloe Vera", "type": "hydratant", "strength": 1.0},
    "acide_salicylique": {"display": "Acide Salicylique (BHA)", "type": "acide", "strength": 3.0},
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
            self.message = "Sous isotrétinoïne — Douceur absolue requise. Consultez votre dermatologue."
            self.lifestyle_tips.append("Changez votre taie d'oreiller tous les 2 jours")
            self.nutrition_tips.append("Hydratez-vous : 2L d'eau par jour minimum")
            self.habits_tips.append("ÉVITEZ le gommage à grains (ex: St. Ives) qui déchire votre barrière cutanée.")
            return True

        # ANTIBIOTICS
        if "antibio" in treat:
            self.nutrition_tips.append("Ajoutez des probiotiques pour soutenir votre flore intestinale")
            self.lifestyle_tips.append("Protection solaire SPF50 obligatoire (photosensibilisation)")
            self.message = "Antibiotiques détectés — protégez votre peau du soleil."

        return False

    def _check_risk_strategy(self):
        try:
            risk = float(self.req.get('risk_today', 0.0))
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
            STRATEGY_PROTECTION: {"level": "intensive",    "msg": "Risque ou inflammation — Priorité à l'apaisement et la réparation."},
            STRATEGY_EQUILIBRE:  {"level": "moderate",     "msg": "Stratégie d'équilibre — Maintenance et régulation du sébum."},
            STRATEGY_PREVENTION: {"level": "maintenance",  "msg": "Score optimal — Routine de prévention et maintien de la barrière."},
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
            self.why_this.append("Votre profil actuel nécessite une approche protectrice pour éviter l'inflammation.")

    def _apply_phase_rules(self):
        if self.strategy == STRATEGY_PROTECTION: return
        
        phase = normalize(self.req.get('phase', ''))
        risk = self._norm(self.req.get('risk_today', 0.0))

        if "folliculaire" in phase:
            self.actives_pool.update({"retinol", "vitamine_c", "aha"})
        elif "ovulatoire" in phase:
            self.actives_pool.update({"niacinamide", "zinc"})
        elif "luteale" in phase:
            if risk < 0.60:
                self.actives_pool.update({"bha", "niacinamide"})
            else:
                self.actives_pool.add("niacinamide") # Risk rule wins over phase
                self.why_this.append("La niacinamide a été choisie pour réguler le sébum sans irriter votre peau en phase lutéale.")
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
            self.nutrition_tips.extend([
                "Aliments anti-inflammatoires : saumon, noix (Omega-3), myrtilles.",
                "Tisane de menthe poivrée : réduit les androgènes et le sébum.",
                "ÉVITEZ le sucre, les produits laitiers et les boissons glacées."
            ])
            self.lifestyle_tips.extend([
                "Sport doux (Yoga, Pilates, Marche) pour limiter le cortisol.",
                "Sommeil : 8h minimum pour aider la régénération cutanée.",
                "Hygiène : Changez votre taie d'oreiller tous les 2 jours."
            ])
        elif "menstruelle" in phase:
            self.nutrition_tips.extend([
                "Aliments riches en fer (lentilles, chocolat noir >70%).",
                "Tisane curcuma/gingembre pour l'inflammation.",
                "Évitez les boissons froides et l'excès de caféine."
            ])
            self.lifestyle_tips.append("Repos prioritaire. Bouillotte chaude et sommeil réparateur.")
        elif "folliculaire" in phase:
            self.nutrition_tips.append("Moment idéal pour des aliments détox (citron, concombre, kéfir).")
            self.lifestyle_tips.append("Énergie haute : idéal pour cardio ou nouveaux soins.")
        elif "ovulatoire" in phase:
            self.nutrition_tips.append("Légumes crucifères (brocoli) pour l'équilibre des œstrogènes.")
            self.lifestyle_tips.append("Restez hydratée, la température corporelle augmente légèrement.")

        # 2. PERSONALIZED ADVICE BASED ON PROFILE & DIET (Section 4.B)
        diet = self.req.get('diet', [])
        if "fast_food" in diet or "fastfood" in diet:
            self.nutrition_tips.append("Le fast-food sature le foie et augmente l'inflammation en phase " + phase)
        if "sugar" in diet or "sucre" in diet:
            self.nutrition_tips.append("Réduire les sucres rapides aide à calmer l'acné inflammatoire.")
            
        stress = self.req.get('stress', 5)
        if stress > 7:
            self.lifestyle_tips.append("Niveau de stress élevé détecté → ajoutez 10min de relaxation et réduisez sucres/produits laitiers.")
            
        sleep = self.req.get('sleep', 7)
        if sleep < 6:
            self.lifestyle_tips.append("Manque de sommeil → la régénération de votre barrière cutanée est ralentie.")
            self.nutrition_tips.append("Le sucre spike l'IGF-1 : évitez les sodas et pâtisseries cette semaine.")
        if "dairy" in diet:
            self.nutrition_tips.append("Les produits laitiers contiennent des hormones de croissance qui stimulent l'acné.")
        if "cold_drinks" in diet:
            self.nutrition_tips.append("Boissons glacées : créent un choc digestif qui favorise l'inflammation.")
            
        if self.req.get('alcohol') == "regular":
            self.nutrition_tips.append("Alcool régulier : déshydrate et augmente le cortisol (inflammation).")
        if self.req.get('smoker') is True:
            self.lifestyle_tips.append("Tabac : réduit l'oxygénation de la peau et retarde la cicatrisation.")

        # 3. HYGIENE & HABITS (Section 4.F)
        self.habits_tips.append("Démaquillage COMPLET chaque soir, sans exception.")
        self.habits_tips.append("Nettoyez l'écran de votre téléphone avec une lingette désinfectante.")
        
        stress = int(self.req.get('stress', 5))
        if stress > 7:
            self.lifestyle_tips.append("Stress élevé : essayez la respiration 'box breathing' (4-4-4-4).")
            self.actives_pool.add("centella_asiatica")
            
        sleep = float(self.req.get('sleep', 8))
        if sleep < 7:
            self.lifestyle_tips.append(f"Seulement {sleep}h de sommeil : pas de téléphone 1h avant de dormir.")
            
        hydration = int(self.req.get('hydration', 6))
        if hydration < 5:
            self.nutrition_tips.append(f"Déshydratation ({hydration} verres) : buvez de l'eau avant votre café.")

        # 4. SHAP FINE-TUNING (Step 7)
        shaps = self.req.get('top3_shap', [])
        if any(word in str(shaps).lower() for word in ["hormon", "progesteron"]):
            self.message += " | Anticipation hormonale requise."
        if any("stress" in str(s).lower() for s in shaps):
            self.lifestyle_tips.append("SHAP Stress : réduisez les actifs irritants cette semaine.")
            
        # 5. ZONES SPECIFIC
        zones = self.req.get('zones', [])
        if "chin" in zones or "jaw" in zones:
            self.habits_tips.append("Acné menton/mâchoire : souvent hormonale. Soyez douce.")
        if "forehead" in zones:
            self.habits_tips.append("Front : évitez les franges et vérifiez vos shampooings.")


    def _apply_allergy_filter(self):
        allergies = self.req.get('allergies', [])
        for a in allergies:
            norm_a = normalize(a)
            cid = SYNONYM_INDEX.get(norm_a)
            if cid:
                self.avoid_pool.add(cid)
            if "parfum" in norm_a:
                self.message += " | SANS PARFUM requis."
            if "alcool" in norm_a:
                self.avoid_pool.add("alcohol")

    def _engine_narrative(self):
        key = os.getenv("GROQ_API_KEY")
        if not key: return
        try:
            client = Groq(api_key=key)
            
            # Prepare context for AI
            risk = self._norm(self.req.get('risk_today', 0.0))
            severity = self._norm(self.req.get('severity', 0.0))
            shaps = self.req.get('top3_shap', [])
            lifestyle = f"Stress: {self.req.get('stress')}, Sommeil: {self.req.get('sleep')}h, Hydratation: {self.req.get('hydration')} verres"
            phase = self.req.get('phase', 'inconnue')
            skin = self.req.get('skin_type', 'mixte')
            
            prompt = f"""
            TU ES HERMONA AI — TON RÔLE : COACH PERSONNEL EN SOINS DE LA PEAU (HUMAN SKINCARE COACH).
            Tu n'es pas un système clinique, mais une voix experte, douce et empathique.

            CONTEXTE UTILISATRICE :
            - Risque aujourd'hui : {risk}/1
            - Sévérité visuelle : {severity}/1
            - Facteurs SHAP (Causes) : {shaps}
            - Phase du cycle : {phase}
            - Type de peau : {skin}
            - Lifestyle : {lifestyle}
            - Allergies : {self.req.get('allergies')}
            - Traitement actuel : {self.req.get('acne_treatment')}

            TES MISSIONS :
            1. EXPLIQUE LA ROUTINE ÉTAPE PAR ÉTAPE comme un tuteur humain.
            2. DÉCRIS LE "COMMENT" : gestuelle, pression des doigts, timing (ex: massage de 60s).
            3. ADAPTE TON TON : Calme et rassurant si la peau est enflammée (risque/sévérité élevés), encourageant si la peau est stable.
            4. INTERPRÈTE LES CAUSES (SHAP) : Explique l'impact du stress ou du sommeil sur sa peau cette semaine.
            5. EXPLIQUE LE "POURQUOI" : Pourquoi cet actif ? Pourquoi cette étape ?
            6. CONSEILS LIFESTYLE : Explique l'impact de son alimentation/sommeil au lieu de juste lister des faits.

            STYLE DE RÉPONSE :
            - Langage humain simple (pas de jargon médical complexe).
            - Ton chaleureux et protecteur.
            - Utilise "Je" pour parler en tant que coach.
            - Structure par 🌅 Routine Matin, 🌙 Routine Soir, et 🌿 Conseils de Coach.
            - TERMINE TOUJOURS par cette phrase exacte : "⚕️ DISCLAIMER : Ceci est un système de recommandation de soins de la peau et non un diagnostic médical. Consultez un dermatologue si nécessaire."

            RÈGLE D'OR : Fais en sorte que l'utilisatrice se sente guidée, en sécurité et comprise.
            """

            chat_completion = client.chat.completions.create(
                messages=[{"role": "user", "content": prompt}], 
                model="llama-3.3-70b-versatile",
                timeout=15.0 # Increased timeout for more detailed response
            )
            self.explanation = chat_completion.choices[0].message.content
        except Exception as e:
            logger.error(f"Groq narrative error: {e}")
            pass

    def _build_response(self) -> Dict[str, Any]:
        # Filter actives by avoid pool
        final_actives = [cid for cid in self.actives_pool if cid not in self.avoid_pool]
        display_actives = [INGREDIENT_DB[a]["display"] for a in final_actives if a in INGREDIENT_DB]
        
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
            "strategy": self.strategy,
            "alternative_strategy": self.alternative_strategy,
            "variation_index": self.variation_index,
            "explanation": self.explanation or self.message,
            "why_this": self.why_this if self.why_this else ["Optimisation de la barrière cutanée", "Régulation du sébum"],
            "brands": "CeraVe, La Roche-Posay, Avène, The Ordinary",
            "disclaimer": "Hermona n'est pas un outil médical. Consultez un dermatologue.",
            "riskScore": self._norm(self.req.get('risk_today', 0.0)),
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
        m_cleanser = "Gel Nettoyant Purifiant" if is_oily else "Nettoyant Doux Hydratant"
        e_cleanser = "Gel Nettoyant Purifiant" if is_oily else "Baume Nettoyant"
        
        if self.is_medical_isotretinoin:
            m_cleanser = "Nettoyant Doux Hydratant"
            e_cleanser = "Baume Nettoyant"

        def get_ex(k): 
            items = PRODUCT_EXAMPLES.get(normalize(k), [])
            if items:
                return self._rng.sample(items, min(2, len(items)))
            return []
        
        # Zone Focus Logic
        zones = self.req.get("zones", [])
        for z in zones:
            if z.lower() == "front":
                self.zone_focus[z] = "Focus on oil control and forehead cleansing"
            elif z.lower() == "chin" or z.lower() == "menton":
                self.zone_focus[z] = "Hormonal acne suspected → monitor closely"
            else:
                self.zone_focus[z] = "Standard care"

        m_instruction = "Lavez votre visage à l'eau tiède avec des mouvements circulaires doux pendant 60 secondes."
        if self.level == "maintenance":
            m_instruction = "Light cleansing once per day is enough (or just warm water in the morning)."

        m = [{
            "step": "1", 
            "product": m_cleanser, 
            "instruction": m_instruction, 
            "icon": "🧼", 
            "productExamples": get_ex(m_cleanser),
            "reason": "Élimine les impuretés de la nuit sans agresser le film hydrolipidique."
        }]
        if "vitamine_c" in actives:
            m.append({
                "step": "2", 
                "product": "Sérum Vitamine C", 
                "instruction": "Appliquez 3 gouttes sur peau sèche. Tapotez légèrement.", 
                "icon": "✨", 
                "productExamples": get_ex("serum_vitamine_c"),
                "reason": "Protège des radicaux libres et booste l'éclat."
            })
        elif "niacinamide" in actives:
            m.append({
                "step": "2", 
                "product": "Sérum Niacinamide", 
                "instruction": "Appliquez sur les zones à pores dilatés ou à rougeurs.", 
                "icon": "🧪", 
                "productExamples": get_ex("serum_niacinamide"),
                "reason": "Régule le sébum et apaise les inflammations."
            })
        
        m.append({
            "step": "3", 
            "product": "Hydratant Adapté", 
            "instruction": "Massez du centre vers l'extérieur du visage.", 
            "icon": "💧", 
            "productExamples": get_ex("fluide_hydratant" if is_oily else "creme_riche"),
            "reason": "Maintient la barrière cutanée scellée et évite la déshydratation."
        })
        m.append({
            "step": "4", 
            "product": "Solaire SPF 50+", 
            "instruction": "La quantité de deux doigts pour tout le visage.", 
            "icon": "☀️", 
            "productExamples": get_ex("solaire_spf_50+"),
            "reason": "Évite l'oxydation du sébum et les taches post-acné."
        })

        e = [{
            "step": "1", 
            "product": "Baume/Huile Démaquillante", 
            "instruction": "Massez sur peau sèche pour dissoudre le maquillage et le SPF, puis rincez.", 
            "icon": "🌙", 
            "productExamples": get_ex("baume_nettoyant"),
            "reason": "Le gras dissout le gras (maquillage, sébum oxydé)."
        }]
        e.append({
            "step": "2", 
            "product": e_cleanser, 
            "instruction": "Utilisez votre nettoyant à base d'eau pour parfaire le nettoyage.", 
            "icon": "🧼", 
            "productExamples": get_ex(e_cleanser),
            "reason": "Élimine les derniers résidus pour une peau parfaitement propre."
        })
        
        if "retinol" in actives and "luteale" not in normalize(self.req.get('phase', '')):
            e.append({
                "step": "3", 
                "product": "Sérum Rétinol", 
                "instruction": "Une noisette sur peau parfaitement sèche. Évitez le contour des yeux.", 
                "icon": "🧪", 
                "productExamples": get_ex("serum_retinol"),
                "reason": "Accélère le renouvellement cellulaire pour traiter l'acné en profondeur."
            })
        elif "bha" in actives:
            e.append({
                "step": "3", 
                "product": "Sérum Acide Salicylique", 
                "instruction": "Appliquez uniquement sur les zones congestionnées.", 
                "icon": "🧪", 
                "productExamples": get_ex("serum_acide_salicylique"),
                "reason": "Débouche les pores et élimine les points noirs."
            })
            
        e.append({
            "step": "4", 
            "product": "Crème de Nuit Réparatrice", 
            "instruction": "Appliquez généreusement pour aider la peau à se régénérer.", 
            "icon": "🌙", 
            "productExamples": get_ex("creme_nuit"),
            "reason": "Soutient la barrière cutanée pendant le pic de régénération nocturne."
        })
        
        return m, e
