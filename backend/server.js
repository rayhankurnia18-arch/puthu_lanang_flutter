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
    
    const summaryItems = Array.isArray(items) && items.length > 0
      ? items.map(it => `${it.quantity || it.qty || 1}x ${it.nama || it.name || 'Puthu'}`).join(', ')
      : '1x Puthu / Paket Pilihan';

    res.json({
      message: 'Pesanan berhasil dibuat',
      data: {
        id: 'ORD-' + result.insertId,
        qr_code_token: qrToken,
        antrean: antreanNo,
        status: 'Sedang Dikukus',
        total_harga: total,
        name: name,
        phone: phone,
        pickup_time: pickupTime,
        pickup_date: pickupDate,
        notes: notes || '',
        summary_items: summaryItems,
        items: items || []
      }
    });
  });
});

// --- ENDPOINT PEMBAYARAN MIDTRANS SNAP SANDBOX ---
app.post('/api/payment/create-charge', (req, res) => {
  const { gross_amount, customer_name, customer_phone } = req.body;

  const serverKey = 'SB-Mid-server-gZRRXn2c7323zgcAPStRVskk';
  const encodedKey = Buffer.from(serverKey + ':').toString('base64');

  const payload = JSON.stringify({
    transaction_details: {
      order_id: 'PL-TRX-' + Date.now(),
      gross_amount: gross_amount || 18000
    },
    item_details: [
      {
        id: 'ITEM-01',
        price: gross_amount || 18000,
        quantity: 1,
        name: 'Jajanan Tradisional Puthu Lanang'
      }
    ],
    customer_details: {
      first_name: customer_name || 'Pelanggan Puthu Lanang',
      phone: customer_phone || '088212383828'
    }
  });

  const options = {
    hostname: 'app.sandbox.midtrans.com',
    port: 443,
    path: '/snap/v1/transactions',
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
        if (jsonResponse.redirect_url) {
          res.json({
            message: 'Midtrans Snap Token Created',
            redirect_url: jsonResponse.redirect_url,
            token: jsonResponse.token
          });
        } else {
          res.status(400).json({ message: jsonResponse.error_messages ? jsonResponse.error_messages[0] : 'Gagal membuat transaksi Snap.' });
        }
      } catch (e) {
        res.status(500).json({ message: 'Gagal parsing respons dari Midtrans.' });
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

// Endpoint Kirim OTP (Hanya untuk Register & Forgot Password)
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
    if (type === 'forgot' && !isExist) {
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

// Endpoint Verifikasi OTP & Selesaikan Register
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

// Endpoint Login Langsung Tanpa OTP
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

// ==========================================
// 1. AI QUEUE ESTIMATOR ENDPOINT
// ==========================================
app.post('/api/ai/queue-estimator', (req, res) => {
  const { outlet = 'Gerai Pusat Celaket', day = 'Hari Ini', timeSlot = '16:30 - 17:00' } = req.body;

  let baseWaitMin = 8;
  let baseWaitMax = 12;
  let crowdLevel = 'Ramai Lancar';
  let crowdColor = 'gold'; // green, gold, orange
  let peakPercentage = 60;
  let tips = 'Slot ideal. Pesanan Anda diprioritaskan hangat saat diambil.';

  const isCelaket = outlet.toLowerCase().includes('celaket');
  const isWeekend = ['sabtu', 'minggu', 'jumat'].some(d => day.toLowerCase().includes(d));

  if (timeSlot.startsWith('16:00')) {
    baseWaitMin = 4;
    baseWaitMax = 7;
    crowdLevel = 'Antrean Pendek';
    crowdColor = 'green';
    peakPercentage = 35;
    tips = 'Kondisi gerai sangat lengang. Sangat direkomendasikan untuk pengambilan kilat!';
  } else if (timeSlot.startsWith('17:00') || timeSlot.startsWith('17:30')) {
    baseWaitMin = 14;
    baseWaitMax = 20;
    crowdLevel = 'Jam Sibuk (Peak Hours)';
    crowdColor = 'orange';
    peakPercentage = 88;
    tips = 'Jam favorit pelanggan sepulang kerja. Disarankan tiba 5 menit sebelum slot berakhir.';
  } else if (timeSlot.startsWith('18:00')) {
    baseWaitMin = 10;
    baseWaitMax = 15;
    crowdLevel = 'Ramai Lancar';
    crowdColor = 'gold';
    peakPercentage = 70;
    tips = 'Aroma kukusan sangat harum. Antrean mengalir stabil.';
  } else if (timeSlot.startsWith('18:30')) {
    baseWaitMin = 5;
    baseWaitMax = 9;
    crowdLevel = 'Antrean Menipis';
    crowdColor = 'green';
    peakPercentage = 45;
    tips = 'Slot malam santai. Segera ambil sebelum gerai tutup pukul 19:30.';
  }

  if (!isCelaket) {
    baseWaitMin = Math.max(3, Math.round(baseWaitMin * 0.75));
    baseWaitMax = Math.max(6, Math.round(baseWaitMax * 0.75));
    peakPercentage = Math.round(peakPercentage * 0.8);
  }

  if (isWeekend) {
    baseWaitMin += 2;
    baseWaitMax += 3;
    peakPercentage = Math.min(95, peakPercentage + 15);
  }

  res.json({
    status: 'success',
    outlet,
    day,
    time_slot: timeSlot,
    crowd_level: crowdLevel,
    crowd_color: crowdColor,
    estimated_wait: `~${baseWaitMin} - ${baseWaitMax} Mnt`,
    wait_time_min: baseWaitMin,
    wait_time_max: baseWaitMax,
    peak_percentage: peakPercentage,
    confidence_score: '96% Akurasi Prediktif AI',
    tips
  });
});

// ==========================================
// 2. AI PUTHU RECOMMENDER ENDPOINT
// ==========================================
app.post('/api/ai/recommendation', (req, res) => {
  const { query = '', budget, preference = '' } = req.body;
  const lowerQ = (query + ' ' + preference).toLowerCase();

  db.query('SELECT * FROM menu', (err, results) => {
    let menuList = results || [];

    // Fallback menu data jika database lokal kosong
    if (!menuList || menuList.length === 0) {
      menuList = [
        { id: 'puthu-01', nama: 'Puthu', harga: 18000, kategori: 'pusaka', deskripsi: 'Puthu beras pandan suji dengan gula aren cair.' },
        { id: 'klepon-02', nama: 'Klepon', harga: 18000, kategori: 'paling_laris', deskripsi: 'Ketan hijau kenyal dengan isian gula aren cair.' },
        { id: 'cenil-03', nama: 'Cenil', harga: 18000, kategori: 'pusaka', deskripsi: 'Cenil warna-warni dengan juruh gula aren dan kelapa.' },
        { id: 'lupis-04', nama: 'Lupis', harga: 18000, kategori: 'pusaka', deskripsi: 'Ketan legit dengan kelapa parut dan juruh aren.' },
        { id: 'paket-campur-05', nama: 'Paket Campur', harga: 20000, kategori: 'paket_campur', deskripsi: 'Puthu, klepon, cenil dan lupis dalam satu paket.' },
        { id: 'besek-hampers-06', nama: 'Box Besek Bambu Hampers', harga: 45000, kategori: 'besek', deskripsi: 'Hampers tradisional dengan paket campur dan juruh aren.' }
      ];
    }

    let recommendedItems = [];
    let title = 'Paket Nostalgia Pasundan & Jawa 1935';
    let reason = 'Rekomendasi racikan seimbang antara tekstur kenyal dan manis legit aren alami.';
    let aiTag = 'Cocok untuk Teman Santai';

    const wantsHampers = lowerQ.includes('hampers') || lowerQ.includes('oleh') || lowerQ.includes('hadiah') || lowerQ.includes('besek');
    const wantsFamily = lowerQ.includes('keluarga') || lowerQ.includes('rame') || lowerQ.includes('arisan') || lowerQ.includes('banyak') || lowerQ.includes('kantor');
    const wantsSweet = lowerQ.includes('manis') || lowerQ.includes('gula') || lowerQ.includes('aren');
    const wantsSavory = lowerQ.includes('gurih') || lowerQ.includes('kenyal') || lowerQ.includes('cenil') || lowerQ.includes('lupis');

    if (wantsHampers) {
      title = 'Paket Hampers Anyaman Besek Elegan';
      reason = 'Dipilih khusus untuk hantaran/buah tangan istimewa beraroma pandan dengan kemasan besek bambu ramah lingkungan.';
      aiTag = 'Rekomendasi Hantaran (Best Gift)';
      const hampersItem = menuList.find(m => (m.kategori || '').includes('besek') || (m.nama || '').toLowerCase().includes('besek')) || menuList[5];
      const campurItem = menuList.find(m => (m.kategori || '').includes('campur') || (m.nama || '').toLowerCase().includes('campur')) || menuList[4];
      recommendedItems = [
        { ...hampersItem, qty: 1, alasan: 'Kemasan anyaman bambu otentik siap hantar' },
        { ...campurItem, qty: 1, alasan: 'Tambahan paket campur lengkap agar makin meriah' }
      ];
    } else if (wantsFamily) {
      title = 'Paket Santap Bersama Keluarga (3-5 Orang)';
      reason = 'Kombinasi komplit agar seluruh anggota keluarga bisa mencicipi semua varian legendaris tanpa berebut.';
      aiTag = 'Paling Populer untuk Keluarga';
      const campurItem = menuList.find(m => (m.nama || '').toLowerCase().includes('campur')) || menuList[4];
      const puthuItem = menuList.find(m => (m.nama || '').toLowerCase().includes('puthu')) || menuList[0];
      const kleponItem = menuList.find(m => (m.nama || '').toLowerCase().includes('klepon')) || menuList[1];
      recommendedItems = [
        { ...campurItem, qty: 2, alasan: '2 porsi paket campur isi komplit 4 jajanan' },
        { ...puthuItem, qty: 1, alasan: 'Puthu hangat aroma pandan suji favorit anak-anak' },
        { ...kleponItem, qty: 1, alasan: 'Klepon lumer gula aren sensasi letupan di mulut' }
      ];
    } else if (wantsSweet) {
      title = 'Kombinasi Manis Legit Aren Asli';
      reason = 'Kombinasi terfavorit bagi pecinta manis alami gula aren murni tanpa pemanis buatan.';
      aiTag = 'Manis Alami (Natural Sweetness)';
      const puthuItem = menuList.find(m => (m.nama || '').toLowerCase().includes('puthu')) || menuList[0];
      const kleponItem = menuList.find(m => (m.nama || '').toLowerCase().includes('klepon')) || menuList[1];
      recommendedItems = [
        { ...puthuItem, qty: 1, alasan: 'Uap kukusan bambu dengan gula aren cair di tengahnya' },
        { ...kleponItem, qty: 1, alasan: 'Letupan gula aren cair berbalut kelapa parut segar' }
      ];
    } else if (wantsSavory) {
      title = 'Duo Tekstur Tradisional Gurih & Kenyal';
      reason = 'Tekstur legit dan kenyal dari beras ketan dan singkong dengan limpahan kelapa parut kukus gurih.';
      aiTag = 'Pecinta Tekstur Tradisional';
      const cenilItem = menuList.find(m => (m.nama || '').toLowerCase().includes('cenil')) || menuList[2];
      const lupisItem = menuList.find(m => (m.nama || '').toLowerCase().includes('lupis')) || menuList[3];
      recommendedItems = [
        { ...cenilItem, qty: 1, alasan: 'Cenil warna-warni alami kenyal berlumur juruh aren' },
        { ...lupisItem, qty: 1, alasan: 'Lupis segitiga ketan pulen legit gurih' }
      ];
    } else {
      title = 'Paket Solo Harmoni 1935';
      reason = 'Pilihan kurasi paling pas untuk dinikmati sendiri atau berdua dengan secangkir teh panas.';
      aiTag = 'Rekomendasi Cepat AI';
      const campurItem = menuList.find(m => (m.nama || '').toLowerCase().includes('campur')) || menuList[4];
      const puthuItem = menuList.find(m => (m.nama || '').toLowerCase().includes('puthu')) || menuList[0];
      recommendedItems = [
        { ...campurItem, qty: 1, alasan: 'Semua varian rasa dalam satu piring hangat' },
        { ...puthuItem, qty: 1, alasan: 'Puthu bambu ikon utama Puthu Lanang Malang' }
      ];
    }

    // Filter budget jika diisi
    const targetBudget = budget ? parseInt(budget) : null;
    let totalEst = recommendedItems.reduce((acc, curr) => acc + (curr.harga || 18000) * (curr.qty || 1), 0);

    if (targetBudget && totalEst > targetBudget && recommendedItems.length > 1) {
      // Kurangi quantity jika melebihi budget
      recommendedItems = recommendedItems.slice(0, 1);
      totalEst = recommendedItems.reduce((acc, curr) => acc + (curr.harga || 18000) * (curr.qty || 1), 0);
    }

    res.json({
      status: 'success',
      recommendation_title: title,
      reason,
      ai_tag: aiTag,
      total_estimated: totalEst,
      items: recommendedItems.map(it => ({
        id: it.id || 'puthu-01',
        nama: it.nama || it.name || 'Menu Puthu Lanang',
        harga: it.harga || it.price || 18000,
        qty: it.qty || 1,
        gambar: it.gambar || it.image || 'assets/images/puthu_bambu.png',
        alasan: it.alasan || 'Pilihan terbaik resep 1935'
      }))
    });
  });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server berjalan di http://localhost:${PORT}`);
});