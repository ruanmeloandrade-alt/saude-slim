# Correção — usuário em múltiplos workspaces e prazo de parceiro técnico

## Objetivo
Permitir que o mesmo e-mail/login pertença a mais de um workspace da MKTOn e permitir que o dono defina por quanto tempo um parceiro técnico ficará ativo.

## Regras
- Um e-mail corresponde a uma única identidade Auth, mas pode possuir memberships em vários workspaces.
- Ao adicionar funcionário com e-mail já existente, reutilizar o usuário existente e adicionar o novo vínculo ao workspace, sem bloquear por vínculo anterior.
- Não sobrescrever nome/senha do usuário existente ao adicioná-lo a outra conta.
- O usuário deve continuar podendo trocar entre os workspaces aos quais pertence.
- Parceiro técnico: acesso por tempo indeterminado ou por quantidade de dias definida pelo dono.
- O prazo começa quando o convite é aceito.
- Membership de parceiro com prazo vencido não pode ser considerado acesso válido pelo resolvedor de workspace.
- Convites continuam com validade própria de link; prazo de acesso é um campo separado.

## Banco
- `workspace_invitations.access_days integer null` — null = indeterminado.
- `workspace_members.access_expires_at timestamptz null` — null = indeterminado.

## Segurança
- Preservar isolamento por `workspace_id`.
- Não duplicar usuários no Auth.
- Não alterar limites comerciais de WhatsApp.
- Não alterar Cora.

## Validação
- Criar funcionário novo continua funcionando.
- Adicionar e-mail já existente adiciona membership no workspace atual sem erro.
- Usuário existente em dois workspaces mantém os dois acessos.
- Parceiro indeterminado recebe `access_expires_at = null`.
- Parceiro com N dias recebe expiração a partir da aceitação.
- Workspace expirado deixa de ser resolvido como acesso válido.
