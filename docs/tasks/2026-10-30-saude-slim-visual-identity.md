# Identidade visual Saúde Slim em todo o sistema e no quiz

Pedido autorizado: restaurar a marca Saúde Slim, substituir a identidade verde pela logo e paleta preto/azul-ciano/rosa enviadas pelo usuário, em todo o sistema e no quiz público. Substituir a imagem da oferta no quiz pela peça fornecida. Atualizar os valores visíveis para os da nova peça: uma ampola R$299,99 e caixa com quatro R$899,99 no Pix. Manter o fluxo e destino do grupo. Ajustar imagens editoriais para expressão reflexiva, sem fabricar resultados nem inferir depressão pelo corpo.

Alvo: repositório independente ruanmeloandrade-alt/saude-slim; base restauracao/sistema-completo-20261014, commit cf073c29b2f9852de5c417e021720c3eba242438; serviço existente Railway saude-slim-web; domínio slimesaude.com. Referências MKTOn herdadas no AGENTS não alteram o alvo deste projeto independente.

Recorte: camada visual compartilhada de tokens, logo, favicon, sidebar e autenticação; HTML/CSS/textos/ativos do quiz. Reutilizar componentes e manter contratos e ações. Não alterar autenticação lógica, CRM, dados, integrações, rotas operacionais, estoque ou preços do ERP. Sem dependências novas, banco ou infraestrutura.

Aceite: identidade consistente no login, shell autenticado e quiz; marca antiga removida do quiz; imagem da nova oferta legível e sem corte; preços das opções coerentes com a peça; contraste e responsividade; navegação, autenticação e fluxo do quiz preservados. Build e checagens relevantes; publicação autorizada e validação no domínio público.

Status: implementação em branch isolada feat/saude-slim-visual-identity-20261030. Arquivos e evidências serão registrados após validação.

## Validação direta
- npm run build: PASS, exit 0; prebuild obrigatório, verificação de rotas, regressões, cliente/SSR/Nitro.
- Marca visível: 17/17 PASS. Interface/comércio: 20/20 PASS após o prebuild obrigatório (a primeira tentativa isolada, sem aplicar os geradores existentes, falhou por ausência dos marcadores esperados; não era regressão da identidade).
- Percurso completo no navegador com nova marca e oferta: PASS. Arte inteira visível, valores coerentes, resultado e convite exato preservados; não houve ingresso no grupo ou envio de mensagens.
- Tela de 390px: imagem do rosto reenquadrada e opções legíveis; viewport restaurado.
- Fontes geradas pelo prebuild removidas do diff; alterações de autenticação limitadas a classes e imagens.

## Login e runtime
Vite dev apresentou AsyncLocalStorage incompatível no runtime local herdado. A conferência foi realizada pelo servidor Node compilado, com a configuração exclusiva existente carregada somente em memória, sem .env. Novo bundle compilado com os valores públicos reais e runtime /auth: logo e formulário reais conferidos em desktop e 390px, sem overflow horizontal. Tokens globais ativos confirmados no DOM. Nenhuma credencial de usuário foi digitada; não foi realizado login nos módulos privados. Sem alterações para contornar autenticação.
Fontes geradas novamente retiradas do diff. Publicação autorizada no serviço existente após a validação direta.
