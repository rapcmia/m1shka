import random

print("\n******* GUESS THE NUMBER *******\n")
print("""
Think of a number from 1-10 then enter until it matches the randomized number by python
""")

python_number = random.randint(1,10)

def endless_prompt():
    while True:
        try:
            user_input = int(input("Enter a number >> "))   

            if user_input < python_number: 
                print("Low number, try again!\n")
            elif user_input > python_number:
                print("High number, try again!\n")
            else:
                print("Congratulation, you have the right number!\n")
                break
        except:
            print("Please only enter a whole number!\n")


if __name__ == "__main__":
    endless_prompt()


