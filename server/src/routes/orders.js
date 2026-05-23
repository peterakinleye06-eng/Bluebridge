const express = require('express');
const Joi = require('joi');
const pool = require('../db/pool');
const authenticate = require('../middleware/auth');

const router = express.Router();

const ORDER_STATUSES = ['placed', 'confirmed', 'out for delivery', 'delivered', 'cancelled'];

const orderSchema = Joi.object({
  user_id: Joi.number().integer().optional(),
  total_amount: Joi.number().precision(2).required(),
  delivery_address: Joi.string().allow('').required(),
  delivery_notes: Joi.string().allow('').optional(),
  payment_method: Joi.string().required(),
  status: Joi.string().default('placed'),
});

router.use(authenticate);

// POST — place a new order
router.post('/', async (req, res, next) => {
  try {
    const data = await orderSchema.validateAsync(req.body);
    pool.run(
      `INSERT INTO orders (user_id, total_amount, delivery_address, delivery_notes, payment_method, status)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [data.user_id || req.user?.userId || null, data.total_amount, data.delivery_address, data.delivery_notes || null, data.payment_method, data.status],
      function(err) {
        if (err) return next(err);
        pool.get('SELECT * FROM orders WHERE id = ?', [this.lastID], (err, row) => {
          if (err) return next(err);
          res.status(201).json(row);
        });
      }
    );
  } catch (err) {
    next(err);
  }
});

// GET — list orders (admin sees all, customer sees their own)
router.get('/', async (req, res, next) => {
  try {
    const isAdmin = req.user?.role === 'admin';
    const query = isAdmin
      ? 'SELECT * FROM orders ORDER BY created_at DESC'
      : 'SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC';
    const params = isAdmin ? [] : [req.user.userId];

    pool.all(query, params, (err, rows) => {
      if (err) return next(err);
      res.json(rows);
    });
  } catch (err) {
    next(err);
  }
});

// GET — single order by ID
router.get('/:id', async (req, res, next) => {
  try {
    pool.get('SELECT * FROM orders WHERE id = ?', [req.params.id], (err, row) => {
      if (err) return next(err);
      if (!row) return res.status(404).json({ error: 'Order not found' });
      // Only admin or order owner can view
      if (req.user?.role !== 'admin' && row.user_id !== req.user?.userId) {
        return res.status(403).json({ error: 'Access denied' });
      }
      res.json(row);
    });
  } catch (err) {
    next(err);
  }
});

// PATCH — update order status (admin only)
router.patch('/:id/status', async (req, res, next) => {
  try {
    if (req.user?.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }

    const { status } = req.body;
    if (!status || !ORDER_STATUSES.includes(status.toLowerCase())) {
      return res.status(400).json({
        error: `Invalid status. Must be one of: ${ORDER_STATUSES.join(', ')}`
      });
    }

    pool.run(
      'UPDATE orders SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [status.toLowerCase(), req.params.id],
      function(err) {
        if (err) return next(err);
        if (this.changes === 0) return res.status(404).json({ error: 'Order not found' });

        pool.get('SELECT * FROM orders WHERE id = ?', [req.params.id], (err, row) => {
          if (err) return next(err);
          res.json(row);
        });
      }
    );
  } catch (err) {
    next(err);
  }
});

module.exports = router;

// GET /orders/analytics/summary — admin only
router.get('/analytics/summary', async (req, res, next) => {
  try {
    if (req.user?.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required' });
    }

    pool.all('SELECT * FROM orders ORDER BY created_at DESC', [], (err, orders) => {
      if (err) return next(err);

      const total = orders.length;
      const totalRevenue = orders
        .filter(o => o.status !== 'cancelled')
        .reduce((sum, o) => sum + parseFloat(o.total_amount || 0), 0);

      const statusCounts = orders.reduce((acc, o) => {
        acc[o.status] = (acc[o.status] || 0) + 1;
        return acc;
      }, {});

      // Revenue by day (last 7 days)
      const now = new Date();
      const revenueByDay = [];
      for (let i = 6; i >= 0; i--) {
        const date = new Date(now);
        date.setDate(date.getDate() - i);
        const dayStr = date.toISOString().split('T')[0];
        const dayRevenue = orders
          .filter(o => o.status !== 'cancelled' && o.created_at && o.created_at.startsWith(dayStr))
          .reduce((sum, o) => sum + parseFloat(o.total_amount || 0), 0);
        revenueByDay.push({ date: dayStr, revenue: dayRevenue });
      }

      // Payment method breakdown
      const paymentBreakdown = orders.reduce((acc, o) => {
        const method = o.payment_method?.includes('Paystack') ? 'Paystack' : o.payment_method || 'Unknown';
        acc[method] = (acc[method] || 0) + 1;
        return acc;
      }, {});

      res.json({
        total_orders: total,
        total_revenue: totalRevenue,
        status_counts: statusCounts,
        revenue_by_day: revenueByDay,
        payment_breakdown: paymentBreakdown,
        recent_orders: orders.slice(0, 5),
      });
    });
  } catch (err) {
    next(err);
  }
});