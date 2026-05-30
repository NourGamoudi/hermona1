import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.main import db

posts = db.collection('forum_posts').limit(5).get()
print("POSTS:")
for p in posts:
    data = p.to_dict()
    print(f"Post {p.id}: authorId={data.get('authorId')}")

profiles = db.collection('public_profiles').limit(5).get()
print("\nPUBLIC PROFILES:")
for p in profiles:
    data = p.to_dict()
    print(f"Profile {p.id}: {data}")
