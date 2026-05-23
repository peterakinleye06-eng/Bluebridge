const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Joi = require('joi');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const pool = require('../db/pool');

const router = express.Router();

// Phone verification schema
const phoneSchema = Joi.object({
  phone: Joi.string().pattern(/^\+?[1-9]\d{1,14}$/).required(),
});

const otpSchema = Joi.object({
  phone: Joi.string().pattern(/^\+?[1-9]\d{1,14}$/).required(),
  code: Joi.string().length(6).required(),
});

// Generate OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Send SMS (mock implementation - replace with actual SMS service)
async function sendSMS(phone, message) {
  console.log(`SMS to ${phone}: ${message}`);
  // In production, integrate with Twilio, AWS SNS, etc.
  // Example with Twilio:
  // const twilio = require('twilio');
  // const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_TOKEN);
  // return client.messages.create({
  //   body: message,
  //   from: process.env.TWILIO_PHONE,
  //   to: phone
  // });
}

// Send OTP for phone verification
router.post('/send-otp', async (req, res, next) => {
  try {
    const { phone } = await phoneSchema.validateAsync(req.body);
    const otp = generateOTP();
    const expires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Store OTP in database
    pool.run(
      `UPDATE users SET verification_code = ?, verification_expires = ? WHERE phone = ?`,
      [otp, expires.toISOString(), phone],
      function(err) {
        if (err) return next(err);

        // If no user found, create temporary user record
        if (this.changes === 0) {
          pool.run(
            'INSERT INTO users (phone, verification_code, verification_expires, name) VALUES (?, ?, ?, ?)',
            [phone, otp, expires.toISOString(), 'Phone User'],
            function(err) {
              if (err) return next(err);
              sendSMS(phone, `Your BridgeLink verification code is: ${otp}`);
              res.json({ message: 'OTP sent successfully' });
            }
          );
        } else {
          sendSMS(phone, `Your BridgeLink verification code is: ${otp}`);
          res.json({ message: 'OTP sent successfully' });
        }
      }
    );
  } catch (err) {
    next(err);
  }
});

// Verify OTP and login/register
router.post('/verify-otp', async (req, res, next) => {
  try {
    const { phone, code } = await otpSchema.validateAsync(req.body);

    pool.get(
      'SELECT * FROM users WHERE phone = ? AND verification_code = ? AND verification_expires > ?',
      [phone, code, new Date().toISOString()],
      (err, user) => {
        if (err) return next(err);
        if (!user) return res.status(401).json({ error: 'Invalid or expired OTP' });

        // Clear verification code
        pool.run(
          'UPDATE users SET verification_code = NULL, verification_expires = NULL, phone_verified = ? WHERE id = ?',
          [true, user.id],
          (err) => {
            if (err) return next(err);

            const token = jwt.sign(
              { userId: user.id, role: user.role || 'customer' },
              process.env.JWT_SECRET || 'default_secret',
              { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
            );

            res.json({
              token,
              user: {
                id: user.id,
                email: user.email,
                name: user.name,
                phone: user.phone,
                role: user.role || 'customer'
              }
            });
          }
        );
      }
    );
  } catch (err) {
    next(err);
  }
});

module.exports = router;