#!/bin/bash

# Prompt the user for the Lambda function name
echo -e "\n=============================="
echo "Enter the name or part of the Lambda function name to search for:"
echo -e "==============================\n"
read -r lambda_name

# Check if the AWS CLI is installed
if ! command -v aws &> /dev/null
then
    echo -e "\n[ERROR] AWS CLI is not installed. Please install it and configure your credentials.\n"
    exit 1
fi

# Search for matching Lambda functions
matching_functions=$(aws lambda list-functions --query "Functions[?contains(FunctionName, \`$lambda_name\`)].FunctionName" --output text)

# Check if any matches were found
if [ -z "$matching_functions" ]; then
    echo -e "\n[INFO] No Lambda functions found matching '$lambda_name'.\n"
    exit 1
fi

# Format the output to display one Lambda function per line
formatted_functions=$(echo "$matching_functions" | tr '\t' '\n')

# Use fzf for interactive selection
if command -v fzf &> /dev/null; then
    echo -e "\n=============================="
    echo "Matching Lambda functions (use arrow keys to navigate and Enter to select):"
    echo -e "==============================\n"
    selected_function=$(echo "$formatted_functions" | fzf --height=20 --border --header="Lambda Functions")

    if [ -z "$selected_function" ]; then
        echo -e "\n[ERROR] No function selected. Exiting.\n"
        exit 1
    fi
    echo -e "\n[INFO] You selected: $selected_function\n"
else
    echo -e "\n[WARNING] fzf is not installed. Falling back to manual selection.\n"

    # Display a menu of matching functions
    echo -e "\n=============================="
    echo "Matching Lambda functions:"
    echo -e "==============================\n"
    IFS=$'\n' read -r -d '' -a functions_array <<< "$formatted_functions"

    for i in "${!functions_array[@]}"; do
        echo "$((i + 1)). ${functions_array[$i]}"
    done

    # Prompt the user to select a function
    echo -e "\n=============================="
    echo "Enter the number of the Lambda function you want to use:"
    echo -e "==============================\n"
    read -r selection

    # Validate the selection
    if [[ "$selection" -gt 0 && "$selection" -le "${#functions_array[@]}" ]]; then
        selected_function="${functions_array[$((selection - 1))]}"
        echo -e "\n[INFO] You selected: $selected_function\n"
    else
        echo -e "\n[ERROR] Invalid selection. Exiting.\n"
        exit 1
    fi
fi
