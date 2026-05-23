const express = require('express');
const Joi = require('joi');
const pool = require('../db/pool');

const router = express.Router();

const productSchema = Joi.object({
  name: Joi.string().required(),
  description: Joi.string().allow('').required(),
  price: Joi.number().precision(2).required(),
  category: Joi.string().required(),
  available: Joi.boolean().default(true),
  featured: Joi.boolean().default(false),
  stock_quantity: Joi.number().integer().min(0).default(0),
});

router.get('/', async (req, res, next) => {
  try {
    pool.all('SELECT * FROM products ORDER BY created_at DESC', [], (err, rows) => {
      if (err) return next(err);
      res.json(rows);
    });
  } catch (err) {
    next(err);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const data = await productSchema.validateAsync(req.body);
    pool.run(
      `INSERT INTO products (name, description, price, category, available, featured, stock_quantity)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [data.name, data.description, data.price, data.category, data.available ? 1 : 0, data.featured ? 1 : 0, data.stock_quantity],
      function(err) {
        if (err) return next(err);

        pool.get('SELECT * FROM products WHERE id = ?', [this.lastID], (err, row) => {
          if (err) return next(err);
          res.status(201).json(row);
        });
      }
    );
  } catch (err) {
    next(err);
  }
});

module.exports = router;
