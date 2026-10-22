// Extensión del mismo servicio publicado en la Práctica 8.
const app = require('./app');
const port = Number(process.env.PORT || 3000);
const version = process.env.APP_VERSION;
app.get('/salud', (_req, res) => res.json({ estado: 'ok', version }));
app.get('/version', (_req, res) => res.json({ version }));
const server = app.listen(port, () => console.log(`API de tareas ${version} en puerto ${port}`));
process.on('SIGTERM', () => server.close(() => process.exit(0)));
