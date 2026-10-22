FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy dependency manifests first to preserve restore cache
COPY Backend.csproj ./

# Cache NuGet packages across builds
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet restore Backend.csproj

# Copy the remaining source code
COPY . .

# Publish a production build
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish Backend.csproj \
    --configuration Release \
    --output /app/publish \
    --no-restore \
    -p:UseAppHost=false

# Runtime image: no SDK or build tools
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

ENV ASPNETCORE_HTTP_PORTS=8080 \
    ASPNETCORE_ENVIRONMENT=Production

EXPOSE 8080

COPY --from=build /app/publish/ ./

# Run as the non-root user provided by the official image
USER $APP_UID

ENTRYPOINT ["dotnet", "BigFit.Backend.dll"]