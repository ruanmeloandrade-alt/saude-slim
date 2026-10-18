# Saúde Slim | Bloco 13: sincronização da Central de Grupos e aceite final

## Status inicial: 🟡 em execução, antes da implementação
Registro de 18/10/2026. Fonte de verdade exclusiva: GitHub ruanmeloandrade-alt/saude-slim, produção restauracao/sistema-completo-20261014, Supabase vyzvfcgpjjzvcjegzzza, empresa c49945db-1960-461a-9339-a43b8403bdd9. Base funcional eb9ca08e8edc7e16158fbc8c51a34d3d48100d94; documentação consolidada em 396af5b514504dbd5e74e4335c6ab2ab7e489c60. Railway 2c72ee70-bd81-486f-94f9-74d0389f7a95 continua SUCCESS na consulta inicial.

## Requisitos do usuário
- Os grupos já aparecem no Inbox, mas não em Automações → Grupos, Regras e SalesBots de grupo. Sincronizar para permitir a configuração das regras.
- Localizar, somente em leitura, o teste real de texto “oi” enviado anteriormente pelo usuário a um grupo.
- Checkout aceito como concluído pelo usuário.
- Conta de funcionário criada pelo usuário e acesso em navegador anônimo confirmado por ele. Conferir os registros disponíveis e encerrar o aceite de acesso, sem confundir esse teste com uso de convite por link.
- Concluir e publicar as correções validadas sem esperar outra autorização. Manter o semáforo com emojis.

## Dentro do escopo
1. Corrigir a ligação entre histórico do Inbox e catálogo da Central de Grupos, preservando empresa, sessão de origem e JID.
2. Sincronização idempotente de metadados existentes, sem criar grupos no WhatsApp, apagar mensagens ou substituir regras, atribuições de bot e nomes já configurados sem evidência do provedor.
3. Conferir e corrigir seleção de grupos em Regras e SalesBots, estado vazio, erros e retorno da sincronização.
4. Limitar chamadas de leitura de metadados à Evolution por prazo, volume e concorrência. Falhas não podem apagar o catálogo nem parecer lista vazia confirmada.
5. Testes isolados dos contratos afetados, compilação completa, versionamento, migration aditiva se necessária, publicação Railway e conferência operacional.
6. Atualizar docs/OPERATION_STATUS.md com aceites e evidência real, distinguindo código validado e cenário real efetivamente observado.

## Fora do escopo
Atendimento autônomo de IA nos grupos permanece retirado por decisão do usuário. Não criar nem iniciar bots, gatilhos, campanhas, mensagens, vendas, convites ou contas reais para QA. Não alterar senhas, fatores, sessões, permissões de funcionários ou dados comerciais. Não tocar Cora, MKTOn, Harpia, Lovable, Vercel ou GitHub Actions; instruções legadas referentes a outros projetos não substituem este recorte autorizado. NF-e real segue fora do escopo, comprovante comercial aceito. Segurança do bloco 12 e todas as regressões anteriores devem ser preservadas.

## Critérios de aceite
- Grupos históricos autorizados ficam disponíveis com identidade persistida utilizável pelas regras, sem duplicar a mesma combinação de sessão/JID.
- Sincronizar novamente preserva regras, bot ativo, dados anteriores e mensagens; falhas e catálogos vazios têm tratamento explícito.
- Usuário, empresa e sessão incorretos são recusados; nenhuma nova abertura de RLS, RPC ou acesso anônimo.
- Regras e SalesBots usam os mesmos grupos da aba Grupos; IA de grupos não volta à interface.
- Teste real “oi” e acesso de funcionário registrados somente conforme os dados encontrados e o relato do usuário.
- Build, testes relevantes e healthcheck aprovados; produção conferida antes de declarar correção concluída.

## Áreas previstas
src/lib/whatsapp-groups.functions.ts, whatsapp-group-sync-robust.functions.ts e helpers focados; src/components/automations/CentralDeGrupos.tsx e integração de ações; scripts de transformação/testes; migration e teste SQL se necessários; documentação deste bloco e semáforo.

## Diagnóstico inicial e decisões
A listagem do Inbox usa list_inbox_group_conversations_page, capaz de recuperar conversas do histórico. A Central lê somente whatsapp_groups via listWorkspaceGroups; suas ações exigem UUID persistido. A causa precisa ser resolvida no catálogo e no contrato de sincronização, não apenas renderizando grupos virtuais sem destino para salvar regras. Consultas reais e desenho final em andamento.

## Adendo de aceite do funcionário, conferido antes da correção
A leitura real de 18/10 às 19:04 UTC confirmou funcionário criado às 18:44:59 UTC, login às 18:45:38 UTC, conta e vínculo ativos e uma sessão nativa válida. O perfil estava selecionando a empresa vazia criada automaticamente para essa nova identidade, em vez da operação Saúde Slim. A leitura de 19:06 UTC encontrou 26 leads e três bots individuais na Slim operacional, e zero leads/grupos/bots na empresa inicial do funcionário.

O código explica o resultado: handle_new_user cria empresa e preenche o perfil; createEmployee confirma o vínculo com a Slim, mas só seleciona a empresa contratante quando o perfil está nulo. O login não oferece troca de empresa na navegação atual. Esse defeito impede considerar o acesso operacional concluído somente pelo login.

Recorte adicional autorizado pelo pedido de conferir/finalizar a conta: selecionar a empresa contratante após o provisionamento de uma identidade nova, confirmando a escrita, e preservar a escolha prévia de identidades reutilizadas. Corrigir somente o campo de empresa ativa da conta de funcionário recém-criada e identificada, sob condições de vínculo ativo, origem na empresa pessoal vazia e seleção anterior conferida. Não modificar conta Auth, senha, sessão, fatores, permissões, memberships ou empresas; não excluir a empresa vazia. A restrição anterior sobre contas refere-se a ações de QA e não impede este reparo concreto do contexto operacional.

A correção será testada com dados sintéticos, versionada antes da operação administrativa e incluída na mesma publicação dos grupos. O aceite do login real é verde; o acesso à empresa operacional será registrado após a correção verificada.
