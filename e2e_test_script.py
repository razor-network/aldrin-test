
import os

def greet(name="World"):
    """Greets the user."""
    # A simple function
    message = f"Hello, {name}!"
    print(message)
    return message

def main():
    # Example usage
    greet("E2E Test")
    if os.path.exists(".env"):
        print(".env file found.")

if __name__ == "__main__":
    main()
