# SideQuest Roblox Marketplace

A static GitHub Pages front end backed by Supabase for Roblox creator listings. The storefront contains **no sample or seeded listings**: it displays only active records submitted by authenticated users.

## Configure the live site

1. Create a Supabase project.
2. In the Supabase SQL Editor, run `supabase/roblox-marketplace.sql`.
3. In Supabase Authentication settings, enable email/password sign-up and set the site's URL/redirect URL to `https://cieardesigned.github.io`.
4. Open `supabase-config.js` and set `url` to the project URL and `anonKey` to the project's **public anon/publishable key**. This key is intended for browser use with Row Level Security enabled. **Never put a service-role key, database password, or Stripe secret in this file.**
5. Commit and push the config change. GitHub Pages will deploy the static site; allow a few minutes for the deployment.

The site reports an empty-state prompt while unconfigured or when there are no live posts. Authentication, image uploads, listings, and comments require the Supabase setup above. Each creator must sign up and post their own listing; the SQL script inserts no listings.

## What the demo supports

- Supabase email/password sign-up and login with a self-reported Roblox username.
- Active live listings, search, genre/currency/price filters, thumbnail upload, and creator profile history.
- Robux instructions and buyer/seller comments. Comment changes update live through Supabase Realtime.
- USD checkout redirects to a Stripe Payment Link provided by the seller. The browser does not process payments and never stores Stripe secrets. A production marketplace should create/check out orders through a trusted server, verify Stripe webhooks, and handle fulfillment/refunds.
- Robux payment is an off-site/manual process. Buyers must independently verify gamepasses, group payouts, and transfers. Never share Roblox passwords or account credentials.

## Important limitations

GitHub Pages is static hosting; it cannot run Next.js API routes, Prisma, server actions, or private payment processing. The configured Supabase database provides the live data/auth/storage features, but a production financial marketplace also needs a trusted backend, verified creator identity, order/escrow procedures, moderation and dispute handling. The current verified badge indicates a signed-in marketplace profile only; it is not Roblox verification. Roblox username/link is self-reported.
