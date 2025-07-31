# Flask Boilerplate Generator

A bash script that generates a complete Flask application boilerplate with modern development and deployment setup.

## Features

- **Complete Flask Application Structure**: Factory pattern with proper organization
- **GCP Integration Ready**: Service account and project configuration support
- **Docker Support**: Dockerfile, docker-compose, and Makefile for easy containerization
- **Production Ready**: Gunicorn configuration for production deployment
- **Code Quality Tools**: Pre-configured flake8 and pylint settings
- **Health Check Endpoint**: Built-in health monitoring
- **Environment Configuration**: Template and JSON-based configuration management
- **Git Ready**: Comprehensive .gitignore and proper project structure

## Quick Start

### Prerequisites

- Bash shell (macOS/Linux)
- Python 3.12+ (for running the generated app)
- Docker (optional, for containerized development)

### Usage

1. Make the script executable:
   ```bash
   chmod +x create_flask_app.sh
   ```

2. Run the script with your app name:
   ```bash
   ./create_flask_app.sh my-awesome-app
   ```

3. Follow the generated instructions to start your app:
   ```bash
   cd my-awesome-app
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   python run.py
   ```

## Generated Project Structure

The script creates a complete Flask application with the following structure:

```
your-app-name/
├── src/
│   ├── __init__.py              # Main Flask application with factory pattern
│   ├── config/
│   │   └── config.json          # Environment-specific configuration
│   └── secrets/
│       ├── .gitkeep            # Placeholder for secrets directory
│       └── service_account_key.json  # GCP service account (not tracked)
├── deploy/
│   └── .gitkeep                # Deployment files directory
├── run.py                      # Application entry point
├── requirements.txt            # Python dependencies
├── gunicorn.conf.py           # Production server configuration
├── Dockerfile                 # Container image definition
├── docker-compose.yml         # Development container setup
├── Makefile                   # Development convenience commands
├── .env.template              # Environment variables template
├── .gitignore                 # Comprehensive git ignore rules
├── .flake8                    # Code style configuration
├── .pylintrc                  # Code quality configuration
└── README.md                  # Project documentation
```

## Generated Application Features

### Endpoints

The generated Flask app includes:
- `GET /` - Root endpoint returning status message
- `GET /health` - Health check endpoint for monitoring

### Configuration Management

- **Environment-based**: Supports multiple environments
- **GCP Integration**: Automatic project ID detection from service account
- **Flexible Config**: JSON-based configuration with fallback defaults

### Development Tools

- **Docker Support**: Ready-to-use containerization
- **Makefile Commands**: 
  - `make build` - Build Docker image
  - `make up` - Start application
  - `make down` - Stop application
  - `make logs` - View logs
  - `make shell` - Access container shell
  - `make clean` - Clean up containers and images
  - `make restart` - Restart application
  - `make status` - Show container status

### Production Ready

- **Gunicorn Configuration**: Optimized for production deployment
- **Health Checks**: Built-in monitoring endpoints
- **Security**: Non-root user in Docker container
- **Logging**: Proper logging configuration

## Script Validation

The generator includes several safety features:

- **App Name Validation**: Only allows alphanumeric characters, hyphens, and underscores
- **Directory Check**: Prevents overwriting existing directories
- **Error Handling**: Exits on any error with clear messages

## Environment Variables

The generated application supports these environment variables:

```bash
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
```

## Development Workflow

### Local Development
```bash
# Create and activate virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run development server
python run.py
```

### Docker Development
```bash
# Build and start
make build && make up

# View logs
make logs

# Access shell
make shell

# Stop
make down
```

## Examples

### Create a simple API project:
```bash
./create_flask_app.sh my-api
```

### Create a microservice:
```bash
./create_flask_app.sh user-service
```

### Create a web application:
```bash
./create_flask_app.sh my-web-app
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the script with different app names
5. Submit a pull request

## License

This project is open source and available under the MIT License.

## Support

If you encounter any issues or have questions:

1. Check that your app name follows the naming rules (alphanumeric, hyphens, underscores only)
2. Ensure the target directory doesn't already exist
3. Verify you have write permissions in the current directory
4. Make sure the script is executable (`chmod +x create_flask_app.sh`)

## Changelog

### Latest Version
- Complete Flask application generator
- GCP integration support
- Docker and docker-compose setup
- Production-ready Gunicorn configuration
- Code quality tools integration
- Comprehensive project documentation
