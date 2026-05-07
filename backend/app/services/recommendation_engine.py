import uuid
import os
import logging
import math
import unicodedata
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
        self.explanation = ""
        self.message = ""
        self.debug_mode = os.getenv("DEBUG_MODE", "false").lower() == "true"

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
            return True

        # ANTIBIOTICS
        if "antibio" in treat:
            self.nutrition_tips.append("Ajoutez des probiotiques pour soutenir votre flore intestinale")
            self.lifestyle_tips.append("Protection solaire SPF50 obligatoire (photosensibilisation)")
            self.message = "Antibiotiques détectés — protégez votre peau du soleil."

        return False

    def _check_risk_strategy(self):
        risk = self._norm(self.req.get('risk_today', 0.0))
        severity = self._norm(self.req.get('severity', 0.0))

        # CNN OVERRIDE (Step 4)
        if severity > 0.6:
            self.strategy = STRATEGY_PROTECTION
            self.avoid_pool.update({"retinol", "aha", "bha", "vitamine_c"})
            self.message = "Sévérité visuelle élevée — repos cutané préconisé."
            return

        # ML RISK (Step 3)
        if risk < 0.35:
            self.strategy = STRATEGY_PREVENTION
        elif risk <= 0.60:
            self.strategy = STRATEGY_EQUILIBRE
        else:
            self.strategy = STRATEGY_PROTECTION
            self.avoid_pool.update({"retinol", "aha", "bha", "vitamine_c"})
            self.message = "Risque élevé — Priorité à l'apaisement."

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
        if "fast_food" in diet:
            self.nutrition_tips.append("Le fast-food sature le foie et augmente l'inflammation en phase " + phase)
        if "sugar" in diet:
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
            prompt = f"Assistant Hermona. Explique cette routine. Stratégie: {self.strategy}. Actifs: {list(self.actives_pool)}. Phase: {self.req.get('phase')}. Sois court et empathique."
            chat_completion = client.chat.completions.create(
                messages=[{"role": "user", "content": prompt}], 
                model="llama-3.3-70b-versatile",
                timeout=5.0
            )
            self.explanation = chat_completion.choices[0].message.content
        except: pass

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
            "explanation": self.explanation or self.message,
            "brands": "CeraVe, La Roche-Posay, Avène, The Ordinary",
            "disclaimer": "Hermona n'est pas un outil médical. Consultez un dermatologue.",
            "riskScore": self._norm(self.req.get('risk_today', 0.0)),
            "severity": self._norm(self.req.get('severity', 0.0)),
            "createdAt": datetime.now(timezone.utc).isoformat()
        }

    def _generate_routines(self, actives: List[str]) -> Tuple[List[Dict], List[Dict]]:
        skin = normalize(self.req.get('skin_type', 'mixte'))
        is_oily = "grasse" in skin or "acneique" in skin
        is_dry = "seche" in skin or "deshydratee" in skin
        
        # Default Cleansers
        m_cleanser = "Gel Nettoyant Purifiant" if is_oily else "Nettoyant Doux Hydratant"
        e_cleanser = "Gel Nettoyant" if is_oily else "Lait/Baume Nettoyant"
        
        if self.is_medical_isotretinoin:
            m_cleanser = "Nettoyant Doux Non-Moussant"
            e_cleanser = "Baume Nettoyant Ultra-Doux"

        m = [{"step": "1", "product": m_cleanser, "instruction": "Matin : Nettoyage doux", "icon": "🧼"}]
        if "vitamine_c" in actives:
            m.append({"step": "2", "product": "Sérum Vitamine C", "instruction": "Antioxydant éclat", "icon": "✨"})
        elif "niacinamide" in actives:
            m.append({"step": "2", "product": "Sérum Niacinamide", "instruction": "Régulateur sébum/pores", "icon": "🧪"})
        
        m.append({"step": "3", "product": "Fluide Hydratant" if is_oily else "Crème Riche", "instruction": "Hydratation", "icon": "💧"})
        m.append({"step": "4", "product": "Solaire SPF 50+", "instruction": "Protection UV obligatoire", "icon": "☀️"})

        e = [{"step": "1", "product": "Huile/Baume Démaquillant", "instruction": "Double nettoyage", "icon": "🌙"}]
        e.append({"step": "2", "product": e_cleanser, "instruction": "Nettoyage en profondeur", "icon": "🧼"})
        
        if "retinol" in actives and "luteale" not in normalize(self.req.get('phase', '')):
            e.append({"step": "3", "product": "Sérum Rétinol", "instruction": "Soin anti-imperfections", "icon": "🧪"})
        elif "bha" in actives:
            e.append({"step": "3", "product": "Sérum Acide Salicylique", "instruction": "Exfoliation douce", "icon": "🧪"})
            
        e.append({"step": "4", "product": "Crème de Nuit Réparatrice", "instruction": "Régénération", "icon": "🌙"})
        
        return m, e
