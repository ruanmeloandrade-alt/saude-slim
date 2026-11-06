# Fluxo contextual do Quiz Saúde Slim

Requisitos: primeira resposta define uma de cinco trilhas; próximas perguntas variam conforme escolhas anteriores; contextualizar protocolo/acompanhamento/PDFs sem nomes de produtos antes da oferta; convergir somente no final para preço e grupo/vendedor. Remover foto da mulher à mesa com doces da etapa pain.

Estado: foto retirada do fluxo; desenho das ramificações em preparação para revisão. Não alterar ofertas, destinatários, integrações ou backend.

Correção solicitada: restaurada a arte comercial original oferta-saude-slim.jpg na pergunta seis; retirada anterior foi indevida. Sem alteração de preços ou arte.

Fotos desktop: remover limite de 300px e ampliar coluna para quase metade do card, até 1240px de largura total; celular sem limite de altura, foto inteira em largura disponível. Restaurada legibilidade da arte comercial. Indicadores de seleção com largura explícita após centralização.

Ajustes adicionais: cinco decisões na pergunta sete; restaurar arte da oferta também no encerramento (desktop em coluna ampla, mobile inteira); remover logo/nome do topo no encerramento e rótulo textual repetido.

Encerramento revisado: preservar oferta; chamada no alto da coluna direita e antes/depois da etapa sete abaixo dos contatos. Mobile em ordem oferta, chamada/botões e antes/depois, ambos inteiros.

Revisão seguinte: no desktop colocar antes/depois no alto da coluna dos contatos; manter sequência mobile oferta, chamada/botões e antes/depois.

Nova arte enviada e preços explicitamente confirmados: R$250,00 por ampola e R$850,00 pela caixa com quatro no Pix. Atualizar imagem, alternativas e mensagem do vendedor em conjunto.

Refino final: arte nova quadrada; reduzir antes/depois desktop para 220px e compactar título, descrição e contatos para equilibrar alturas. Mobile preserva imagens inteiras.

Galeria final solicitada: quatro imagens antes/depois, pequenas no alto à direita; texto e contatos abaixo, último botão alinhado à base da oferta. Layout estreito: oferta, chamada/contatos, galeria de imagens inteiras. Publicação autorizada.

Checkpoint visual: galeria 4/4, arte atualizada, R$250/R$850, cinco decisões finais, foto de comida removida, arte também na etapa seis. Navegador confirmou bases do vendedor e imagem da oferta coincidentes. Ramificações novas seguem em implementação separada.

Revisão posterior: galeria desktop 2x2 compacta em vez de faixa horizontal; card final centralizado verticalmente. Mobile: oferta, título/descrição/contatos, quatro antes/depois um abaixo do outro, inteiros.

Implementação contextual: flow.js isolado e sem rede, cinco perguntas 2, 25 perguntas 3, 125 perguntas 4 e 625 perguntas 5 a partir do contexto acumulado. Alternativas da pergunta 3 acompanham a trilha, pergunta 4 acompanha a dificuldade e pergunta 5 conversa sobre apoio. Oferta na etapa seis; cinco decisões na sete. Voltar e alterar escolha limpa respostas posteriores. Sessão v3 não reaproveita respostas incompatíveis do fluxo antigo. Prévia completa aguardando validação.

Refino das etapas seis/sete: compactar condições e alternativas de oferta; informações do protocolo já contextualizadas nas etapas anteriores, sem bloco genérico repetido. Coluna direita da oferta usa altura da foto; foto da decisão final acompanha altura do questionário, inteira e sem corte.

Correção de preservação: restaurar o bloco integral de protocolo, acompanhamento e PDFs na oferta; remoção para compactar layout foi indevida. Compactar via espaçamento/tipografia e ampliar coluna da foto, sem retirar informação aprovada.

Validação: 3.125 percursos completos até a oferta; variantes 5/25/125/625 nas etapas 2–5; limpeza de respostas posteriores e restauração verificadas. Cinco trilhas completas percorridas no navegador sem erros de console. Testes de preservação exigem arte comercial, protocolo, acompanhamento, PDFs, galeria 4/4 e mensagens R$250/R$850. Build padrão npm run build aprovado. Vite isolado falhou por não executar os geradores herdados; não alterado backend para contornar. Prévia completa aberta no navegador interno e usuário já iniciou revisão. Ramificações ainda não publicadas; galeria aprovada publicada no commit fb7f47e384aa8ccd2361ab2e78a82f8cb396fec1, Railway SUCCESS, HTML/JS/CSS/arte HTTP200 e SHA256 igual ao commit.

Novo escopo autorizado: gênero, idade, altura, peso atual aproximado, meta desejada em 27 dias, primeiro nome e confirmação antes das sete etapas anteriores. Nome incorreto volta à digitação e pede confirmação novamente. Personalizar perguntas/alternativas por gênero, idade e nome, sem inferir diagnóstico nem definir protocolo clínico. Medidas e nome ficam apenas na sessão local, sem inclusão nas mensagens WhatsApp. Atualizar prévia completa e publicar após validar.

Validação da personalização: 25.000 percursos com dois gêneros/quatro faixas etárias aprovados; 14 etapas. Nome inválido bloqueado; correção do nome volta à confirmação; altura em metros/cm e peso decimal normalizados; preço e bloco completo da oferta preservados. Percurso feminino completo no navegador, com correção Ana→Marina e mensagem de caixa por R$850,00, sem perfil no WhatsApp e sem erros de console. Prévia atualizada com as perguntas iniciais; usuário em teste. Publicação explicitamente autorizada. Não recarregar/fechar/navegar na aba do usuário durante o teste.
