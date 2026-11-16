# Bible Study Library / 圣经学习资料库

A bilingual (Chinese/English) public read-only Bible study library with a separate administrator login. Visitors do not register. Public access is controlled by a long random share token in the URL. Student names, private notes and personal reflections are kept in admin-only tables and are never returned by the public RPC.

## Included
- Public bilingual library page (`?share=...`), no visitor account.
- Separate administrator login (`?admin=1`) using Supabase Auth email/password.
- Admin can add, edit and delete study entries; choose whether each entry is published.
- Admin can add and remove student profiles.
- Admin can generate/rotate the private share URL. Rotating it invalidates the previous URL.
- Supabase Row Level Security protects admin data; the public RPC returns only published summaries.

## 1. Create Supabase project
1. Create a project at https://supabase.com/dashboard.
2. In Authentication > Users, create the one administrator user (email + password). Disable public sign-ups in Auth settings after creating the admin account.
3. Open SQL Editor and run all of `supabase-schema.sql`.
4. Copy the Project URL and the publishable key from Project Settings > API Keys.

## 2. Configure locally
```sh
cp .env.example .env
# Edit .env and set VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY
npm install
npm run dev
```
Open the local URL. Visit `?admin=1` to sign in. Generate a share link in the admin dashboard. Add study entries and tick “Publish after saving”. Open the share link in a private/incognito window to test the visitor experience.

## 3. Deploy free
1. Push this folder to a private or public GitHub repository (do not add passwords or secret keys).
2. Import the repository into https://vercel.com/ and choose Vite as the framework (or let Vercel detect it).
3. Add environment variables in Vercel Project Settings > Environment Variables:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_PUBLISHABLE_KEY`
4. Deploy. Vercel will provide a free `*.vercel.app` URL.
5. In Supabase Authentication URL Configuration, set the Site URL to the deployed Vercel URL and add the local/deployment URLs to Redirect URLs if needed.
6. Sign in at `https://YOUR-APP.vercel.app/?admin=1`, generate the share link, and share only that URL.

## Important privacy/security notes
- “Link-only” is an unlisted bearer-link model, not identity verification. Anyone who receives or is forwarded the URL can view published summaries. Rotate the link if it is shared too widely.
- Never put student names, contact details, testimonies, prayer requests, personal reflections or follow-up notes in public title/summary fields. Keep those in private admin notes/reflections.
- Only the Supabase publishable key belongs in the browser. Never expose a Supabase secret/service-role key.
- This starter app has not been deployed to your accounts. It becomes a live website only after you create/configure Supabase and deploy to Vercel.
- Before using with real personal data, review the Supabase production security checklist and test access using a separate browser session.

## Existing local-only data
The previous standalone HTML prototype stores records in that browser's local storage. This cloud version starts with a new Supabase database; it does not automatically migrate that browser-local data. Export/backup the old records before switching, and add only the information appropriate for the new public/private split.
