# Saúde Slim | Serviço WhatsApp Web
# Mesmo método de deploy usado na Harpia:
# Railway -> GitHub -> Root Directory /services/whatsapp-connector -> Dockerfile
# A Saúde Slim integra com Evolution API, portanto usamos o runtime Evolution
# isolado neste serviço, sem importar código, credenciais ou banco da Harpia.
FROM evoapicloud/evolution-api:v2.3.7

# Isolate errors in Baileys' offline queue without changing dependencies,
# authentication, decryption, receipt policy or persisted sessions.
COPY services/whatsapp-connector/patch-offline-queue.cjs /tmp/patch-offline-queue.cjs
RUN node /tmp/patch-offline-queue.cjs

EXPOSE 8080
