#!/bin/bash

# Flask App Boilerplate Generator
# Usage: ./create_flask_app.sh <app_name>

set -e  # Exit on any error

# Check if app name is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <app_name>"
    echo "Example: $0 my-flask-app"
    exit 1
fi

APP_NAME="$1"

# Validate app name (basic validation)
if [[ ! "$APP_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: App name should only contain letters, numbers, hyphens, and underscores"
    exit 1
fi

# Check if directory already exists
if [ -d "$APP_NAME" ]; then
    echo "Error: Directory '$APP_NAME' already exists"
    exit 1
fi

echo "Creating Flask app boilerplate: $APP_NAME"

# Create main directory
mkdir -p "$APP_NAME"
cd "$APP_NAME"

# Create directory structure
mkdir -p src/config
mkdir -p src/secrets
mkdir -p deploy

echo "📁 Created directory structure"

# Create src/__init__.py
cat > src/__init__.py << 'EOF'
"""Main application module."""

import os
import json
from flask import Flask, jsonify


def load_config(path: str, instance_id: str) -> dict:
    """load instance specific section from `path`
    or use `default` if not found
    """
    with open(path, encoding="utf8") as file:
        configs = json.load(file)
        return configs.get(instance_id) or configs[next(iter(configs))]


def get_project_id(service_account_path: str) -> str:
    """Get the GCP project ID from service account or environment variable."""
    project_id = None
    if os.path.exists(service_account_path):
        try:
            with open(service_account_path, "r", encoding="utf8") as f:
                service_account_info = json.load(f)
                project_id = service_account_info.get("project_id")
        except Exception as e:  # pylint: disable=broad-except
            print(f"Warning: Could not read service account file: {e}")
    return os.environ.get("PROJECT_ID", project_id or "minute-dev")


def load_instance_config(config_path: str, project_id: str) -> dict:
    """Load instance-specific config from file."""
    if not os.path.exists(config_path):
        print(f"Warning: Config file not found at {config_path}")
        return {}
    try:
        return load_config(path=config_path, instance_id=project_id)
    except Exception as e:  # pylint: disable=broad-except
        print(f"Warning: Could not load config from {config_path}: {e}")
        return {}


def configure_app(app: Flask):
    """Load configuration and apply it to the Flask app."""

    base_dir = os.path.dirname(__file__)
    service_account_path = os.path.join(base_dir, "secrets/service_account_key.json")
    config_path = os.path.join(base_dir, "config/config.json")

    project_id = get_project_id(service_account_path)
    loaded_config = load_instance_config(config_path, project_id)
    app.config.update(loaded_config)


def register_blueprints_and_routes(app: Flask):
    """Register blueprints and define routes for the Flask app."""

    @app.route("/", methods=["GET", "POST"])
    def index():
        """Root endpoint."""
        return jsonify({"message": "App is up and running."}), 200

    @app.route("/health", methods=["GET"])
    def health():
        """Health check endpoint."""
        return jsonify({"status": "healthy"}), 200


def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)

    configure_app(app)

    register_blueprints_and_routes(app)

    return app
EOF

echo "✅ Created src/__init__.py"

# Create run.py
cat > run.py << 'EOF'
"""Main entry point for the Flask application."""

import os
from src import create_app

if __name__ == "__main__":
    app = create_app()
    
    debug_mode = os.environ.get("FLASK_DEBUG", "False").lower() == "true"
    port = int(os.environ.get("PORT", 8080))
    
    app.run(
        debug=debug_mode,
        host="0.0.0.0",
        port=port
    )
EOF

echo "✅ Created run.py"

# Create requirements.txt
cat > requirements.txt << 'EOF'
blinker==1.9.0
click==8.1.7
Flask==3.1.1
gunicorn==23.0.0
itsdangerous==2.2.0
Jinja2==3.1.4
MarkupSafe==3.0.2
packaging==24.2
Werkzeug==3.1.3
EOF

echo "✅ Created requirements.txt"

# Create gunicorn.conf.py
cat > gunicorn.conf.py << 'EOF'
"""Gunicorn WSGI server configuration."""

import os

# Server socket
bind = f"0.0.0.0:{os.environ.get('PORT', 8080)}"
backlog = 2048

# Worker processes
workers = int(os.environ.get("GUNICORN_WORKERS", 1))
worker_class = "sync"
worker_connections = 1000
timeout = int(os.environ.get("GUNICORN_TIMEOUT", 30))
keepalive = 2

# Restart workers after this many requests, to help control memory usage
max_requests = 1000
max_requests_jitter = 50

# Logging
accesslog = "-"
errorlog = "-"
loglevel = os.environ.get("GUNICORN_LOG_LEVEL", "info")

# Process naming
proc_name = "gunicorn"

# Worker timeouts
timeout = 30
graceful_timeout = 30

# SSL (if needed)
# keyfile = None
# certfile = None

# Threading
threads = int(os.environ.get("GUNICORN_THREADS", 2))

# Pre-load app for better memory usage
preload_app = True
EOF

echo "✅ Created gunicorn.conf.py"

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Create a non-root user
RUN useradd --create-home --shell /bin/bash app
RUN chown -R app:app /app
USER app

# Expose port
EXPOSE 8080

# Command to run the application
CMD ["gunicorn", "--config", "gunicorn.conf.py", "run:app"]
EOF

echo "✅ Created Dockerfile"

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    build: .
    ports:
      - "8080:8080"
    environment:
      - FLASK_ENV=development
      - FLASK_DEBUG=true
      - PORT=8080
    volumes:
      - ./src:/app/src
      - ./src/secrets:/app/src/secrets
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

echo "✅ Created docker-compose.yml"

# Create Makefile
cat > Makefile << 'EOF'
.PHONY: build up down logs shell clean restart status help

# Default target
help:
	@echo "Available commands:"
	@echo "  build    - Build the Docker image"
	@echo "  up       - Start the application"
	@echo "  down     - Stop the application"
	@echo "  logs     - Show application logs"
	@echo "  shell    - Open a shell in the container"
	@echo "  clean    - Remove containers and images"
	@echo "  restart  - Restart the application"
	@echo "  status   - Show container status"

build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

shell:
	docker-compose exec web /bin/bash

clean:
	docker-compose down -v --rmi all --remove-orphans

restart: down up

status:
	docker-compose ps
EOF

echo "✅ Created Makefile"

# Create .gitignore
cat > .gitignore << 'EOF'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
pip-wheel-metadata/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
target/

# Jupyter Notebook
.ipynb_checkpoints

# IPython
profile_default/
ipython_config.py

# pyenv
.python-version

# pipenv
Pipfile.lock

# PEP 582
__pypackages__/

# Celery stuff
celerybeat-schedule
celerybeat.pid

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Project specific
src/secrets/service_account_key.json
*.log
.env.local
.env.production
EOF

echo "✅ Created .gitignore"

# Create .flake8
cat > .flake8 << 'EOF'
[flake8]
max-line-length = 88
extend-ignore = E203, E231, E501, W503, W504, W605
EOF

echo "✅ Created .flake8"

# Create .pylintrc
cat > .pylintrc << 'EOF'
[MASTER]
jobs=0

[MESSAGES CONTROL]
disable=
    E0401,  # import-error
    W0511,  # fixme
    C0301,  # line-too-long
    R0914,  # too-many-locals
    R1702,  # too-many-nested-blocks

[FORMAT]
max-line-length=88
EOF

echo "✅ Created .pylintrc"

# Create empty config.json
cat > src/config/config.json << 'EOF'
{
    "default": {
        "DEBUG": false,
        "TESTING": false
    },
    "minute-dev": {
        "DEBUG": true,
        "TESTING": false
    }
}
EOF

echo "✅ Created src/config/config.json"

# Create .env.template
cat > .env.template << 'EOF'
# Flask Configuration
FLASK_DEBUG=true
FLASK_ENV=development
PORT=8080

# GCP Configuration
PROJECT_ID=your-project-id

# Gunicorn Configuration
GUNICORN_WORKERS=1
GUNICORN_THREADS=2
GUNICORN_TIMEOUT=30
GUNICORN_LOG_LEVEL=info
EOF

echo "✅ Created .env.template"

# Create README.md
cat > README.md << EOF
# $APP_NAME

A Flask application with modern deployment setup.

## Features

- Flask application with factory pattern
- GCP integration ready
- Docker and docker-compose setup
- Gunicorn production server configuration
- Code quality tools (flake8, pylint)
- Health check endpoint

## Quick Start

### Local Development

1. Create virtual environment:
   \`\`\`bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\\Scripts\\activate
   \`\`\`

2. Install dependencies:
   \`\`\`bash
   pip install -r requirements.txt
   \`\`\`

3. Run the application:
   \`\`\`bash
   python run.py
   \`\`\`

### Docker Development

1. Build and start:
   \`\`\`bash
   make build
   make up
   \`\`\`

2. View logs:
   \`\`\`bash
   make logs
   \`\`\`

3. Stop:
   \`\`\`bash
   make down
   \`\`\`

## Available Endpoints

- \`GET /\` - Root endpoint
- \`GET /health\` - Health check endpoint

## Configuration

- Copy \`.env.template\` to \`.env\` and adjust values
- Modify \`src/config/config.json\` for environment-specific settings
- Add GCP service account key to \`src/secrets/service_account_key.json\` if needed

## Project Structure

\`\`\`
$APP_NAME/
├── src/
│   ├── __init__.py          # Main Flask application
│   ├── config/
│   │   └── config.json      # Configuration file
│   └── secrets/
│       └── service_account_key.json  # GCP service account (not in git)
├── deploy/                  # Deployment files
├── run.py                   # Application entry point
├── requirements.txt         # Python dependencies
├── gunicorn.conf.py        # Gunicorn configuration
├── Dockerfile              # Docker image definition
├── docker-compose.yml      # Docker compose setup
├── Makefile                # Convenience commands
├── .gitignore              # Git ignore rules
├── .flake8                 # Code style configuration
├── .pylintrc               # Code quality configuration
└── README.md               # This file
\`\`\`

## Development

### Code Quality

Run linting:
\`\`\`bash
flake8 src/
pylint src/
\`\`\`

### Testing

Add your tests in a \`tests/\` directory and run with:
\`\`\`bash
python -m pytest
\`\`\`
EOF

echo "✅ Created README.md"

# Create a placeholder service account file structure
cat > src/secrets/.gitkeep << 'EOF'
# This file keeps the secrets directory in git
# Add your service_account_key.json here (it will be ignored by git)
EOF

echo "✅ Created src/secrets/.gitkeep"

# Create deploy directory placeholder
cat > deploy/.gitkeep << 'EOF'
# This directory is for deployment-related files
EOF

echo "✅ Created deploy/.gitkeep"

# Make the script executable if it was created
echo ""
echo "🎉 Flask app '$APP_NAME' created successfully!"
echo ""
echo "Next steps:"
echo "1. cd $APP_NAME"
echo "2. python -m venv venv"
echo "3. source venv/bin/activate"
echo "4. pip install -r requirements.txt"
echo "5. python run.py"
echo ""
echo "Or use Docker:"
echo "1. cd $APP_NAME"
echo "2. make build"
echo "3. make up"
echo ""
echo "Your app will be available at: http://localhost:8080"
