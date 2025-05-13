#!/usr/bin/env python3

import requests
import sys
import time
import threading

OLLAMA_HOST = "http://localhost:11434"
MODEL_NAME = "SRE"  # Replace with your actual model name if different
PROMPT = "What is your Quest?"

class Spinner:
    def __init__(self, message="Processing...", done_message="Done!"):
        self.message = message
        self.done_message = done_message
        self.done = False

    def spinner_task(self):
        spinner_chars = "|/-\\"
        idx = 0
        sys.stdout.write(self.message + " ")
        sys.stdout.flush()
        while not self.done:
            sys.stdout.write(spinner_chars[idx % len(spinner_chars)])
            sys.stdout.flush()
            time.sleep(0.1)
            sys.stdout.write("\b")
            idx += 1

    def start(self):
        self.done = False
        self.thread = threading.Thread(target=self.spinner_task)
        self.thread.start()

    def stop(self):
        self.done = True
        self.thread.join()
        sys.stdout.write(f"\b{self.done_message}\n")
        sys.stdout.flush()

def query_ollama(model: str, prompt: str) -> str:
    url = f"{OLLAMA_HOST}/api/generate"
    headers = {"Content-Type": "application/json"}
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False  # Set to True if you want to handle streaming responses
    }

    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        result = response.json()
        return result.get("response", "No response field in result")
    except requests.exceptions.RequestException as e:
        return f"Request failed: {e}"
    except ValueError:
        return "Failed to decode JSON response"

if __name__ == "__main__":
    spinner = Spinner(f"Query: {PROMPT} (Model: {MODEL_NAME}, Host: {OLLAMA_HOST})\n", f"Response from Ollama:\n")
    spinner.start()
    answer = query_ollama(MODEL_NAME, PROMPT)
    spinner.stop()
    print(answer)

