  const express = require('express');
  const cors = require('cors');
  const mysql = require('mysql2');
  const https = require('https');

  const app = express();
  app.use(express.json());
  app.use(cors());

  // Konfigurasi Database MySQL (XAMPP / Laragon)
  const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'puthu_lanang_db'
  });

  db.connect((err) => {
    if (err) {
      console.error('Koneksi MySQL gagal:', err);
      return;
    }
    console.log('Berhasil terhubung ke database MySQL Puthu Lanang.');
  });

  // Fungsi helper untuk kirim WhatsApp via Fonnte
  function sendFonnteMessage(targetPhone, message) {
    return new Promise((resolve, reject) => {
      const data = JSON.stringify({
        target: targetPhone,
        message: message,
        countryCode: '62',
      });

      const options = {
        hostname: 'api.fonnte.com',
        port: 443,
        path: '/send',
        method: 'POST',
        headers: {
          'Authorization': 'x97GBmRqfzqDm8mSVd1U', // Token Fonnte kamu
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data)
        }
      };

      const req = https.request(options, (res) => {
        let responseBody = '';
        res.on('data', (chunk) => { responseBody += chunk; });
        res.on('end', () => { 
          console.log('[FONNTE API RESPONSE]:', responseBody);
          resolve(responseBody); 
        });
      });

      req.on('error', (error) => { 
        console.error('[FONNTE API ERROR]:', error);
        reject(error); 
      });
      
      req.write(data);
      req.end();
    });
  }

  // Endpoint Cek Server
  app.get('/', (req, res) => {
    res.json({ message: 'API Backend Puthu Lanang Berjalan Aktif!' });
  });

  // Endpoint Get Menu
  app.get('/api/menu', (req, res) => {
    db.query('SELECT * FROM menu', (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(results);
    });
  });

  // Endpoint Buat Pesanan / E-Tiket
  app.post('/api/orders', (req, res) => {
    const { name, phone, pickupTime, pickupDate, items, total, notes } = req.body;
    const qrToken = 'PL-2026-' + Math.floor(10000 + Math.random() * 90000);
    const antreanNo = Math.floor(50 + Math.random() * 50);

    const query = 'INSERT INTO orders (name, phone, pickup_time, pickup_date, total, notes, qr_token, antrean) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
    
    db.query(query, [name, phone, pickupTime, pickupDate, total, notes, qrToken, antreanNo], (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      
      res.json({
        message: 'Pesanan berhasil dibuat',
        data: {
          id: 'ORD-' + result.insertId,
          qr_code_token: qrToken,
          antrean: antreanNo,
          status: 'Sedang Dikukus',
          total_harga: total
        }
      });
    });
  });

  // --- ENDPOINT PEMBAYARAN MIDTRANS SANDBOX ---
  app.post('/api/payment/create-charge', (req, res) => {
    const { gross_amount, customer_name, customer_phone, payment_type } = req.body;

    const serverKey = 'SB-Mid-server-gZRRXn2c7323zgcAPStRVskk';
    const encodedKey = Buffer.from(serverKey + ':').toString('base64');

    const payload = JSON.stringify({
      payment_type: payment_type === 'QRIS' ? 'qris' : 'bank_transfer',
      transaction_details: {
        order_id: 'PL-TRX-' + Date.now(),
        gross_amount: gross_amount || 18000
      },
      bank_transfer: payment_type !== 'QRIS' ? {
        bank: payment_type === 'BCA' ? 'bca' : 'mandiri'
      } : undefined,
      customer_details: {
        first_name: customer_name || 'Pelanggan Puthu Lanang',
        phone: customer_phone || '088212383828'
      }
    });

    const options = {
      hostname: 'api.sandbox.midtrans.com',
      port: 443,
      path: '/v2/charge',
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + encodedKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const midtransReq = https.request(options, (midtransRes) => {
      let body = '';
      midtransRes.on('data', (chunk) => { body += chunk; });
      midtransRes.on('end', () => {
        try {
          const jsonResponse = JSON.parse(body);
          res.json({
            message: 'Midtrans charge processed successfully',
            redirect_url: jsonResponse.actions?.[0]?.url || jsonResponse.pdf_url || 'https://simulator.sandbox.midtrans.com/',
            data: jsonResponse
          });
        } catch (e) {
          res.status(500).json({ message: 'Gagal memproses respons dari Midtrans.' });
        }
      });
    });

    midtransReq.on('error', (err) => {
      res.status(500).json({ message: err.message });
    });

    midtransReq.write(payload);
    midtransReq.end();
  });
  // ------------------------------------------

  // Endpoint Kirim OTP (Support Login, Register, & Lupa Password)
  app.post('/api/auth/send-otp', async (req, res) => {
    const { no_whatsapp, type } = req.body;
    if (!no_whatsapp) {
      return res.status(400).json({ message: 'Nomor WhatsApp wajib diisi.' });
    }

    db.query('SELECT * FROM users WHERE no_whatsapp = ?', [no_whatsapp], async (err, results) => {
      if (err) return res.status(500).json({ message: err.message });

      const isExist = results.length > 0;

      if (type === 'register' && isExist) {
        return res.status(400).json({ message: 'Nomor WhatsApp sudah terdaftar. Silakan masuk.' });
      }
      if ((type === 'login' || type === 'forgot') && !isExist) {
        return res.status(400).json({ message: 'Akun belum terdaftar. Silakan daftar terlebih dahulu.' });
      }

      const otpCode = Math.floor(1000 + Math.random() * 9000).toString();
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

      const query = 'INSERT INTO otp_codes (no_whatsapp, otp_code, expires_at) VALUES (?, ?, ?)';
      db.query(query, [no_whatsapp, otpCode, expiresAt], async (err2) => {
        if (err2) return res.status(500).json({ message: err2.message });

        try {
          const pesanWa = `🔒 *KODE OTP PUTHU LANANG*\n\nKode verifikasi Anda adalah: *${otpCode}*\nBerlaku selama 5 menit. Jangan berikan kode ini kepada siapa pun.`;
          
          await sendFonnteMessage(no_whatsapp, pesanWa);
          console.log(`[FONNTE WA] OTP terkirim ke ${no_whatsapp}: ${otpCode}`);

          res.json({ message: 'Kode OTP berhasil dikirim ke WhatsApp Anda.' });
        } catch (apiErr) {
          console.error('Gagal kirim Fonnte:', apiErr);
          res.status(500).json({ message: 'Gagal mengirim pesan WhatsApp via Fonnte.' });
        }
      });
    });
  });

  // Endpoint Verifikasi OTP & Selesaikan Register/Login
  app.post('/api/auth/verify-otp', (req, res) => {
    const { nama, no_whatsapp, password, otp_code, is_register } = req.body;

    if (!no_whatsapp || !otp_code) {
      return res.status(400).json({ message: 'Nomor WhatsApp dan kode OTP wajib diisi.' });
    }

    const checkOtpQuery = 'SELECT * FROM otp_codes WHERE no_whatsapp = ? AND otp_code = ? AND expires_at > NOW() ORDER BY id DESC LIMIT 1';
    db.query(checkOtpQuery, [no_whatsapp, otp_code], (err, otpResults) => {
      if (err) return res.status(500).json({ message: err.message });
      if (otpResults.length === 0) {
        return res.status(400).json({ message: 'Kode OTP salah atau sudah kedaluwarsa.' });
      }

      db.query('SELECT * FROM users WHERE no_whatsapp = ?', [no_whatsapp], (err2, userResults) => {
        if (err2) return res.status(500).json({ message: err2.message });

        const userExists = userResults.length > 0;

        if (is_register) {
          if (userExists) {
            return res.status(400).json({ message: 'Nomor WhatsApp sudah terdaftar. Silakan masuk.' });
          }

          const insertUser = 'INSERT INTO users (nama, no_whatsapp, password, is_verified) VALUES (?, ?, ?, 1)';
          db.query(insertUser, [nama || 'Pelanggan', no_whatsapp, password], (err3, result) => {
            if (err3) return res.status(500).json({ message: err3.message });
            
            db.query('DELETE FROM otp_codes WHERE no_whatsapp = ?', [no_whatsapp]);

            res.json({
              message: 'Registrasi & Verifikasi Berhasil!',
              data: {
                id: result.insertId,
                nama: nama || 'Pelanggan',
                no_whatsapp: no_whatsapp,
                token: 'server-token-' + no_whatsapp
              }
            });
          });
        } else {
          if (!userExists) {
            return res.status(400).json({ message: 'Akun belum terdaftar. Silakan daftar terlebih dahulu.' });
          }

          db.query('DELETE FROM otp_codes WHERE no_whatsapp = ?', [no_whatsapp]);
          const user = userResults[0];

          res.json({
            message: 'Login Berhasil!',
            data: {
              nama: user.nama,
              no_whatsapp: user.no_whatsapp,
              token: 'server-token-' + user.no_whatsapp
            }
          });
        }
      });
    });
  });

  // Endpoint Lupa Password (Reset Password via OTP)
  app.post('/api/auth/forgot-password', (req, res) => {
    const { no_whatsapp, otp_code, new_password } = req.body;

    if (!no_whatsapp || !otp_code || !new_password) {
      return res.status(400).json({ message: 'Semua kolom wajib diisi.' });
    }

    const checkOtpQuery = 'SELECT * FROM otp_codes WHERE no_whatsapp = ? AND otp_code = ? AND expires_at > NOW() ORDER BY id DESC LIMIT 1';
    db.query(checkOtpQuery, [no_whatsapp, otp_code], (err, otpResults) => {
      if (err) return res.status(500).json({ message: err.message });
      if (otpResults.length === 0) {
        return res.status(400).json({ message: 'Kode OTP salah atau sudah kedaluwarsa.' });
      }

      const updateQuery = 'UPDATE users SET password = ? WHERE no_whatsapp = ?';
      db.query(updateQuery, [new_password, no_whatsapp], (err2) => {
        if (err2) return res.status(500).json({ message: err2.message });

        db.query('DELETE FROM otp_codes WHERE no_whatsapp = ?', [no_whatsapp]);

        res.json({ message: 'Password berhasil diubah. Silakan masuk dengan password baru.' });
      });
    });
  });

  // Endpoint Register User Lama (Opsional / Cadangan)
  app.post('/api/auth/user-register', (req, res) => {
    const { nama, no_whatsapp, password } = req.body;
    
    if (!nama || !no_whatsapp || !password) {
      return res.status(400).json({ message: 'Semua kolom wajib diisi.' });
    }

    const checkQuery = 'SELECT * FROM users WHERE no_whatsapp = ?';
    db.query(checkQuery, [no_whatsapp], (err, results) => {
      if (err) return res.status(500).json({ message: err.message });
      if (results.length > 0) {
        return res.status(400).json({ message: 'Nomor WhatsApp sudah terdaftar. Silakan masuk.' });
      }

      const insertQuery = 'INSERT INTO users (nama, no_whatsapp, password) VALUES (?, ?, ?)';
      db.query(insertQuery, [nama, no_whatsapp, password], (err2, result) => {
        if (err2) return res.status(500).json({ message: err2.message });
        
        res.json({
          message: 'Registrasi berhasil',
          data: {
            id: result.insertId,
            nama: nama,
            no_whatsapp: no_whatsapp,
            token: 'server-token-' + no_whatsapp
          }
        });
      });
    });
  });

  // Endpoint Login User Lama (Opsional / Cadangan)
  app.post('/api/auth/user-login', (req, res) => {
    const { no_whatsapp, password } = req.body;

    if (!no_whatsapp || !password) {
      return res.status(400).json({ message: 'Nomor WhatsApp dan password wajib diisi.' });
    }

    const query = 'SELECT * FROM users WHERE no_whatsapp = ? AND password = ?';
    db.query(query, [no_whatsapp, password], (err, results) => {
      if (err) return res.status(500).json({ message: err.message });
      if (results.length === 0) {
        return res.status(400).json({ message: 'Nomor WhatsApp atau password salah.' });
      }

      const user = results[0];
      res.json({
        message: 'Login berhasil',
        data: {
          nama: user.nama,
          no_whatsapp: user.no_whatsapp,
          token: 'server-token-' + user.no_whatsapp
        }
      });
    });
  });

  const PORT = 3000;
  app.listen(PORT, () => {
    console.log(`Server berjalan di http://localhost:${PORT}`);
  });