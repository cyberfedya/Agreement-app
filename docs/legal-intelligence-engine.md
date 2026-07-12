# Legal Intelligence Engine

`LegalKnowledgeEngine` is a deterministic, provider-based enrichment boundary. Providers have an explicit `Order`; each receives the facts produced by earlier providers. Providers append provenance-preserving facts and cannot replace existing facts. A conflicting derived result is retained in the internal `LegalKnowledgeReport` as a conflict instead of overwriting the source.

Included providers are `money`, `vehicle`, `address`, `property`, and `date`. They are pure local logic: no LLM, network, or database access. New domains implement `ILegalKnowledgeProvider` and are registered in DI; `InterviewPlanner` remains provider-agnostic.
