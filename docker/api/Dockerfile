FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore first, in its own layer keyed only on project files - this layer
# is reused (no NuGet re-download) on every subsequent build where the
# dependency set hasn't changed, instead of restoring from scratch on every
# deploy just because some .cs file changed.
COPY src/EasyAgree.Domain/*.csproj src/EasyAgree.Domain/
COPY src/EasyAgree.Contracts/*.csproj src/EasyAgree.Contracts/
COPY src/EasyAgree.Application/*.csproj src/EasyAgree.Application/
COPY src/EasyAgree.Infrastructure/*.csproj src/EasyAgree.Infrastructure/
COPY src/EasyAgree.Api/*.csproj src/EasyAgree.Api/
RUN dotnet restore src/EasyAgree.Api/EasyAgree.Api.csproj

COPY . .
RUN dotnet publish src/EasyAgree.Api/EasyAgree.Api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "EasyAgree.Api.dll"]
