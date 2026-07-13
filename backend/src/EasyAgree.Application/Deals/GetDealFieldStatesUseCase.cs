using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

public sealed record DealFieldState(
    int FieldId,
    string Label,
    string? Value,
    bool Required,
    string Source,
    double Confidence,
    string ConfirmationStatus,
    string Party,
    bool Dispute,
    string Status,
    string Reason);

public sealed record DealFieldStateResult(
    IReadOnlyList<DealFieldState> Fields,
    string WorkflowStatus,
    string WorkflowReason);

public sealed class GetDealFieldStatesUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUploadedDocumentRepository documentRepository)
{
    public async Task<DealFieldStateResult?> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return null;

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return null;

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        var hints = DocumentFieldHintCollection.FromDocuments(documents);
        var answers = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        var classified = FieldEligibilityEngine.Classify(template.Fields, labels);
        var mapped = DocumentFieldMapper.FindMatches(template.Fields, labels, hints, answers.Keys)
            .ToDictionary(mapping => mapping.FieldId);
        var conflictKeys = DocumentConflictEngine.Detect(documents)
            .Where(conflict => conflict.Severity == "HIGH")
            .Select(conflict => conflict.Field)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
        var disputed = DealPartyResponseSerializer.Deserialize(deal.PartyResponsesJson)
            .Where(response => response.Type == DealPartyResponseTypes.ProposedChange && response.FieldId is not null)
            .GroupBy(response => response.FieldId!.Value)
            .ToDictionary(group => group.Key, group => group.OrderByDescending(response => response.CreatedAt).First());

        var states = new List<DealFieldState>();
        foreach (var field in classified)
        {
            var templateField = template.Fields.First(f => f.FieldId == field.FieldId);
            var required = templateField.Mode == AgreementFieldMode.Required && field.Category != FieldCategory.Optional;

            if (answers.TryGetValue(field.FieldId, out var answer))
            {
                states.Add(State(field, answer, required, "manual", 1.0, "CONFIRMED", Party(field), false,
                    "CONFIRMED", "Recorded interview answer"));
                continue;
            }

            if (mapped.TryGetValue(field.FieldId, out var mapping))
            {
                var hasDocumentConflict = mapping.HintKeys.Any(conflictKeys.Contains);
                var hasPartyDispute = disputed.ContainsKey(field.FieldId);
                if (hasDocumentConflict || hasPartyDispute)
                {
                    var proposed = disputed.GetValueOrDefault(field.FieldId);
                    var reason = proposed is null
                        ? $"Conflicting documents disagree on {string.Join(", ", mapping.HintKeys)}"
                        : $"Second party proposed: {proposed.ProposedValue}";
                    states.Add(State(field, mapping.Value, required, mapping.Source, mapping.Confidence, "DISPUTED",
                        Party(field), true, "DISPUTED", reason));
                    continue;
                }

                var status = string.Equals(mapping.Source, "user_override", StringComparison.OrdinalIgnoreCase)
                    ? "CORRECTED"
                    : "AUTO_FILLED";
                states.Add(State(field, mapping.Value, required, mapping.Source, mapping.Confidence,
                    mapping.Confidence >= 0.75 ? "CONFIRMED" : "NEEDS_CONFIRMATION",
                    Party(field), false, status, $"Mapped from {string.Join(", ", mapping.HintKeys)}"));
                continue;
            }

            if (disputed.TryGetValue(field.FieldId, out var dispute))
            {
                states.Add(State(field, dispute.ProposedValue, required, "second_party", 1.0, "DISPUTED",
                    Party(field), true, "DISPUTED", dispute.Message ?? "Second party proposed a different value"));
                continue;
            }

            if (FieldDependencyEngine.IsObsolete(field, answers, labels))
            {
                states.Add(State(field, null, required, "system", 1.0, "NOT_REQUIRED", Party(field), false,
                    "SKIPPED", "Obsolete because a dependency answer made it irrelevant"));
                continue;
            }

            if (field.Category == FieldCategory.NeverAsk)
            {
                states.Add(State(field, null, required, "profile_or_qr", 1.0, "WAITING_SOURCE", Party(field), false,
                    "LOCKED", "Resolved from account profile, second-party QR profile, or legal metadata"));
                continue;
            }

            if (field.Category == FieldCategory.Optional)
            {
                states.Add(State(field, null, false, "optional", 1.0, "NOT_REQUIRED", Party(field), false,
                    "OPTIONAL", "Optional term; not asked during the minimal interview"));
                continue;
            }

            if (field.Category == FieldCategory.DocumentOnly)
            {
                // Technical characteristics are never asked and never block
                // anything: required=false keeps them out of the mandatory-
                // terms workflow gate, and the draft renders them blank
                // until a document fills them in.
                states.Add(State(field, null, false, "document", 1.0, "WAITING_SOURCE", Party(field), false,
                    "DOCUMENT_PENDING", "Fills in automatically from an uploaded document"));
                continue;
            }

            states.Add(State(field, null, required, "unknown", 0, "MISSING", Party(field), false,
                "MISSING", "No trusted value available"));
        }

        var dismissedDocumentSuggestions =
            DealDismissedDocumentSuggestionsSerializer.Deserialize(deal.DismissedDocumentSuggestionsJson);

        return new DealFieldStateResult(
            states,
            WorkflowStatus(deal, template.Domain, states, hints, dismissedDocumentSuggestions),
            WorkflowReason(deal, states));
    }

    private static DealFieldState State(
        ClassifiedField field,
        string? value,
        bool required,
        string source,
        double confidence,
        string confirmationStatus,
        string party,
        bool dispute,
        string status,
        string reason) =>
        new(field.FieldId, field.Label, value, required, source, confidence, confirmationStatus, party, dispute, status, reason);

    private static string WorkflowStatus(
        Deal deal,
        string templateDomain,
        IReadOnlyList<DealFieldState> states,
        DocumentFieldHintCollection hints,
        ISet<string> dismissedDocumentSuggestions)
    {
        if (states.Any(s => s.Dispute) || deal.InviteStatus is InviteStatus.ChangeRequested or InviteStatus.ClarificationRequested)
            return DealWorkflowStatus.LegalReviewRequired;

        var missing = states.Where(s => s.Required && s.Status == "MISSING").ToList();
        if (missing.Count > 0)
        {
            var askable = missing
                .Select(s => new ClassifiedField(s.FieldId, s.Label, FieldCategory.RequiredObject))
                .ToList();
            if (DocumentSuggestionEngine.Evaluate(templateDomain, askable, hints, dismissedDocumentSuggestions) is not null)
                return DealWorkflowStatus.WaitingForObjectDocument;

            return DealWorkflowStatus.MissingMandatoryTerms;
        }

        if (!string.IsNullOrWhiteSpace(deal.GeneratedHtml) && deal.InviteStatus is InviteStatus.Pending or InviteStatus.Opened)
            return DealWorkflowStatus.WaitingForSecondParty;

        if (!string.IsNullOrWhiteSpace(deal.GeneratedHtml) && deal.SecondPartySignedAt is null)
            return DealWorkflowStatus.WaitingForPartyAgreement;

        return DealWorkflowStatus.ReadyToGenerate;
    }

    private static string WorkflowReason(Deal deal, IReadOnlyList<DealFieldState> states)
    {
        if (states.Any(s => s.Dispute) || deal.InviteStatus is InviteStatus.ChangeRequested or InviteStatus.ClarificationRequested)
            return "One or more fields need explicit agreement before generation/signing.";
        if (states.Any(s => s.Required && s.Status == "MISSING"))
            return "Mandatory agreement terms are still missing.";
        if (!string.IsNullOrWhiteSpace(deal.GeneratedHtml) && deal.InviteStatus is InviteStatus.Pending or InviteStatus.Opened)
            return "Agreement draft is ready and waiting for the second party.";
        if (!string.IsNullOrWhiteSpace(deal.GeneratedHtml) && deal.SecondPartySignedAt is null)
            return "Agreement draft is waiting for party agreement/signature.";
        return "All mandatory terms have trusted values.";
    }

    private static string Party(ClassifiedField field) =>
        field.Category == FieldCategory.NeverAsk ? "profile_or_qr" : "deal";
}
