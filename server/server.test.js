'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createApp, createMessage, EVENTS, TOPIC } = require('./server');

async function start(t, config) {
  const server = createApp(config).listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  return `http://127.0.0.1:${server.address().port}`;
}

test('Every scenario produces notification + string data for the real topic', () => {
  for (const type of Object.keys(EVENTS)) {
    const message = createMessage(type);
    assert.equal(message.topic, TOPIC);
    assert.equal(message.data.type, type);
    assert.equal(message.notification.title, EVENTS[type].title);
    assert.equal(message.android.notification.channelId, 'lockmachine_alerts');
    assert.ok(Object.values(message.data).every((value) => typeof value === 'string'));
    assert.equal(Object.keys(message.data).length, 10);
    assert.ok(!Number.isNaN(Date.parse(message.data.timestamp)));
    assert.notEqual(message.data.id, createMessage(type).data.id);
  }
  assert.throws(() => createMessage('__proto__'), RangeError);
});

test('Missing credentials never report a successful send and stay private', async (t) => {
  const base = await start(t);
  assert.equal((await (await fetch(`${base}/api/status`)).json()).configured, false);
  const response = await fetch(`${base}/api/events`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ type: 'unauthorized_access' }),
  });
  assert.equal(response.status, 503);
  assert.equal((await fetch(`${base}/serviceAccountKey.json`)).status, 404);
  const home = await fetch(base);
  assert.equal(home.status, 200);
  assert.match(await home.text(), /Simulador de Controle de Acesso/);
});

test('HTTP validates inputs and reports success only after send resolves', async (t) => {
  const sent = [];
  // SDK substitute is confined to tests; production always uses Firebase Admin.
  const base = await start(t, { messaging: { send: async (message) => {
    sent.push(message);
    return 'projects/test/messages/42';
  } } });
  const send = (body, origin) => fetch(`${base}/api/events`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', ...(origin ? { Origin: origin } : {}) }, body,
  });
  assert.equal((await send('{')).status, 400);
  assert.equal((await send(JSON.stringify({ type: '__proto__' }))).status, 400);
  assert.equal((await send(JSON.stringify({ type: 'authorized_access' }), 'https://example.com')).status, 403);
  assert.equal((await send(JSON.stringify({ type: 'authorized_access', extra: 'x'.repeat(3000) }))).status, 413);
  assert.equal(sent.length, 0);
  const response = await send(JSON.stringify({ type: 'unauthorized_access' }));
  assert.equal(response.status, 200);
  assert.equal((await response.json()).messageId, 'projects/test/messages/42');
  assert.equal(sent.length, 1);
  assert.equal(sent[0].data.machineId, 'MAQ-02');
});

test('FCM rejection returns an error instead of fake success', async (t) => {
  const base = await start(t, { messaging: { send: async () => {
    throw Object.assign(new Error('Rejected'), { code: 'messaging/server-unavailable' });
  } } });
  const response = await fetch(`${base}/api/events`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ type: 'blocked_machine' }),
  });
  assert.equal(response.status, 502);
  assert.match((await response.json()).message, /Erro ao enviar evento/);
});
