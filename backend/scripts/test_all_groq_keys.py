import sys
import os
import re

# Ensure backend dir is in path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from groq import Groq

def parse_keys():
    env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env")
    keys = {}
    if not os.path.exists(env_path):
        print(f"[ERROR] .env file not found at {env_path}")
        return keys

    with open(env_path, "r") as f:
        content = f.read()

    # Regex search for all Groq keys (active or in comments)
    pattern = r"(?:#\s*)?(gsk_[a-zA-Z0-9_]+)\s*(\w+)??"
    matches = re.findall(pattern, content)
    
    # Custom parse for labeled lines
    for line in content.splitlines():
        line = line.strip()
        if "GROQ_API_KEY=" in line and not line.startswith("#"):
            key = line.split("GROQ_API_KEY=")[1].split("#")[0].strip()
            keys["Active (Sana's key)"] = key
        elif "my API key" in line:
            key = line.replace("#", "").replace("my API key", "").strip()
            keys["Your personal key"] = key
        elif "Adil" in line:
            key = line.replace("#", "").replace("Adil", "").strip()
            keys["Adil's key"] = key
            
    return keys

def check_key_limits(label, key):
    print(f"\nTesting: {label}...")
    print(f"  Key snippet: {key[:8]}...{key[-8:]}")
    
    try:
        client = Groq(api_key=key)
        raw_completion = client.chat.completions.with_raw_response.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": "ping"}],
            temperature=0.1,
            max_tokens=10,
        )
        
        headers = raw_completion.headers
        completion = raw_completion.parse()
        
        print("  [SUCCESS] Key is active and working!")
        print("  " + "-" * 50)
        
        # Display rate limit headers
        rl_headers = {k: v for k, v in headers.items() if "ratelimit" in k.lower()}
        if rl_headers:
            for key_name, val in sorted(rl_headers.items()):
                # Format headers beautifully
                name = key_name.upper().replace("X-RATELIMIT-", "")
                print(f"    {name:<25}: {val}")
        else:
            print("    No rate limit headers returned by API.")
        print("  " + "-" * 50)
        return True
    except Exception as e:
        err_msg = str(e)
        if "organization_restricted" in err_msg:
            print("  [RESTRICTED] Groq has restricted/blocked this account.")
        elif "authentication" in err_msg or "invalid" in err_msg:
            print("  [INVALID] Invalid API key format or expired credential.")
        else:
            print(f"  [FAILED] Connection or API error: {err_msg}")
        return False

def main():
    print("=" * 60)
    print(">>> AUDITING ALL GROQ API KEYS & TOKEN LIMITS <<<")
    print("=" * 60)
    
    keys = parse_keys()
    if not keys:
        print("[ERROR] No Groq keys parsed from .env.")
        return
        
    print(f"Parsed {len(keys)} keys from your .env file.")
    
    working_key_label = None
    working_key_val = None
    
    for label, key in keys.items():
        is_working = check_key_limits(label, key)
        if is_working and not working_key_val:
            working_key_label = label
            working_key_val = key
            
    print("=" * 60)
    if working_key_val:
        print(f"[RECOMMENDATION] Use '{working_key_label}' as your active key!")
        print("To switch, simply set GROQ_API_KEY to this key inside backend/.env.")
    else:
        print("[WARNING] All keys in .env are restricted or inactive. We recommend creating a new Gemini key.")
    print("=" * 60)

if __name__ == "__main__":
    main()
