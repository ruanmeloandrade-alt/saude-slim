# Saúde Slim: bloco 9 de convites por link com acesso explícito

## Estado: 🟡 escopo antes da implementação

Base b4185b0cb61169571b7d3cac002e5490643def21. Branch fix/slim-invitations-block9-20261018. Produção restauracao/sistema-completo-20261014, repositório ruanmeloandrade-alt/saude-slim. Supabase vyzvfcgpjjzvcjegzzza, empresa c49945db-1960-461a-9339-a43b8403bdd9. Somente Saúde Slim.

## Pedido e continuidade

O usuário pediu fechar as pendências e continuar publicando enquanto ele testa, com semáforo por emojis. A ficha do Funil com Mini-Inbox, Editar/Excluir pedidos e a prevenção de novos contatos duplicados foram publicados nos blocos 6–8. Copiloto e os testes reais de gatilho/SalesBot/IA individual continuam aceitos. IA autônoma de grupos saiu do escopo. Convites e segurança permanecem pendências distintas; este bloco entrega somente o convite de parceiro técnico por link usado pela UI atual.

AGENTS.md foi conferido. As referências legadas a outros repositórios/projetos, Lovable e main não ampliam a autorização exclusiva da Saúde Slim e sua branch operacional. PROJECT_STATUS.md não existe neste checkout; OPERATION_STATUS.md e os escopos Slim são os checkpoints atuais. A regra de versionar docs/tasks antes do código e de publicar automaticamente após validação continua aplicável.

## Evidência e decisão de acesso

Metadados somente leitura confirmaram workspace_invitations existente, RLS ativa e política de gerenciamento somente para workspaces.owner_id. Há zero convites na empresa. As funções preview_invitation e accept_invitation não existem. A geração atual revoga e insere em requisições distintas; renovação conserva o token e pode reabrir estados consumidos; o aceite tem uma atualização administrativa posterior de prazo, sem transação comum. A rota envia invite/email ao login, que só preserva next e perde o retorno ao convite.

Os gates atuais concedem acesso completo para workspace_members.role=admin; is_partner e role_type são categoria. module_permissions.modules não é aplicado pelos gates ativos e o hook atual não usa a matriz granular. A expiração não é aplicada uniformemente por todos os caminhos. Portanto este bloco não apresenta restrição granular ou prazo como proteção funcional.

O formulário de parceiro por link disponibilizará somente **acesso administrativo completo, sem prazo**, exigindo escolha explícita sem seleção padrão. A revisão e a prévia mostram esse mesmo alcance. access_role será novo campo nullable, sem default; somente o valor admin explicitamente aprovado permite criar/renovar/aceitar um convite moderno. access_days deve ser NULL. modules=[] permanece metadado legado, sem concessão ou promessa de restrição. Outros papéis e prazo ficam indisponíveis com explicação curta até terem enforcement próprio. Não transformar um convite legado/omisso em administrativo nem promover membros existentes. Ações exclusivas do dono continuam exclusivas do dono.

## Dentro do bloco

- Nova migration aditiva criada pelo CLI oficial, com helpers privados e RPCs públicas INVOKER. Nenhuma RPC anônima nova. Prévia somente via serviço do servidor; ações do dono e aceite exigem usuário autenticado validado no banco. Limites de espera por trava/consulta e erros sanitizados.
- Gerar convite revisado: dono real da empresa, e-mail normalizado, acesso escolhido explicitamente, fingerprint do estado lido e identificador da tentativa. Revogar convites pendentes substituídos e criar o novo em uma transação. Rejeitar vínculo já existente quando identificado, com orientação para gerenciar a equipe.
- Renovar somente convite pendente válido ou expirado compatível com este contrato, após revisão; gerar token novo e sete dias para validade do link. Não reabrir convite revogado ou aceito nem converter acesso legado. Revogar convite ainda não consumido após confirmação; não alterar o acesso de quem já é membro.
- Serializar tentativas concorrentes por empresa/e-mail e registrar recibos privados vinculados a ator, empresa, ação, alvo e conteúdo aprovado. Repetição da mesma tentativa recupera o resultado, sem repetir efeitos. Consulta explícita do resultado pode encerrar uma tentativa ausente sob a mesma trava, impedindo execução tardia com aquele ID. Não reenviar automaticamente após erro de rede ou prazo excedido.
- Lista de convites sem token. Consultar link em ação explícita autorizada; copiar somente após clipboard confirmar. Não incluir tokens, e-mails ou comandos completos no journal local. Preservar apenas referência opaca vinculada à identidade para recuperar uma tentativa incerta; limpar em troca de identidade e rejeitar resposta atrasada de outro contexto.
- Prévia apresenta empresa, e-mail, papel/acesso, status e validade do link, sem fingir convite inválido quando o serviço falha. Retorno do login usa next=/convite/<token>, já suportado. Não alterar política de autenticação ou criar conta automaticamente.
- Aceite explícito exige auth.uid, identidade atual, e-mail confirmado em auth.users, comparação exata normalizada, token da Slim, estado pendente, link válido e acesso aprovado persistido. Criar vínculo admin/parceiro/sem prazo e consumir o convite na mesma transação. Registrar accepted_by/accepted_at; repetição do mesmo usuário não renova prazo, recria vínculo removido nem reaplica permissões. Vínculo existente permanece com seu papel/permissões; acesso expirado é recusado, não renovado.
- Entrar na empresa deve funcionar: somente no aceite explícito bem-sucedido, selecionar a Slim em profiles.current_workspace_id do próprio usuário, atomicamente com o resultado; perfil ausente ou falha de seleção não pode deixar aceite parcial. A recuperação de resultado deve conferir vínculo ainda válido e não criar acesso. Nunca alterar perfis/contas reais pela equipe para QA.
- Validar recibo antes de mostrar sucesso, limpar formulário ou navegar. Consulta do aceite após falha é explícita e não executa novo aceite. Mudança de token/usuário invalida resultados anteriores. Preservar mensagem de erro e saída segura em login incompatível, não confirmado, expirado, revogado, serviço indisponível ou resultado incerto.

## Contrato compartilhado

Nomes novos: slim_invitation_context, slim_invitation_change, slim_invitation_change_lookup, slim_invitation_link, slim_invitation_preview e slim_invitation_accept. Não instalar as RPCs genéricas antigas por compatibilidade nem copiar o pacote histórico inteiro. Helpers e ledger ficam em private, sem grants diretos às tabelas para papéis da aplicação.

DTOs JSON usam version=1 e camelCase. Toda resposta autenticada inclui workspaceId/actorId e IDs relevantes; domínio valida os discriminadores e o vínculo da resposta com a requisição. Parâmetros SQL mantêm snake_case:

- Contexto: p_workspace_id, p_actor_id, p_action (create/renew/revoke), p_email opcional e p_invitation_id opcional. Retorna action, email, invitationId, expectedFingerprint, invitation (resumo sem token), pendingToReplace, canProceed, reason quando bloqueado e acesso exigido. A revisão mostra efeitos reais desse contexto.
- Mudança: p_workspace_id, p_actor_id, p_request_id, p_action, p_payload, p_expected_fingerprint, p_approved. Payload create={email,accessRole:'admin',accessDays:null}; renew/revoke={invitationId}. Aprovação deve ser true. Resultado status=confirmed/rejected inclui requestId/action/targetId, invitationId, code/message quando rejeitado e resumo atual. Links são obtidos separadamente, não gravados no recibo/journal.
- Consulta: mesmos workspace/actor/request/action e p_invitation_id (NULL para create). Retorna recibo persistido ou rejeição terminal de tentativa encerrada sem execução, sob a mesma trava da escrita. Nunca retornar sucesso com ausência ou reiniciar ação.
- Link: p_workspace_id, p_actor_id, p_invitation_id. Retorna IDs, token/validade/revisão somente ao dono e somente para convite pendente elegível. Servidor constrói URL pelo origin configurado e validado.
- Prévia: p_token; acesso SQL somente service_role, sem sessão anônima direta. Retorna resumo versionado ou status=invalid; nunca token ou identidade do dono. Indisponibilidade sobe como erro.
- Aceite: p_token, p_actor_id, p_approved e p_mode (accept/lookup). Aceite requer approved=true; lookup é somente leitura do resultado e não altera vínculo ou perfil. Resultado status=accepted/already_member/already_accepted/pending/rejected inclui invitationId/workspaceId/actorId, acceptedAt, membershipRole/activeWorkspaceId quando aplicável e code/message para rejeição. Lookup de convite não consumido pode informar pending, sem repetir efeito. O frontend não navega até confirmar resultado e contexto válidos.

Agentes podem ajustar detalhes não substantivos deste DTO em coordenação direta, registrando a decisão no escopo antes da integração. Não ampliar papéis, prazo, grants ou efeitos sem reavaliar este contrato.

## Fora do bloco

Nenhum convite, e-mail, WhatsApp, vínculo, conta, fator MFA, senha, permissão, perfil, lead, pedido, documento ou estoque real de QA. Nenhum envio por ferramenta da equipe. Sem alterar createEmployee, remoção/edição de membros existentes, matrizes e RLS gerais, MFA/passkeys/recuperação/dispositivos, Cora, emissão NF-e, IA de grupos, outras empresas, infraestrutura, DNS, credenciais, Lovable, Vercel ou GitHub Actions. Não prometer expiração global ou permissões granulares não implementadas. Não modificar os pacotes antigos recusados nem trocar transporte para contornar eventual recusa atual.

Há registro antigo de recusa do pacote slim_restore_settings_security_and_invitations sem payload/motivo específico preservado. Esta é uma implementação nova e limitada, contra metadados atuais, submetida à revisão normal. A autorização do usuário já existe; não inventar motivo de recusa nem declarar bloqueio atual sem resposta da ferramenta. Se a revisão atual recusar uma operação, parar aquela ação e registrar o motivo exato; continuar apenas trabalho independente.

## Verificação, divisão e publicação

Banco: agente audit_lead_card_gap, migration nova e testes SQL/concorrência sintéticos. Aplicação/backend: audit_remaining_blocks, domínio/servidor novo, integração settings.functions.ts e compatibilidade focal do transform existente. UI: audit_next_runtime_task, componente dedicado, integração EquipeTab/InviteDialog e rota convite, testes dos componentes reais. Root integra, revisa, documenta, instala e publica. Nenhuma edição concorrente no mesmo arquivo sem coordenação.

Cobrir rejeição sem aprovação/role/prazo válido, dono real, empresa distinta, e-mail confirmado/exato, expiração/consumo, token renovado invalidado, vínculo existente preservado, replay sem recriar membro, aceite/perfil atômico, transações concorrentes reais, stale fingerprint, referência errada, ausência encerrada, network/timeout, clipboard negado e respostas atrasadas após troca de ator/token/empresa. Não substituir disputa transacional por teste sequencial. Reusar PostgreSQL efêmero local existente; nenhum serviço real para QA.

Rodar gates focados necessários, revisão cruzada e uma compilação completa em cópia isolada. Preservar transformações/gates anteriores e não executar transforms no checkout compartilhado. Versionar implementação e resultados antes da instalação. Metadados e hashes agregados de convites/membros/permissões/perfis da Slim antes/depois devem demonstrar que a instalação não concede acesso nem altera contas. Instalar somente migration nova revisada; conferir grants, RLS, hashes e advisors; publicar código aprovado por atualização CAS da branch de produção. Concluir somente com Railway SUCCESS, healthcheck e quatro serviços conferidos. Aceite autenticado continua com o usuário, distinto de verde técnico. Sem deploy documental separado.

## Reversão

Preparar correção compatível ou desabilitar apenas os novos handlers mediante nova revisão se um erro material aparecer. Preservar convites/recibos/vínculos históricos, manter proteção de autorização e não reescrever histórico Git. Não apagar membros nem invalidar acessos existentes para reverter código.
