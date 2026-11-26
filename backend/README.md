# NITC Campus Bus Tracking System – Backend

A FastAPI-based REST API backend for the NIT Calicut Campus Bus Tracking System. The backend provides services for authentication, user management, bus management, route management, and related transportation operations.

## Features

- User registration and authentication
- Role-based access control
- Student, Staff, Driver, and Admin management
- Bus management
- Bus registration number management
- Route and stop management
- Route-stop ordering
- Departure offset management
- Bus location and ETA-related services

## Technology Stack

- Python
- FastAPI
- Uvicorn
- MySQL
- REST API
- JWT authentication, where configured

## Requirements

- Python
- MySQL Server
- Git

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/nitc-bus-tracking-backend.git
cd nitc-bus-tracking-backend
```

Create a virtual environment:

```bash
python -m venv venv
```

Activate it on Windows PowerShell:

```powershell
.\venv\Scripts\Activate.ps1
```

Install dependencies:

```bash
pip install -r requirements.txt
```

## Database Configuration

1. Install and start MySQL Server.
2. Create the project database.
3. Execute the database schema SQL file.
4. Load sample data if provided.
5. Configure the database connection in the backend settings.

Keep database passwords and other secrets in a local `.env` file. Never commit that file to GitHub.

## Run the Backend

For the project entry point previously used:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

If the application entry point differs, use the correct module path.

## API Documentation

After starting the backend, access:

Swagger UI:

```text
http://127.0.0.1:8000/docs
```

ReDoc:

```text
http://127.0.0.1:8000/redoc
```

## Frontend Integration

The Flutter frontend communicates with this backend through REST APIs.

For Android Emulator, the frontend should use:

```text
http://10.0.2.2:8000
```

## Project Structure

```text
nitc_bus_tracking/
  app/
  database/
  requirements.txt
  README.md
```

Update this structure to reflect the actual files in the repository.

## Security

- Never upload database passwords or API secrets.
- Do not commit `.env` files.
- Do not upload production database dumps or private user information.
- Use HTTPS and secure configuration for production deployment.

## Contributors

| S. No. | Name | Roll Number |
|---|---|---|
| 1 | Aasrith Raj | M260774CS |
| 2 | Vinay Kumar Guddati | M261191CS |
| 3 | Shruti | M260997CS |
