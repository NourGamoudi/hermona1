import requests

url = "http://localhost:8000/cycle-status/Z29k1aS79lSv1QJkXJBDr82F1s02"
headers = {"X-API-Key": "hermona_secret_2026"}

try:
    response = requests.get(url, headers=headers, timeout=5)
    print(f"Status: {response.status_code}")
    print(f"Body: {response.json()}")
except Exception as e:
    print(f"Error: {e}")
