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
headers = {
    "Content-Type": "application/json",
    "X-API-Key": "hermona_secret_2026"
}

try:
    response = requests.post(url, data=json.dumps({"answers": sample_answers}), headers=headers)
    print("Status Code:", response.status_code)
    if response.status_code == 200:
        print("Response:", json.dumps(response.json(), indent=2))
    else:
        print("Error Response:", response.text)
except Exception as e:
    print("Error:", e)