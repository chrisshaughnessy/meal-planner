# 🍽️ Family Dinner Planner

A shareable weekly/monthly **dinner** planner + calendar for the whole family.
Everyone opens one web link (PC or phone), picks who they are, and:

- keeps a shared **recipe library** (your HelloFresh-inspired favorites)
- picks **components** — protein / vegetable / starch — for what they're in the mood for
- gets **dinner proposals** (from your own stuff *and* invented by a local AI)
- **votes** on proposals, and the winners drop onto the **weekly calendar**

Everything syncs live between the kids' PCs and your wife's phone.

**Stack:** one `index.html` (no build step) · Supabase (free) for shared data · GitHub Pages (free) to host · Ollama on your PC for the AI. Total cost: **$0**.

---

## Setup (about 15 minutes, once)

### 1. Supabase — the shared database

1. Go to **[supabase.com](https://supabase.com)** → sign up (free) → **New project**.
   - Give it a name, set a database password (save it), pick a region near you.
2. Wait ~2 min for it to provision.
3. Left sidebar → **SQL Editor** → **New query**. Open `schema.sql` from this folder,
   paste the whole thing in, and click **Run**. You should see "Success".
4. Left sidebar → **Project Settings** → **API**. Copy two things:
   - **Project URL** (like `https://abcd1234.supabase.co`)
   - **anon public** key (a long `eyJ...` string) — the *anon* one, **not** the service_role key.

You'll paste those into the app on first open.

### 2. Ollama — the local AI (on the PC that stays on)

1. Install **[Ollama](https://ollama.com/download)** (Windows).
2. Open a terminal and pull a model (8B is a good balance):
   ```
   ollama pull llama3.1
   ```
   (You can try `qwen2.5:7b` or `llama3.2` too — put whichever name in the app's Model field.)

   For **photo recipe import** (snap a card → auto-fill), also pull a *vision* model:
   ```
   ollama pull llama3.2-vision
   ```
   (Set it in the app under ⚙︎ Settings → "Vision model". Text-only models like llama3.1 can't read images.)
3. **Let the web app talk to Ollama.** By default Ollama only allows localhost.
   Set an environment variable so your hosted page is allowed, then restart Ollama:

   - Press **Win**, search **"Edit the system environment variables"** → **Environment Variables…**
   - Under **User variables** → **New…**
     - Variable name: `OLLAMA_ORIGINS`
     - Variable value: `*`  *(simplest; or list your exact site, e.g. `https://YOURNAME.github.io`)*
   - Also add `OLLAMA_HOST` = `0.0.0.0` only if other devices on your home network
     should reach it directly (not required — see the note about who generates AI).
   - **Quit Ollama from the tray and reopen it** so the variables take effect.

> **Who can use the AI button?** The AI runs on *this* PC. You (and the kids on PCs
> in the house) can click **"Invent new dinners (AI)"** as long as their browser can
> reach `http://localhost:11434` — meaning it works on the PC Ollama runs on. The
> generated dinners save to Supabase, so **your wife's phone instantly sees them and
> can vote** — she just doesn't trigger generation herself. That's the normal flow:
> the planner generates, everyone votes.

### 3. Host it on GitHub Pages — the family link

1. Create a new repo on GitHub, e.g. `dinner-planner`.
2. Upload `index.html` (that's the only file the site needs).
3. Repo → **Settings** → **Pages** → Source: **Deploy from a branch** → branch `main`, folder `/root` → **Save**.
4. After a minute you get a URL like `https://YOURNAME.github.io/dinner-planner/`.
   That's the link you share with the family.

> Prefer to keep it private/local? You can also just double-click `index.html` on the
> PC. But for the kids' PCs + wife's phone to all share it live, host it (GitHub Pages)
> so everyone loads the same URL.

### 4. First run

1. Open the site. Paste your Supabase **URL** and **anon key**. Leave Ollama as
   `http://localhost:11434` and set the Model to what you pulled (`llama3.1`).
2. **Create a new family**: name it, pick a **family code** (long & unguessable — this
   is your household's shared password), and enter your name.
3. Share the **site URL + family code** with your wife and kids. On their device they
   open the URL → **Join with a code** → enter the code + their name.

Done. Add a few recipes, set each person's likes/dislikes on the **Family** tab, then
head to **Propose** to generate and vote.

---

## How it's meant to be used

- **Family tab** — add everyone, their likes/dislikes/allergies, and edit the
  protein/vegetable/starch building blocks.
- **Recipes tab** — save your go-to dinners with their components.
- **Propose tab** — tap what you're in the mood for → *Propose from our stuff* (instant,
  uses your recipes + components) or *Invent new dinners (AI)* → everyone votes 👍/👎 →
  hit **Add to plan** to schedule the winner.
- **Plan tab** — the weekly calendar. Use **"Next week ★"** as your main view.

## Privacy / security notes

- Your recipes and votes live in *your* Supabase project. The AI runs entirely on your
  PC — nothing about your family is sent to any AI company.
- Access is gated by your **family code**. The public anon key alone shows nothing; a
  request also has to present the matching code (enforced by the database's row-level
  security). Keep the code private and make it long.

## Troubleshooting

- **AI button errors ("Could not reach Ollama")** — Ollama isn't running, or
  `OLLAMA_ORIGINS` isn't set / Ollama wasn't restarted after setting it. Use the
  **Settings → Test AI connection** button to check. Remember it only works from a
  device that can reach the PC's `localhost:11434`.
- **"relation does not exist"** on connect — you didn't run `schema.sql` yet (step 1.3).
- **Nothing syncs** — make sure everyone used the exact same family code.
