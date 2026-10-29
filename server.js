require("dotenv").config();
const express = require("express");
const cors = require("cors");
const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const app = express();
app.use(cors());
app.use(express.json());

const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Nilai ENUM di database -> nilai yang dipakai aplikasi Flutter
const toApp = { mekanik: "mechanic", owner: "owner" };

// Middleware: wajib kirim header "Authorization: Bearer <token>"
function auth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ message: "Belum login" });
  }
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (e) {
    return res
      .status(401)
      .json({ message: "Sesi tidak valid, silakan login ulang" });
  }
}

// LOGIN: hanya username + password, role diambil dari database
app.post("/api/login", async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ message: "Data login tidak lengkap" });
    }

    const [rows] = await db.query(
      "SELECT id, name, username, password_hash, role, is_active FROM users WHERE username = ?",
      [username],
    );
    const u = rows[0];

    if (!u || !(await bcrypt.compare(password, u.password_hash))) {
      return res.status(401).json({ message: "Username atau password salah" });
    }
    if (!u.is_active) {
      return res.status(403).json({ message: "Akun tidak aktif" });
    }

    const token = jwt.sign({ id: u.id, role: u.role }, process.env.JWT_SECRET, {
      expiresIn: "1d",
    });
    res.json({
      token,
      user: {
        id: u.id,
        name: u.name,
        username: u.username,
        role: toApp[u.role],
      },
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

// GANTI PASSWORD: wajib password lama yang benar
app.put("/api/change-password", auth, async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return res
        .status(400)
        .json({ message: "Password lama dan baru wajib diisi" });
    }
    if (newPassword.length < 6) {
      return res
        .status(400)
        .json({ message: "Password baru minimal 6 karakter" });
    }

    const [rows] = await db.query(
      "SELECT password_hash FROM users WHERE id = ?",
      [req.user.id],
    );
    const u = rows[0];
    if (!u) {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }

    const oldOk = await bcrypt.compare(oldPassword, u.password_hash);
    if (!oldOk) {
      return res.status(400).json({ message: "Password lama salah" });
    }

    const newHash = await bcrypt.hash(newPassword, 10);
    await db.query("UPDATE users SET password_hash = ? WHERE id = ?", [
      newHash,
      req.user.id,
    ]);

    res.json({ message: "Password berhasil diganti" });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

// UPDATE PROFIL: simpan nama user yang sedang login
app.put("/api/profile", auth, async (req, res) => {
  try {
    const username = (req.body.username || "").trim();

    if (!username) {
      return res.status(400).json({ message: "Username tidak boleh kosong" });
    }
    if (username.length < 3 || username.length > 50) {
      return res
        .status(400)
        .json({ message: "Username harus 3-50 karakter" });
    }
    if (!/^[A-Za-z0-9_.]+$/.test(username)) {
      return res.status(400).json({
        message: "Username hanya boleh huruf, angka, titik, dan underscore",
      });
    }

    await db.query("UPDATE users SET username = ? WHERE id = ?", [
      username,
      req.user.id,
    ]);

    res.json({ message: "Username berhasil diperbarui", username });
  } catch (e) {
    if (e.code === "ER_DUP_ENTRY") {
      return res.status(409).json({ message: "Username sudah dipakai" });
    }
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

// Ambil semua motor milik user yang login
app.get("/api/motors", auth, async (req, res) => {
  try {
    const [rows] = await db.query(
      "SELECT id, name, type FROM motors ORDER BY id",
    );
    res.json(rows);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

// Tambah motor
app.post("/api/motors", auth, async (req, res) => {
  try {
    const name = (req.body.name || "").trim();
    const type = parseInt(req.body.type, 10);

    if (!name) {
      return res.status(400).json({ message: "Nama motor wajib diisi" });
    }
    if (name.length > 60) {
      return res.status(400).json({ message: "Nama motor maksimal 60 karakter" });
    }
    if (!Number.isInteger(type) || type < 0 || type > 65535) {
      return res.status(400).json({ message: "Tipe motor harus berupa angka" });
    }

    const [result] = await db.query(
      "INSERT INTO motors (user_id, name, type) VALUES (?, ?, ?)",
      [req.user.id, name, type],
    );
    res.status(201).json({ id: result.insertId, name, type });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

// Ubah motor
app.put("/api/motors/:id", auth, async (req, res) => {
  try {
    const name = (req.body.name || "").trim();
    const type = parseInt(req.body.type, 10);

    if (!name) {
      return res.status(400).json({ message: "Nama motor wajib diisi" });
    }
    if (name.length > 60) {
      return res.status(400).json({ message: "Nama motor maksimal 60 karakter" });
    }
    if (!Number.isInteger(type) || type < 0 || type > 65535) {
      return res.status(400).json({ message: "Tipe motor harus berupa angka" });
    }

    const [result] = await db.query(
      "UPDATE motors SET name = ?, type = ? WHERE id = ?",
      [name, type, req.params.id],
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Motor tidak ditemukan" });
    }
    res.json({ message: "Motor berhasil diubah" });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

// Hapus motor
app.delete("/api/motors/:id", auth, async (req, res) => {
  try {
    const [result] = await db.query(
      "DELETE FROM motors WHERE id = ?",
      [req.params.id],
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Motor tidak ditemukan" });
    }
    res.json({ message: "Motor berhasil dihapus" });
  } catch (e) {
    // motor masih dipakai oleh tabel lain (mis. sessions) lewat foreign key
    if (e.code === "ER_ROW_IS_REFERENCED_2") {
      return res
        .status(409)
        .json({ message: "Motor tidak bisa dihapus karena masih dipakai data sesi" });
    }
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

// ================= KELOLA AKUN MEKANIK (khusus owner) =================
function requireOwner(req, res, next) {
  if (req.user.role !== "owner") {
    return res.status(403).json({ message: "Hanya owner yang boleh mengakses" });
  }
  next();
}

// Daftar semua akun mekanik
app.get("/api/accounts", auth, requireOwner, async (req, res) => {
  try {
    const [rows] = await db.query(
      "SELECT id, name, username, is_active FROM users WHERE role = 'mekanik' ORDER BY id",
    );
    res.json(
      rows.map((r) => ({
        id: r.id,
        name: r.name,
        username: r.username,
        active: Boolean(r.is_active),
      })),
    );
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

// Tambah akun mekanik
app.post("/api/accounts", auth, requireOwner, async (req, res) => {
  try {
    const name = (req.body.name || "").trim();
    const username = (req.body.username || "").trim();
    const password = req.body.password || "";

    if (!name || !username || !password) {
      return res
        .status(400)
        .json({ message: "Nama, username, dan password wajib diisi" });
    }
    if (name.length > 45) {
      return res.status(400).json({ message: "Nama maksimal 45 karakter" });
    }
    if (username.length > 50) {
      return res.status(400).json({ message: "Username maksimal 50 karakter" });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: "Password minimal 6 karakter" });
    }

    const hash = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      "INSERT INTO users (name, username, password_hash, role, is_active) VALUES (?, ?, ?, 'mekanik', 1)",
      [name, username, hash],
    );
    res.status(201).json({
      id: result.insertId,
      name,
      username,
      active: true,
    });
  } catch (e) {
    if (e.code === "ER_DUP_ENTRY") {
      return res.status(409).json({ message: "Username sudah dipakai" });
    }
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

// Aktifkan / nonaktifkan akun mekanik
app.put("/api/accounts/:id/active", auth, requireOwner, async (req, res) => {
  try {
    const active = req.body.active ? 1 : 0;
    const [result] = await db.query(
      "UPDATE users SET is_active = ? WHERE id = ? AND role = 'mekanik'",
      [active, req.params.id],
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Akun tidak ditemukan" });
    }
    res.json({ message: "Status akun diperbarui", active: Boolean(active) });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

// Reset password akun mekanik
app.put("/api/accounts/:id/password", auth, requireOwner, async (req, res) => {
  try {
    const password = req.body.password || "";
    if (password.length < 6) {
      return res.status(400).json({ message: "Password minimal 6 karakter" });
    }

    const hash = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      "UPDATE users SET password_hash = ? WHERE id = ? AND role = 'mekanik'",
      [hash, req.params.id],
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Akun tidak ditemukan" });
    }
    res.json({ message: "Password berhasil direset" });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: "Kesalahan server" });
  }
});

app.listen(process.env.PORT, "0.0.0.0", () =>
  console.log("API jalan di port " + process.env.PORT),
);