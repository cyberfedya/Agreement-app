using EasyAgree.Application.Documents;
using EasyAgree.Application.Legal;

namespace UnitTests;

public sealed class LegalKnowledgeEngineTests
{
    [Theory]
    [InlineData("$18,000", "18000", "USD")]
    [InlineData("18 thousand dollars", "18000", "USD")]
    [InlineData("18 mln so'm", "18000000", "UZS")]
    public void Normalizes_explicit_money(string value, string amount, string currency)
    {
        var facts = new LegalKnowledgeEngine([new MoneyKnowledgeProvider()]).Enrich([new DocumentFieldHint("price", value, 0.95, "document")]);
        Assert.Contains(facts, f => f.Key == "normalized_amount" && f.Value == amount);
        Assert.Contains(facts, f => f.Key == "currency" && f.Value == currency && f.Confidence == 1.0);
    }

    [Fact]
    public void Derived_value_never_overwrites_existing_source()
    {
        var facts = new LegalKnowledgeEngine([new MoneyKnowledgeProvider()]).Enrich([
            new DocumentFieldHint("price", "$18,000", 0.95, "document"),
            new DocumentFieldHint("currency", "EUR", 1.0, "user_override")]);
        Assert.Equal("EUR", Assert.Single(facts, f => f.Key == "currency").Value);
    }
}
