# NITC Campus Bus Tracking System

A real-time campus bus tracking and management system developed as part of the Software Systems Laboratory (SSL) project at the **National Institute of Technology Calicut (NITC)**.

The system provides students and staff with bus tracking information while allowing drivers and administrators to manage bus operations through role-based interfaces.

## Project Overview

The NITC Campus Bus Tracking System aims to improve campus transportation by providing a centralized platform for bus tracking, route information, schedule management, and administrative operations.

The project consists of two major components:

- **Frontend:** Flutter-based mobile application.
- **Backend:** FastAPI-based REST API with a MySQL database.

## Key Features

### Student / Staff
- User registration and login.
- View available buses and routes.
- Access bus stop and schedule information.
- View bus tracking information.
- Receive announcements and notifications.

### Driver
- Driver login and dashboard.
- Access assigned bus information.
- Share bus location.
- View relevant route and schedule information.
- Submit breakdown reports.

### Administrator
- Manage users and user roles.
- Manage buses and bus registration details.
- Manage routes and stops.
- Manage driver assignments.
- Manage bus schedules.
- Publish announcements.
- View and manage breakdown reports.

## Technology Stack

| Component | Technology |
|---|---|
| Frontend | Flutter, Dart |
| Backend | Python, FastAPI |
| Database | MySQL |
| API Documentation | Swagger UI |
| Map Integration | OpenStreetMap |
| Android Development | Android SDK |

## Project Structure

```text
NITC_BUS_LIVE_TRACKING/
│
├── frontend/
│   ├── android/
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   ├── test/
│   ├── pubspec.yaml
│   └── README.md
│
├── backend/
│   ├── app/
│   │   ├── database/
│   │   ├── models/
│   │   ├── schemas/
│   │   └── services/
│   ├── database/
│   ├── requirements.txt
│   └── README.md
│
├── .gitignore
└── README.md
```

## Installation and Setup

### 1. Clone the Repository

```bash
git clone https://github.com/aasrith-raj/NITC_BUS_LIVE_TRACKING.git
cd NITC_BUS_LIVE_TRACKING
```

### 2. Backend Setup

Navigate to the backend directory:

```bash
cd backend
```

Create and activate a Python virtual environment:

```bash
python -m venv venv
```

For Windows PowerShell:

```powershell
.\venv\Scripts\Activate.ps1
```

Install the required dependencies:

```bash
pip install -r requirements.txt
```

### 3. Database Configuration

- Install and start MySQL.
- Create the project database.
- Execute `backend/database/schema.sql` to create the database tables.
- Use `backend/database/sample_data.sql` if sample data is required.
- Configure your database credentials in a local `.env` file inside the `backend` directory.

Example environment variables:

```env
DB_USER=your_mysql_username
DB_PASSWORD=your_mysql_password
DB_HOST=localhost
DB_PORT=3306
DB_NAME=your_database_name
```

**Important:** Do not upload your actual `.env` file or database credentials to GitHub.

### 4. Run the Backend

From the `backend` directory, start the FastAPI server:

```bash
uvicorn app.main:app --reload
```

Backend API:

```text
http://127.0.0.1:8000
```

Interactive API documentation:

```text
http://127.0.0.1:8000/docs
```

### 5. Frontend Setup

Open another terminal and navigate to the frontend directory:

```bash
cd frontend
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

For Android Emulator development, the application should use `http://10.0.2.2:8000` to access the backend running on the host machine. Ensure the frontend API configuration matches your environment.

## API Documentation

The backend provides interactive API documentation through FastAPI Swagger UI.

Once the backend is running, visit:

http://127.0.0.1:8000/docs

## Contributors

| S. No. | Name                | Roll Number |
|--------|---------------------|-------------|
| 1      | Aasrith Raj         | M260774CS   |
| 2      | Vinay Kumar Guddati | M261191CS   |
| 3      | Shruti              | M260997CS   |

**Institution:** National Institute of Technology Calicut (NITC)

## Project Information

- **Project:** NITC Campus Bus Tracking System
- **Project Type:** Software Systems Laboratory (SSL)
- **Institution:** National Institute of Technology Calicut
- **Repository:** [NITC_BUS_LIVE_TRACKING](https://github.com/aasrith-raj/NITC_BUS_LIVE_TRACKING)

---

Developed as an academic project at **National Institute of Technology Calicut (NITC)**.
