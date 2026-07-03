-- ============================================================
-- PELOTÃO — SCHEMA SUPABASE (Fase 1 e 2)
-- Rode este arquivo inteiro no SQL Editor do seu projeto Supabase
-- (Project → SQL Editor → New query → colar tudo → Run)
-- ============================================================

-- ---------- extensões úteis ----------
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1. USUÁRIOS (perfil público, ligado ao auth.users do Supabase)
-- ============================================================
create table if not exists usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null default 'Ciclista',
  avatar_url text,
  cidade text default 'Rio de Janeiro',
  ftp_watts int default 200,
  peso_kg numeric(5,2),
  criado_em timestamptz not null default now()
);

alter table usuarios enable row level security;

create policy "usuarios: leitura publica"
  on usuarios for select
  using (true);

create policy "usuarios: cada um edita o proprio perfil"
  on usuarios for update
  using (auth.uid() = id);

create policy "usuarios: cada um cria o proprio perfil"
  on usuarios for insert
  with check (auth.uid() = id);

-- cria o perfil automaticamente quando alguém se cadastra
create or replace function public.criar_perfil_novo_usuario()
returns trigger as $$
begin
  insert into public.usuarios (id, nome)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', 'Ciclista'));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.criar_perfil_novo_usuario();


-- ============================================================
-- 2. POSTS (feed da comunidade)
-- ============================================================
create table if not exists posts (
  id uuid primary key default uuid_generate_v4(),
  autor_id uuid not null references usuarios(id) on delete cascade,
  conteudo text not null check (char_length(conteudo) between 1 and 500),
  tag text default 'Geral',
  criado_em timestamptz not null default now()
);

alter table posts enable row level security;

create policy "posts: leitura publica"
  on posts for select
  using (true);

create policy "posts: usuario logado pode postar"
  on posts for insert
  with check (auth.uid() = autor_id);

create policy "posts: autor pode apagar o proprio post"
  on posts for delete
  using (auth.uid() = autor_id);


-- ============================================================
-- 3. CURTIDAS
-- ============================================================
create table if not exists curtidas (
  post_id uuid not null references posts(id) on delete cascade,
  usuario_id uuid not null references usuarios(id) on delete cascade,
  criado_em timestamptz not null default now(),
  primary key (post_id, usuario_id)
);

alter table curtidas enable row level security;

create policy "curtidas: leitura publica"
  on curtidas for select
  using (true);

create policy "curtidas: usuario logado pode curtir"
  on curtidas for insert
  with check (auth.uid() = usuario_id);

create policy "curtidas: usuario pode descurtir"
  on curtidas for delete
  using (auth.uid() = usuario_id);


-- ============================================================
-- 4. OCORRÊNCIAS (reports de segurança)
-- ============================================================
create table if not exists ocorrencias (
  id uuid primary key default uuid_generate_v4(),
  autor_id uuid not null references usuarios(id) on delete cascade,
  tipo text not null check (tipo in (
    'Assalto', 'Colisão / atropelamento', 'Buraco / risco na via', 'Assédio / ameaça', 'Outro'
  )),
  descricao text,
  latitude numeric(9,6) not null,
  longitude numeric(9,6) not null,
  criado_em timestamptz not null default now()
);

alter table ocorrencias enable row level security;

create policy "ocorrencias: leitura publica"
  on ocorrencias for select
  using (true);

create policy "ocorrencias: usuario logado pode reportar"
  on ocorrencias for insert
  with check (auth.uid() = autor_id);

-- índice pra buscar ocorrências recentes rapidamente
create index if not exists idx_ocorrencias_criado_em on ocorrencias (criado_em desc);


-- ============================================================
-- 5. LOCALIZAÇÕES AO VIVO (modo "compartilhar pedal")
--    Cada usuário tem no máximo 1 linha — ela é sobrescrita
--    a cada atualização de posição, e removida ao desativar.
-- ============================================================
create table if not exists localizacoes_ao_vivo (
  usuario_id uuid primary key references usuarios(id) on delete cascade,
  latitude numeric(9,6) not null,
  longitude numeric(9,6) not null,
  atualizado_em timestamptz not null default now()
);

alter table localizacoes_ao_vivo enable row level security;

create policy "localizacoes: leitura publica"
  on localizacoes_ao_vivo for select
  using (true);

create policy "localizacoes: usuario atualiza a propria posicao"
  on localizacoes_ao_vivo for insert
  with check (auth.uid() = usuario_id);

create policy "localizacoes: usuario sobrescreve a propria posicao"
  on localizacoes_ao_vivo for update
  using (auth.uid() = usuario_id);

create policy "localizacoes: usuario para de compartilhar"
  on localizacoes_ao_vivo for delete
  using (auth.uid() = usuario_id);


-- ============================================================
-- 6. ASSESSORIAS E OFICINAS
-- ============================================================
create table if not exists assessorias (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  tipo text not null check (tipo in ('assessoria', 'oficina')),
  bairro text,
  foco text,
  descricao text,
  criado_em timestamptz not null default now()
);

alter table assessorias enable row level security;

create policy "assessorias: leitura publica"
  on assessorias for select
  using (true);

-- inserir/editar fica restrito por enquanto (você cadastra manualmente
-- pelo Table Editor do Supabase, como faz com os imóveis no ImóvelPRO)


-- ============================================================
-- 7. AVALIAÇÕES das assessorias
-- ============================================================
create table if not exists avaliacoes (
  id uuid primary key default uuid_generate_v4(),
  assessoria_id uuid not null references assessorias(id) on delete cascade,
  usuario_id uuid not null references usuarios(id) on delete cascade,
  nota int not null check (nota between 1 and 5),
  comentario text,
  criado_em timestamptz not null default now(),
  unique (assessoria_id, usuario_id)
);

alter table avaliacoes enable row level security;

create policy "avaliacoes: leitura publica"
  on avaliacoes for select
  using (true);

create policy "avaliacoes: usuario logado avalia"
  on avaliacoes for insert
  with check (auth.uid() = usuario_id);


-- ============================================================
-- 8. PEDAIS (histórico de treino)
-- ============================================================
create table if not exists pedais (
  id uuid primary key default uuid_generate_v4(),
  usuario_id uuid not null references usuarios(id) on delete cascade,
  nome_rota text not null,
  distancia_km numeric(6,2),
  duracao_min int,
  potencia_media_w int,
  realizado_em timestamptz not null default now()
);

alter table pedais enable row level security;

create policy "pedais: cada um ve o proprio historico"
  on pedais for select
  using (auth.uid() = usuario_id);

create policy "pedais: usuario registra o proprio pedal"
  on pedais for insert
  with check (auth.uid() = usuario_id);


-- ============================================================
-- 9. HABILITAR REALTIME nas tabelas que precisam de atualização
--    ao vivo (feed, reports, ciclistas no mapa)
-- ============================================================
alter publication supabase_realtime add table posts;
alter publication supabase_realtime add table curtidas;
alter publication supabase_realtime add table ocorrencias;
alter publication supabase_realtime add table localizacoes_ao_vivo;


-- ============================================================
-- 10. DADOS INICIAIS — assessorias/oficinas (mesmos do protótipo)
-- ============================================================
insert into assessorias (nome, tipo, bairro, foco, descricao) values
  ('Rio Pedal Team', 'assessoria', 'Aterro do Flamengo', 'Estrada · pelotão', 'Treinos em grupo de terça a domingo, com apoio de carro-guia nos pedais longos.'),
  ('Carioca MTB Clube', 'assessoria', 'Zona Oeste', 'Mountain bike', 'Trilhas guiadas na Pedra Branca, foco em técnica de descida.'),
  ('TriRio Endurance', 'assessoria', 'Barra da Tijuca', 'Triathlon · estrada', 'Planilhas de potência personalizadas e testes de FTP mensais.'),
  ('Pedal Iniciante RJ', 'assessoria', 'Tijuca', 'Iniciantes', 'Turma para quem está começando, ritmo leve e foco em segurança no trânsito.'),
  ('Oficina do Seu Ari', 'oficina', 'Botafogo', 'Manutenção geral', 'Referência em ajuste de câmbio e revisão completa, atende no mesmo dia.'),
  ('BikeFix Copacabana', 'oficina', 'Copacabana', 'Bike fit · manutenção', 'Estúdio de bike fit com análise de pedalada em vídeo.')
on conflict do nothing;
