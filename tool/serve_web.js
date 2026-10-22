// Serves the release web build (build/web) so it can be shared, e.g. through
// VS Code's Ports panel / dev tunnels.
//
//   flutter build web
//   node tool/serve_web.js            # http://localhost:8080
//   node tool/serve_web.js 3000       # custom port
//
// Unlike `flutter run -d chrome`, this keeps running when browser windows
// close and doesn't need a debugger connection, so forwarded ports work.
// No dependencies — plain Node.

const http = require('http');
const fs = require('fs');
const path = require('path');

const port = Number(process.argv[2] || process.env.PORT || 8080);
const root = path.resolve(__dirname, '..', 'build', 'web');

if (!fs.existsSync(path.join(root, 'index.html'))) {
  console.error(`No build found in ${root}\nRun "flutter build web" first.`);
  process.exit(1);
}

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
  '.bin': 'application/octet-stream',
  '.frag': 'application/octet-stream',
};

const server = http.createServer((req, res) => {
  let urlPath;
  try {
    urlPath = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  } catch {
    res.writeHead(400).end('Bad request');
    return;
  }

  // Resolve inside build/web only (no "../" escapes).
  let file = path.normalize(path.join(root, urlPath));
  if (file !== root && !file.startsWith(root + path.sep)) {
    res.writeHead(403).end('Forbidden');
    return;
  }
  if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
  // Unknown paths fall back to the app shell so deep links still load.
  if (!fs.existsSync(file)) file = path.join(root, 'index.html');

  const ext = path.extname(file).toLowerCase();
  const isEntry = ['.html', '.json'].includes(ext) || /flutter_(bootstrap|service_worker)\.js$/.test(file);
  res.writeHead(200, {
    'Content-Type': types[ext] || 'application/octet-stream',
    // Always pick up a fresh build; static assets can be cached briefly.
    'Cache-Control': isEntry ? 'no-cache' : 'public, max-age=3600',
  });
  fs.createReadStream(file).pipe(res);
  console.log(`${new Date().toLocaleTimeString()}  ${req.method} ${req.url}`);
});

server.on('error', (e) => {
  console.error(e.code === 'EADDRINUSE' ? `Port ${port} is already in use.` : e.message);
  process.exit(1);
});

// 0.0.0.0 = reachable from port forwarding and other devices, not just localhost.
server.listen(port, '0.0.0.0', () => {
  console.log(`Serving ${root}\n  Local:   http://localhost:${port}\n  Forward port ${port} to share it.`);
});
