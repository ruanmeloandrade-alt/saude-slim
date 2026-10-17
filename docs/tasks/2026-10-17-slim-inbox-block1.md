# Saúde Slim | Bloco 1: Inbox, grupos e mídia

## Solicitação de 17/10/2026

Executar uma etapa por vez e pausar ao concluir para conferência do usuário. Este bloco cobre exclusivamente o Inbox. O usuário informou teste real bem-sucedido em 16/10/2026 de SalesBot passando o atendimento para IA individual; localizar evidência operacional e atualizar o registro sem reenviar mensagens. Atendimento autônomo de IA nos grupos foi retirado do escopo pelo usuário; manter SalesBots e gatilhos de grupos.

## Contexto e limites

Repositório ruanmeloandrade-alt/saude-slim, produção restauracao/sistema-completo-20261014, base 71aeb83b9bd8afc69a08ccf4e9d9c5e0c9017788. Supabase exclusivo vyzvfcgpjjzvcjegzzza. Branch de trabalho fix/slim-inbox-block1-20261017. As referências a outros projetos e ciclos antigos no AGENTS.md herdado não substituem este escopo autorizado pelo usuário.

Não enviar mensagens reais, iniciar bots, mover leads, alterar pedidos, mesclar contatos ou recriar grupos durante QA. Não implementar IA de grupos, mini-Inbox do Funil, Copiloto, ERP ou demais blocos. Preservar dados e migrações existentes. Não usar Lovable, Vercel nem GitHub Actions. Publicação automática apenas após validação técnica; depois pausar para conferência.

## Diagnóstico inicial

1. Controles de SalesBot do Inbox não reconhecem a chave composta sessão|JID dos grupos recuperados sem metadados. O resolver os classifica como lead, impedindo carregamento das automações e mostrando controles individuais indevidos.
2. Histórico dos grupos ainda não oferece recuperação autenticada sob clique para mídia sem URL ou com URL Storage expirada.
3. Webhook de recebimento continua realizando download antecipado sem prazo e armazenando base64 em JSONB, apesar da recuperação segura já publicada no caminho individual.

## Implementação prevista

Resolver grupos históricos no workspace e sessão corretos, preservar SalesBots/gatilhos e remover entrada operacional de IA para grupos. Disponibilizar áudio/PDF/imagem de grupos sob clique por mensagem autorizada, com limite de tamanho/prazo e Storage privado. Retirar recuperação antecipada do recebimento, preservando as chaves/metadados necessários para a abertura posterior. Não descarregar mensagens nem regravar o histórico em lote.

## Critérios de aceite

- Grupo histórico mantém sessão/JID, não é tratado como lead e permite carregar seus controles SalesBot.
- Anexos individuais e de grupos têm abertura explícita, com verificação de workspace/conversa/mensagem e tratamento de indisponibilidade.
- Novas entradas não dependem de download antecipado da Evolution nem acrescentam mídia base64 ao histórico.
- Testes direcionados e build real aprovados; verificar versão publicada e saúde após a publicação.
- Evidência do teste informado separada de testes ainda não executados; não declarar navegação autenticada ou envio real realizados sem prova.
- Pausar após este bloco para o usuário conferir antes da etapa seguinte.

## Execução

Em andamento. GitHub/Railway acessados. Ambiente com quatro serviços online no início. Navegador disponível abriu /auth sem sessão; validação visual autenticada ainda não executada. Consultas Supabase somente leitura em andamento.
