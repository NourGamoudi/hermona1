import requests
import json

# Sample data for prediction
sample_answers = {
    "profile": {
        "age": 25,
        "imc": 22.0,
        "skinType": "mixte",
        "sopk": False,
        "acneFamilyHistory": False,
        "smoker": False,
        "alcohol": "jamais"
    },
    "weekly": {
        "makeupFrequency": "jamais",
        "cleansingFrequency": "2x/jour",
        "spfThisWeek": "toujours"
    },
    "hormonal_cycle": "folliculaire",
    "diet": "good",
    "stress": "medium",
    "sleep": "good"
}

url = "http://localhost:8000/predict"
headers = {"Content-Type": "application/json"}

try:
    response = requests.post(url, data=json.dumps({"answers": sample_answers}), headers=headers)
    print("Status Code:", response.status_code)
    print("Response:", response.json())
except Exception as e:
    print("Error:", e)