print("\n******* TODO LIST *******\n")
print("A simple python script for todo list\n")

def show_todo():
    todo_list = ['','Show list','Add to list','Update list','Remove from list']
    for a in range(1, len(todo_list)):
        print(f"[{a}] {todo_list[a]}")
    print("\n")
    return

def main():
    try:
        while True:
            show_todo()
            user_input = int(input("Enter a number for todo >> "))       

            """
            Todo:
                - execute the selected todo task
            """

            print("\n***\n")                  
    except:
        print("Please select from the todo list\n")


if __name__ == "__main__":
    main()