#!/bin/bash
PS3="Select an option "
mkdir -p myDB
mkdir -p scripts
select item in "Create Database" "List Database" "Connect to Database" "Drop Database" "Exit"
do
case $REPLY in 
1)  # Create Database
            ./scripts/createDB
        ;;

        2)  # List Database
            ./scripts/listDB
        ;;

        3)  # Connect
            ./scripts/connectDB
        ;;

        4)  # Drop Database
            ./scripts/dropDB
        ;;

        5)
            echo "Goodbye!"
            exit
        ;;

        *)
            echo "Invalid option!"
        ;;

    esac
done
