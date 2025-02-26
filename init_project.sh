#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 app_name model_name [field1 field2 field3 ...]"
    echo "Example: $0 blog Post title content author"
    exit 1
}

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    usage
fi

# Set project name and extract command line arguments
PROJECT_DIR="Django-Init-Automation"
APP_NAME="$1"
MODEL_NAME="$2"
shift 2
FIELDS=("$@")  # Remaining arguments are fields

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
    # Using printf to ensure newlines are properly added
    printf "\nAPP_NAME=%s\n" "$APP_NAME" >> .env
    printf "MODEL_NAME=%s\n" "$MODEL_NAME" >> .env
    printf "MODEL_FIELDS=\"%s\"\n" "${FIELDS[*]}" >> .env
fi

# Step 4: Start Docker Compose (Postgres + Django)
echo "Starting Docker containers..."
docker-compose up -d --build 

echo "Django app '$APP_NAME' with model '$MODEL_NAME' is being created..."
echo "Added fields: ${FIELDS[*]}"
echo "Access your project at http://localhost:8000"