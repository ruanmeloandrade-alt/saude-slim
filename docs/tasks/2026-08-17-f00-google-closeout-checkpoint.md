# F00 Google Closeout — checkpoint 2026-08-17

Status: em execução.

- Google Ads: OAuth e discovery funcionando; leitura de campanha real bloqueada por `DEVELOPER_TOKEN_NOT_APPROVED` porque o Developer Token está aprovado apenas para contas de teste. Próximo gate externo: Basic/Standard Access no Google Ads API Center.
- GA4: Admin API funcional e propriedade real descoberta/salva; Data API foi habilitada pelo owner e aguarda propagação para smoke de relatório 28 dias.
- GTM: API e fluxo conta -> container -> workspace -> tags/gatilhos implementados. Não há ativo GTM real disponível na conta homologada para smoke final; não marcar falha de integração por ausência de recurso.
- Business Profile: OAuth/API alcançados; `429 RESOURCE_EXHAUSTED` na Account Management API. Bloqueio externo de quota/acesso, não de OAuth.
- Merchant Center: backend já possui discovery via Merchant API v1 (`merchantListAccounts`), mas a server function/UI ainda não expõem a descoberta. Correção cirúrgica pendente nesta frente.

Regra: não reabrir OAuth Google nem reconstruir integrações já homologadas. Consumidores funcionais (Dashboard/Gestor de Tráfego) pertencem às frentes funcionais posteriores.
