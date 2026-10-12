-- Campos adicionais do cadastro Affiliate / Partner.
alter table public.partner_program_profiles
  add column if not exists instagram_handle text,
  add column if not exists experience_level text,
  add column if not exists person_type text;

alter table public.partner_program_profiles
  drop constraint if exists partner_program_profiles_experience_level_check;
alter table public.partner_program_profiles
  add constraint partner_program_profiles_experience_level_check
  check (experience_level is null or experience_level in ('iniciante','intermediario','avancado','especialista'));

alter table public.partner_program_profiles
  drop constraint if exists partner_program_profiles_person_type_check;
alter table public.partner_program_profiles
  add constraint partner_program_profiles_person_type_check
  check (person_type is null or person_type in ('pf','pj'));
