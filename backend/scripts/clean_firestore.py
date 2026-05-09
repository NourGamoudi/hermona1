import firebase_admin
from firebase_admin import credentials, firestore

# 1. INITIALIZATION
try:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
except:
    firebase_admin.initialize_app()

db = firestore.client()

def clean_collection(collection_name):
    print(f"\n--- Cleaning {collection_name} ---")

    docs = db.collection(collection_name).stream()

    batch = db.batch()
    batch_count = 0
    total_cleaned = 0

    for doc in docs:
        print(f"Processing {doc.id}")
        data = doc.to_dict()
        updates = {}

        # 🔥 REMOVE BASE64 IMAGES
        for key in ["imageUrls", "images", "media"]:
            if key in data:
                val = data[key]
                if isinstance(val, list) and any("data:image" in str(v) for v in val):
                    updates[key] = []
                elif isinstance(val, str) and "data:image" in val:
                    updates[key] = ""

        # 🔥 REMOVE VERY HEAVY STRINGS
        for k, v in data.items():
            if isinstance(v, str) and len(v) > 100000:
                updates[k] = firestore.DELETE_FIELD

        # APPLY UPDATE ONLY IF NEEDED
        if updates:
            doc_ref = db.collection(collection_name).document(doc.id)
            batch.update(doc_ref, updates)
            batch_count += 1
            total_cleaned += 1

        # Commit batch every 400 ops (Firestore limit safe)
        if batch_count == 400:
            batch.commit()
            batch = db.batch()
            batch_count = 0

    if batch_count > 0:
        batch.commit()

    print(f"✔ Cleaned {total_cleaned} documents in {collection_name}")


if __name__ == "__main__":
    collections = [
        "detections",
        "predictions",
        "weekly_surveys",
        "daily_surveys",
        "analysis_history",
        "chat_history"
    ]

    for col in collections:
        try:
            clean_collection(col)
        except Exception as e:
            print(f"❌ Error in {col}: {e}")

    print("\n🔥 DONE: Firestore is now metadata-only")
