# Server

This directory contains the Node.js backend API for BridgeLink logistics.

## Setup
1. Copy `.env.example` to `.env`.
2. Install dependencies:
   ```powershell
   cd server
   npm install
   ```
3. Start the server:
   ```powershell
   npm run dev
   ```

## API Overview
- `GET /api/health` — health check
- `POST /api/auth/register` — user registration
- `POST /api/auth/login` — user login
- `GET /api/products` — list products
- `POST /api/products` — create a product (admin)

## Database
- PostgreSQL schema is defined in `src/schema.sql`.
- Use `DATABASE_URL` from `.env` to connect.
