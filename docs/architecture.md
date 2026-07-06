# Architecture

EasyAgree is split into three top-level parts:

- `app/` — Flutter client (Splash → Auth (MyID) → Home → QR Scanner / AI Questionnaire → Agreement Preview → Profile).
- `backend/` — .NET solution following Clean Architecture: `EasyAgree.Domain` → `EasyAgree.Application` → `EasyAgree.Infrastructure` / `EasyAgree.Api`, with `EasyAgree.Contracts` shared between Api and external clients.
- `ai/` — prompt library and schemas used by `EasyAgree.Infrastructure/AI` to classify, extract, question, explain, risk-analyze, generate, and negotiate agreements.

See the deal lifecycle in `docs/roadmap.md` for the end-to-end flow from voice/text input to signed PDF.
