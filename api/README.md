# E-Commerce RESTful API Server (Local Backend)

A fast, fully-working Node.js + Express REST API created for the Flutter E-Commerce shopping app based on the official Postman collection (`ecommerce-backend-mohamed-eid.json`).

---

## 🚀 Features

- **No Database Setup Needed**: Automatically saves users, carts, favorites, and profile changes to local persistent JSON files (`api/data/`).
- **Pre-Seeded with Real Data**: Comes with **194 authentic products**, **24 categories**, and **14 brands** extracted from the course supermarket database.
- **100% Working Endpoints**:
  - `POST /api/v1/user/addCart` (Adds products to user's cart without HTTP 500 errors)
  - `DELETE /api/v1/user/deleteCart`
  - `GET /api/v1/user/getCart`
  - `POST /api/v1/user/addFavorite` (Adds products to user's favorites without HTTP 500 errors)
  - `DELETE /api/v1/user/deleteFavorite`
  - `GET /api/v1/user/getFavorite`
  - `POST /api/v1/portfoilo/addImage` (Saves uploaded images locally to `api/public/images/portfolio/` permanently — no more 404s after sleep)
  - `GET /api/v1/portfoilo/userData` & `POST /api/v1/portfoilo/editUserData`
  - Full Auth (`signUp`, `signIn`, `resetPassCode`, `activeResetPass`, `resetPassword`)
  - Full Products, Search, Categories, Brands (`products`, `productsFilter`, `category/:cat`, `brand/:brand`, etc.)
- **CORS Enabled**: Compatible with Flutter Web, Android Emulators, and Physical Devices.

---

## 🛠️ How to Run

1. Open a terminal in the `api` directory:
   ```bash
   cd api
   ```
2. Start the server:
   ```bash
   npm start
   ```
   Or for auto-restart on changes:
   ```bash
   npm run dev
   ```
3. The server starts at:
   `http://localhost:5000`

---

## 📱 Connecting from Flutter

In `lib/core/constants/api_constants.dart`:

- **For Flutter Web & Windows**:
  ```dart
  static const String baseUrl = 'http://localhost:5000/api/v1';
  ```
- **For Android Emulator**:
  ```dart
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';
  ```
- **For Physical Phone (same Wi-Fi)**:
  ```dart
  static const String baseUrl = 'http://<YOUR_COMPUTER_LOCAL_IP>:5000/api/v1';
  ```

---

## 🔑 Default Test Account

- **Email:** `flutteruser2026@test.com`
- **Password:** `Pass@1234`

