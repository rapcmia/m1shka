print("\n******* TODO LIST *******\n")
print("A simple python script for todo list\n")

todo_list = ['','Show list','Add to list','Update list','Remove from list']

def show_todo():
    # displays the todo list

    for a in range(1, len(todo_list)):
        print(f"[{a}] {todo_list[a]}")
    print("\n")
    return

def main():
    try:    
        while True:
            show_todo()
            user_input = int(input("Enter a number for todo >> "))    

            if user_input == 1:
                pass
            elif user_input == 2:
                pass
            elif user_input == 3:
                pass
            elif user_input == 4:
                pass
            else:
                print("Please only select from the todo list\n")
                return
                            
            """
            Todo:
                - execute the selected todo task
            """

            print("\n***\n")                  
    except ValueError:  # Specifically handle invalid integer input
        print("Please only select from the todo list\n")



if __name__ == "__main__":
    main()