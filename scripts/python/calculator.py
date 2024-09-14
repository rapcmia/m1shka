import re

print("\n******* CALCULATOR *******\n")
print("""
    + for addition \n
    - for substraction \n
    / for divistion \n
    * for multiplication \n
            """)
user_input = input("Enter numbers here separated with a operator >> ")
error_log = ""

# look for the operator on the user_input to use on the two numbers 
operator = ['+','-','/','*']
found_operator = None
for op in operator:
    if op in user_input:
        found_operator = op
        break
if found_operator is None:
    error_log += "\nPlease use correct operators!"

""" 
- split then map the strings into integer
- This regular expression pattern captures both integers and decimals:
    -?: Matches an optional minus sign for negative numbers.
    \d*: Matches zero or more digits before the decimal point.
    \.?: Matches an optional decimal point.
    \d+: Matches one or more digits after the decimal point.
- map converts user_input from string to float
"""
numbers = list(map(float, re.findall(r'-?\d*\.?\d+', user_input)))

if len(numbers) == 2:
    num1,num2 = numbers
else:
    error_log += "\nPlease enter exactly two numbers only!"


# display result 
if error_log == "":
    if found_operator == '+':
        result = num1+num2
    elif found_operator == '-':
        result = num1-num2
    elif found_operator == "*":
        result = num1*num2
    else:
        result = num1/num2
    print(f"The result is {result}\n")
else:
    print(error_log)

