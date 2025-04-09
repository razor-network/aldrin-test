
import os

def greet(name="World"):
    """Greets the user."""
    # A simple function with an unused variable to trigger a line comment
    unused_var = 123 # This should trigger a line comment
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
