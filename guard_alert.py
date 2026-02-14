import requests
import sys
import os
from dotenv import load_dotenv

# Load credentials from .env file
load_dotenv()

def send_alert(message):
    """Sends a notification to the configured Telegram bot."""
    
    # Retrieve tokens from environment variables
    token = os.getenv("TELEGRAM_TOKEN")
    chat_id = os.getenv("TELEGRAM_CHAT_ID")

    # Safety check: ensure credentials are not missing
    if not token or not chat_id:
        print("Config Error: Ensure TELEGRAM_TOKEN and TELEGRAM_CHAT_ID are set in .env")
        return

    # Telegram API URL
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    
    # Prepare payload with the Sentinel identifier
    payload = {
        "chat_id": chat_id, 
        "text": f"🛡️ [Sentinel]: {message}"
    }

    try:
        # Post request to Telegram servers
        response = requests.post(url, data=payload, timeout=10)
        
        # Check if the message was successfully delivered
        if response.status_code == 200:
            print("Alert sent!")
        else:
            print(f"Telegram API Error: {response.text}")
            
    except Exception as error:
        # Handle network or configuration issues
        print(f"Error: Failed to send notification: {error}")

if __name__ == "__main__":
    # Use CLI argument as message or fallback to default
    user_msg = sys.argv[1] if len(sys.argv) > 1 else "System initialized."
    send_alert(user_msg)
