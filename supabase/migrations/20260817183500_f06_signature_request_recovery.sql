-- F06 · Assinaturas recuperáveis
--
-- Requests de ZapSign/DocuSign precisam existir localmente antes da chamada
-- externa. O identificador remoto é preenchido logo depois da criação no
-- provedor; enquanto isso o registro fica em status `creating`.
--
-- Providers de assinatura não são gate da F06. Em ambientes onde uma integração
-- não existe, esta migration deve simplesmente ignorar aquela coluna em vez de
-- interromper toda a sequência de migrations.

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'zapsign_signature_requests'
      and column_name = 'document_token'
  ) then
    alter table public.zapsign_signature_requests
      alter column document_token drop not null;
    comment on column public.zapsign_signature_requests.document_token is
      'Token remoto ZapSign; pode ser NULL somente durante criação/recovery do request local.';
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'docusign_signature_requests'
      and column_name = 'envelope_id'
  ) then
    alter table public.docusign_signature_requests
      alter column envelope_id drop not null;
    comment on column public.docusign_signature_requests.envelope_id is
      'Envelope remoto DocuSign; pode ser NULL somente durante criação/recovery do request local.';
  end if;
end;
$$;
