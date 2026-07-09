using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Profile;
using EasyAgree.Contracts.Profile;

namespace EasyAgree.Api.Endpoints;

public static class ProfileEndpoints
{
    public static IEndpointRouteBuilder MapProfileEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/profile").WithTags("Profile");

        group.MapGet("/{id}", async (string id, GetUserProfileUseCase useCase, CancellationToken ct) =>
        {
            var profile = await useCase.ExecuteAsync(id, ct);
            return profile is null ? Results.NotFound() : Results.Ok(profile);
        })
        .WithName("GetUserProfile");

        group.MapPut("/{id}", async (
            string id, SaveUserProfileRequest request, SaveUserProfileUseCase useCase, CancellationToken ct) =>
        {
            var profile = await useCase.ExecuteAsync(id, request, ct);
            return Results.Ok(profile);
        })
        .WithName("SaveUserProfile");

        group.MapDelete("/{id}", async (string id, IUserProfileRepository repository, CancellationToken ct) =>
        {
            await repository.DeleteAsync(id, ct);
            return Results.NoContent();
        })
        .WithName("DeleteUserProfile");

        return app;
    }
}
