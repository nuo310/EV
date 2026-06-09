# EV Charging Station Admin Dashboard Documentation

Welcome to the documentation for the **EV Charging Station Admin Dashboard (OCPP-based)**. This module is designed to give network operators full control and real-time observability over EV charging stations, user transactions, telemetry, and device statuses.

---

## Table of Contents
1. [Tech Stack](#1-tech-stack)
2. [Directory Structure](#2-directory-structure)
3. [Authentication & RBAC Security](#3-authentication--rbac-security)
4. [REST API Reference](#4-rest-api-reference)
5. [WebSocket Telemetry System](#5-websocket-telemetry-system)
6. [Dashboard Sections & Features](#6-dashboard-sections--features)
7. [Local Testing & Command Utilities](#7-local-testing--command-utilities)

---

## 1. Tech Stack

The Admin Dashboard is built on a modern, decoupled web architecture:
*   **Frontend**: React (Vite-powered), Tailwind CSS (v3), Framer Motion (premium micro-animations), Lucide React (vector iconography).
*   **Database & Auth**: Firebase Auth + Cloud Firestore.
*   **Central System Backend**: Express.js (Node.js) handling direct OCPP 1.6J JSON messages, serving REST APIs, and acting as a WebSocket central server.
*   **Styling Theme**: Sleek, high-contrast **Neo-Brutalist Design System** with crisp black borders, solid drop shadows (`boxShadow`), neon green accent colors, and custom fonts.

---

## 2. Directory Structure

All files relating to the admin capabilities are contained inside the frontend and backend directories:

```text
CogniBot-main/
├── client/
│   └── src/
│       ├── admin-dashboard/
│       │   ├── AdminDashboard.jsx  # Main Dashboard page containing UI tabs and logic
│       │   └── useAdminSocket.js   # Real-time WebSocket telemetry listener hook
│       ├── components/
│       │   ├── Navbar.jsx          # App navigation (contains dynamic Admin links)
│       │   └── ProtectedRoute.jsx  # Enforces Admin-only route guard
│       ├── contexts/
│       │   └── AuthContext.jsx     # Handles credentials, logins, and role provisioning
│       └── App.jsx                 # Routes management (/admin-route mount)
└── ocpp-backend/
    ├── firebase.js                 # Firebase Admin SDK initialization
    ├── server.js                   # OCPP Central Server + Admin APIs & WS Hub
    ├── promote-user.js             # CLI tool to promote any user to Admin
    └── ev-app-firebase-service.json # Service account credentials file
```

---

## 3. Authentication & RBAC Security

The app restricts administrative tools to verified accounts.

### Roles and Storage
1.  **Auth Store**: Firebase Authentication manages sessions.
2.  **User Profiles**: Firestore collects profiles in `users/{uid}`.
3.  **Role Field**: The profile document contains a `role` field.
    *   `role: 'user'` (Default for standard accounts).
    *   `role: 'admin'` (Grants access to dashboard APIs and client views).

### Super Admin Credentials
For convenience and development speed, a hardcoded **Super Admin** is configured in [AuthContext.jsx](file:///d:/Flutter%20Projects/EV-APP/EV-APP/CogniBot-main/client/src/contexts/AuthContext.jsx):
*   **Email**: `admin-ev@gmail.com`
*   **Password**: `admin@ev`

#### Auto-Registration Loop:
If you attempt to sign in using the credentials above:
1.  The system tries logging into Firebase Auth.
2.  If the account does not exist (returns `auth/user-not-found` or `auth/invalid-credential`), the app **automatically registers** the account in Firebase Auth.
3.  The auth listener sets the Firestore document role field to `'admin'` and grants instant access.

### Route Guarding (RBAC)
*   **Client Routes**: Configured in [App.jsx](file:///d:/Flutter%20Projects/EV-APP/EV-APP/CogniBot-main/client/src/App.jsx) and enforced by [ProtectedRoute.jsx](file:///d:/Flutter%20Projects/EV-APP/EV-APP/CogniBot-main/client/src/components/ProtectedRoute.jsx).
    *   Mount Point: `/admin-route`
    *   Guard: `<ProtectedRoute adminOnly={true}>`
    *   Behaviour: If a logged-in user does not have `role: 'admin'`, they are redirected to `/dashboard`. Unauthenticated sessions are redirected to `/login`.
*   **Navbar Links**: In [Navbar.jsx](file:///d:/Flutter%20Projects/EV-APP/EV-APP/CogniBot-main/client/src/components/Navbar.jsx), the links `"Admin Panel"`, `"Admin Dashboard"`, and `"Manage Stations"` are filtered out of the view for non-admin accounts.

---

## 4. REST API Reference

The backend Express server (`ocpp-backend`) exposes administrative API endpoints. All requests expect/return JSON.

### 1. Retrieve User Accounts
*   **Route**: `GET /admin/users`
*   **Returns**: Total user count and profiles list.
*   **Response Payload**:
    ```json
    {
      "count": 1,
      "users": [
        {
          "id": "abc123xyz",
          "name": "Super Admin",
          "email": "admin-ev@gmail.com",
          "role": "admin",
          "walletBalance": 10000
        }
      ]
    }
    ```

### 2. Retrieve All Charging Stations
*   **Route**: `GET /admin/stations`
*   **Returns**: All registered stations from Firestore overlayed with live WebSocket connection details.
*   **Response Payload**:
    ```json
    {
      "count": 1,
      "stations": [
        {
          "id": "STATION_001",
          "name": "Downtown Station",
          "ocppStationId": "STATION_001",
          "lat": 12.9716,
          "lng": 77.5946,
          "chargerType": "CCS2 DC Fast",
          "connectorId": 1,
          "pricePerHour": 25,
          "energyRatePerKwh": 18,
          "availableSlots": 1,
          "published": true,
          "isOnline": true,
          "status": "Available"
        }
      ]
    }
    ```

### 3. Add Station Manually
*   **Route**: `POST /admin/stations`
*   **Request Body**:
    ```json
    {
      "stationId": "STATION_001",
      "name": "Downtown Station",
      "lat": 12.9716,
      "lng": 77.5946,
      "chargerType": "CCS2 DC Fast",
      "connectorId": 1,
      "pricePerHour": 25,
      "energyRatePerKwh": 18,
      "availableSlots": 1,
      "published": true
    }
    ```
*   **Returns**: Success confirmation and created document.

### 4. Edit Station Details
*   **Route**: `PUT /admin/stations/:stationId`
*   **Request Body**: Any subset of fields to update.
*   **Returns**: `{ "success": true }`

### 5. Delete Station
*   **Route**: `DELETE /admin/stations/:stationId`
*   **Returns**: `{ "success": true }`

### 6. Live Connected Chargers Snapshot
*   **Route**: `GET /admin/live-chargers`
*   **Returns**: Raw details of OCPP chargers currently connected to the server.

---

## 5. WebSocket Telemetry System

Real-time telemetry and charger status updates are driven by a custom WebSocket server endpoint: `/admin-telemetry` (port matching the server port).

### 1. Connection Protocol
The frontend hook [useAdminSocket.js](file:///d:/Flutter%20Projects/EV-APP/EV-APP/CogniBot-main/client/src/admin-dashboard/useAdminSocket.js) handles connections dynamically:
1.  Replaces `http` with `ws` in the backend base URL.
2.  Connects to `/admin-telemetry`.
3.  Listens for state changes.
4.  On disconnect, tries reconnecting automatically every **3 seconds** to prevent UI stale data.

### 2. Message Payload Schemas
The backend broadcasts JSON strings containing a `type`, `data`, and a ISO-8601 `timestamp`.

#### A. Initial State Snapshot (`type: "initial_snapshot"`)
Sent immediately when the dashboard connects:
```json
{
  "type": "initial_snapshot",
  "data": {
    "count": 1,
    "chargers": [
      {
        "id": "STATION_001",
        "readyState": 1,
        "websocketUrl": "ws://localhost:9221/ocpp/STATION_001",
        "latitude": 12.9716,
        "longitude": 77.5946,
        "status": "Available",
        "telemetry": {
          "lastSeenAt": "2026-06-09T06:00:00.000Z",
          "lastHeartbeatAt": "2026-06-09T06:00:00.000Z"
        }
      }
    ]
  },
  "timestamp": "2026-06-09T06:00:01.000Z"
}
```

#### B. Charger Connected (`type: "charger_connected"`)
Sent when a new physical charger creates an OCPP connection:
```json
{
  "type": "charger_connected",
  "data": {
    "stationId": "STATION_001",
    "websocketUrl": "ws://localhost:9221/ocpp/STATION_001",
    "latitude": 12.9716,
    "longitude": 77.5946
  },
  "timestamp": "2026-06-09T06:01:00.000Z"
}
```

#### C. Charger Disconnected (`type: "charger_disconnected"`)
Sent when a charger closes its connection:
```json
{
  "type": "charger_disconnected",
  "data": { "stationId": "STATION_001" },
  "timestamp": "2026-06-09T06:02:00.000Z"
}
```

#### D. Status Notification (`type: "status_notification"`)
Broadcasts changes in connector states (Available, Preparing, Charging, Faulted, etc.):
```json
{
  "type": "status_notification",
  "data": {
    "stationId": "STATION_001",
    "connectorId": 1,
    "status": "Charging",
    "errorCode": "NoError",
    "at": "2026-06-09T06:03:00.000Z"
  },
  "timestamp": "2026-06-09T06:03:00.000Z"
}
```

#### E. Meter Values (`type: "meter_values"`)
Periodic updates of active power consumption, charging speeds, energy delivered:
```json
{
  "type": "meter_values",
  "data": {
    "stationId": "STATION_001",
    "at": "2026-06-09T06:04:00.000Z",
    "meterValues": {
      "connectorId": 1,
      "transactionId": 1234,
      "meterValue": [
        {
          "timestamp": "2026-06-09T06:04:00Z",
          "sampledValue": [
            { "value": "4500", "unit": "W", "measurand": "Power.Active.Import" },
            { "value": "15200", "unit": "Wh", "measurand": "Energy.Active.Import.Register" }
          ]
        }
      ]
    }
  },
  "timestamp": "2026-06-09T06:04:00.000Z"
}
```

---

## 6. Dashboard Sections & Features

The admin control panel UI consists of five primary sections:

1.  **Overview Tab**:
    *   **Live Metrics Panel**: Displays real-time counts for Total Registered Users, Stations Added, Active WebSockets, and Total Charging Power.
    *   **Telemetry Preview**: Lists active chargers with live connect statuses.
2.  **Stations Tab**:
    *   **Manually Register Stations**: Form to set IDs, location coordinates, connector types, energy rates, and publish states.
    *   **Interactive List**: Edit values or unpublish stations immediately to restrict user search in the mobile app.
3.  **Users Tab**:
    *   **User Profiles Table**: Displays Firestore user records with names, emails, roles, and creation dates.
    *   **Wallet Adjustments**: Quick tools to view account balances.
4.  **Commands Tab (Remote Control)**:
    *   **RemoteStartTransaction Test**: Allows forcing a charging session on any selected online station by assigning an `idTag` and `connectorId`.
    *   **RemoteStopTransaction Test**: Sends stop commands using the active `transactionId`.
    *   **Interactive Command Logs**: Text terminal outputting the raw JSON call-and-response messages.
5.  **Live Logs Tab (Diagnostic Suite)**:
    *   **Telemetry Stream**: Lists all raw JSON packets exchanging between chargers and backend.
    *   **Filtering**: Clear logs or highlight connection types to trace bugs in boot, meter values, or heartbeats.

---

## 7. Local Testing & Command Utilities

For convenience, two Node helper scripts are available in the backend folder to speed up testing:

### 1. Auto-Fill Credentials (Client UI)
On the Login Screen (`/login`), click the button **`AUTO-FILL ADMIN CREDENTIALS`**. It fills in `admin-ev@gmail.com` / `admin@ev` for fast authorization testing.

### 2. Promote Existing User via CLI
To make any custom user account an admin without logging into the Firebase Console:
```bash
cd ocpp-backend
node promote-user.js employee@example.com
```

### 3. Pre-Authorize Admin Registration
To pre-approve an email for standard registration as an admin:
```bash
cd ocpp-backend
node -e "require('./firebase').collection('preauthorized_admins').doc('admin-new@gmail.com').set({ createdAt: new Date() })"
```
*(This allows the user to register an account normally and be instantly granted admin permissions).*
