# MiroFish — Quick Start (personal setup)

My standalone import of [666ghj/MiroFish](https://github.com/666ghj/MiroFish)
(AGPL-3.0, imported at upstream commit `39d8491`), with easy-start extras:

- `start.ps1` — one-click start on Windows (checks `.env`, starts Docker)
- `docker-compose.build.yml` — builds the image **from this source** instead
  of pulling the maintainer's prebuilt image (better supply-chain posture)
- This file. Everything else is untouched upstream source — see `README.md`
  for the full original docs.

## 1. One-time setup

You need two API keys:

| Key | Where to get it | Notes |
|-----|-----------------|-------|
| `LLM_API_KEY` | Any OpenAI-compatible provider | Set `LLM_BASE_URL` + `LLM_MODEL_NAME` to match |
| `ZEP_API_KEY` | https://app.getzep.com/ | Free tier is enough to start |

```powershell
copy .env.example .env
notepad .env   # fill in the keys
```

## 2. Start it

```powershell
./start.ps1              # uses the prebuilt image (fastest)
./start.ps1 -Build       # builds from this repo's source (most trustworthy)
```

Or manually: `docker compose up -d` (prebuilt) /
`docker compose -f docker-compose.build.yml up -d --build` (from source).

- UI: http://localhost:3000
- API: http://localhost:5001

Stop with `docker compose down`.

## 3. Usage notes

- **Start small**: keep first simulations under ~40 rounds — every agent
  makes LLM calls each round, cost grows fast.
- **Privacy**: the app runs locally but seed material and agent memory go to
  your LLM provider and Zep Cloud. Don't feed it anything you wouldn't send
  to those services.
- **Keep it on localhost**: the API has no authentication and the backend
  binds `0.0.0.0`. Don't port-forward or expose it to the internet as-is.
- Uploads/simulation data persist in `backend/uploads/` (volume-mapped,
  gitignored).

## Updating from upstream

```powershell
git remote add upstream https://github.com/666ghj/MiroFish.git   # once
git fetch upstream
git merge upstream/main
```
