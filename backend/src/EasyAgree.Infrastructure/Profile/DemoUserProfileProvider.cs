using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Infrastructure.Profile;

/// <summary>
/// Fixed demo identity, mirrored by the app's Profile screen. Replace this
/// registration with a MyID-backed provider once the real integration
/// lands — nothing else in the pipeline changes.
/// </summary>
public sealed class DemoUserProfileProvider : IUserProfileProvider
{
    private static readonly UserProfile Demo = new(
        FullName: "Иванов Иван Иванович",
        PassportNumber: "AD 1234567",
        PassportIssuedBy: "ИИБ Юнусабадского района г. Ташкента",
        PassportIssueDate: "01.01.2015",
        BirthDate: "01.01.1990",
        Address: "г. Ташкент, ул. Примерная, 1");

    public Task<UserProfile> GetCurrentAsync(CancellationToken cancellationToken = default) => Task.FromResult(Demo);
}
