# 🛒 Flutter E-Commerce App — Day 15: Clean Architecture, Cubit & Dependency Injection

A complete, full-stack Flutter e-commerce application built with **Clean Architecture**, **Cubit State Management**, and **GetIt / Injectable Dependency Injection**. Features dual-layer offline persistence (SQLite on mobile/desktop + SharedPreferences on web) and a dedicated local **MERN REST API** (Node.js, Express, MongoDB) seeded with 194 products.

---

## 🏗️ Architecture Overview

The codebase is organized into modular feature packages, with each feature applying appropriate structural patterns:

```
lib/
├── core/                                # Core utilities & cross-cutting concerns
│   ├── constants/                       # Colors, assets, API endpoints
│   ├── database/                        # SqfliteHelper (SQLite initialization & schemas)
│   ├── di/                              # GetIt service locator & Injectable config
│   ├── local_storage/                   # CacheHelper (Token & user preferences)
│   ├── network/                         # ApiResult (Success / Failure monad)
│   ├── routes/                          # AppRoutes named routing
│   ├── services/                        # NotificationService (web & mobile safe)
│   ├── utils/                           # Validators & formatters
│   └── widgets/                         # Reusable UI widgets
│
├── features/
│   ├── home/                            # Clean Architecture (3-tier)
│   │   ├── domain/                      # Entities, abstract repository & use cases
│   │   ├── data/                        # DTOs, data sources & repository implementation
│   │   └── presentation/                # HomeScreen, HomeCubit, HomeState & widgets
│   │
│   ├── cart/                            # Clean Data & Presentation layers
│   │   ├── data/                        # CartItemModel, local (SQLite/Prefs) & remote sources
│   │   ├── repository/                  # CartRepository (local-first sync)
│   │   └── presentation/                # CartScreen, CartCubit, CartState & widgets
│   │
│   ├── favorite/                        # Clean Data & Presentation layers
│   │   ├── data/                        # Favorite local & remote sources
│   │   ├── repository/                  # FavoriteRepository (local-first sync)
│   │   └── presentation/                # FavoriteScreen, FavoriteCubit, FavoriteState & widgets
│   │
│   ├── account/                         # Clean Data & Presentation layers
│   │   ├── data/                        # ProfileModel, local & remote sources (multipart)
│   │   ├── repositories/                # UserRepository
│   │   └── presentation/                # AccountScreen, AccountCubit & AccountState
│   │
│   ├── auth/                            # Data & Presentation layers
│   │   ├── data/                        # Request/response models, AuthRemoteDataSource & API
│   │   └── presentation/                # Login, Register views & Cubits
│   │
│   └── app_section/                     # Root navigation shell with MultiBlocProvider
│
└── main.dart                            # Application entry point
```

### Architectural Breakdown by Feature:
- **`home`:** Implements full 3-layer Clean Architecture with Domain Entities (`CategoryEntity`, `ProductEntity`), abstract repository interfaces (`HomeRepository`), domain Use Cases (`GetAllCategoriesUseCase`, `GetAllProductsUseCase`), and Data DTOs (`CategoryDto`, `ProductDto`).
- **`cart` & `favorite`:** Feature-driven architecture with dedicated Data layers (local SQLite/Prefs sources, remote HTTP sources, repository) and Presentation layers (`CartCubit`, `FavoriteCubit`, views, and widgets).
- **`account`:** Feature-driven architecture with `UserLocalDataSource`, `UserRemoteDataSource` (multipart requests), `UserRepository`, `AccountCubit`, and reactive form views.
- **`auth`:** Feature-driven architecture with request/response models, `AuthRemoteDataSource`, and dedicated `LoginCubit` and `RegisterCubit`.

---

## ⚙️ State Management & Dependency Injection

### 1. Automated Dependency Injection with `GetIt` & `Injectable`
All repositories, use cases, data sources, and cubits are registered declaratively using `@injectable` annotations and compiled into `service_locator.config.dart` via `build_runner`:

```dart
final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
```

- **Singleton Services:** HTTP client, `SqfliteHelper`, `SharedPreferences`.
- **Factory Services:** Data sources, repositories, use cases, and cubits.

### 2. Root MultiBlocProvider Orchestration
In `AppSection`, all four core feature cubits are provided at the root level using `MultiBlocProvider`, allowing state and badges to synchronize across tabs without duplicate Cubit instantiations:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => getIt<HomeCubit>()..getAllCategories()..getAllProducts()),
    BlocProvider(create: (context) => getIt<CartCubit>()..getCart()),
    BlocProvider(create: (context) => getIt<FavoriteCubit>()..getFavorites()),
    BlocProvider(create: (context) => getIt<AccountCubit>()..getUserData()),
  ],
  child: Scaffold(...),
)
```

---

## 🚀 Implemented Application Features

### 1. 🏠 Home Feature
- **Category Filter Carousel:** 24 horizontally scrollable categories loaded dynamically. Supports title/slug matching ("Vehicle", "Beauty", "Mens Shirts").
- **Product Catalog:** Paginated grid (`skip` & `limit`) with infinite scrolling support.
- **Dynamic Greeting Banner:** Live greeting (`Hi NQSuki !`) that updates reactively when the user edits their profile.
- **Skeletonizer Loading States:** Smooth placeholder loading animation during asynchronous fetches.
- **Product Search:** Dedicated search screen with live keyword queries.

### 2. 🛒 Cart Feature (Local-First Resilience)
- **Cart Management:** Add items, increment/decrement quantity, and remove items with immediate subtotal and total calculations.
- **Resilient Offline Architecture:** Product additions and quantity changes write immediately to local storage. Even if remote backend synchronization fails, local cart state remains safe.
- **Badge Indicators:** Real-time item count reflected on screen.

### 3. ❤️ Favorites / Wishlist
- **Toggle Wishlist:** Instant toggle on product cards across Home and Product Details.
- **Favorite Screen:** Grid presentation of favorited products with responsive dimensions preventing `RenderFlex` overflow errors.
- **Backend & Local Sync:** Synchronizes with user account while preserving local offline copies.

### 4. 👤 Account & Profile Management
- **Profile Details:** Live display and editing of name, phone number, and delivery address.
- **Image Picker & Multipart Upload:** Pick images from the device gallery via `image_picker` and upload them to the backend using multipart HTTP requests (`/portfoilo/addImage`).
- **Dynamic Image Host Resolution:** Relative image paths (`images/portfolio/...`) automatically resolve to the active host without hardcoding.
- **Live State Synchronization:** Updates immediately synchronize to local cache, MongoDB, and the Home greeting.
- **Secure Logout:** Dialog confirmation, clearing auth tokens and sensitive cached records.

### 5. 🔐 Authentication
- **Sign In & Sign Up:** Form validation (email, password) and token-based authentication.
- **Session Persistence:** Remembers user token across app restarts.
- *(Note: Password reset endpoints exist on the backend; the Flutter client currently implements Login, Registration, and Session management).*

---

## 🗄️ Local Development Backend (MERN Stack)

The application includes a self-contained local development API server in the `api/` directory (Node.js, Express, MongoDB) to support offline development and testing:

- **Server Framework:** Express 4 with CORS enabled for Flutter Web preflights (`*`).
- **Database Engine:** MongoDB via Mongoose schemas (`User`, `Product`, `Category`, `Brand`, `ResetCode`).
- **Authentication:** Password hashing via `bcryptjs` (8 rounds) and JWT verification with 30-day expiry.
- **Static Media Serving:** Serves uploaded user images at `/images/portfolio/*`.
- **Pre-Seeded Catalog:**
  - 📦 **194 Products** (Full descriptions, prices, stock, ratings, and image lists)
  - 🏷️ **24 Categories** (With URLs and representative icons)
  - 🏢 **14 Brands** (With category emojis)
  - 👤 **Default Local Development Account:** `flutteruser2026@test.com` / `Pass@1234`

### Verified Express Routes (`api/server.js`):
| Router | Method | Path | Description |
|---|---|---|---|
| `auth` | `POST` | `/api/v1/auth/signIn` | Authenticate user & issue JWT |
| `auth` | `POST` | `/api/v1/auth/signUp` | Register new user account |
| `auth` | `POST` | `/api/v1/auth/resetPassCode` | Request 6-digit password reset code |
| `auth` | `POST` | `/api/v1/auth/activeResetPass` | Verify reset code validity |
| `auth` | `POST` | `/api/v1/auth/resetPassword` | Update user password |
| `home` | `GET` | `/api/v1/home/products` | Paginated product catalog |
| `home` | `GET` | `/api/v1/home/products/:id` | Single product by ID |
| `home` | `POST` | `/api/v1/home/productsFilter` | Search / filter products |
| `home` | `GET` | `/api/v1/home/products/category/:category` | Filter products by category |
| `home` | `GET` | `/api/v1/home/products/brand/:brand` | Filter products by brand |
| `home` | `GET` | `/api/v1/home/categories` | Retrieve all 24 categories |
| `home` | `GET` | `/api/v1/home/categories/names` | Retrieve category names |
| `home` | `GET` | `/api/v1/home/brands` | Retrieve all 14 brands |
| `home` | `GET` | `/api/v1/home/brands/names` | Retrieve brand names |
| `user` | `GET` | `/api/v1/user/getCart` | Retrieve authenticated user's cart |
| `user` | `POST` | `/api/v1/user/addCart` | Add item to cart in MongoDB |
| `user` | `DELETE` | `/api/v1/user/deleteCart` | Remove item from cart |
| `user` | `GET` | `/api/v1/user/getFavorite` | Retrieve user favorites |
| `user` | `POST` | `/api/v1/user/addFavorite` | Add product to favorites |
| `user` | `DELETE` | `/api/v1/user/deleteFavorite` | Remove product from favorites |
| `portfolio` | `GET` | `/api/v1/portfoilo/userData` | Retrieve user profile data |
| `portfolio` | `POST` | `/api/v1/portfoilo/editUserData` | Update user name, phone, address |
| `portfolio` | `POST` | `/api/v1/portfoilo/addImage` | Multipart upload for profile picture |

---

## 💾 Dual-Layer Persistence Strategy

To solve platform storage differences — where SQLite on Flutter Web runs in-memory (`inMemoryDatabasePath`) and loses state upon browser reload (`F5`) — the app implements a resilient dual-layer caching strategy:

| Platform | Primary Storage | Secondary / Fallback Storage | Behavior on Restart |
|---|---|---|---|
| **Android / Desktop** | **SQLite (`sqflite`)** | `SharedPreferences` | Persistent database file on disk. Restores immediately. |
| **Flutter Web (Chrome)** | `SharedPreferences` (localStorage) | SQLite (in-memory) | In-memory SQLite re-seeds automatically from `SharedPreferences` upon reload (`F5`). |

- All Cart and Favorite mutations write locally first, guaranteeing immediate UI feedback and resilience against network failures.

---

## 🛠️ Tech Stack

### Frontend (Flutter):
- **Dart SDK & Flutter Framework**
- **flutter_bloc** — State management with Cubit
- **get_it** & **injectable** — Dependency injection & service locator
- **build_runner** — Compile-time code generation
- **sqflite** & **sqflite_common_ffi_web** — Relational local storage
- **shared_preferences** — Key-value local storage
- **skeletonizer** — Skeleton loading animations
- **image_picker** — Camera & gallery image selection
- **http** — REST API client with multipart request handling
- **flutter_local_notifications** — Notification service with platform permission safety

### Local Development Backend:
- **Node.js** & **Express**
- **MongoDB** & **Mongoose**
- **jsonwebtoken (JWT)** & **bcryptjs**
- **multer** — Multi-part image upload handling
- **dotenv** & **cors**

---

## 🚦 Getting Started

### Prerequisites:
1. **Flutter SDK** (3.x or higher)
2. **Node.js** (v18 or higher) & **npm**
3. **MongoDB** service running locally on `localhost:27017`

### 1. Start the Local Development API Server
```bash
# Navigate to the api directory
cd api

# Install dependencies (if not already installed)
npm install

# Start the server (connects to MongoDB shopping_app database)
npm start
# Server runs on http://localhost:5000
```

> **Security Note:** Environment variables are configured in `api/.env` (excluded from git via `.gitignore`). Refer to `api/.env.example` for required keys.

### 2. Run Flutter App
```bash
# Return to project root
cd ..

# Get Flutter packages
flutter pub get

# Generate Injectable DI registrations (if modified)
dart run build_runner build --delete-conflicting-outputs

# Launch on Chrome (Web)
flutter run -d chrome --web-port=3000

# Or launch on Windows desktop
flutter run -d windows
```

> **Android Emulator Note:** If running on an Android emulator, update `lib/core/constants/api_constants.dart` to use `emulatorBaseUrl` (`http://10.0.2.2:5000/api/v1`).

---

## 🧪 Testing & Verification

The project includes an automated test suite verifying dependency injection, cubit workflows, persistence fallback, and image formatting:

```bash
# Run static code analysis (0 issues)
flutter analyze

# Run all 36 unit and integration tests (36 passed)
flutter test
```
