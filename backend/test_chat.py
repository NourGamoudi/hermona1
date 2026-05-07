import requests
import json

url = "http://localhost:8000/chat"
headers = {"Content-Type": "application/json"}

payload = {
    "message": "Que dois-je faire pour ma peau aujourd'hui ?",
    "profile": {
        "pseudonym": "Sarah",
        "age": 28,
        "skinType": "grasse",
        "sopk": True,
        "acneTreatment": "Isocrétinoïne"
    },
    "daily": {
        "stress": 8,
        "sleepDuration": 5,
        "cyclePhase": "luteale",
        "symptoms": ["inflammation", "douleur"]
    },
    "weekly": {
        "makeupFrequency": "souvent",
        "cleansingFrequency": "1x/jour"
    },
    "prediction": {
        "riskScore": 0.85,
        "routine": ["Nettoyant doux", "Baume apaisant", "SPF 50+"],
        "shapFactors": {"Stress": 0.3, "Phase": 0.2, "Sommeil": 0.1}
    },
    "history": []
}

try:
    response = requests.post(url, data=json.dumps(payload), headers=headers)
    print("Status Code:", response.status_code)
    # Use ensure_ascii=True to avoid encoding issues with emojis in terminal
    print("Response JSON:", json.dumps(response.json(), indent=2, ensure_ascii=True))
except Exception as e:
    print("Error:", e)
