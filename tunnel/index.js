const express = require('express');
const path = require('path');
const compression = require('compression');
const ngrok = require('@ngrok/ngrok');

const app = express();
const PORT = 8080;
const WEB_BUILD_DIR = path.join(__dirname, '..', 'flutter_app', 'build', 'web');

// Enable gzip / deflate HTTP compression for 4x faster asset loading
app.use(compression());

// Middleware to serve static Flutter web files with correct MIME types & ServiceWorker support
app.use((req, res, next) => {
  res.setHeader('Service-Worker-Allowed', '/');
  if (req.path.toLowerCase().endsWith('.mpeg') || req.path.toLowerCase().endsWith('.mp3')) {
    res.setHeader('Content-Type', 'audio/mpeg');
  }
  next();
});

app.use(express.static(WEB_BUILD_DIR, {
  maxAge: 0,
  setHeaders: (res, filePath) => {
    const lower = filePath.toLowerCase();
    if (lower.endsWith('.js')) {
      res.setHeader('Content-Type', 'application/javascript');
    } else if (lower.endsWith('.mpeg') || lower.endsWith('.mp3')) {
      res.setHeader('Content-Type', 'audio/mpeg');
    }
  }
}));

// Fallback to index.html for SPA routing
app.use((req, res) => {
  res.sendFile(path.join(WEB_BUILD_DIR, 'index.html'));
});

// Start Express HTTP Server
const server = app.listen(PORT, '0.0.0.0', async () => {
  console.log(`[StorePulse Web Server] Local server running at http://0.0.0.0:${PORT}`);
  console.log(`[StorePulse Web Server] Serving static build from: ${WEB_BUILD_DIR}`);

  try {
    const authtoken = process.env.NGROK_AUTHTOKEN || '3Kak4wfhszXyU6wjCR8Btcq4pnB_5y9f2KKXbZ3SMXnJPqgar';
    console.log('[StorePulse Tunnel] Connecting ngrok with authtoken...');

    const listener = await ngrok.forward({
      addr: PORT,
      authtoken: authtoken,
    });

    const publicUrl = listener.url();
    console.log('\n======================================================');
    console.log('🚀 STOREPULSE LIVE PUBLIC URL READY:');
    console.log(publicUrl);
    console.log('======================================================\n');
    console.log('Your friend can open this URL directly in Safari or Chrome!');
  } catch (err) {
    console.error('[StorePulse Tunnel Error]:', err);
  }
});
