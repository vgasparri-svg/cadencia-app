# Ativando o Supabase no Pelotão

O app já está com o código pronto pra ler e escrever dados de verdade.
Faltam 3 coisas simples pra ligar tudo:

## 1. Criar o projeto no Supabase

1. Entre em [supabase.com](https://supabase.com) → **New Project**.
2. Dê um nome (ex: `pelotao`), escolha uma senha de banco (guarde num
   lugar seguro) e a região mais próxima (South America se disponível,
   senão a mais próxima).
3. Aguarde ~2 minutos até o projeto ficar pronto.

## 2. Rodar o schema SQL

1. No painel do projeto, vá em **SQL Editor** → **New query**.
2. Abra o arquivo `schema-supabase.sql` (está junto com esses
   arquivos), copie tudo, cole no editor.
3. Clique em **Run**.
4. Isso cria todas as tabelas (`usuarios`, `posts`, `curtidas`,
   `ocorrencias`, `assessorias`, etc.), as regras de segurança, e já
   deixa as 6 assessorias/oficinas de exemplo cadastradas.

## 3. Conectar o app ao seu projeto

1. No painel do Supabase, vá em **Project Settings** (ícone de
   engrenagem) → **API**.
2. Copie o **Project URL** e a chave **anon public**.
3. Abra o arquivo `index.html` no seu editor de código, procure por:

```js
const SUPABASE_URL = 'COLE_AQUI_A_URL_DO_SEU_PROJETO';
const SUPABASE_ANON_KEY = 'COLE_AQUI_A_CHAVE_ANON_PUBLIC';
```

4. Substitua pelos valores copiados. Fica assim, por exemplo:

```js
const SUPABASE_URL = 'https://xyzabc123.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

5. Salve o arquivo e suba novamente pro GitHub (mesmo processo de
   sempre: editar o arquivo direto na interface do GitHub, ou arrastar
   o `index.html` atualizado por cima do antigo). O Vercel republica
   sozinho.

## 4. Configurar o e-mail de login (link mágico)

Por padrão, o Supabase já envia o link mágico funcionando, sem
configuração extra — mas os e-mails saem de um domínio genérico do
Supabase e o limite é baixo (pouquíssimos e-mails por hora), o que é
ótimo pra testar, mas não pra uso real com muitos ciclistas.

Quando for testar com mais gente:
1. Vá em **Authentication → Providers → Email** e confirme que "Enable
   Email provider" está ligado (já vem assim).
2. Mais adiante, em **Project Settings → Auth → SMTP Settings**, você
   pode conectar um provedor de e-mail próprio (Resend, SendGrid, etc.)
   pra remover o limite.

## O que já funciona depois disso

- **Login por e-mail** (link mágico, sem senha)
- **Feed da comunidade** — posts reais, gravados no banco, aparecendo
  pra todo mundo em tempo real
- **Curtidas** persistentes e sincronizadas ao vivo
- **Reports de incidente** — gravados com localização real do
  celular (pede permissão de GPS ao reportar), aparecem na hora pra
  quem estiver com o app aberto
- **Assessorias/oficinas** vindas do banco (edite/adicione direto pela
  aba **Table Editor** do Supabase, mesmo fluxo que você já usa no
  ImóvelPRO)

## O que ainda é só protótipo (próximas fases)

- Mapa continua sendo o desenho ilustrativo — a Fase 3 do roteiro troca
  isso por Mapbox/Google Maps de verdade
- "Compartilhar pedal ao vivo" ainda não grava posição real — é o
  próximo pedaço a conectar na tabela `localizacoes_ao_vivo`, que já
  está criada e pronta
- Histórico de treino (`pedais`) segue local — o schema já tem a
  tabela pronta pra quando você quiser persistir de verdade

Testando localmente antes de subir: como o app usa `fetch` para o
Supabase, dá pra abrir o `index.html` direto no navegador (duplo
clique) pra testar login e feed antes de publicar — só o Service
Worker/instalação como PWA que exige estar num servidor HTTPS.
