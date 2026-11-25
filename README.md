# Devur

A dark, creator-first marketplace for complete game projects, templates, and studio assets.

## Local setup

Requires Node.js 20.9+.

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open http://localhost:3000. Supabase keys are optional for browsing demo listings. Add them to `.env.local` for live client setup.

## Supabase

1. Create a project at https://supabase.com.
2. Run `supabase/schema.sql` in the SQL Editor.
3. Enable Email and optional GitHub/Discord providers in Authentication.
4. Copy the project URL and anon/public key into `.env.local`.
5. Keep service-role keys server-only and perform purchase/status transitions through trusted server actions or RPC functions.

## Pages

- `/` — landing and featured projects
- `/explore` — search and filters
- `/sell` — listing form
- `/project/[id]` — project detail and inquiry modal
- `/dashboard` — listings, requests, and profile settings

## Deploy to Vercel

Push to GitHub, import the repository in Vercel, and keep the Next.js preset. Add both environment variables. Configure the Supabase Auth site URL and redirect URLs with the Vercel domain. Run the schema migration on the production database before enabling writes.

**Note:** GitHub Pages does not execute Next.js server features. Use Vercel or a Node-compatible host.
