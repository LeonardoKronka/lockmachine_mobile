'use strict';

const buttons = [...document.querySelectorAll('[data-type]')];
const result = document.getElementById('result');
let configured = false;
let sending = false;

function updateButtons() {
  for (const button of buttons) button.disabled = !configured || sending;
}

async function refreshStatus() {
  try {
    const response = await fetch('/api/status', { cache: 'no-store' });
    if (!response.ok) throw new Error('Servidor indisponível.');
    const status = await response.json();
    configured = status.configured === true;
    document.getElementById('status-dot').classList.toggle('ready', configured);
    document.getElementById('connection-title').textContent = configured ? 'Firebase Admin SDK configurado' : 'Aguardando configuração Firebase';
    document.getElementById('connection-detail').textContent = status.message || `Envio para o tópico ${status.topic}. A conexão com o FCM será verificada ao enviar.`;
  } catch {
    configured = false;
    document.getElementById('status-dot').classList.remove('ready');
    document.getElementById('connection-title').textContent = 'Servidor indisponível';
    document.getElementById('connection-detail').textContent = 'Verifique se node server.js está em execução.';
  }
  updateButtons();
}

for (const button of buttons) {
  button.addEventListener('click', async () => {
    if (sending || !configured) return;
    sending = true;
    updateButtons();
    result.className = 'result';
    result.textContent = 'Enviando evento ao Firebase Cloud Messaging…';
    try {
      const response = await fetch('/api/events', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: button.dataset.type }),
        signal: AbortSignal.timeout(30000),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.message || 'Erro ao enviar evento.');
      result.className = 'result ok';
      result.textContent = `${data.message} FCM aceitou a mensagem para ${data.topic}. Confira o tablet. Evento: ${data.eventId}`;
    } catch (error) {
      result.className = 'result error';
      result.textContent = error.name === 'TimeoutError'
        ? 'O servidor não respondeu a tempo. Confira o tablet antes de repetir: o envio pode ter sido concluído.'
        : `Erro ao enviar evento. ${error.message}`;
    } finally {
      sending = false;
      updateButtons();
    }
  });
}

refreshStatus();
setInterval(refreshStatus, 15000);
