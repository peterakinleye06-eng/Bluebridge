const { Pool } = require('pg');

const isProduction = process.env.NODE_ENV === 'production';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isProduction ? { rejectUnauthorized: false } : false,
});

// Initialize tables
async function initDb() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email TEXT UNIQUE,
        password_hash TEXT,
        name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'customer',
        phone TEXT,
        phone_verified BOOLEAN DEFAULT false,
        google_id TEXT UNIQUE,
        apple_id TEXT UNIQUE,
        verification_code TEXT,
        verification_expires TIMESTAMP,
        reset_token TEXT,
        reset_expires TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price NUMERIC(10,2) NOT NULL,
        category TEXT NOT NULL,
        available BOOLEAN DEFAULT true,
        featured BOOLEAN DEFAULT false,
        stock_quantity INTEGER DEFAULT 0,
        image_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        status TEXT NOT NULL DEFAULT 'placed',
        total_amount NUMERIC(10,2) NOT NULL,
        delivery_address TEXT,
        delivery_notes TEXT,
        payment_method TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS order_items (
        id SERIAL PRIMARY KEY,
        order_id INTEGER REFERENCES orders(id),
        product_id INTEGER REFERENCES products(id),
        quantity INTEGER NOT NULL,
        price NUMERIC(10,2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    console.log('Database tables ready');
  } catch (err) {
    console.error('Database init error:', err);
  } finally {
    client.release();
  }
}

initDb();

// Helper methods to match SQLite-style API used across routes
pool.run = (text, params, callback) => {
  // Convert ? placeholders to $1, $2 etc
  let i = 0;
  const pgText = text.replace(/\?/g, () => `$${++i}`);
  
  pool.query(pgText, params).then(result => {
    if (callback) {
      const context = {
        lastID: result.rows[0]?.id || null,
        changes: result.rowCount,
      };
      callback.call(context, null);
    }
  }).catch(err => {
    if (callback) callback(err);
  });
};

pool.get = (text, params, callback) => {
  let i = 0;
  const pgText = text.replace(/\?/g, () => `$${++i}`);
  
  pool.query(pgText, params).then(result => {
    callback(null, result.rows[0] || null);
  }).catch(err => callback(err));
};

pool.all = (text, params, callback) => {
  let i = 0;
  const pgText = text.replace(/\?/g, () => `$${++i}`);
  
  pool.query(pgText, params).then(result => {
    callback(null, result.rows);
  }).catch(err => callback(err));
};

module.exports = pool;