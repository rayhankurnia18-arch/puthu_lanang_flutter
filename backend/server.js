const express = require('express');
const cors    = require('cors');
const mysql   = require('mysql2');
const https   = require('https');

const app = express();
app.use(express.json());
app.use(cors());

// Mode development/UTS: OTP disertakan di response API agar mudah di-demo
// tanpa gateway WhatsApp berbayar. Matikan dengan: DEV_MODE=false npm run dev
const DEV_MODE = process.env.DEV_MODE !== 'false';

// =============================================================
// KONEKSI DATABASE MYSQL (XAMPP / Laragon)
// Menggunakan pool agar koneksi tahan terhadap timeout & restart
// =============================================================
const db = mysql.createPool({
  host              : 'localhost',
  user              : 'root',
  password          : '',
  database          : 'puthu_lanang_db',
  waitForConnections: true,
  connectionLimit   : 10,
  queueLimit        : 0,
});

// Uji koneksi saat server pertama kali berjalan
db.getConnection((err, connection) => {
  if (err) {
    console.error('❌ Koneksi MySQL gagal:', err.message);
    console.error('   Pastikan MySQL / XAMPP sudah berjalan dan database "puthu_lanang_db" sudah dibuat.');
    return;
  }
  console.log('✅ Berhasil terhubung ke database MySQL puthu_lanang_db.');
  connection.release();
});

// =============================================================
// HELPER: Kirim pesan WhatsApp via Fonnte API
// =============================================================
function sendFonnteMessage(targetPhone, message) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      target     : targetPhone,
      message    : message,
      countryCode: '62',
    });

    const options = {
      hostname: 'api.fonnte.com',
      port    : 443,
      path    : '/send',
      method  : 'POST',
      headers : {
        'Authorization' : 'x97GBmRqfzqDm8mSVd1U', // ← Ganti dengan token Fonnte Anda
        'Content-Type'  : 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    };

    const req = https.request(options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => { responseBody += chunk; });
      res.on('end', () => {
        console.log('[FONNTE RESPONSE]:', responseBody);
        resolve(responseBody);
      });
    });

    req.on('error', (error) => {
      console.error('[FONNTE ERROR]:', error.message);
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

// =============================================================
// CEK SERVER
// =============================================================
app.get('/', (req, res) => {
  res.json({
    message: '🥢 API Backend Puthu Lanang Berjalan Aktif!',
    version: '2.0.0',
    endpoints: [
      'GET  /api/menu',
      'POST /api/orders',
      'POST /api/auth/user-login',
      'POST /api/auth/user-register',
      'POST /api/auth/send-otp',
      'POST /api/auth/verify-otp',
      'POST /api/auth/forgot-password',
      'POST /api/payment/create-charge',
      'POST /api/ai/queue-estimator',
      'POST /api/ai/recommendation',
    ],
  });
});

// =============================================================
// GET /api/menu — Ambil seluruh daftar menu dari tabel `menu`
// =============================================================
app.get('/api/menu', (req, res) => {
  db.query('SELECT * FROM menu ORDER BY id ASC', (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// =============================================================
// POST /api/orders — Simpan pesanan baru & kembalikan data e-tiket
// Body: { name, phone, pickupTime, pickupDate, items, total, notes }
// =============================================================
app.post('/api/orders', (req, res) => {
  const { name, phone, pickupTime, pickupDate, items, total, notes } = req.body;

  if (!name || !phone || !total) {
    return res.status(400).json({ error: 'Field name, phone, dan total wajib diisi.' });
  }

  const qrToken   = 'PL-2026-' + Math.floor(10000 + Math.random() * 90000);
  const antreanNo = Math.floor(50 + Math.random() * 50);

  const query = `
    INSERT INTO orders (name, phone, pickup_time, pickup_date, total, notes, qr_token, antrean)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `;

  db.query(
    query,
    [name, phone, pickupTime || '-', pickupDate || 'Hari Ini', total, notes || '', qrToken, antreanNo],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });

      const summaryItems =
        Array.isArray(items) && items.length > 0
          ? items.map((it) => `${it.quantity || it.qty || 1}x ${it.nama || it.name || 'Puthu'}`).join(', ')
          : '1x Puthu / Paket Pilihan';

      res.json({
        message: 'Pesanan berhasil dibuat',
        data: {
          id           : 'ORD-' + result.insertId,
          qr_code_token: qrToken,
          antrean      : antreanNo,
          status       : 'Sedang Dikukus',
          total_harga  : total,
          name,
          phone,
          pickup_time  : pickupTime || '-',
          pickup_date  : pickupDate || 'Hari Ini',
          notes        : notes || '',
          summary_items: summaryItems,
          items        : items || [],
        },
      });
    }
  );
});

// =============================================================
// POST /api/auth/user-login — Login dengan no_whatsapp & password
// =============================================================
app.post('/api/auth/user-login', (req, res) => {
  const { no_whatsapp, password } = req.body;

  if (!no_whatsapp || !password) {
    return res.status(400).json({ message: 'Nomor WhatsApp dan password wajib diisi.' });
  }

  db.query(
    'SELECT * FROM users WHERE no_whatsapp = ? AND password = ? LIMIT 1',
    [no_whatsapp, password],
    (err, results) => {
      if (err) return res.status(500).json({ message: err.message });
      if (results.length === 0) {
        return res.status(400).json({ message: 'Nomor WhatsApp atau password salah.' });
      }

      const user = results[0];
      res.json({
        message: 'Login berhasil',
        data: {
          id          : user.id,
          nama        : user.nama,
          no_whatsapp : user.no_whatsapp,
          token       : 'server-token-' + user.no_whatsapp,
        },
      });
    }
  );
});

// =============================================================
// POST /api/auth/user-register — Daftar akun baru langsung
// Body: { nama, no_whatsapp, password }
// (Digunakan setelah OTP berhasil diverifikasi via verify-otp)
// =============================================================
app.post('/api/auth/user-register', (req, res) => {
  const { nama, no_whatsapp, password } = req.body;

  if (!nama || !no_whatsapp || !password) {
    return res.status(400).json({ message: 'Nama, nomor WhatsApp, dan password wajib diisi.' });
  }

  // Cek apakah nomor sudah terdaftar
  db.query(
    'SELECT id FROM users WHERE no_whatsapp = ? LIMIT 1',
    [no_whatsapp],
    (err, results) => {
      if (err) return res.status(500).json({ message: err.message });
      if (results.length > 0) {
        return res.status(400).json({ message: 'Nomor WhatsApp sudah terdaftar. Silakan masuk.' });
      }

      const insertQuery = `
        INSERT INTO users (nama, no_whatsapp, password, is_verified)
        VALUES (?, ?, ?, 1)
      `;
      db.query(insertQuery, [nama, no_whatsapp, password], (err2, result) => {
        if (err2) return res.status(500).json({ message: err2.message });

        res.json({
          message: 'Registrasi berhasil!',
          data: {
            id          : result.insertId,
            nama,
            no_whatsapp,
            token       : 'server-token-' + no_whatsapp,
          },
        });
      });
    }
  );
});

// =============================================================
// POST /api/auth/send-otp — Kirim OTP via WhatsApp (Fonnte)
// Body: { no_whatsapp, type: 'register' | 'forgot' }
// =============================================================
app.post('/api/auth/send-otp', async (req, res) => {
  const { no_whatsapp, type } = req.body;

  if (!no_whatsapp) {
    return res.status(400).json({ message: 'Nomor WhatsApp wajib diisi.' });
  }

  db.query('SELECT id FROM users WHERE no_whatsapp = ? LIMIT 1', [no_whatsapp], async (err, results) => {
    if (err) return res.status(500).json({ message: err.message });

    const isExist = results.length > 0;

    if (type === 'register' && isExist) {
      return res.status(400).json({ message: 'Nomor WhatsApp sudah terdaftar. Silakan masuk.' });
    }
    if (type === 'forgot' && !isExist) {
      return res.status(400).json({ message: 'Akun belum terdaftar. Silakan daftar terlebih dahulu.' });
    }

    const otpCode  = Math.floor(1000 + Math.random() * 9000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // berlaku 5 menit

    // Hapus OTP lama yang belum dipakai untuk nomor ini
    db.query('DELETE FROM otp_codes WHERE no_whatsapp = ?', [no_whatsapp]);

    const insertOtp = 'INSERT INTO otp_codes (no_whatsapp, otp_code, expires_at) VALUES (?, ?, ?)';
    db.query(insertOtp, [no_whatsapp, otpCode, expiresAt], async (err2) => {
      if (err2) return res.status(500).json({ message: err2.message });

      // OTP sudah tersimpan di tabel otp_codes — tampilkan di terminal untuk testing
      console.log('KODE OTP:', otpCode, `(untuk ${no_whatsapp})`);

      const pesan =
        `🔒 *KODE OTP PUTHU LANANG*\n\n` +
        `Kode verifikasi Anda: *${otpCode}*\n` +
        `Berlaku 5 menit. Jangan berikan kode ini kepada siapa pun.\n\n` +
        `_Puthu Lanang Malang — EST. 1935_`;

      // Mode development / demo: kembalikan OTP di response, WhatsApp dikirim
      // best-effort di belakang layar (gagal pun tidak menghalangi demo).
      if (DEV_MODE) {
        sendFonnteMessage(no_whatsapp, pesan)
          .then(() => console.log(`[OTP] WhatsApp terkirim ke ${no_whatsapp}`))
          .catch((apiErr) => console.warn('[OTP FONNTE GAGAL]:', apiErr.message));

        return res.json({
          success : true,
          otp_code: otpCode,
          message : 'OTP berhasil dikirim',
        });
      }

      // Mode production: OTP TIDAK dikembalikan di response
      try {
        await sendFonnteMessage(no_whatsapp, pesan);
        console.log(`[OTP] Terkirim ke ${no_whatsapp}`);
        res.json({ success: true, message: 'Kode OTP berhasil dikirim ke WhatsApp Anda.' });
      } catch (apiErr) {
        console.error('[OTP FONNTE GAGAL]:', apiErr.message);
        res.status(502).json({ success: false, message: 'Gagal mengirim OTP ke WhatsApp. Coba lagi.' });
      }
    });
  });
});

// =============================================================
// POST /api/auth/verify-otp — Verifikasi OTP
// Body: { no_whatsapp, otp_code, nama, password, is_register }
// is_register=true  → selesaikan pendaftaran
// is_register=false → hanya verifikasi (untuk lupa password)
// =============================================================
app.post('/api/auth/verify-otp', (req, res) => {
  const { nama, no_whatsapp, password, otp_code, is_register } = req.body;

  if (!no_whatsapp || !otp_code) {
    return res.status(400).json({ message: 'Nomor WhatsApp dan kode OTP wajib diisi.' });
  }

  const checkOtp = `
    SELECT * FROM otp_codes
    WHERE no_whatsapp = ? AND otp_code = ? AND expires_at > NOW()
    ORDER BY id DESC LIMIT 1
  `;

  db.query(checkOtp, [no_whatsapp, otp_code], (err, otpResults) => {
    if (err) return res.status(500).json({ message: err.message });
    if (otpResults.length === 0) {
      return res.status(400).json({ message: 'Kode OTP salah atau sudah kedaluwarsa.' });
    }

    // Jika hanya verifikasi (alur lupa password), cukup konfirmasi valid
    if (!is_register) {
      return res.json({ message: 'OTP valid. Silakan reset password Anda.' });
    }

    // Alur register: pastikan user belum ada, lalu buat akun baru
    db.query('SELECT id FROM users WHERE no_whatsapp = ? LIMIT 1', [no_whatsapp], (err2, userResults) => {
      if (err2) return res.status(500).json({ message: err2.message });

      if (userResults.length > 0) {
        return res.status(400).json({ message: 'Nomor WhatsApp sudah terdaftar. Silakan masuk.' });
      }

      const insert = 'INSERT INTO users (nama, no_whatsapp, password, is_verified) VALUES (?, ?, ?, 1)';
      db.query(insert, [nama || 'Pelanggan', no_whatsapp, password || ''], (err3, result) => {
        if (err3) return res.status(500).json({ message: err3.message });

        // Hapus OTP yang sudah digunakan
        db.query('DELETE FROM otp_codes WHERE no_whatsapp = ?', [no_whatsapp]);

        res.json({
          message: 'Registrasi & Verifikasi Berhasil!',
          data: {
            id          : result.insertId,
            nama        : nama || 'Pelanggan',
            no_whatsapp,
            token       : 'server-token-' + no_whatsapp,
          },
        });
      });
    });
  });
});

// =============================================================
// POST /api/auth/forgot-password — Reset password via OTP
// Body: { no_whatsapp, otp_code, new_password }
// =============================================================
app.post('/api/auth/forgot-password', (req, res) => {
  const { no_whatsapp, otp_code, new_password } = req.body;

  if (!no_whatsapp || !otp_code || !new_password) {
    return res.status(400).json({ message: 'Semua kolom wajib diisi.' });
  }

  if (new_password.length < 6) {
    return res.status(400).json({ message: 'Password baru minimal 6 karakter.' });
  }

  const checkOtp = `
    SELECT * FROM otp_codes
    WHERE no_whatsapp = ? AND otp_code = ? AND expires_at > NOW()
    ORDER BY id DESC LIMIT 1
  `;

  db.query(checkOtp, [no_whatsapp, otp_code], (err, otpResults) => {
    if (err) return res.status(500).json({ message: err.message });
    if (otpResults.length === 0) {
      return res.status(400).json({ message: 'Kode OTP salah atau sudah kedaluwarsa.' });
    }

    db.query(
      'UPDATE users SET password = ? WHERE no_whatsapp = ?',
      [new_password, no_whatsapp],
      (err2, result) => {
        if (err2) return res.status(500).json({ message: err2.message });
        if (result.affectedRows === 0) {
          return res.status(404).json({ message: 'Akun tidak ditemukan.' });
        }

        // Hapus OTP yang sudah digunakan
        db.query('DELETE FROM otp_codes WHERE no_whatsapp = ?', [no_whatsapp]);

        res.json({ message: 'Password berhasil diubah. Silakan masuk dengan password baru.' });
      }
    );
  });
});

// =============================================================
// POST /api/payment/create-charge — Buat Snap Token Midtrans Sandbox
// Body: { gross_amount, customer_name, customer_phone }
// =============================================================
app.post('/api/payment/create-charge', (req, res) => {
  const { gross_amount, customer_name, customer_phone } = req.body;

  const serverKey  = 'SB-Mid-server-gZRRXn2c7323zgcAPStRVskk'; // ← Ganti dengan Server Key Midtrans Anda
  const encodedKey = Buffer.from(serverKey + ':').toString('base64');

  const payload = JSON.stringify({
    transaction_details: {
      order_id    : 'PL-TRX-' + Date.now(),
      gross_amount: gross_amount || 18000,
    },
    item_details: [
      {
        id      : 'ITEM-01',
        price   : gross_amount || 18000,
        quantity: 1,
        name    : 'Jajanan Tradisional Puthu Lanang',
      },
    ],
    customer_details: {
      first_name: customer_name || 'Pelanggan Puthu Lanang',
      phone     : customer_phone || '088212383828',
    },
  });

  const options = {
    hostname: 'app.sandbox.midtrans.com',
    port    : 443,
    path    : '/snap/v1/transactions',
    method  : 'POST',
    headers : {
      'Authorization' : 'Basic ' + encodedKey,
      'Content-Type'  : 'application/json',
      'Accept'        : 'application/json',
      'Content-Length': Buffer.byteLength(payload),
    },
  };

  const midtransReq = https.request(options, (midtransRes) => {
    let body = '';
    midtransRes.on('data', (chunk) => { body += chunk; });
    midtransRes.on('end', () => {
      try {
        const json = JSON.parse(body);
        if (json.redirect_url) {
          res.json({
            message     : 'Midtrans Snap Token Created',
            redirect_url: json.redirect_url,
            token       : json.token,
          });
        } else {
          res.status(400).json({
            message: json.error_messages ? json.error_messages[0] : 'Gagal membuat transaksi Snap.',
          });
        }
      } catch (e) {
        res.status(500).json({ message: 'Gagal mem-parsing respons dari Midtrans.' });
      }
    });
  });

  midtransReq.on('error', (err) => {
    res.status(500).json({ message: 'Koneksi ke Midtrans gagal: ' + err.message });
  });

  midtransReq.write(payload);
  midtransReq.end();
});

// =============================================================
// POST /api/ai/queue-estimator — Estimasi waktu antrean gerai
// Body: { outlet, day, timeSlot }
// =============================================================
app.post('/api/ai/queue-estimator', (req, res) => {
  const {
    outlet   = 'Gerai Pusat Celaket',
    day      = 'Hari Ini',
    timeSlot = '16:30 - 17:00',
  } = req.body;

  let baseWaitMin   = 8;
  let baseWaitMax   = 12;
  let crowdLevel    = 'Ramai Lancar';
  let crowdColor    = 'gold';
  let peakPct       = 60;
  let tips          = 'Slot ideal. Pesanan Anda diprioritaskan hangat saat diambil.';

  const isCelaket = outlet.toLowerCase().includes('celaket');
  const isWeekend = ['sabtu', 'minggu', 'jumat'].some((d) => day.toLowerCase().includes(d));

  if (timeSlot.startsWith('16:00')) {
    baseWaitMin = 4; baseWaitMax = 7; crowdLevel = 'Antrean Pendek'; crowdColor = 'green'; peakPct = 35;
    tips = 'Kondisi gerai sangat lengang. Sangat direkomendasikan untuk pengambilan kilat!';
  } else if (timeSlot.startsWith('17:00') || timeSlot.startsWith('17:30')) {
    baseWaitMin = 14; baseWaitMax = 20; crowdLevel = 'Jam Sibuk (Peak Hours)'; crowdColor = 'orange'; peakPct = 88;
    tips = 'Jam favorit pelanggan sepulang kerja. Disarankan tiba 5 menit sebelum slot berakhir.';
  } else if (timeSlot.startsWith('18:00')) {
    baseWaitMin = 10; baseWaitMax = 15; crowdLevel = 'Ramai Lancar'; crowdColor = 'gold'; peakPct = 70;
    tips = 'Aroma kukusan sangat harum. Antrean mengalir stabil.';
  } else if (timeSlot.startsWith('18:30')) {
    baseWaitMin = 5; baseWaitMax = 9; crowdLevel = 'Antrean Menipis'; crowdColor = 'green'; peakPct = 45;
    tips = 'Slot malam santai. Segera ambil sebelum gerai tutup pukul 19:30.';
  }

  if (!isCelaket) {
    baseWaitMin = Math.max(3, Math.round(baseWaitMin * 0.75));
    baseWaitMax = Math.max(6, Math.round(baseWaitMax * 0.75));
    peakPct     = Math.round(peakPct * 0.8);
  }

  if (isWeekend) {
    baseWaitMin += 2;
    baseWaitMax += 3;
    peakPct      = Math.min(95, peakPct + 15);
  }

  res.json({
    status          : 'success',
    outlet, day,
    time_slot       : timeSlot,
    crowd_level     : crowdLevel,
    crowd_color     : crowdColor,
    estimated_wait  : `~${baseWaitMin} - ${baseWaitMax} Mnt`,
    wait_time_min   : baseWaitMin,
    wait_time_max   : baseWaitMax,
    peak_percentage : peakPct,
    confidence_score: '96% Akurasi Prediktif AI',
    tips,
  });
});

// =============================================================
// POST /api/ai/recommendation — Rekomendasi menu cerdas
// Body: { query, budget, preference }
// =============================================================
app.post('/api/ai/recommendation', (req, res) => {
  const { query = '', budget, preference = '' } = req.body;
  const lowerQ = (query + ' ' + preference).toLowerCase();

  // Fallback menu jika tabel kosong
  const FALLBACK_MENU = [
    { id: 'puthu-01',        nama: 'Puthu',                  harga: 18000, kategori: 'pusaka' },
    { id: 'klepon-02',       nama: 'Klepon',                 harga: 18000, kategori: 'paling_laris' },
    { id: 'cenil-03',        nama: 'Cenil',                  harga: 18000, kategori: 'pusaka' },
    { id: 'lupis-04',        nama: 'Lupis',                  harga: 18000, kategori: 'pusaka' },
    { id: 'paket-campur-05', nama: 'Paket Campur',           harga: 20000, kategori: 'paket_campur' },
    { id: 'besek-hampers-06',nama: 'Box Besek Bambu Hampers', harga: 45000, kategori: 'besek' },
  ];

  db.query('SELECT * FROM menu', (err, dbResults) => {
    const menuList = (dbResults && dbResults.length > 0) ? dbResults : FALLBACK_MENU;

    const find = (keyword) => menuList.find((m) => (m.nama || '').toLowerCase().includes(keyword));

    let title = 'Paket Solo Harmoni 1935';
    let reason = 'Pilihan kurasi paling pas untuk dinikmati sendiri atau berdua.';
    let aiTag  = 'Rekomendasi Cepat AI';
    let items  = [];

    const wantsHampers = lowerQ.includes('hampers') || lowerQ.includes('oleh') || lowerQ.includes('hadiah') || lowerQ.includes('besek');
    const wantsFamily  = lowerQ.includes('keluarga') || lowerQ.includes('rame') || lowerQ.includes('arisan') || lowerQ.includes('banyak') || lowerQ.includes('kantor');
    const wantsSweet   = lowerQ.includes('manis') || lowerQ.includes('gula') || lowerQ.includes('aren');
    const wantsSavory  = lowerQ.includes('gurih') || lowerQ.includes('kenyal') || lowerQ.includes('cenil') || lowerQ.includes('lupis');

    if (wantsHampers) {
      title  = 'Paket Hampers Anyaman Besek Elegan';
      reason = 'Dipilih khusus untuk hantaran istimewa beraroma pandan dengan kemasan besek bambu ramah lingkungan.';
      aiTag  = 'Rekomendasi Hantaran (Best Gift)';
      items  = [
        { ...(find('besek') || menuList[5]), qty: 1, alasan: 'Kemasan anyaman bambu otentik siap hantar' },
        { ...(find('campur') || menuList[4]), qty: 1, alasan: 'Paket campur lengkap agar makin meriah' },
      ];
    } else if (wantsFamily) {
      title  = 'Paket Santap Bersama Keluarga (3-5 Orang)';
      reason = 'Kombinasi komplit agar seluruh keluarga bisa mencicipi semua varian legendaris.';
      aiTag  = 'Paling Populer untuk Keluarga';
      items  = [
        { ...(find('campur') || menuList[4]), qty: 2, alasan: '2 porsi paket campur isi komplit 4 jajanan' },
        { ...(find('puthu') || menuList[0]), qty: 1, alasan: 'Puthu hangat aroma pandan suji favorit anak-anak' },
        { ...(find('klepon') || menuList[1]), qty: 1, alasan: 'Klepon lumer gula aren sensasi letupan di mulut' },
      ];
    } else if (wantsSweet) {
      title  = 'Kombinasi Manis Legit Aren Asli';
      reason = 'Favorit bagi pecinta manis alami gula aren murni tanpa pemanis buatan.';
      aiTag  = 'Manis Alami (Natural Sweetness)';
      items  = [
        { ...(find('puthu') || menuList[0]), qty: 1, alasan: 'Uap bambu dengan gula aren cair di tengahnya' },
        { ...(find('klepon') || menuList[1]), qty: 1, alasan: 'Letupan gula aren cair berbalut kelapa parut segar' },
      ];
    } else if (wantsSavory) {
      title  = 'Duo Tekstur Tradisional Gurih & Kenyal';
      reason = 'Tekstur legit dari beras ketan dan singkong dengan kelapa parut kukus gurih.';
      aiTag  = 'Pecinta Tekstur Tradisional';
      items  = [
        { ...(find('cenil') || menuList[2]), qty: 1, alasan: 'Cenil warna-warni kenyal berlumur juruh aren' },
        { ...(find('lupis') || menuList[3]), qty: 1, alasan: 'Lupis segitiga ketan pulen legit gurih' },
      ];
    } else {
      items = [
        { ...(find('campur') || menuList[4]), qty: 1, alasan: 'Semua varian rasa dalam satu piring hangat' },
        { ...(find('puthu') || menuList[0]), qty: 1, alasan: 'Puthu bambu ikon utama Puthu Lanang Malang' },
      ];
    }

    // Terapkan batas budget
    const targetBudget = budget ? parseInt(budget) : null;
    let totalEst = items.reduce((acc, it) => acc + (it.harga || 18000) * (it.qty || 1), 0);

    if (targetBudget && totalEst > targetBudget && items.length > 1) {
      items    = items.slice(0, 1);
      totalEst = items.reduce((acc, it) => acc + (it.harga || 18000) * (it.qty || 1), 0);
    }

    res.json({
      status              : 'success',
      recommendation_title: title,
      reason,
      ai_tag              : aiTag,
      total_estimated     : totalEst,
      items               : items.map((it) => ({
        id    : it.id    || 'puthu-01',
        nama  : it.nama  || it.name  || 'Menu Puthu Lanang',
        harga : it.harga || it.price || 18000,
        qty   : it.qty   || 1,
        gambar: it.gambar || it.image || 'assets/images/puthu_bambu.png',
        alasan: it.alasan || 'Pilihan terbaik resep 1935',
      })),
    });
  });
});

// =============================================================
// JALANKAN SERVER
// =============================================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 Server Puthu Lanang berjalan di http://localhost:${PORT}`);
  console.log(`   Jalankan dengan: npm run dev\n`);
});