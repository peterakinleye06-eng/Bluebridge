# Bridgelink Logistics App

A Flutter-based customer and responsive admin dashboard app with a Node.js backend and PostgreSQL database.

## Stack
- Client: Flutter (mobile + web)
- Backend: Node.js / Express
- Database: PostgreSQL

## What is included
- `client/` — Flutter app with authentication, product catalogue, cart, checkout, and admin management
- `server/` — Node.js API service with auth, product, and order routes
- `ARCHITECTURE.md` — app architecture and MVP planning

## Features Implemented
### Authentication
- User registration and login
- JWT-based authentication
- Role-based access (customer/admin)

### Customer Features
- Product catalogue with grid layout
- Shopping cart with quantity management
- Checkout with delivery address and payment options
- Order placement and tracking

### Admin Features
- Product management (add, view, edit, delete)
- Order management with status updates
- Dashboard overview with navigation

## Getting Started

### Backend
1. Install dependencies
   ```powershell
   cd server
   npm install
   ```
2. Copy `.env.example` to `.env` and fill values.
3. Start the server
   ```powershell
   npm run dev
   ```

### Client
1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. Run from the workspace root:
   ```powershell
   cd client
   flutter pub get
   flutter run
   ```

## Next Steps
- Add image upload for products
- Implement order status updates
- Add push notifications
- Integrate payment gateways
- Add analytics and reporting
