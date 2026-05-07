import os
from ultralytics import YOLO

# Déterminer le chemin vers le dossier backend/
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "model", "best.pt")

# Charger le modèle une seule fois 
acne_model = YOLO(MODEL_PATH)

def get_model():
    return acne_model
