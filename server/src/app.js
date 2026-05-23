const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const smsRoutes = require('./routes/sms');
const oauthRoutes = require('./routes/oauth');
const passwordRoutes = require('./routes/password');
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/orders');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/auth', smsRoutes);
app.use('/api/auth', oauthRoutes);
app.use('/api/auth', passwordRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'bridgelink-logistics' });
});

app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

module.exports = app;
