# Quiz público Lobo Paraguaio

## Escopo autorizado
Publicar a versão local revisada e aprovada pelo usuário em `/quiz` no sistema existente. Alterar apenas a marca para Lobo Paraguaio; a nova logo será fornecida depois. Preservar perguntas, preços, imagens, comportamento e convite de WhatsApp da versão aprovada.

## Destino confirmado
Repositório independente `ruanmeloandrade-alt/saude-slim`, base de produção `restauracao/sistema-completo-20261014`, commit `b4b3df96c499e3f78108b11760ded925cb3eae32`. Serviço Railway `saude-slim-web`, domínio `slimesaude.com`, confirmados ao vivo pelo CLI autenticado. As referências MKTOn herdadas no AGENTS.md não mudam o projeto exclusivo já identificado nos escopos Saúde Slim deste repositório.

## Implementação delimitada
- Rota pública de documento HTML `/quiz`, independente do shell autenticado.
- Arquivos estáticos e imagens aprovados em `public/quiz/`.
- Base de assets `/quiz/`; convite real de WhatsApp preservado.
- Sem logo improvisada: usar a marca textual Lobo Paraguaio até receber a logo do usuário.
- Sem mudanças em CRM, autenticação, banco, integrações, Cora ou outros serviços.
- Sem dependências novas, infraestrutura nova ou alterações de domínio.

## Critérios de aceite
- `/quiz` abre sem autenticação, com marca correta e assets funcionando.
- Fluxo aprovado chega ao resultado e mantém o link exato do grupo.
- Build e verificações relevantes aprovados; checagem funcional no runtime e após publicação.
- Home e autenticação existentes preservadas.

## Estado
Preparação iniciada em branch isolada. Acesso ao conector Railway exige reautenticação; CLI local autenticado funciona e foi utilizado para a confirmação do destino. Aprovação de publicação explicitamente recebida nesta conversa.

## Validação e logo recebida
Build completo aprovado. Runtime compilado confirmou /quiz e /quiz/ HTTP 200, JS/CSS/imagem carregados, home e auth HTTP 200. Percurso completo de sete respostas validado no navegador, com pergunta condicional e link exato de WhatsApp no resultado. Logo enviada pelo usuário incorporada com exterior transparente, preservando o preto interno; arquivo RGBA verificado. Nenhuma pergunta, preço ou fluxo aprovado foi redesenhado.
