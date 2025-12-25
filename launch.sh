#!/bin/bash

# Conferencer Launch Script

set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
echo "Checking for required tools..."
if ! command_exists docker; then
    echo "Error: docker is not installed."
    exit 1
fi
if ! command_exists npm; then
    echo "Error: npm is not installed."
    exit 1
fi
if ! command_exists python3; then
    echo "Error: python3 is not installed."
    exit 1
fi

# Check Docker permissions
if ! docker ps >/dev/null 2>&1; then
    echo "Error: Docker permission denied."
    echo "Please run this script with sudo or add your user to the docker group:"
    echo "  sudo ./launch.sh"
    exit 1
fi

# Start MongoDB container
echo "Starting MongoDB container..."
if [ ! "$(docker ps -q -f name=conferencer-mongo)" ]; then
    if [ "$(docker ps -aq -f name=conferencer-mongo)" ]; then
        echo "Restarting existing conferencer-mongo container..."
        docker start conferencer-mongo
    else
        echo "Creating and starting new conferencer-mongo container..."
        docker run -d --name conferencer-mongo -p 27017:27017 mongo:latest
    fi
else
    echo "MongoDB container is already running."
fi

# Setup and start Backend
echo "Setting up Backend..."
cd backend
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

echo "Installing backend dependencies..."
./venv/bin/pip install -r requirements.txt

echo "Starting Backend..."
# Run in background and save PID
./venv/bin/python3 app.py &
BACKEND_PID=$!
cd ..

# Setup and start Frontend
echo "Setting up Frontend..."
cd frontend
echo "Installing frontend dependencies..."
npm install

echo "Starting Frontend..."
echo "The application will be available at http://localhost:5173"
echo "Press Ctrl+C to stop the application."

# Trap SIGINT (Ctrl+C) to kill backend process
trap "kill $BACKEND_PID; exit" INT

npm run dev
