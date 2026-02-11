import requests
import sys
import os
from dotenv import load_dotenv

# Grab the secret tokens from my .env file
load_dotenv()

def send_alert(message):
    """Function to push a notification to my Telegram bot."""
    
    # Getting my credentials from the environment variables
    bot_token = os.getenv("TELEGRAM_TOKEN")
    my_chat_id = os.getenv("TELEGRAM_CHAT_ID")

    # Safety check: make sure I didn't forget to set up the .env file
    if not bot_token or not my_chat_id:
        print("Config Error: Did you forget to add the tokens to your .env file?")
        return

    # Telegram API endpoint for sending messages
    telegram_url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    
    # Wrapping the message for the API
    data_payload = {
        "chat_id": my_chat_id, 
        "text": f"🚀 [Cybertech Lab]: {message}"
    }

    try:
        # Pushing the request to Telegram servers
        api_response = requests.post(telegram_url, data=data_payload, timeout=10)
        
        # Checking if the bot actually accepted the message
        if api_response.status_code != 200:
            print(f"Telegram API complained: {api_response.text}")
            
        api_response.raise_for_status()
        print("Notification sent! Check your phone.")
        
    except Exception as network_error:
        # Something went wrong (probably no internet or wrong token)
        print(f"Bummer! Failed to send the alert: {network_error}")

if __name__ == "__main__":
    # If I pass a message via CLI, use it; otherwise, send a placeholder
    cli_message = sys.argv[1] if len(sys.argv) > 1 else "No manual message provided."
    send_alert(cli_message)
