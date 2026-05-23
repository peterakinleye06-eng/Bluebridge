const express = require('express');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const appleSignin = require('apple-signin-auth');
const pool = require('../db/pool');

const router = express.Router();

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Google Sign-In
router.post('/google', async (req, res, next) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ error: 'Google token required' });

    // Verify Google token
    const ticket = await googleClient.verifyIdToken({
      idToken: token,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    const { sub: googleId, email, name, picture } = payload;

    // Check if user exists
    pool.get('SELECT * FROM users WHERE google_id = ? OR email = ?', [googleId, email], (err, user) => {
      if (err) return next(err);

      if (user) {
        // Update Google ID if not set
        if (!user.google_id) {
          pool.run('UPDATE users SET google_id = ? WHERE id = ?', [googleId, user.id]);
        }

        const jwtToken = jwt.sign(
          { userId: user.id, role: user.role },
          process.env.JWT_SECRET || 'default_secret',
          { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        return res.json({
          token: jwtToken,
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role
          }
        });
      } else {
        // Create new user
        pool.run(
          'INSERT INTO users (google_id, email, name, role) VALUES (?, ?, ?, ?)',
          [googleId, email, name, 'customer'],
          function(err) {
            if (err) return next(err);

            const jwtToken = jwt.sign(
              { userId: this.lastID, role: 'customer' },
              process.env.JWT_SECRET || 'default_secret',
              { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
            );

            res.status(201).json({
              token: jwtToken,
              user: {
                id: this.lastID,
                email,
                name,
                role: 'customer'
              }
            });
          }
        );
      }
    });
  } catch (err) {
    console.error('Google auth error:', err);
    res.status(401).json({ error: 'Invalid Google token' });
  }
});

// Apple Sign-In
router.post('/apple', async (req, res, next) => {
  try {
    const { identityToken, authorizationCode, user: appleUser } = req.body;

    if (!identityToken) return res.status(400).json({ error: 'Apple identity token required' });

    // Verify Apple token
    const applePayload = await appleSignin.verifyIdToken(identityToken, {
      audience: process.env.APPLE_CLIENT_ID,
      ignoreExpiration: true, // for testing
    });

    const appleId = applePayload.sub;
    let email = applePayload.email;
    let name = 'Apple User';

    // If user data provided, use it
    if (appleUser) {
      const userData = JSON.parse(appleUser);
      if (userData.name) {
        name = `${userData.name.firstName} ${userData.name.lastName}`.trim();
      }
      if (userData.email) {
        email = userData.email;
      }
    }

    // Check if user exists
    pool.get('SELECT * FROM users WHERE apple_id = ? OR email = ?', [appleId, email], (err, user) => {
      if (err) return next(err);

      if (user) {
        // Update Apple ID if not set
        if (!user.apple_id) {
          pool.run('UPDATE users SET apple_id = ? WHERE id = ?', [appleId, user.id]);
        }

        const jwtToken = jwt.sign(
          { userId: user.id, role: user.role },
          process.env.JWT_SECRET || 'default_secret',
          { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        return res.json({
          token: jwtToken,
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role
          }
        });
      } else {
        // Create new user
        pool.run(
          'INSERT INTO users (apple_id, email, name, role) VALUES (?, ?, ?, ?)',
          [appleId, email, name, 'customer'],
          function(err) {
            if (err) return next(err);

            const jwtToken = jwt.sign(
              { userId: this.lastID, role: 'customer' },
              process.env.JWT_SECRET || 'default_secret',
              { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
            );

            res.status(201).json({
              token: jwtToken,
              user: {
                id: this.lastID,
                email,
                name,
                role: 'customer'
              }
            });
          }
        );
      }
    });
  } catch (err) {
    console.error('Apple auth error:', err);
    res.status(401).json({ error: 'Invalid Apple token' });
  }
});

module.exports = router;