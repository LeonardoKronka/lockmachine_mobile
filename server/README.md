# Servidor de Push LockMachine

Simulador local de controle de acesso industrial. O painel envia eventos reais pelo Firebase Admin SDK para o tópico `lockmachine-supervisores`.

## Preparar e executar

Use Node.js 22 ou superior. Baixe a Service Account real do mesmo projeto Firebase configurado no Android e salve-a em `server/serviceAccountKey.json`. Nunca compartilhe a chave no chat, nem a coloque no Flutter ou em `public/`. O arquivo é ignorado pelo Git.

```powershell
cd server
npm install
node server.js
```

Abra http://localhost:3000 no notebook. O servidor escuta somente `127.0.0.1`; o tablet recebe as mensagens pelo FCM, sem acessar o notebook. Sem credenciais o painel continua acessível, mas os envios ficam indisponíveis. Reinicie o servidor após inserir a chave.

É necessário habilitar a Firebase Cloud Messaging API (HTTP v1), permitir o envio para a Service Account e usar o mesmo projeto no app. Abra o aplicativo Android e confirme que ele está inscrito no tópico antes do envio.

## Endpoints

- `GET /`: painel de simulação.
- `GET /api/status`: informa se a credencial foi carregada; não garante conectividade FCM.
- `POST /api/events`: aceita JSON com `type` igual a um dos cinco tipos abaixo.

```json
{ "type": "unauthorized_access" }
```

Tipos aceitos: `unauthorized_access`, `expired_qualification`, `blocked_machine`, `qualification_expiring`, `authorized_access`.

O servidor cria UUID e timestamp ISO UTC, envia `notification + data` com todos os campos string e prioridade Android alta pelo canal `lockmachine_alerts`. Só retorna “Evento enviado com sucesso.” depois de `messaging.send()` resolver. Isso confirma aceitação pelo FCM, não entrega ao dispositivo.

Erros HTTP: 400 para JSON/tipo inválido, 403 para navegador de outra origem, 413 para corpo excessivo, 503 sem Service Account e 502 se o FCM recusar o envio. Apenas `public/` é servido estaticamente. Não há API completa, autenticação ou persistência nesta demonstração local.

## Verificar

```powershell
node --check server.js
node --check public/app.js
npm test
```

Os testes de contrato e HTTP usam um substituto do SDK apenas dentro de `server.test.js`. O servidor real não possui modo de Push fake.

Consulte o [README principal](../README.md) para configuração FlutterFire, execução no tablet, diferenças entre Local e Push e roteiro da apresentação. Referência oficial: [Firebase Admin SDK e FCM](https://firebase.google.com/docs/cloud-messaging/send/admin-sdk).
