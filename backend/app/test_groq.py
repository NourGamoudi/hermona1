import os
from groq import Groq
from dotenv import load_dotenv

load_dotenv()
key = os.getenv("GROQ_API_KEY")
print(f"Testing key: {key[:10]}...")

try:
    client = Groq(api_key=key)
    chat_completion = client.chat.completions.create(
        messages=[{"role": "user", "content": "Hello"}],
        model="llama-3.3-70b-versatile",
        timeout=5.0
    )
    print("Success:", chat_completion.choices[0].message.content)
except Exception as e:
    print("Error:", e)
