const express = require('express');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const Joi = require('joi');
const pool = require('../db/pool');

const router = express.Router();

// Lazy-load nodemailer only when actually needed (avoids crash if not installed)
function getTransporter() {
  try {
    const nodemailer = require('nodemailer');
    return nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT) || 587,
      secure: false,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  } catch (e) {
    console.warn('nodemailer not installed — email sending disabled');
    return null;
  }
}

const resetRequestSchema = Joi.object({
  email: Joi.string().email(),
  phone: Joi.string().pattern(/^\+?[1-9]\d{1,14}$/),
}).or('email', 'phone');

const resetPasswordSchema = Joi.object({
  token: Joi.string().required(),
  password: Joi.string().min(8).required(),
});

async function sendSMS(phone, message) {
  console.log(`[SMS mock] To ${phone}: ${message}`);
}

async function sendResetEmail(email, token) {
  const transporter = getTransporter();
  if (!transporter) {
    console.log(`[Email mock] Reset token for ${email}: ${token}`);
    return;
  }
  const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${token}`;
  return transporter.sendMail({
    from: process.env.SMTP_USER,
    to: email,
    subject: 'BridgeLink Password Reset',
    html: `
      <h2>Password Reset Request</h2>
      <p>Click the link below to reset your password:</p>
      <a href="${resetUrl}">Reset Password</a>
      <p>This link will expire in 1 hour.</p>
    `,
  });
}

router.post('/forgot-password', async (req, res, next) => {
  try {
    const { email, phone } = await resetRequestSchema.validateAsync(req.body);
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetExpires = new Date(Date.now() + 60 * 60 * 1000).toISOString();

    const query = email
      ? 'UPDATE users SET reset_token = ?, reset_expires = ? WHERE email = ?'
      : 'UPDATE users SET reset_token = ?, reset_expires = ? WHERE phone = ?';
    const params = [resetToken, resetExpires, email || phone];

    pool.run(query, params, function(err) {
      if (err) return next(err);
      if (this.changes === 0) return res.status(404).json({ error: 'User not found' });

      const action = email
        ? sendResetEmail(email, resetToken).then(() => res.json({ message: 'Password reset email sent' }))
        : sendSMS(phone, `Your BridgeLink reset token: ${resetToken}`).then(() => res.json({ message: 'Password reset SMS sent' }));

      action.catch(err => {
        console.error('Notification error:', err);
        res.status(500).json({ error: 'Failed to send reset notification' });
      });
    });
  } catch (err) {
    next(err);
  }
});

router.post('/reset-password', async (req, res, next) => {
  try {
    const { token, password } = await resetPasswordSchema.validateAsync(req.body);

    pool.get(
      'SELECT * FROM users WHERE reset_token = ? AND reset_expires > ?',
      [token, new Date().toISOString()],
      async (err, user) => {
        if (err) return next(err);
        if (!user) return res.status(401).json({ error: 'Invalid or expired reset token' });

        const hashedPassword = await bcrypt.hash(password, 10);
        pool.run(
          'UPDATE users SET password_hash = ?, reset_token = NULL, reset_expires = NULL WHERE id = ?',
          [hashedPassword, user.id],
          function(err) {
            if (err) return next(err);
            res.json({ message: 'Password reset successfully' });
          }
        );
      }
    );
  } catch (err) {
    next(err);
  }
});

module.exports = router;