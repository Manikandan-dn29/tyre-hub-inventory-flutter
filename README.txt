# MRF Inventory Management App (Flutter)

A professional **Inventory Management / ERP mobile application** built using **Flutter** with a secure **ASP.NET Core Web API** backend.

---

## 🚀 Features

### 🔐 Authentication
- JWT-based Login
- Refresh Token handling
- Auto session expiry handling
- Secure logout

### 📦 Inventory Modules
- **GRN (Goods Receipt – IN)**
- **Issue (Stock OUT)**
- **Items Master**
- **Stock Overview**
- **Stock Adjustment**

### 📊 Dashboard
- Live stock chart (Day / Week / Month)
- KPI-style dashboard cards
- Low stock indicators
- Notification badge

### 🔔 Notifications
- Auto-generated **Low Stock Alerts**
- System messages
- Notification page
- Firebase Push Notifications (FCM)

### ⚙️ Technical Highlights
- REST API integration
- Token auto-refresh
- SharedPreferences storage
- Modular & scalable architecture

---

## 🛠 Tech Stack

### Frontend
- **Flutter (Dart)**
- Material UI
- HTTP
- Shared Preferences
- Firebase Messaging

### Backend
- **ASP.NET Core Web API**
- Entity Framework Core
- JWT Authentication
- SQL Server

---

## 📂 Project Structure

lib/
├── api.dart
├── login.dart
├── dashboard.dart
├── grn.dart
├── issue.dart
├── items_page.dart
├── stock_page.dart
├── stock_adjustment.dart
├── transaction_page.dart
├── notification_page.dart
└── current_stock_chart.dart

yaml
Copy code

---

## 🔧 Setup Instructions

### 1️⃣ Clone Repository
```bash
git clone https://github.com/<your-username>/mrf-inventory-flutter.git
cd mrf-inventory-flutter
2️⃣ Install Dependencies
bash
Copy code
flutter pub get
3️⃣ Run App
bash
Copy code
flutter run
🔐 API Configuration
Update base URL in api.dart:

dart
Copy code
static const String baseUrl = "http://10.0.2.2:5095/api";
Use your local IP for real device testing.

