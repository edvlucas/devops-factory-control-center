FROM mcr.microsoft.com/azure-cli:2.35.0

ENV BICEP_VERSION=0.5.6
LABEL version=${BICEP_VERSION}

RUN curl -Lo bicep https://github.com/Azure/bicep/releases/download/v${BICEP_VERSION}/bicep-linux-musl-x64 \
    && chmod +x ./bicep \
    && mv ./bicep /usr/local/bin/bicep

WORKDIR /bicep

ENTRYPOINT [ "bicep", "--version" ]