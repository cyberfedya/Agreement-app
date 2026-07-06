# EasyAgree

AI-assisted agreement drafting and signing, end to end: voice/text input →
classification → agreement template matching → guided questionnaire → risk
analysis → generated agreement → QR handoff → MyID-verified digital signature
→ PDF.

## Structure

- `app/` — Flutter client
- `backend/` — .NET backend (Clean Architecture: Domain, Application, Infrastructure, Api, Contracts)
- `ai/` — prompts, schemas, examples, evaluations
- `agreements/` — agreement templates by category
- `localization/` — uz/ru/en strings
- `database/` — migrations, seeds, scripts, diagrams
- `docs/` — architecture, api, database, ai, deployment, roadmap, requirements
- `docker/` — local dev stack (api, postgres, redis, nginx)
- `.github/workflows/` — CI

See `docs/architecture.md` and `docs/roadmap.md` for details.
