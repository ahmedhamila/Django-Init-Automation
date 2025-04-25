#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 app_name model1:field1,field2 [model2:field1,field2,field3 ...]"
    echo "Example: $0 blog Post:title,content,author Comment:content,author,post"
    exit 1
}

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    usage
fi

# Set project name and extract app name
PROJECT_DIR="Django-Init-Automation"
APP_NAME="$1"
shift

# Process models and their fields
MODELS_DATA=""
for model_arg in "$@"; do
    # Split by colon to separate model name and fields
    IFS=':' read -r model_name fields <<< "$model_arg"
    
    if [ -z "$model_name" ] || [ -z "$fields" ]; then
        echo "Error: Invalid model format. Use model_name:field1,field2,..."
        usage
    fi
    
    # Add to MODELS_DATA with a semicolon separator between models
    if [ -z "$MODELS_DATA" ]; then
        MODELS_DATA="${model_name}:${fields}"
    else
        MODELS_DATA="${MODELS_DATA};${model_name}:${fields}"
    fi
done

# Step 1: Clone the repository if not exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Cloning Django project template..."
    git clone https://github.com/ahmedhamila/Django-Init-Automation.git
fi

# Step 2: Navigate into project
cd $PROJECT_DIR

# Step 3: Copy .env.example to .env if it doesn't exist
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    
    # Update .env with app and model information
    printf "\nAPP_NAME=%s\n" "$APP_NAME" >> .env
    printf "MODELS_DATA=\"%s\"\n" "$MODELS_DATA" >> .env
fi

# Step 4: Start Docker Compose (Postgres + Django)
echo "Starting Docker containers..."
docker-compose up -d --build 

echo "Django app '$APP_NAME' with models is being created..."
echo "Access your project at http://localhost:8000"