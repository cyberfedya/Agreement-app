using System.Text.Json;

namespace EasyAgree.Application.Deals;

public sealed record DealPartyResponse(
    string Type,
    int? FieldId,
    string? ProposedValue,
    string? Message,
    string? ProfileId,
    DateTime CreatedAt);

public static class DealPartyResponseTypes
{
    public const string Decline = "decline";
    public const string ProposedChange = "proposed_change";
    public const string Clarification = "clarification";
}

public static class DealPartyResponseSerializer
{
    private static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web);

    public static List<DealPartyResponse> Deserialize(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return [];

        try
        {
            return JsonSerializer.Deserialize<List<DealPartyResponse>>(json, Options) ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }

    public static string Serialize(IEnumerable<DealPartyResponse> responses) =>
        JsonSerializer.Serialize(responses.OrderBy(r => r.CreatedAt).ToList(), Options);
}
