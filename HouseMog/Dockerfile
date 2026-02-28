# syntax=docker/dockerfile:1

# Create a stage for building the application.
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build

COPY . /source

WORKDIR /source

# This is the architecture you're building for, which is passed in by the builder.
ARG TARGETARCH

# Build the application.
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish -a ${TARGETARCH/amd64/x64} --use-current-runtime --self-contained false -o /app

# Create a new stage for running the application
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS final
WORKDIR /app

# Install ICU libraries for full globalization support (required by Discord.Net)
RUN apk add --no-cache icu-libs
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

# Copy everything needed to run the app from the "build" stage.
COPY --from=build /app .
COPY --from=build /source/time.txt .
# Create a non-privileged user that the app will run under.
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser

ENTRYPOINT ["dotnet", "HouseMog.dll"]
