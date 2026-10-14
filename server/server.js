'use strict';

const express = require('express');
const path = require('node:path');
const fs = require('node:fs');
const { randomUUID } = require('node:crypto');
const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');

const TOPIC = 'lockmachine-supervisores';
const EVENTS = Object.freeze({
  unauthorized_access: {
    title: 'Acesso não autorizado', operatorName: 'Carlos Henrique', operatorId: 'OP-042',
    machineName: 'Prensa Hidráulica 02', machineId: 'MAQ-02',
    reason: 'Operador não possui qualificação para esta máquina.', severity: 'critical',
  },
  expired_qualification: {
    title: 'Qualificação vencida', operatorName: 'João Silva', operatorId: 'OP-017',
    machineName: 'Torno CNC 03', machineId: 'MAQ-03',
    reason: 'Treinamento obrigatório vencido.', severity: 'warning',
  },
  blocked_machine: {
    title: 'Máquina bloqueada', operatorName: 'Marcos Oliveira', operatorId: 'OP-025',
    machineName: 'Fresadora CNC 01', machineId: 'MAQ-01',
    reason: 'Máquina indisponível para operação.', severity: 'critical',
  },
  qualification_expiring: {
    title: 'Treinamento próximo do vencimento', operatorName: 'Lucas Martins', operatorId: 'OP-031',
    machineName: 'Centro de Usinagem 04', machineId: 'MAQ-04',
    reason: 'Qualificação vence em 5 dias.', severity: 'warning',
  },
  authorized_access: {
    title: 'Acesso autorizado', operatorName: 'Ana Souza', operatorId: 'OP-008',
    machineName: 'Torno CNC 01', machineId: 'MAQ-05',
    reason: 'Operador autorizado.', severity: 'success',
  },
});

function createMessage(type) {
  if (!Object.hasOwn(EVENTS, type)) throw new RangeError('Tipo de evento inválido.');
  const data = {
    id: randomUUID(), type, ...EVENTS[type], timestamp: new Date().toISOString(),
  };
  return {
    topic: TOPIC,
    notification: { title: data.title, body: `${data.machineName}: ${data.reason}` },
    data,
    android: {
      priority: 'high',
      notification: {
        channelId: 'lockmachine_alerts', icon: 'ic_stat_lockmachine',
        color: '#E53935', sound: 'default', tag: data.id,
      },
    },
  };
}

function loadMessaging() {
  const keyPath = path.join(__dirname, 'serviceAccountKey.json');
  if (!fs.existsSync(keyPath)) {
    return { messaging: null, error: 'Coloque a Service Account real em server/serviceAccountKey.json e reinicie o servidor.' };
  }
  try {
    const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
    const app = initializeApp({ credential: cert(serviceAccount) });
    return { messaging: getMessaging(app), error: null };
  } catch {
    return { messaging: null, error: 'Não foi possível carregar a Service Account. Verifique o arquivo real e reinicie o servidor.' };
  }
}

function createApp({ messaging = null, error = null } = {}) {
  const app = express();
  app.disable('x-powered-by');
  app.use((req, res, next) => {
    res.setHeader('Content-Security-Policy', "default-src 'self'; style-src 'self'; script-src 'self'; connect-src 'self'; img-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'");
    res.setHeader('X-Content-Type-Options', 'nosniff');
    next();
  });
  app.use(express.json({ limit: '2kb' }));
  app.get('/api/status', (_req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.json({ configured: Boolean(messaging), topic: TOPIC, message: error });
  });
  app.post('/api/events', async (req, res) => {
    // This demonstration runs only on localhost; reject cross-origin browsers.
    if (req.get('origin') && req.get('origin') !== `${req.protocol}://${req.get('host')}`) {
      return res.status(403).json({ message: 'Origem não permitida.' });
    }
    const type = req.body?.type;
    if (typeof type !== 'string' || !Object.hasOwn(EVENTS, type)) {
      return res.status(400).json({ message: 'Tipo de evento inválido.' });
    }
    if (!messaging) {
      return res.status(503).json({ message: error || 'Firebase Admin SDK ainda não configurado.' });
    }
    try {
      const message = createMessage(type);
      const messageId = await messaging.send(message);
      return res.json({ message: 'Evento enviado com sucesso.', messageId, eventId: message.data.id, topic: TOPIC });
    } catch (sendError) {
      console.error('FCM recusou o envio:', sendError.code || 'erro de comunicação');
      return res.status(502).json({ message: 'Erro ao enviar evento. Verifique a Service Account, o projeto Firebase, a API FCM e a conexão do servidor.' });
    }
  });
  // Serve only public/: the Service Account can never be downloaded here.
  app.use(express.static(path.join(__dirname, 'public')));
  app.use((err, _req, res, _next) => {
    if (err.type === 'entity.too.large') return res.status(413).json({ message: 'Requisição muito grande.' });
    if (err instanceof SyntaxError) return res.status(400).json({ message: 'JSON inválido.' });
    return res.status(500).json({ message: 'Erro interno do servidor.' });
  });
  return app;
}

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    console.error('PORT deve ser um número entre 1 e 65535.');
    process.exitCode = 1;
  } else {
    const config = loadMessaging();
    if (config.error) console.warn(config.error);
    const server = createApp(config).listen(port, '127.0.0.1', () => {
      console.log(`LockMachine: http://localhost:${port}`);
      console.log(`Tópico FCM: ${TOPIC}`);
    });
    server.on('error', (error) => {
      console.error('Não foi possível iniciar o servidor:', error.code);
      process.exitCode = 1;
    });
  }
}

module.exports = { createApp, createMessage, EVENTS, TOPIC };
