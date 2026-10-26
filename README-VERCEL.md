# Abdul Hossen High School — Vercel Deployment

This is a static HTML/CSS/JS website with Supabase used for authentication, database, storage and notices.

## Deploy

1. Create a new Vercel project and import this folder/repository.
2. Framework Preset: **Other** (or leave as detected static site).
3. Build Command: **None**.
4. Output Directory: **`.`**.
5. Deploy.

## Supabase

The current frontend uses `supabase-config.js`. Keep the existing publishable/anon key in the frontend; never add a Supabase service-role/secret key to this site.

After Vercel deployment, update Supabase Authentication URL settings:
- Site URL: your Vercel/custom domain
- Redirect URLs: your Vercel/custom domain and the Teacher Zone page if you use an explicit redirect

Also update the final custom domain in Vercel and DNS only after the Vercel deployment has been verified.

## Important

Do not delete the old Netlify site until the Vercel deployment, Supabase login, Teacher Zone, Admin Zone and notices have all been tested.
