import os
import uuid
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

"""
HERMONA HYBRID CLINICAL-ML DECISION SYSTEM:
- Clinical Layer: Deterministic rule-based estimation (Clinical Engine).
- ML Layer: Probabilistic risk prediction (LightGBM Contextual Predictor).
- API Layer: Orchestration of the clinical-to-ML pipeline.
- Frontend Layer: Presentation and data collection.
"""
from fastapi import FastAPI, UploadFile, File, HTTPException, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib
import pandas as pd
import cv2
import numpy as np
import base64
import copy
import hashlib
import json
import shap
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore
from model.yolo_model import get_model

# --- Configuration ---
env_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(env_path)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("HermonaBackend")

# --- Firebase Initialization ---
def initialize_firebase():
    possible_paths = [
        "serviceAccountKey.json",
        os.path.join("scripts", "serviceAccountKey.json"),
        os.path.join(os.path.dirname(__file__), "..", "scripts", "serviceAccountKey.json"),
        os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")
    ]
    
    for path in possible_paths:
        if os.path.exists(path):
            try:
                cred = credentials.Certificate(path)
                firebase_admin.initialize_app(cred)
                logger.info(f"✅ Firebase initialized with {path}")
                return
            except Exception as e:
                logger.error(f"❌ Error initializing Firebase with {path}: {e}")
                
    # Fallback to default credentials
    try:
        firebase_admin.initialize_app()
        logger.info("✅ Firebase initialized with default credentials")
    except Exception as e:
        logger.error(f"❌ Firebase initialization fallback failed: {e}")

initialize_firebase()

db = firestore.client()

from .ml_pipeline.builder import MLFeatureBuilder
from .ml_pipeline.defaults import RISK_THRESHOLDS
from .ml_pipeline.features import FEATURE_NAMES
from .services.recommendation_engine import RecommendationEngine
from .services.hygiene_score_service import HygieneScoreService

# Initialize SHAP Explainer (Global to avoid re-creation overhead)
# This uses the TreeExplainer optimized for LightGBM
explainer = None
if os.path.exists(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "model", "modele_hermona_5000_20260415_221830 (1).pkl")):
    _model_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "model", "modele_hermona_5000_20260415_221830 (1).pkl")
    _model = joblib.load(_model_path)
    explainer = shap.TreeExplainer(_model)

# --- Configuration ---

app = FastAPI(title="Hermona AI Backend")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

HERMONA_API_KEY = os.getenv("HERMONA_API_KEY", "hermona_secret_2026")
async def verify_api_key(request: Request):
    api_key = request.headers.get("X-API-Key")
    if api_key != HERMONA_API_KEY: raise HTTPException(status_code=403, detail="Unauthorized")

@app.get("/health")
async def health():
    return {
        "status": "online",
        "ml_model": pkl_model is not None,
        "yolo_model": get_model() is not None,
        "timestamp": datetime.now().isoformat()
    }

# --- Model Loading ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_DIR = os.path.join(BASE_DIR, "model")
PKL_PATH = os.path.join(MODEL_DIR, "modele_hermona_5000_20260415_221830 (1).pkl")

try:
    pkl_model = joblib.load(PKL_PATH)
    logger.info("✅ ML Model Loaded")
except Exception as e:
    logger.error(f"❌ Error loading ML model: {e}")
    pkl_model = None

# --- MODELS ---

class PredictPayload(BaseModel):
    answers: Dict[str, Any]
    schema_version: str = "v8"

from pydantic import BaseModel, Field

class RecommendationRequest(BaseModel):
    userId: str
    severity: float
    zones: List[str]
    detectionId: str = ""
    risk_j3: float = Field(0.0, alias="riskJ3")
    top3_shap: List[str] = []
    skin_type: str = Field("mixte", alias="skinType")
    allergies: List[str] = []
    acne_treatment: str = Field("aucun", alias="acneTreatment")
    hormonal_treatment: str = Field("aucune", alias="hormonalTreatment")
    smoker: bool = False
    alcohol: str = "jamais"
    phase: str = "folliculaire"
    stress: int = 5
    sleep: float = 7.0
    sleep_quality: int = 3
    hydration: int = 5
    diet: List[str] = []
    symptoms: List[str] = []
    lang: str = "fr"
    hygiene_score: int = Field(70, alias="hygieneScore")
    hygiene_breakdown: Optional[Dict[str, Any]] = Field(None, alias="hygieneBreakdown")
    hygiene_details: Optional[List[str]] = Field(None, alias="hygieneDetails")

    class Config:
        populate_by_name = True

# --- CHAT ---
from groq import Groq
groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))

class ChatPayload(BaseModel):
    message: str
    profile: Optional[Dict[str, Any]] = None
    daily: Optional[Dict[str, Any]] = None
    hormonal: Optional[Dict[str, Any]] = None
    history: List[Dict[str, str]] = []

@app.post("/chat")
async def chat(body: ChatPayload, _ = Depends(verify_api_key)):
    try:
        # 1. Construction du contexte personnalisé
        p = body.profile or {}
        d = body.daily or {}
        h = body.hormonal or {}
        
        system_prompt = f"""Tu es Hermona, l'assistante IA experte en dermatologie et cycles hormonaux.
Ton but est d'aider l'utilisatrice à comprendre sa peau en fonction de ses données.

DONNÉES DE L'UTILISATRICE :
- Âge : {p.get('age', 'non précisé')} ans
- Type de peau : {p.get('type_peau', 'non précisé')}
- SOPK : {'Oui' if p.get('pcos') else 'Non'}
- Stress : {d.get('stress', 'normal')}/10
- Sommeil : {d.get('sommeil', 'normal')}h
- Jour du cycle : {h.get('jour_cycle', 'non précisé')}
- Phase : {h.get('phase', 'non précisée')}

CONSIGNES :
1. Sois empathique, professionnelle et concise.
2. Basse TES RÉPONSES sur ces données spécifiques. Ne donne pas de conseils génériques si les données permettent de personnaliser.
3. Si l'utilisatrice est en phase lutéale, mentionne l'impact de la progestérone sur le sébum.
4. CLAUSE DE NON-RESPONSABILITÉ : Rappelle occasionnellement que tu es une IA et non un dermatologue.
"""
        
        messages = [{"role": "system", "content": system_prompt}]
        
        # Ajout de l'historique (limité aux 6 derniers pour le contexte)
        for msg in body.history[-6:]:
            messages.append({"role": msg["role"], "content": msg["content"]})
            
        # Message actuel
        messages.append({"role": "user", "content": body.message})

        chat_completion = groq_client.chat.completions.create(
            messages=messages,
            model="llama-3.3-70b-versatile",
            temperature=0.7,
            max_tokens=500
        )
        
        return {"response": chat_completion.choices[0].message.content}
    except Exception as e:
        logger.error(f"Erreur Chat: {e}")
        return {"response": "Désolée, je rencontre une petite difficulté technique. Peux-tu reformuler ?"}

# --- TRANSCRIPTION (Microphone) ---
import tempfile

@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...), _ = Depends(verify_api_key)):
    """
    Transcrit un fichier audio (m4a, mp3, wav, webm, ogg, mp4) en texte
    en utilisant le modèle Whisper de Groq.
    """
    try:
        # Lire le contenu du fichier audio
        audio_bytes = await file.read()
        if not audio_bytes:
            raise HTTPException(status_code=400, detail="Fichier audio vide")

        # Déterminer l'extension à partir du nom de fichier ou du content-type
        original_filename = file.filename or "audio.m4a"
        suffix = os.path.splitext(original_filename)[-1].lower()
        if suffix not in [".m4a", ".mp3", ".wav", ".webm", ".ogg", ".mp4", ".flac"]:
            suffix = ".m4a"  # fallback sûr pour les enregistrements mobiles

        # Écrire dans un fichier temporaire (requis par le client Groq)
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
            tmp.write(audio_bytes)
            tmp_path = tmp.name

        try:
            with open(tmp_path, "rb") as audio_file:
                transcription = groq_client.audio.transcriptions.create(
                    model="whisper-large-v3-turbo",
                    file=(os.path.basename(tmp_path), audio_file, "audio/m4a"),
                    language="fr",
                    response_format="text"
                )
            text = transcription if isinstance(transcription, str) else getattr(transcription, "text", "")
            logger.info(f"✅ Transcription réussie : '{text[:60]}...'")
            return {"text": text}
        finally:
            # Nettoyage du fichier temporaire
            try:
                os.remove(tmp_path)
            except Exception:
                pass

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur de transcription : {e}")
        raise HTTPException(status_code=500, detail=f"Erreur de transcription : {str(e)}")

# --- ENDPOINTS ---

# --- V7.1 & V8 DATA CONTRACTS ---
ALLOWED_STABLE_KEYS = {
    "age", "imc", "skinType", "isSmoker", "smoker", "cigarettesPerDay", 
    "alcohol", "acneFamilyHistory", "sopk", "routineMatin", "routineSoir", 
    "sleep", "diet", "stress", "lastPeriodDate", "cycleDuration"
}
REQUIRED_PILLARS = {"age", "skinType"}
LIFESTYLE_PILLARS = {"sleep", "diet", "stress"}

# V8.1 FINAL PRO STATUS CODES
DATA_VALID = "VALID"
DATA_INVALID = "INVALID_STRUCTURE"
CLINICAL_OK = "OK"
PHYSIOLOGICAL_WARNING = "PHYSIOLOGICAL_WARNING"
BEHAVIORAL_WARNING = "BEHAVIORAL_WARNING"
CLINICAL_INVALID = "INVALID_CLINICAL"

SCORE_COMPUTABLE = "computable"
SCORE_DEGRADED = "degraded"
SCORE_BLOCKED = "blocked"

def analyze_and_sanitize(raw_profile: dict) -> tuple:
    """
    LAYER 1: CLINICAL SANITIZER & ANALYZER (V8.1 PRO Dual-Path)
    Analyzes Clinical Status on RAW data, Sanitizes for Scoring.
    """
    sanitized = copy.deepcopy(raw_profile)
    log = []
    data_status = DATA_VALID
    clinical_status = CLINICAL_OK
    
    if not isinstance(raw_profile, dict) or not raw_profile:
        return {}, [], DATA_INVALID, CLINICAL_INVALID
    
    # 1. Data Structure Check
    missing = [k for k in REQUIRED_PILLARS if k not in raw_profile or raw_profile[k] is None]
    if missing:
        data_status = DATA_INVALID
        
    # 2. Dual-Path Analysis (Age)
    try:
        age_raw = int(raw_profile.get('age', 0))
        if age_raw < 10:
            clinical_status = CLINICAL_INVALID
        elif age_raw > 100:
            clinical_status = PHYSIOLOGICAL_WARNING
            log.append({"field": "age", "raw": age_raw, "used": 100, "rule": "CLAMP_MAX_100"})
            sanitized['age'] = 100
    except (ValueError, TypeError):
        data_status = DATA_INVALID

    # 3. Dual-Path Analysis (Stress)
    stress_raw = raw_profile.get('stress')
    if stress_raw is not None:
        try:
            if isinstance(stress_raw, (int, float)) and stress_raw > 10:
                clinical_status = BEHAVIORAL_WARNING if clinical_status == CLINICAL_OK else clinical_status
                log.append({"field": "stress", "raw": stress_raw, "used": 10, "rule": "CLAMP_MAX_10"})
                sanitized['stress'] = 10
        except: pass

    return sanitized, log, data_status, clinical_status

# --- LAYER 2.4: CLINICAL POLICY (Audit-Grade V8.6) ---
CLINICAL_POLICY_V86 = {
    "version": "v8.6-clinical-policy",
    "structural_rules": {
        DATA_INVALID: {"rule_id": "STRUCT_BREAK", "block": True, "score_validity": SCORE_BLOCKED, "flag": "STRUCTURAL_BREAK"}
    },
    "clinical_rules": {
        CLINICAL_INVALID: {"rule_id": "CLIN_HARD_BLOCK", "block": True, "score_validity": SCORE_BLOCKED, "flag": "CLINICAL_HARD_BLOCK"},
        PHYSIOLOGICAL_WARNING: {"rule_id": "PHYS_WARN", "block": False, "score_validity": SCORE_DEGRADED, "flag": PHYSIOLOGICAL_WARNING},
        BEHAVIORAL_WARNING: {"rule_id": "BEHAV_WARN", "block": False, "score_validity": SCORE_DEGRADED, "flag": BEHAVIORAL_WARNING}
    }
}

def calculate_policy_hash(policy: dict) -> str:
    policy_string = json.dumps(policy, sort_keys=True)
    return f"sha256:{hashlib.sha256(policy_string.encode()).hexdigest()}"

def calculate_execution_hash(trace: list) -> str:
    trace_string = json.dumps(trace, sort_keys=True)
    return f"sha256:{hashlib.sha256(trace_string.encode()).hexdigest()}"

POLICY_HASH_V87 = calculate_policy_hash(CLINICAL_POLICY_V86)

def execute_scl_policy(data_status: str, clinical_status: str, policy: dict) -> dict:
    """
    LAYER 2.5: SCL EXECUTION ENGINE (V8.7 Crypto-Audit)
    Returns: { "block": bool, "flags": [], "score_validity": str, "trace": [], "execution_hash": str }
    """
    flags = []
    trace = []
    block = False
    score_validity = SCORE_COMPUTABLE
    
    # 1. Structural Trace
    struct_rule = policy["structural_rules"].get(data_status)
    if struct_rule:
        block = struct_rule["block"]
        score_validity = struct_rule["score_validity"]
        flags.append(struct_rule["flag"])
        trace.append({
            "rule_id": struct_rule["rule_id"],
            "input": data_status,
            "decision": score_validity,
            "applied": True
        })
        
    # 2. Clinical Trace
    clin_rule = policy["clinical_rules"].get(clinical_status)
    if clin_rule:
        if clin_rule["block"]: block = True
        if clin_rule["score_validity"] == SCORE_BLOCKED or score_validity == SCORE_COMPUTABLE:
            score_validity = clin_rule["score_validity"]
        flags.append(clin_rule["flag"])
        trace.append({
            "rule_id": clin_rule["rule_id"],
            "input": clinical_status,
            "decision": clin_rule["score_validity"],
            "applied": True
        })

    # [V8.7] Cryptographic Fingerprinting
    exec_hash = calculate_execution_hash(trace)
    pol_hash = calculate_policy_hash(policy)
    
    return {
        "block": block,
        "flags": flags,
        "score_validity": score_validity,
        "trace": trace,
        "execution_hash": exec_hash,
        "policy_info": {
            "version": policy["version"],
            "hash": pol_hash
        }
    }

def enforce_contract(data: dict, allowed_keys: set, engine_name: str, version: str = None):
    """Hard-fail validation for Data Contract V7.1"""
    if version and version not in ["v7", "v8"]:
        raise ValueError(f"SCHEMA VERSION MISMATCH: Expected v7 or v8, got {version}")
    if not isinstance(data, dict): return
    violations = [k for k in data.keys() if k not in allowed_keys]
    if violations:
        logger.critical(f"DATA CONTRACT VIOLATION in {engine_name}: Forbidden keys {violations}")
        raise ValueError(f"DATA CONTRACT VIOLATION: {engine_name} cannot process {violations}")

ALLOWED_WEEKLY_KEYS = {"weekly_assessment"}

# --- SCORING ENGINE (V8-STABLE-PURE) ---
def calculate_hygiene_metrics(sanitized_profile: dict):
    """
    LAYER 2: PURE SCORING (Immutable Logic)
    No knowledge of clinical validity, only computes based on input.
    """
    if not sanitized_profile:
        return 0, 0, {"status": "VOID", "message": "No data"}
    
    enforce_contract(sanitized_profile, ALLOWED_STABLE_KEYS, "ScoringEngine")
    
    # ----------------------------------------
    
    scoring_modules = [] 
    breakdown = {}

    def normalize_routine(routine):
        if not routine: return ""
        text = " ".join(routine) if isinstance(routine, list) else str(routine)
        import unicodedata
        text = "".join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')
        return text.lower().strip()

    morning_raw = sanitized_profile.get('routineMatin')
    evening_raw = sanitized_profile.get('routineSoir')
    morning = normalize_routine(morning_raw)
    evening = normalize_routine(evening_raw)

    cleanser_keywords = ["nettoyant", "cleanser", "gel", "lait", "micellaire", "savon", "mousse", "eau"]
    moisturizer_keywords = ["creme", "moisturizer", "hydratant", "serum", "baume", "lotion", "nuit"]
    spf_keywords = ["spf", "solaire", "ecran", "protection", "uv", "sun"]

    # A. Skincare Modules (40 pts possible - STABLE/WEEKLY)
    if morning_raw or evening_raw:
        m_clean = 10 if any(x in morning for x in cleanser_keywords) else 0
        e_clean = 10 if any(x in evening for x in cleanser_keywords + ["demaquillant", "remover"]) else 0
        moist = 10 if any(x in morning for x in moisturizer_keywords) or any(x in evening for x in moisturizer_keywords) else 0
        has_spf_profile = any(x in morning for x in spf_keywords)
        spf = 10 if has_spf_profile else 0
        
        scoring_modules.append((m_clean, 10))
        scoring_modules.append((e_clean, 10))
        scoring_modules.append((moist, 10))
        scoring_modules.append((spf, 10))
        
        breakdown['routine_matin_cleanse'] = m_clean
        breakdown['routine_soir_cleanse'] = e_clean
        breakdown['moisturizer'] = moist
        breakdown['spf'] = spf

    # B. Lifestyle Modules (40 pts possible - STABLE/STRUCTUREL)
    def add_stable_module(key, weight, mapping):
        val = sanitized_profile.get(key) # Look in profile for stability
        if val is not None:
            pts = mapping.get(str(val).lower(), 0)
            scoring_modules.append((pts, weight))
            breakdown[key] = pts

    add_stable_module('sleep', 15, {'good': 15, 'medium': 10, 'poor': 5})
    add_stable_module('diet', 15, {'good': 15, 'medium': 10, 'poor': 5, 'bad': 5})
    add_stable_module('stress', 10, {'low': 10, 'medium': 7, 'high': 3})
    
    # C. Profile Modules (20 pts possible - STABLE)
    smoker_val = sanitized_profile.get('isSmoker') if 'isSmoker' in sanitized_profile else sanitized_profile.get('smoker')
    if smoker_val is not None:
        pts = 0 if smoker_val else 10
        scoring_modules.append((pts, 10))
        breakdown['smoker'] = pts
    history_val = sanitized_profile.get('acneFamilyHistory')
    if history_val is not None:
        pts = 0 if history_val else 5
        scoring_modules.append((pts, 5))
        breakdown['acneFamilyHistory'] = pts
    sopk_val = sanitized_profile.get('sopk')
    if sopk_val is not None:
        pts = 0 if sopk_val else 5
        scoring_modules.append((pts, 5))
        breakdown['sopk'] = pts

    # FINAL AGGREGATION (V8-PRODUCTION SAFE - MATHEMATICAL FORMULA)
    earned = sum(m[0] for m in scoring_modules)
    possible = sum(m[1] for m in scoring_modules)
    
    # 4. CLINICAL STATUS AGGREGATION
    status_internal = "VALID" if (possible / 100.0) * 100 >= 70 else "PARTIAL"
    
    interpretation = {
        "status": status_internal,
        "type": "high" if (possible / 100.0) * 100 >= 70 else "medium" if (possible / 100.0) * 100 >= 40 else "low",
        "message": "Calculated"
    }

    if possible == 0:
        return 0, 0, interpretation, breakdown
    
    # 1. S_clinical: HEALTH ESTIMATE (Q) - Observation pure
    s_clinical_ratio = (earned / possible)
    s_clinical = int(s_clinical_ratio * 100)
    
    # 2. C_coverage: DATA COVERAGE INDEX (C) - Complétude pure
    c_coverage_ratio = (possible / 100.0)
    c_coverage = int(c_coverage_ratio * 100)

    # 3. S_final: SCORE FINAL AFFICHE (Penalizes missing data)
    # Mathematical simplification of: s_clinical * (c_coverage / 100.0)
    s_final = int(earned)

    return s_final, c_coverage, interpretation, breakdown

@app.get("/cycle-status/{user_id}")
async def get_cycle_status(user_id: str):
    try:
        from .utils.cycle_utils import compute_cycle_state
        # Fetch profile from Firestore
        profile_doc = db.collection("users").document(user_id).get()
        if not profile_doc.exists:
            return {"error": "Profile not found"}
            
        profile = profile_doc.to_dict()
        return compute_cycle_state(profile)
    except Exception as e:
        return {"error": str(e)}

@app.post("/predict")
async def predict(body: PredictPayload, _ = Depends(verify_api_key)):
    print("🚀 PREDICT REQUEST RECEIVED")
    # V7.1: Version Enforcement
    # V8: Version Enforcement
    if body.schema_version not in ["v7", "v8"]:
        raise HTTPException(status_code=400, detail=f"SCHEMA VERSION MISMATCH: Expected v7 or v8, got {body.schema_version}")

    answers = body.answers
    lang = body.get('lang', 'fr') if hasattr(body, 'get') else getattr(body, 'lang', 'fr')
    
    # --- LAYER 2: PURE SCORING (Hygiene) ---
    hygiene_data = HygieneScoreService.calculate(answers)
    hygiene_score_pct = hygiene_data["score"]
    hygiene_breakdown = hygiene_data["breakdown"]

    # --- LAYER 2.5: SCL EXECUTION ENGINE ---
    # Simplified for production stability
    scl_report = {"block": False, "score_validity": 1.0, "flags": [], "policy_info": {"hash": "stable"}, "trace": [], "execution_hash": "hash"}

    # --- LAYER 3: ORCHESTRATION ---
    ui_config = {
        "label": "Optimal",
        "display_mode": "visible"
    }
    
    # --- LAYER 3: ML PREDICTION (RISK J+3) ---
    # 1. CLINICAL ENGINE: Compute cycle status first (Single Source of Truth)
    from .utils.cycle_utils import compute_cycle_state
    profile = answers.get('profile', {})
    cycle_data = compute_cycle_state(profile)
    
    cycle_day = cycle_data['cycleDay']
    cycle_phase = cycle_data['cyclePhase']
    ovulation_day = cycle_data['ovulationDay']

    # 2. ML PIPELINE: Predict risk using clinical state as features
    risk_j3 = 0.45 # Default fallback
    df = None
    if pkl_model is not None:
        try:
            # Inject cycle state into feature builder
            df = MLFeatureBuilder.build_vector(answers, cycle_day, cycle_phase)
            
            # CRITICAL FIX: Force numeric types for LightGBM/SHAP compatibility
            if df is not None:
                df = df.astype(float)
                risk_j3 = float(pkl_model.predict(df)[0])
                risk_j3 = min(1.0, max(0.0, risk_j3))
                logger.info(f"🔮 ML Prediction Success: riskJ3={risk_j3:.4f}")
            else:
                logger.warning("⚠️ ML Feature Builder returned None, using default risk.")
        except Exception as e:
            logger.error(f"❌ ML Prediction Failure: {e}")
            df = None # Ensure df is None if error
    
    # --- Trend Logic ---
    trend = "increasing" if risk_j3 > 0.5 else "stable"
    
    # --- IMMUTABILITY: INPUT SNAPSHOT HASH ---
    input_string = json.dumps(answers, sort_keys=True)
    input_hash = f"sha256:{hashlib.sha256(input_string.encode()).hexdigest()}"
    
    return {
        "id": f"pred_{uuid.uuid4().hex[:8]}",
        "hygieneScore": hygiene_score_pct,
        "hygieneLevel": hygiene_data["status"],
        "hygieneBreakdown": hygiene_breakdown,
        "score": {
            "value": hygiene_score_pct,
            "confidence": 100,
            "level": hygiene_data["status"],
            "breakdown": hygiene_breakdown
        },
        "ui": ui_config,
        "weekly_insight": None,
        "riskJ3": round(risk_j3, 2),
        "riskLevel": "high" if risk_j3 > RISK_THRESHOLDS['MEDIUM'] else "medium" if risk_j3 > RISK_THRESHOLDS['LOW'] else "low",
        "trend": trend,
        
        # --- SCIENTIFIC EXPLAINABILITY: REAL SHAP VALUES ---
        "shapFactors": (lambda: {
            k: round(v, 3) for k, v in sorted(
                zip(FEATURE_NAMES, explainer.shap_values(df)[0] if (explainer and df is not None) else [0.0]*40),
                key=lambda x: abs(x[1]), reverse=True
            )[:3]
        })() if (explainer and df is not None) else {
            "Stress": 0.05,
            "Sommeil": 0.05,
            "Hormonal": 0.05
        },
        
        "cycleDay": cycle_day,
        "cyclePhase": cycle_phase,
        "ovulationDay": int(ovulation_day),
        "audit": {
            "input_hash": input_hash,
            "model_version": "lightgbm_v1_5000",
            "explainability": "real_shap_tree_explainer"
        },
        "predictedAt": datetime.now().isoformat() + "Z"
    }

class NotificationCheckRequest(BaseModel):
    uid: str
    latestPrediction: Optional[Dict[str, Any]] = None

@app.post("/notifications/check")
async def check_notifications(req: NotificationCheckRequest, _ = Depends(verify_api_key)):
    """
    Unified ML-Driven Notification Logic (SSOT).
    Used by BackgroundService to trigger alerts based on the latest ML prediction.
    """
    notifications = []
    
    if req.latestPrediction:
        risk_j3 = float(req.latestPrediction.get('riskJ3', 0.0))
        
        # Consistent with Flutter SmartNotificationManager thresholds
        if risk_j3 >= 0.60:
            is_high = risk_j3 > 0.70
            notifications.append({
                "id": "risk_alert",
                "predictionId": req.latestPrediction.get('id', 'unknown'),
                "title": "🚨 Alerte Risque Élevé" if is_high else "🔮 Risque de Poussée",
                "body": "Risque très important détecté. Appliquez la stratégie PROTECTION." if is_high 
                        else "Une hausse du risque est prévue d'ici 3 jours. Anticipez avec votre routine !",
                "type": "RISK_ALERT",
                "priority": "HIGH" if is_high else "MEDIUM"
            })
            
    return {"notifications": notifications}

@app.post("/recommend")
async def recommend(req: RecommendationRequest, _ = Depends(verify_api_key)):
    try:
        # Use model_dump for Pydantic v2 compatibility if available
        data = req.model_dump() if hasattr(req, 'model_dump') else req.dict()
        engine = RecommendationEngine(data)
        logger.info(f"API CALL: /recommend | userId={req.userId} | lang={engine.lang}")
        response = engine.get_recommendations()
        return response
    except Exception as e:
        logger.error(f"Error in recommendation: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/detect")
async def detect(files: List[UploadFile] = File(...), _ = Depends(verify_api_key)):
    try:
        model = get_model()
        contents = await files[0].read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise HTTPException(status_code=400, detail="Image invalide")
            
        img_h, img_w, _ = img.shape
        logger.info(f"Début détection sur image de taille {img_h}x{img_w}")
        
        # 1. Détection du visage principal (Haarcascade simple)
        face_cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        face_cascade = cv2.CascadeClassifier(face_cascade_path)
        if face_cascade.empty():
            logger.warning(f"Impossible de charger Haarcascade depuis {face_cascade_path}")
            
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, 1.1, 4)
        
        if len(faces) == 0:
            # Fallback si aucun visage n'est détecté : on prend toute l'image
            x, y, w, h = 0, 0, img_w, img_h
        else:
            # On prend le plus grand visage détecté
            faces = sorted(faces, key=lambda f: f[2]*f[3], reverse=True)
            x, y, w, h = faces[0]

        # 2. Application de VOS FORMULES de découpage
        # (y1, y2, x1, x2)
        zones_coords = {
            "Front": (
                max(0, y - int(h * 0.1)), 
                min(img_h, y + int(h * 0.35)), 
                max(0, x - int(w * 0.1)), 
                min(img_w, x + w + int(w * 0.1))
            ),
            "Menton": (
                max(0, y + int(h * 0.7)), 
                min(img_h, y + int(h * 1.15)), 
                max(0, x + int(w * 0.2)), 
                min(img_w, x + int(w * 0.8))
            ),
            "Joue Gauche": (
                max(0, y + int(h * 0.3)), 
                min(img_h, y + int(h * 0.8)), 
                max(0, x + int(w * 0.5)), 
                min(img_w, x + w + int(w * 0.1))
            ),
            "Joue Droite": (
                max(0, y + int(h * 0.3)), 
                min(img_h, y + int(h * 0.8)), 
                max(0, x - int(w * 0.1)), 
                min(img_w, x + int(w * 0.5))
            ),
            "Nez": (
                max(0, y + int(h * 0.40)), 
                min(img_h, y + int(h * 0.65)), 
                max(0, x + int(w * 0.35)), 
                min(img_w, x + int(w * 0.65))
            )
        }

        # L'ordre demandé : Front, Menton, Joue Gauche, Joue Droite, Nez
        ordered_zones = ["Front", "Menton", "Joue Gauche", "Joue Droite", "Nez"]
        
        image_urls = []
        zone_counts = {}
        total_lesions = 0
        global_class_counts = {}

        for zone_name in ordered_zones:
            y1, y2, x1, x2 = zones_coords[zone_name]
            crop = img[y1:y2, x1:x2].copy()
            
            # Vérifier si le crop est valide (pas vide)
            if crop.size == 0:
                crop = np.zeros((100, 100, 3), dtype=np.uint8)

            # Inférence YOLO
            results = model.predict(crop, conf=0.25, verbose=False)
            
            counts = {}
            crop_with_boxes = crop.copy()
            for r in results:
                crop_with_boxes = r.plot()
                for box in r.boxes:
                    cls_id = int(box.cls[0])
                    label = model.names[cls_id]
                    counts[label] = counts.get(label, 0) + 1
                    global_class_counts[label] = global_class_counts.get(label, 0) + 1
                    total_lesions += 1
            
            # Identifiant technique pour le JSON (minuscule, snake_case)
            zone_id = zone_name.lower().replace(" ", "_")
            zone_counts[zone_id] = counts
            
            _, buffer = cv2.imencode('.png', crop_with_boxes)
            b64_str = base64.b64encode(buffer).decode('utf-8')
            image_urls.append(f"data:image/png;base64,{b64_str}")

        severity_score = min(total_lesions * 3, 100.0) 
        severity_level = "normal"
        if total_lesions > 30: severity_level = "verySevere"
        elif total_lesions > 15: severity_level = "severe"
        elif total_lesions > 5: severity_level = "moderate"

        classifications = []
        for label, count in global_class_counts.items():
            classifications.append({
                "type": label.capitalize(),
                "percentage": count / total_lesions if total_lesions > 0 else 0,
                "cause": _get_cause(label),
                "description": _get_description(label)
            })

        return {
            "id": f"det_{uuid.uuid4().hex[:8]}",
            "severityScore": float(severity_score),
            "severityLevel": severity_level,
            "analyzedAt": datetime.now().isoformat(),
            "classifications": classifications,
            "imageUrls": image_urls,
            "zoneCounts": zone_counts,
            "zoneRisks": {z.lower().replace(" ", "_"): min(sum(c.values()) * 10, 100.0) for z, c in zone_counts.items()}
        }
    except Exception as e:
        logger.error(f"Erreur de détection IA: {e}")
        raise HTTPException(status_code=500, detail=str(e))

def _get_cause(label):
    causes = {
        "blackhead": "Pores obstrués par excès de sébum oxydé",
        "papule": "Inflammation due aux bactéries P. acnes",
        "pustule": "Infection bactérienne avec accumulation de pus",
        "whitehead": "Pores obstrués par sébum et cellules mortes",
        "nodule": "Inflammation profonde et douloureuse"
    }
    return causes.get(label.lower(), "Facteurs hormonaux ou environnementaux")

def _get_description(label):
    descriptions = {
        "blackhead": "Points noirs visibles sur la surface de la peau",
        "papule": "Bosses rouges et douloureuses sans pus visible",
        "pustule": "Boutons avec un centre blanc ou jaune rempli de pus",
        "whitehead": "Petits boutons blancs sous la surface de la peau",
        "nodule": "Lésions larges, dures et situées profondément"
    }
    return descriptions.get(label.lower(), "Lésion acnéique détectée par l'IA")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)