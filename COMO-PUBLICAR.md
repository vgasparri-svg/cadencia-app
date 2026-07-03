# Pelotão — como publicar e instalar

Este pacote já é um **PWA** (Progressive Web App): tem manifest, ícones e
service worker prontos. Só falta hospedar em HTTPS — celular nenhum instala
PWA direto de um arquivo local, precisa de uma URL real.

## 1. Publicar (mais rápido: Vercel, do jeito que você já usa no ImóvelPRO)

1. Crie um repositório novo no GitHub (ex: `pelotao-app`) e suba estes 6
   arquivos na raiz: `index.html`, `manifest.json`, `sw.js`, `icon-192.png`,
   `icon-512.png`, `icon-180.png`.
2. No [vercel.com](https://vercel.com), *Add New Project* → importe esse
   repositório → **Framework Preset: Other** → Deploy.
   Não precisa de build command, é só HTML/CSS/JS puro.
3. Em alguns segundos você tem uma URL tipo `pelotao-app.vercel.app`.

## 2. Instalar no iPhone (Safari)

1. Abra a URL publicada no **Safari** (tem que ser Safari, não funciona
   pelo Chrome no iOS).
2. Toque no ícone de compartilhar (quadrado com seta pra cima).
3. Toque em **"Adicionar à Tela de Início"**.
4. O ícone do Pelotão aparece na tela como um app normal, abre em tela
   cheia, sem barra de navegador.

## 3. Instalar no Android (Chrome)

1. Abra a URL publicada no Chrome.
2. Chrome mostra automaticamente um banner **"Adicionar Pelotão à tela
   inicial"** (ou vá no menu ⋮ → "Instalar app").

## Sobre a App Store de verdade

Isso te dá um app instalável, com ícone e tela cheia, **sem** passar pela
revisão da Apple nem pagar os US$ 99/ano — ótimo para validar com outros
ciclistas. Se depois quiser publicar na App Store oficialmente, o caminho
mais direto a partir daqui é envolver esse mesmo HTML com **Capacitor**
(https://capacitorjs.com), que gera um projeto Xcode a partir de um app
web. Nesse ponto também vale trocar os dados fictícios por um backend de
verdade (dá pra reaproveitar Supabase, como no ImóvelPRO).
