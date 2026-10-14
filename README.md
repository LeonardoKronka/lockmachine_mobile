# LockMachine Mobile

Central de Alertas de um supervisor de máquinas industriais, desenvolvida para a atividade de PDM do SENAI sobre Push Notifications e relacionada ao Projeto Integrador/TCC LockMachine.

O aplicativo recebe **Push reais pelo Firebase Cloud Messaging (FCM)**. O simulador Node.js representa eventos de controle de acesso; ele não simula a entrega da Push. A demonstração local é identificada separadamente.

## Objetivo e arquitetura

No sistema conceitual:

```text
Cartão RFID → LockMachine → Servidor → Firebase Cloud Messaging → App do Supervisor
```

Na demonstração implementada:

```text
Painel no notebook → Express → Firebase Admin SDK → FCM
                                                    ↓
                                      tópico lockmachine-supervisores
                                                    ↓
                                      tablet Android → notificação → detalhes
```

RFID, ESP32, Arduino, autenticação, cadastros, banco de dados e uma API de negócio completa estão fora desta etapa. Os cinco eventos têm operadores e máquinas didáticos, mas os alertas exibidos no app vêm do payload recebido.

```text
lib/
  main.dart                          Tema Material 3 e navegação
  models/lockmachine_alert.dart       Conversão segura do payload
  screens/home_screen.dart           Central de alertas responsiva
  screens/alert_detail_screen.dart    Detalhes do evento recebido
  services/notification_service.dart FCM, permissões, canal e histórico
  widgets/alert_card.dart             Resumo de alerta
  widgets/status_card.dart            Estado real de registro FCM
  widgets/notification_flow.dart      Fluxo educativo
server/
  server.js                          Express e Firebase Admin SDK
  package.json / package-lock.json    Dependências Node.js
  public/index.html                  Painel de simulação
  public/app.js / styles.css          Interação e aparência do painel
  server.test.js                     Verificação HTTP e contrato FCM
  .gitignore / README.md
```

O nome interno do pacote Dart (`push_notification`) e o identificador Android (`com.example.push_notification`) foram preservados. O nome visível é **LockMachine Mobile**. Android é a plataforma implementada nesta etapa; os diretórios das outras plataformas originais permanecem no projeto, mas não foram configurados para Push.

## Dependências e requisitos

Flutter e Dart compatíveis com o `pubspec.yaml` (Dart `^3.12.2`); Android SDK 36, Java 17 e tablet Android 7/API 24 ou superior com Google Play Services. O Gradle usa os valores do SDK Flutter instalado. Node.js 22 ou superior.

- `firebase_core ^4.15.0`: inicialização Firebase.
- `firebase_messaging ^16.7.0`: token, tópico, recebimento e clique na Push.
- `flutter_local_notifications ^22.3.1`: canal Android, notificação local e apresentação de Push no foreground.
- `flutter_test` e `flutter_lints`: testes e análise.
- `cupertino_icons`: dependência original preservada.
- Servidor: `express` e `firebase-admin`, com versões resolvidas em `server/package-lock.json`.

No Windows, ative **Modo de Desenvolvedor** se o Flutter informar que os plugins precisam de suporte a links simbólicos. Essa configuração é do notebook usado para compilar, não do tablet.

## Conceitos para a apresentação

**Notificação local:** criada pelo próprio aplicativo; não precisa de servidor. O botão “Testar notificação local” cria uma notificação Android real e registra um evento identificado como LOCAL, sem inventar uma Push.

**Push Notification:** enviada pelo servidor a um serviço de Push. O servidor deste projeto chama `Firebase Admin SDK → FCM`; o Android recebe a mensagem. No foreground, o app usa uma notificação local apenas para tornar a Push recebida visível. A origem desse evento continua sendo o servidor.

**FCM Token:** identifica uma instalação do aplicativo. Pode mudar, por isso o serviço acompanha `onTokenRefresh`. É mostrado e pode ser copiado para fins educativos; o simulador usa o tópico como destino principal.

**Tópico FCM:** grupo de instalações inscritas. O app chama automaticamente `subscribeToTopic('lockmachine-supervisores')`, e o servidor envia para o mesmo tópico. Abra o app e confirme a inscrição antes de enviar o primeiro evento.

“Sistema conectado” significa que o Firebase foi inicializado, um token foi obtido e a inscrição no tópico foi concluída. Não é um monitor de conectividade contínua. Permissão de notificações e inscrição são mostradas separadamente; o Android pode bloquear a exibição mesmo com token válido.

## Configuração Firebase — ação externa necessária

Não existe `firebase_options.dart` inventado, `google-services.json` fictício nem Service Account neste repositório. Antes da configuração, a interface funciona e o teste local pode ser usado no Android; o status mostra que o Firebase está pendente.

1. Crie ou selecione um projeto real no [Firebase Console](https://console.firebase.google.com/).
2. Instale as ferramentas oficiais, se ainda não estiverem disponíveis:

```powershell
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

3. Na raiz deste projeto execute exatamente:

```powershell
flutterfire configure
```

Selecione seu projeto e a plataforma **Android**. Use o aplicativo Android com package name `com.example.push_notification`. Se a CLI não estiver no PATH, use `dart pub global run flutterfire_cli:flutterfire configure`.

4. Confirme que o processo oficial gerou `lib/firebase_options.dart` e `android/app/google-services.json`. Se a CLI não produzir o JSON Android, baixe a configuração cliente do mesmo app pelo Firebase Console e coloque-a em `android/app/google-services.json`. Nunca crie valores fictícios.
5. O plugin Google Services já está declarado no Gradle e é aplicado quando o JSON real está presente. Ele converte o JSON em recursos nativos; **esta implementação Android usa `Firebase.initializeApp()` sem opções explícitas**, lendo esses recursos tanto no app quanto no handler de background. Por isso não importa um arquivo inexistente antes da configuração. O `firebase_options.dart` oficialmente gerado pode permanecer no projeto; ele não é necessário nesse caminho Android. Outras plataformas exigiriam usar as opções oficiais e configuração específica.
6. Garanta que a **Firebase Cloud Messaging API (HTTP v1)** esteja habilitada no projeto e que a Service Account possa enviar mensagens pelo FCM.
7. Recompile/reinstale o app após configurar o Firebase. Hot reload não aplica mudanças na configuração Android.

Referência: [Configuração oficial FlutterFire](https://firebase.google.com/docs/flutter/setup) e [configuração Android Firebase](https://firebase.google.com/docs/android/setup).

## Service Account — somente no servidor

No Firebase Console, abra **Configurações do projeto → Contas de serviço → Firebase Admin SDK → Gerar nova chave privada**. Baixe o arquivo real do **mesmo projeto** usado pelo aplicativo e salve localmente como:

```text
server/serviceAccountKey.json
```

Não cole a chave no chat e não a coloque em `lib/`, `android/`, `assets/` ou `server/public/`. A chave concede acesso administrativo ao projeto. Os `.gitignore` da raiz e do servidor excluem esse arquivo, `.env` e `node_modules/`.

O Express publica exclusivamente `server/public/`; a Service Account não é servida ao navegador. Nenhuma credencial administrativa fica no Flutter ou no HTML. A configuração cliente normal do Firebase é diferente da Service Account e pode ser usada no app.

## Executar o servidor

```powershell
cd server
npm install
node server.js
```

Abra **http://localhost:3000** no notebook. O servidor escuta somente `127.0.0.1`, adequado para esta demonstração local sem login. O tablet não precisa acessar o notebook: recebe a Push pela internet, através do FCM. Notebook e tablet precisam de conexão com a internet.

Sem a Service Account, o painel abre, mostra a configuração pendente e os envios retornam erro 503. Depois de colocar a chave, reinicie o servidor. A indicação “Firebase Admin SDK configurado” confirma o carregamento da credencial; a conexão e a autorização para enviar são verificadas no envio real.

Para mudar a porta no PowerShell: `$env:PORT = '3001'` e depois `node server.js`. A porta padrão é 3000. Encerre com Ctrl+C.

Os cenários disponíveis são acesso sem qualificação, qualificação vencida, máquina bloqueada, treinamento próximo do vencimento e acesso autorizado.

## Executar no tablet Android

```powershell
flutter pub get
flutter devices
flutter run -d ID_DO_TABLET
```

`ID_DO_TABLET` deve ser substituído pelo identificador real listado por `flutter devices`. Ative as opções do desenvolvedor e a depuração USB no tablet, conecte-o e aceite a autorização de depuração. Alternativamente, gere um APK de demonstração com `flutter build apk --debug` e instale-o no tablet.

Permita as notificações quando o app solicitar. No Android 13 ou superior, `POST_NOTIFICATIONS` é solicitado em runtime. Se a permissão já tiver sido negada e o Android não abrir outro diálogo, permita-a em **Configurações → Aplicativos → LockMachine Mobile → Notificações**. Ao retornar ao app, o estado é atualizado.

## Payload e comportamento

O servidor envia `notification + data`. Cada evento recebe UUID e timestamp UTC no momento do clique. Todos os dez valores de `data` são strings:

```text
id, type, title, operatorName, operatorId,
machineName, machineId, reason, timestamp, severity
```

Tipos: `unauthorized_access`, `expired_qualification`, `blocked_machine`, `qualification_expiring` e `authorized_access`. Severidades: `critical`, `warning`, `info` e `success`. Campos ausentes ou inválidos recebem valores seguros; a data exibida usa o fuso horário do dispositivo.

| Estado | Recebimento e abertura |
| --- | --- |
| App aberto | `onMessage` registra o alerta e mostra notificação Android pelo canal `lockmachine_alerts`; tocar nela abre os detalhes do payload local. |
| App em background | Android exibe `notification`; `onMessageOpenedApp` registra e abre o alerta ao tocar. O handler top-level tem `@pragma('vm:entry-point')` e inicializa Firebase quando necessário. |
| App encerrado pelo sistema | Android pode exibir a Push; `getInitialMessage()` abre os detalhes ao iniciar por toque na Push. Notificações locais usam `getNotificationAppLaunchDetails()`. |

O handler de background não cria outra notificação para evitar duplicação. Quando o isolate principal ainda existir e o FCM executar o handler, um `SendPort` permite incorporar o evento ao histórico dessa execução. Como `notification + data` pode ser entregue ao código somente ao tocar na notificação em background, o app também incorpora o payload no clique. Não há promessa de um histórico completo de mensagens não abertas enquanto o processo esteve morto.

O histórico vive apenas em memória, ordenado por timestamp (mais recente primeiro) e sem duplicar IDs ao abrir notificações. Encerrar o processo limpa o histórico; abrir uma Push depois disso incorpora o evento correspondente na nova execução. O teste local aparece explicitamente como demonstração, sem operador ou máquina inventados.

**Limites de entrega:** abra o app pelo menos uma vez e confirme a inscrição no tópico. “Forçar parada” nas configurações Android bloqueia mensagens até reabrir o app; isso é diferente de colocá-lo em background. Economia de bateria, ausência de Google Play Services, falta de rede, notificações bloqueadas e Não Perturbe podem atrasar ou impedir a exibição. O sucesso do servidor confirma aceitação pelo FCM, não confirmação de entrega ao tablet. O projeto não implementa recibos de entrega.

Referências: [Recebimento Flutter/FCM](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages), [envio pelo Admin SDK](https://firebase.google.com/docs/cloud-messaging/send/admin-sdk) e [plugin de notificações locais](https://pub.dev/packages/flutter_local_notifications).

## Verificação

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
cd server
npm install
node --check server.js
node --check public/app.js
npm test
```

Os testes Flutter cobrem payload incompleto, fallback FCM, preservação dos campos, ordenação e deduplicação do histórico, interface em smartphone/tablet e abertura de detalhes. Os testes Node verificam os cinco payloads, dados somente string, IDs únicos, validação HTTP, falhas FCM e ausência de sucesso sem credenciais. Substitutos do SDK existem exclusivamente nos testes, nunca no servidor de demonstração. Esses testes não comprovam entrega real; a validação ponta a ponta requer Firebase real e tablet conectado.

Após configurar, confira manualmente: envio com app aberto; clique na notificação; envio com app em background; clique com processo encerrado normalmente; permissão negada; cópia do token; todos os cinco cenários; teste local. Não use “Forçar parada” para testar recebimento com app fechado.

## Roteiro da apresentação

1. Abrir LockMachine Mobile no tablet.
2. Mostrar o status Firebase.
3. Mostrar o FCM Token e o botão de copiar.
4. Mostrar a inscrição no tópico `lockmachine-supervisores`.
5. Clicar em “Testar notificação local”.
6. Explicar que essa notificação foi criada pelo próprio aplicativo, sem servidor.
7. Abrir o painel LockMachine no notebook em `http://localhost:3000`.
8. Clicar em “Acesso sem qualificação”.
9. Explicar o fluxo: Servidor → Firebase Cloud Messaging → Tablet.
10. Conferir a Push no tablet, com o app aberto ou em background.
11. Tocar na Push.
12. Mostrar os detalhes: operador, máquina, motivo e horário do evento recebido.
13. Explicar que no sistema real o evento seria iniciado pela leitura RFID.

## Acessos autorizados

No sistema real não seria recomendado enviar Push para todos os acessos autorizados, pois isso geraria excesso de notificações. A Push seria prioritariamente usada para tentativa de acesso não autorizado, qualificação vencida, máquina bloqueada, treinamento prestes a vencer e eventos críticos. O acesso autorizado existe no simulador apenas para fins didáticos.

O build release original ainda usa assinatura de debug e identificador `com.example.push_notification`; esta entrega é para demonstração escolar. Publicação em loja exigiria identidade e assinatura próprias.

## Resultado da validação desta etapa — 07/10/2026

- `flutter pub get`: concluído.
- `dart format .`: 10 arquivos, nenhum ajuste pendente na última execução.
- `flutter analyze`: nenhum problema encontrado.
- `flutter test`: 8 testes aprovados.
- Instalação de Express e Firebase Admin SDK: concluída.
- `node --check server.js` e `node --check public/app.js`: sintaxe válida.
- `npm test`: 4 testes aprovados.
- `npm audit fix`: atualizações compatíveis aplicadas; auditoria terminou com 0 vulnerabilidades.
- Inicialização real de `node server.js`: painel HTTP 200, status de configuração pendente e acesso à Service Account HTTP 404. Servidor de verificação encerrado após os checks.
- `flutter build apk --debug`: concluído. Artefato: `build/app/outputs/flutter-apk/app-debug.apk`.

Esse APK foi compilado **sem configuração Firebase** e serve para conferir a interface e o teste local no Android. Após `flutterfire configure`, gere ou execute novamente para incluir a configuração real. Recebimento FCM, permissão no tablet e entrega com app aberto, em background ou encerrado ainda exigem validação no dispositivo real.

O Gradle informou avisos provenientes dos plugins sobre uso de APIs Android depreciadas e a migração futura do Kotlin em `firebase_core`; eles não impediram o build e não são problemas apontados pelo analisador Dart. Foi preservada a configuração Kotlin do template Flutter atual.
