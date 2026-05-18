import sys
import os

# Ensure backend dir is in path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from groq import Groq
from config import settings

def main():
    print("=" * 60)
    print(">>> CHECKING LIVE GROQ API RATE LIMITS & HEADERS <<<")
    print("=" * 60)

    if not settings.GROQ_API_KEY or settings.GROQ_API_KEY == "your_groq_key_here":
        print("[ERROR] Groq API key is not configured in backend/.env!")
        return

    try:
        print("[1/3] Instantiating Groq client...")
        client = Groq(api_key=settings.GROQ_API_KEY)

        print("[2/3] Querying Groq completion endpoint with raw response...")
        raw_completion = client.chat.completions.with_raw_response.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": "ping"}],
            temperature=0.1,
            max_tokens=10,
        )

        headers = raw_completion.headers
        completion = raw_completion.parse()

        print("[3/3] Live Rate Limit Analysis:\n")
        print(f"  Model Used:       {completion.model}")
        print(f"  System Message:   {completion.choices[0].message.content.strip()}")
        print("-" * 50)
        
        # Display rate limit headers
        rl_headers = {k: v for k, v in headers.items() if "ratelimit" in k.lower()}
        if rl_headers:
            for key, val in sorted(rl_headers.items()):
                print(f"  {key.upper():<35}: {val}")
        else:
            print("  No rate limit headers returned. Raw headers list:")
            for key, val in headers.items():
                print(f"    {key}: {val}")
                
        print("-" * 50)
        print("\n[SUCCESS] Groq API limits verified successfully!")

    except Exception as e:
        print(f"\n[FAILED] Error querying Groq API: {e}")

    print("=" * 60)

if __name__ == "__main__":
    main()
