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

# Tesseract OCR engine, self-hosted (no API key). Language data is
# downloaded directly from the official tessdata repo rather than relying
# on whatever Uzbek package name/path the base image's apt repos happen to
# ship - documents mix Russian, English, and Uzbek in both scripts.
ENV TESSDATA_PREFIX=/usr/share/tessdata
RUN apt-get update \
    && apt-get install -y --no-install-recommends tesseract-ocr ca-certificates curl \
    && mkdir -p /usr/share/tessdata \
    && curl -fsSL -o /usr/share/tessdata/eng.traineddata https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata \
    && curl -fsSL -o /usr/share/tessdata/rus.traineddata https://github.com/tesseract-ocr/tessdata/raw/main/rus.traineddata \
    && curl -fsSL -o /usr/share/tessdata/uzb.traineddata https://github.com/tesseract-ocr/tessdata/raw/main/uzb.traineddata \
    && curl -fsSL -o /usr/share/tessdata/uzb_cyrl.traineddata https://github.com/tesseract-ocr/tessdata/raw/main/uzb_cyrl.traineddata \
    && apt-get purge -y curl && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "EasyAgree.Api.dll"]
