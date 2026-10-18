# Saúde Slim: bloco 8 de prevenção de novos contatos duplicados

## Estado: 🟢 implementação, 50 verificações e build aprovados; 🟡 instalação e publicação

Base funcional 42b11fc16158b7b40f45c56b85cebc12fa3acaaa. Branch fix/slim-contact-guard-block8-20261017. Produção restauracao/sistema-completo-20261014, repositório ruanmeloandrade-alt/saude-slim. Supabase vyzvfcgpjjzvcjegzzza, empresa c49945db-1960-461a-9339-a43b8403bdd9. Somente Saúde Slim.

## Pedido e continuidade

O usuário pediu concluir as pendências e seguir a produção enquanto ele testa, sem aguardar a conferência de cada bloco. A prevenção de contatos duplicados permanece pendente no semáforo. Copiloto, gatilho do Funil e passagem SalesBot → IA individual já foram aceitos. IA autônoma de grupos foi retirada. O card do lead/Mini-Inbox foi publicado em 5abfbda; Editar/Excluir pedidos está versionado em 42b11fc, com migration instalada e implantação em andamento ao registrar este escopo.

## Diagnóstico atual

Os cadastros compartilham leitura de identidade, mas usam travas diferentes: a aplicação usa exclusão mútua dentro do processo, o Funil usa uma chave transacional por empresa/telefone e o checkout usa outra chave. Uma criação simultânea entre esses caminhos ainda pode passar pelas leituras anteriores e inserir dois contatos.

Metadados somente leitura de 18/10 confirmaram índice parcial para source=whatsapp e phone_normalized, mas nenhuma proteção comum para todos os cadastros por telefone integral. O normalizador private.slim_funnel_contact_phone_key está instalado, aceita apenas telefone completo com 8–15 dígitos e pontuação/espaços previstos, incluindo espaços Unicode. Não deriva telefone de nome, sufixo, JID ou identificador de canal, nem presume DDI.

As propostas antigas 20261016130000_slim_contact_identity.sql e 20261016130100_slim_contact_identity_unique.sql incluem vínculo físico de aliases e índice único sobre dados históricos. Permanecem intactas. Há registro histórico de recusa, sem o payload completo e a causa específica preservados. Não atribuir a recusa à falta de consentimento. Este bloco prepara uma mudança aditiva diferente, sem migração física, usando a revisão normal das ferramentas. Não reenviar pacote antigo intacto, não alternar ferramenta/endpoint para contornar recusa atual. Se uma ação atual for recusada, parar aquela ação e registrar o motivo exato, continuando apenas o trabalho independente.

## Dentro do bloco

- Nova migration criada pelo CLI oficial, limitada à Saúde Slim. Acrescentar uma barreira privada no banco para INSERT e mudanças de identidade/reativação em public.leads, abrangendo Funil, Clientes, checkout e integrações que escrevem nessa tabela.
- Reutilizar a definição instalada de telefone integral. Contato elegível deve estar sem merged_into_id e fora dos estados deleted, archived e merged. Definir explicitamente o tratamento de status nulo conforme o contrato atual. Identificadores não telefônicos não devem ser convertidos em números de telefone.
- A barreira compartilha uma trava transacional por empresa/telefone, lê o estado após a trava e rejeita nova colisão com erro identificável. Não depender de uma trava de processo, de leitura anterior ao INSERT ou de um teste sequencial para afirmar proteção concorrente.
- Permitir edição de campos que não alterem a identidade dos aliases históricos. Revalidar mudança de telefone/empresa, retirada de merged_into_id e reativação. A instalação não atualiza, mescla ou remove contatos, mensagens, pedidos ou vínculos existentes.
- Preservar RLS e permissões atuais. Função de trigger em schema privado, search_path vazio, sem nova RPC pública, sem grants de escrita ou acesso direto à função para papéis de aplicação. Escopo e leitura de colisões devem ser seguros mesmo quando o gravador tem visibilidade restrita por RLS.
- Usar READ COMMITTED para a garantia descrita e recusar isolamento incompatível no caminho protegido. Limitar espera por trava. Documentar limites e erro de concorrência; não repetir automaticamente cadastros, vendas ou gatilhos.
- Manter transação/recibos/outbox do Funil e confirmação financeira/frete do checkout intactos. Adaptar somente a apresentação do conflito conhecido, quando necessário: selecionar o cliente existente. A criação canônica pode recuperar o contato já persistido após a rejeição confirmada; nunca inventar sucesso nem tratar resultado incerto como rejeição.
- Os aliases históricos continuam preservados e o resolvedor operacional atual permanece. O resultado deste bloco é impedir novas colisões elegíveis entre gravadores, não afirmar unicidade física de todos os registros antigos.

## Fora do bloco

Sem índice único que exija limpar duplicados antigos; sem migração física de aliases, nomes, telefones, contatos, mensagens ou pedidos. Sem cadastros ou vendas reais de QA, movimentos de leads, envios, campanhas, início de bots, alteração de contas ou segurança, Cora, NF-e, IA de grupos, outras empresas, credenciais, infraestrutura, DNS, Lovable, Vercel ou GitHub Actions. O PostgreSQL efêmero de testes fica em /tmp; não modifica serviços de produção nem pacotes globais.

## Verificação e divisão

- Banco e concorrência: guard e migration novos, preservando propostas antigas; testes de integração com contratos atuais e dados sintéticos. Usar PostgreSQL local real com duas conexões independentes para demonstrar que a segunda transação aguarda a primeira e rejeita a colisão após seu commit. Incluir rollback liberando criação, Funil × checkout/cadastro direto, troca de telefone/reativação, isolamento, empresa distinta, pontuação/Unicode, identificadores não telefônicos, aliases antigos inalterados e rejeição sem efeitos financeiros/outbox parciais.
- Aplicação: ajuste mínimo no conflito conhecido e testes dos handlers reais com transporte sintético, sem alterar recuperação de resultado incerto ou repetir operações.
- Revisão cruzada: conferir classificação de identidade, privilégios, ordem de travas e comportamento em lote. Não expandir testes após resolver os riscos concretos e gates existentes.
- Integração: uma compilação completa em cópia isolada com os gates anteriores; nenhum transform executado no checkout compartilhado. Versionar implementação e evidências antes da instalação.

Antes de instalar, conferir metadados/contratos relevantes e agregados/hash de contatos e vínculos da empresa. Instalar somente a nova migration pelo processo normal de revisão. Conferir triggers, grants, preservação do estado e advisors depois. Publicar a revisão funcional somente após os testes, com Railway SUCCESS, healthcheck e serviços conferidos. Caso a instalação de banco não exija mudança funcional no frontend, não criar deploy só de documentação. Aceite autenticado do usuário continua distinto de validação técnica.

## Reversão

Se houver incompatibilidade real, preparar uma correção compatível ou remover somente a barreira nova por migration revisada, sem apagar dados ou reescrever histórico Git. Não desativar validações existentes nem alterar a implantação de outro bloco. Este escopo é versionado antes do código da proteção.

## Execução

Escopo versionado em 55f39934e3117df06c3706afd52f2f0004edb312 antes da implementação. Consulta agregada somente leitura: 26 contatos, 25 com telefone elegível, um grupo histórico de colisão e três linhas excedentes. Nenhum contato de source whatsapp_group, instagram, facebook ou messenger com chave telefônica elegível nesta consulta. Hash SHA-256 do corpo do normalizador instalado: 13b638b254fabc1d3e3898016842732a045f95b0bca8d978c0a0640b3a5877e7. Esses dados não autorizam mesclar ou remover registros e não foram expostos como telefones ou nomes.

Editar/Excluir do bloco 7 terminou a implantação: 42b11fc, Railway b6567ceb SUCCESS às 02:15:28 UTC de 18/10 e healthcheck 1/1 às 02:15:25 UTC; os quatro serviços foram conferidos online. O trabalho neste bloco continua sem esperar a conferência comercial do usuário.

## Implementação e validação

Nova migration 20261018021846_slim_contact_phone_guard.sql criada pelo CLI oficial com escalonamento normal aprovado para seu cache/telemetria, sem alterar HOME. O EROFS inicial do sandbox não foi uma recusa de revisão. Nenhuma recusa automática ocorreu nesta implementação. A migration acrescenta somente uma função/trigger privada, comentários e preflight; os arquivos históricos permanecem intactos. Instalação tem lock_timeout 5s e statement_timeout 30s.

O guard AFTER ROW e VOLATILE usa exclusivamente phone integral do normalizador conferido, preserva atualizações sem mudança efetiva de identidade e revalida criação, reativação, unmerge e mudança de empresa/telefone. NULL é elegível. Identificadores de canais permanecem nas colunas próprias; JIDs de grupos não se tornam telefone. A função privada tem execução direta revogada de PUBLIC/anon/authenticated/service_role, search_path vazio e visibilidade somente para detectar colisões escondidas por política de leitura; não amplia a escrita do chamador. Somente a empresa Slim recebe a proteção. A consulta após o lock exige READ COMMITTED e limita espera a 5s.

A aplicação reconhece apenas 23505 acompanhado do marcador exato slim_leads_contact_phone_guard. O checkout retorna rejeição confirmada e atualiza a leitura do catálogo sem desmontar o formulário; itens, endereço, frete e pagamento ficam preenchidos. Outros erros/timeout permanecem incertos, com referência preservada e sem repetição. createSlimCanonicalContact ficou intacto; os testes comprovam sua recuperação tanto pelo índice WhatsApp anterior quanto pelo novo guard, sem novo INSERT.

Gates concluídos, sem somar repetição de rodadas ou regressões:

- scripts/test-slim-contact-guard-runtime.mjs: 12/12 com handlers, Workspace, Checkout e sessão reais, IO sintético e transformação real da rejeição em memória.
- scripts/test-slim-contact-guard-postgres.mjs: 26/26, incluindo execução final após o ajuste dos limites DDL. Fixture reutiliza Funil/outbox, checkout/frete, documentos e revisão de pedidos atuais. Preserva aliases, vínculo e venda sintéticos; cobre RLS parcial, lote, BEFORE trigger, isolamento e rollback.
- scripts/test-slim-contact-guard-concurrency.mjs: 12/12 e exit 0 no PostgreSQL 16.15 local, com processos psql e PIDs independentes. O observador exige pg_locks advisory não concedido e pg_blocking_pids antes de liberar a transação. Cobre Funil × checkout em ambas as ordens, cadastro direto, rollback, alteração/reativação, lote, outra empresa, timeout medido em 5.010 ms com 55P03 e deadlock com rollback integral com 40P01. Não usa DATABASE_URL/TCP nem declara aprovação se faltar ambiente; banco descartável removido ao terminar.
- Regressões focadas: ERP 37/37 e UI de Editar/Excluir 25/25 preservadas. Revisão cruzada somente leitura sem bloqueador, incluindo o teste real.
- npm run build em /tmp/slim-contact-guard-build-5qw2ut3k: exit 0 na primeira tentativa, todos os gates anteriores e saída Nitro concluídos. Log /tmp/slim-contact-guard-build.log. Os dez arquivos de código/teste/migration do bloco continuaram com os mesmos hashes após o build; diff --check limpo. O gate concorrente real é local, não adiciona PostgreSQL/download ao build de produção.

Total: 50 verificações novas. A semântica da leitura após o lock foi conferida na documentação primária de [volatilidade das funções](https://www.postgresql.org/docs/current/xfunc-volatility.html) e [visibilidade dos triggers](https://www.postgresql.org/docs/current/trigger-datachanges.html), além da prova executada com conexões independentes. Nenhum contato, pedido, estoque ou envio real foi usado como QA.
