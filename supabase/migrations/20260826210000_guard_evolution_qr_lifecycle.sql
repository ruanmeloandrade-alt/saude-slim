-- Protege o onboarding do WhatsApp Web contra eventos QRCODE_UPDATED vazios
-- que chegam logo depois de um QR válido. Esses eventos são observados na
-- Evolution/Baileys e não significam, por si só, falha de geração.

create or replace function public.guard_evolution_qr_lifecycle()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  qr_error_prefix constant text := 'Webhook recebido, mas a Evolution não enviou code/base64 do QR';
  last_generated_at timestamptz;
begin
  -- Marca o instante em que um QR realmente novo foi persistido.
  if new.status = 'aguardando_qr'
     and length(coalesce(new.last_qr, '')) > 100
     and new.last_qr is distinct from old.last_qr then
    new.metadata := coalesce(old.metadata, '{}'::jsonb)
      || coalesce(new.metadata, '{}'::jsonb)
      || jsonb_build_object('qr_generated_at', now());
    new.metadata := new.metadata - 'last_error' - 'last_event';
  end if;

  -- O webhook antigo marcava erro_qr em qualquer QRCODE_UPDATED sem payload,
  -- mesmo quando outro evento tinha acabado de entregar um QR válido. Preserve
  -- somente QRs recentes; um QR antigo continua podendo expirar/falhar de fato.
  if new.status = 'erro_qr'
     and length(coalesce(old.last_qr, '')) > 100
     and coalesce(new.metadata->>'last_error', '') like qr_error_prefix || '%' then
    begin
      last_generated_at := coalesce(
        nullif(old.metadata->>'qr_generated_at', '')::timestamptz,
        old.updated_at
      );
    exception when others then
      last_generated_at := old.updated_at;
    end;

    if last_generated_at >= now() - interval '90 seconds' then
      new.status := 'aguardando_qr';
      new.last_qr := old.last_qr;
      new.metadata := (coalesce(old.metadata, '{}'::jsonb)
        || jsonb_build_object(
          'qr_incomplete_event_ignored_at', now(),
          'qr_incomplete_event', coalesce(new.metadata->>'last_event', 'qrcode.updated')
        )) - 'last_error';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_evolution_qr_lifecycle on public.whatsapp_web_sessions;
create trigger trg_guard_evolution_qr_lifecycle
before update on public.whatsapp_web_sessions
for each row
execute function public.guard_evolution_qr_lifecycle();
