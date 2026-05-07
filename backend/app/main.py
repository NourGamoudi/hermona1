import os
import uuid
import logging
from typing import List, Dict, Any, Optional

from datetime import datetime

from fastapi import FastAPI, UploadFile, File, HTTPException, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib
import pandas as pd
from dotenv import load_dotenv

from .services.recommendation_engine import RecommendationEngine

# --- Configuration ---
env_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(env_path)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("HermonaBackend")

app = FastAPI(title="Hermona AI Backend - Senior Architecture")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

HERMONA_API_KEY = os.getenv("HERMONA_API_KEY", "hermona_secret_2026")
async def verify_api_key(request: Request):
    api_key = request.headers.get("X-API-Key")
    if api_key != HERMONA_API_KEY: raise HTTPException(status_code=403, detail="Unauthorized")

# --- Model Loading ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_DIR = os.path.join(BASE_DIR, "model")
PKL_PATH = os.path.join(MODEL_DIR, "modele_hermona_v1.pkl")

try:
    pkl_model = joblib.load(PKL_PATH)
    logger.info("✅ ML Model Loaded")
except Exception as e:
    logger.error(f"❌ Error loading ML model: {e}")
    pkl_model = None

# --- MODELS ---

class PredictPayload(BaseModel):
    answers: Dict[str, Any]

class RecommendationRequest(BaseModel):
    userId: str
    severity: float
    zones: List[str]
    detectionId: Optional[str] = ""
    risk_today: Optional[float] = 0.0
    risk_j3: Optional[float] = 0.0
    top3_shap: Optional[List[str]] = []
    skin_type: Optional[str] = "mixte"
    allergies: Optional[List[str]] = []
    acne_treatment: Optional[str] = "aucun"
    hormonal_treatment: Optional[str] = "aucune"
    smoker: Optional[bool] = False
    alcohol: Optional[str] = "jamais"
    phase: Optional[str] = "folliculaire"
    stress: Optional[int] = 5
    sleep: Optional[float] = 7.0
    hydration: Optional[int] = 5
    diet: Optional[List[str]] = []
    symptoms: Optional[List[str]] = []
    hygiene_score: Optional[int] = 70

# --- ENDPOINTS ---

@app.post("/predict")
async def predict(body: PredictPayload, _ = Depends(verify_api_key)):
    answers = body.answers
    profile = answers.get('profile', {})
    
    # Defaults
    data = {
        'age': 25, 'pcos': 0, 'stress': 5, 'sommeil': 7, 'alimentation_impact': 0.5,
        'LH': 5.0, 'estradiol': 50.0, 'progesterone': 10.0, 'testosterone': 0.5,
        'jour_cycle': 14, 'soleil_heures': 1.0, 'protection_solaire': 1,
        'allergies': 0, 'antecedents_familiaux': 0, 'maquillage': 1,
        'hydratation_verres': 6, 'fumeur': 0, 'cigarettes': 0, 'imc': 22.0,
        'alcool_jamais': 1, 'alcool_occasionnel': 0, 'alcool_régulier': 0,
        'type_peau_acnéique': 0, 'type_peau_déshydratée': 0, 'type_peau_grasse': 0, 
        'type_peau_mixte': 1, 'type_peau_normale': 0, 'type_peau_seche': 0, 'type_peau_sensible': 0,
        'sport_1-2x/semaine': 1, 'sport_3-4x/semaine': 0, 'sport_jamais': 0,
        'lavage_1x/jour': 0, 'lavage_2x/jour': 1, 'lavage_3x/jour': 0, 'lavage_parfois': 0,
        'phase_folliculaire': 1, 'phase_luteale': 0, 'phase_menstruelle': 0, 'phase_ovulatoire': 0
    }

    # Simplified mapping
    if profile:
        data['age'] = int(profile.get('age', 25))
        if profile.get('sopk') in [True, 'oui']: data['pcos'] = 1
        if profile.get('isSmoker'): data['fumeur'] = 1
        
    hormonal = str(answers.get('hormonal_cycle', 'folliculaire')).lower()
    if 'luteale' in hormonal: data['phase_luteale'] = 1
    elif 'menstruelle' in hormonal: data['phase_menstruelle'] = 1

    risk_score = 0.35
    if pkl_model:
        try:
            df = pd.DataFrame([data])
            risk_score = float(pkl_model.predict_proba(df)[0][1]) if hasattr(pkl_model, 'predict_proba') else float(pkl_model.predict(df)[0])
        except: pass

    risk_j3 = min(1.0, risk_score + 0.1) if data.get('phase_luteale') == 1 else max(0.0, risk_score - 0.05)
    
    return {
        "id": f"pred_{uuid.uuid4().hex[:8]}",
        "riskScore": round(risk_score, 2),
        "riskJ3": round(risk_j3, 2),
        "riskLevel": "high" if risk_score > 0.6 else "medium" if risk_score > 0.35 else "low",
        "trend": "increasing" if risk_j3 > risk_score else "decreasing",
        "shapFactors": {"Hormones": 0.4, "Stress": 0.3, "Sommeil": 0.3},
        "hygieneScore": answers.get('hygieneScore', 70),
        "cycleDay": data['jour_cycle'],
        "cyclePhase": hormonal,
        "predictedAt": datetime.now().isoformat() + "Z"
    }

@app.post("/recommend")
async def recommend(req: RecommendationRequest, _ = Depends(verify_api_key)):
    try:
        engine = RecommendationEngine(req.dict())
        response = engine.get_recommendations()
        return response
    except Exception as e:
        logger.error(f"Error in recommendation: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/detect")
async def detect(files: List[UploadFile] = File(...), _ = Depends(verify_api_key)):
    return {"id": f"det_{uuid.uuid4().hex[:8]}", "severityScore": 45.0, "severityLevel": "moderate", "analyzedAt": datetime.now().isoformat()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)