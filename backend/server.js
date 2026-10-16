require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

const toDb = { mechanic: 'mekanik', mekanik: 'mekanik', owner: 'owner' };
const toApp = { mekanik: 'mechanic', owner: 'owner' };

app.post('/api/login', async (req, res) => {
  try {
    const { username, password, role } = req.body;
    const dbRole = toDb[role];
    if (!username || !password || !dbRole) {
      return res.status(400).json({ message: 'Data login tidak lengkap' });
    }

    const [rows] = await db.query(
      'SELECT id, username, password_hash, role, is_active FROM users WHERE username = ? AND role = ?',
      [username, dbRole]
    );
    const u = rows[0];

    if (!u || !(await bcrypt.compare(password, u.password_hash))) {
      return res.status(401).json({ message: 'Username atau password salah' });
    }
    if (!u.is_active) {
      return res.status(403).json({ message: 'Akun tidak aktif' });
    }

    const token = jwt.sign({ id: u.id, role: u.role }, process.env.JWT_SECRET, { expiresIn: '1d' });
    res.json({
      token,
      user: { id: u.id, name: u.username, username: u.username, role: toApp[u.role] },
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Kesalahan server' });
  }
});

app.listen(process.env.PORT, '0.0.0.0', () =>
  console.log('API jalan di port ' + process.env.PORT)
);