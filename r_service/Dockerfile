# ==============================================================================
# Dockerfile: r_service/Dockerfile
# Sprint: Sprint 3 (Home Energy Coach - R Analytics Microservice)
# Description: Containerizes the decoupled R analytics engine + thin plumber
#              HTTP transport layer on port 8001.
# ==============================================================================

FROM rocker/r-ver:4.4.2

# Install system dependencies required by httr2, curl, openssl, and arules/forecast
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libsodium-dev \
    zlib1g-dev \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Install required CRAN packages
RUN Rscript -e "install.packages(c( \
    'plumber', 'jsonlite', 'here', 'httr2', \
    'dplyr', 'tidyr', 'stringr', 'lubridate', 'readr', 'purrr', \
    'forecast', 'recommenderlab', 'arules' \
  ), repos = 'https://cloud.r-project.org', Ncpus = 2)"

WORKDIR /app

# Create sentinel .here file at container app root so here::here() resolves to /app
RUN touch /app/.here

# Copy r_service directory into /app/r_service
COPY . /app/r_service

EXPOSE 8001

ENTRYPOINT ["Rscript", "-e", "pr <- plumber::plumb('/app/r_service/plumber.R'); pr$run(host = '0.0.0.0', port = 8001)"]