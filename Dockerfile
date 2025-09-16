# Use official Python 3.12 slim image
FROM mcr.microsoft.com/devcontainers/python:1-3.12

# Set environment variables
ARG PACKAGE_USER
ARG PACKAGE_TOKEN
ENV PIP_INDEX_URL="https://${PACKAGE_USER}:${PACKAGE_TOKEN}@artifactory.chevron.com/api/pypi/pypi/simple/"
ENV PIP_EXTRA_INDEX_URL=https://pypi.org/simple
WORKDIR /code
# Build Arguments
ARG KEY_VAULT_NAME
ARG AZURE_TENANT_ID
ARG AZURE_CLIENT_ID
ARG AZURE_CLIENT_SECRET
ARG DB_CONNECTION_STRING
ARG AZURE_OPENAI_API_VERSION
ARG AZURE_OPENAI_ENDPOINT
ARG AZURE_OPENAI_MODEL_NAME


# Environment Variables
ENV KEY_VAULT_NAME=$KEY_VAULT_NAME
ENV AZURE_TENANT_ID=$AZURE_TENANT_ID
ENV AZURE_CLIENT_ID=$AZURE_CLIENT_ID
ENV AZURE_CLIENT_SECRET=$AZURE_CLIENT_SECRET
ENV DB_CONNECTION_STRING=$DB_CONNECTION_STRING
ENV AZURE_OPENAI_API_VERSION=$AZURE_OPENAI_API_VERSION
ENV AZURE_OPENAI_ENDPOINT=$AZURE_OPENAI_ENDPOINT
ENV AZURE_OPENAI_MODEL_NAME=$AZURE_OPENAI_MODEL_NAME

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    unixodbc-dev \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

    # Add Microsoft repository and install ODBC driver
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 \
    && rm -rf /var/lib/apt/lists/*
# Install Python dependencies
RUN pip install --upgrade pip

COPY ./requirements.txt /code/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

EXPOSE 8081
COPY ./ /code
CMD ["uvicorn", "app.main:fastapi_app", "--host", "0.0.0.0", "--port", "8081"]