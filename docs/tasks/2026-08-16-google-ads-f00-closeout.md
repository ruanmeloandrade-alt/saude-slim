# F00.2.2 — Google Ads — Closeout de integração

Status: **🟢 HOMOLOGADA NO NÍVEL DE CONEXÃO/API**
Data: 2026-08-16
Escopo: Frente 00 — Conexões e homologação real

## Evidência real
- OAuth Google central já homologado no workspace correto.
- `GOOGLE_ADS_DEVELOPER_TOKEN` foi obtido no Google Ads Manager/API Center e configurado no servidor pelo owner.
- O runtime da MKTOn passou a executar `customers:listAccessibleCustomers` com sucesso.
- A UI da Google Central listou contas Google Ads reais acessíveis ao usuário autorizado.
- A seleção de conta está funcional na Google Central e atualmente é **single-account por workspace** (`adsCustomerId`).

## Limite atual que NÃO pertence ao closeout da conexão
O módulo `Gestor de Tráfego IA` ainda não consome Google Ads. O código atual marca Google Ads como `ready: false` e o módulo funcional está ligado ao provider Meta. Dashboard/Gestor de Tráfego serão conectados ao provider Google em frente funcional posterior.

Portanto, o critério da Frente 00 para Google Ads é a disponibilidade real da conexão/API e discovery de contas, não a conclusão do frontend de gestão de tráfego.

## Estado para handoff
- Provider Google Ads: pronto para consumo posterior.
- Developer Token: configurado no servidor.
- Discovery de contas: funcional.
- Seleção/configuração da conta: funcional.
- Multi-account simultâneo: não implementado; atualmente 1 conta selecionada por workspace.
- Consumo em Dashboard/Gestor de Tráfego: pendente de frente funcional, sem reabrir OAuth/API.

## Próximo passo da Frente 00
Avançar para `F00.2.3 — Google Analytics 4` e homologar discovery de propriedades + leitura mínima via Admin/Data API.
