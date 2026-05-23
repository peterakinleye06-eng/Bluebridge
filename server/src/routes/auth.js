const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Joi = require('joi');
const pool = require('../db/pool');

const router = express.Router();

const registerSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required(),
  name: Joi.string().required(),
  role: Joi.string().valid('customer', 'admin').default('customer'),
});

router.post('/register', async (req, res, next) => {
  try {
    const { email, password, name, role } = await registerSchema.validateAsync(req.body);
    const hashed = await bcrypt.hash(password, 10);

    pool.run(
      'INSERT INTO users (email, password_hash, name, role) VALUES (?, ?, ?, ?)',
      [email, hashed, name, role || 'customer'],
      function(err) {
        if (err) {
          if (err.message.includes('UNIQUE constraint failed')) {
            return res.status(409).json({ error: 'Email already exists' });
          }
          return next(err);
        }

        const newId = this.lastID;
        pool.get('SELECT id, email, name, role FROM users WHERE id = ?', [newId], (err, row) => {
          if (err) return next(err);

          // Generate JWT token so Flutter can authenticate immediately after registration
          const token = jwt.sign(
            { userId: row.id, role: row.role },
            process.env.JWT_SECRET || 'default_secret',
            { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
          );

          res.status(201).json({ token, user: row });
        });
      }
    );
  } catch (err) {
    next(err);
  }
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = await loginSchema.validateAsync(req.body);

    pool.get('SELECT id, email, password_hash, name, role FROM users WHERE email = ?', [email], async (err, user) => {
      if (err) return next(err);
      if (!user) return res.status(401).json({ error: 'Invalid credentials' });

      const valid = await bcrypt.compare(password, user.password_hash);
      if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

      const token = jwt.sign({ userId: user.id, role: user.role }, process.env.JWT_SECRET || 'default_secret', {
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
      });

      res.json({ token, user: { id: user.id, email: user.email, name: user.name, role: user.role } });
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;