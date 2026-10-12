# MKTOn — F00 Google / GA4 — Handoff para Tracking e Dashboard

Chave: `MKTON-F00-CONEXOES`
Data: 2026-08-17
Status: integração GA4 homologada no provider; consumo funcional deferido para as frentes de Tracking/Dashboard.

## Evidência real da integração

- OAuth Google central está conectado.
- A propriedade GA4 foi descoberta pela Google Analytics Admin API e salva no workspace.
- O smoke `Relatório (28 dias)` retornou dados reais após habilitar a Google Analytics Data API.
- O backend usa `analyticsdata.googleapis.com/v1beta/properties/{propertyId}:runReport`.
- Dimensão atual do smoke: `sessionDefaultChannelGroup`.
- Métricas: `sessions`, `totalUsers`, `screenPageViews`, `keyEvents`.
- Não existe mock/fallback no fluxo `getGa4Report` / `ga4RunReport`.

## Regra arquitetural

A Google Central é camada de conexão, discovery e smoke. Não deve virar dashboard de analytics.

Fluxo obrigatório futuro:

`Google Central (credencial + property id)`
→ `Tracking (normalização, identidade, UTMs, origem, atribuição e reconciliação com eventos MKTOn)`
→ `Dashboard (visão executiva e KPIs consolidados)`

## Delta funcional registrado

### Tracking

Hoje `TrackingOverview` consome `getTrackingOverview`, baseado nos eventos próprios da MKTOn. Ele ainda não lê GA4.

Na frente funcional de Tracking deve:
- ler a propriedade GA4 configurada na Google Central;
- ingerir/consultar métricas GA4 como fonte complementar, sem substituir a verdade first-party do Pixel MKTOn;
- reconciliar `sessionDefaultChannelGroup`, source/medium/campaign e UTMs com as identidades/sessões da MKTOn;
- evitar dupla contagem entre GA4 e tracking first-party;
- expor um contrato normalizado para Dashboard.

### Dashboard

Hoje a Dashboard consome `getTrackingOverview` para tracking e `getCustomKpiCards` para mídia Meta. GA4 ainda não entra no board.

Na frente funcional de Dashboard deve:
- consumir o contrato normalizado do Tracking, incluindo GA4 quando disponível;
- mostrar origem/canais/sessões e KPIs derivados sem depender da tela Google Central;
- diferenciar claramente dados first-party MKTOn de dados reportados pelo GA4;
- remover qualquer dependência funcional de `MOCK_METRICS` para produção. O fallback atual deve ser eliminado ou restrito explicitamente a ambiente de demo/dev antes do aceite final.

## Critério de fechamento futuro

GA4 só estará funcional ponta a ponta quando:
1. Google Central conecta e descobre a propriedade;
2. Tracking consome e normaliza dados GA4;
3. Tracking reconcilia GA4 com Pixel MKTOn/UTM/conversões;
4. Dashboard recebe esse contrato e mostra os KPIs reais;
5. nenhum dado mock é apresentado como métrica de produção.

## Classificação F00

Para a Frente 00, GA4 pode ser marcado como provider/integration homologado, pois autenticação, discovery, seleção e leitura real foram provados. O consumo nos módulos não bloqueia a F00, mas este handoff é obrigatório para as frentes funcionais posteriores.