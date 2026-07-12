using EasyAgree.Application.Documents;
using EasyAgree.Application.Legal;

namespace UnitTests;

public sealed class LegalKnowledgeProviderTests
{
    [Fact]
    public void Vehicle_provider_normalizes_vin_and_derives_wmi_country()
    {
        var facts = new LegalKnowledgeEngine([new VehicleKnowledgeProvider()])
            .Enrich([new DocumentFieldHint("vin", "JHM-CM56557C404453", 0.99, "document")]);
        Assert.Contains(facts, f => f.Key == "vin_normalized" && f.Value == "JHMCM56557C404453");
        Assert.Contains(facts, f => f.Key == "vehicle_country" && f.Value == "JP");
    }

    [Fact]
    public void Address_provider_extracts_explicit_city_only()
    {
        var facts = new LegalKnowledgeEngine([new AddressKnowledgeProvider()])
            .Enrich([new DocumentFieldHint("property_address", "Tashkent, Chilanzar 12", 0.99, "document")]);
        Assert.Contains(facts, f => f.Key == "city" && f.Value == "Tashkent");
    }

    [Fact]
    public void Date_provider_uses_supplied_clock_for_relative_date()
    {
        var clock = new FakeTimeProvider(new DateTimeOffset(2026, 7, 12, 0, 0, 0, TimeSpan.Zero));
        var facts = new LegalKnowledgeEngine([new DateKnowledgeProvider(clock)])
            .Enrich([new DocumentFieldHint("transfer_date", "end of year", 1, "manual")]);
        Assert.Contains(facts, f => f.Key == "normalized_transfer_date" && f.Value == "2026-12-31");
    }

    [Fact]
    public void Existing_fact_creates_conflict_instead_of_being_overwritten()
    {
        var report = new LegalKnowledgeEngine([new ConflictingProvider()]).EnrichWithReport([new DocumentFieldHint("currency", "EUR", 1, "user_override")]);
        Assert.Equal("EUR", Assert.Single(report.Facts, f => f.Key == "currency").Normalized);
        Assert.Single(report.Conflicts);
    }

    private sealed class ConflictingProvider : ILegalKnowledgeProvider
    {
        public int Order => 1;
        public string Name => "test";
        public IReadOnlyList<LegalFact> Derive(IReadOnlyList<LegalFact> _) => [new("currency", "test", "USD", 1, Name, "AUTO", "test", ["test"])];
    }

    private sealed class FakeTimeProvider(DateTimeOffset now) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => now;
    }
}
