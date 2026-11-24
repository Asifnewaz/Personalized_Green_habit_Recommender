FROM rocker/tidyverse:4.4.2

# Install system libraries for plumber (libsodium) and sparse matrix/graph deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsodium-dev \
    libglpk-dev \
    && rm -rf /var/lib/apt/lists/*

# Install remaining CRAN packages from Posit Package Manager (pre-compiled Ubuntu binaries)
RUN Rscript -e "options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/noble/latest')); \
  pkgs <- c('plumber', 'here', 'forecast', 'recommenderlab', 'arules'); \
  install.packages(pkgs, Ncpus = 2); \
  invisible(lapply(c(pkgs, 'jsonlite', 'httr2', 'dplyr', 'tidyr', 'stringr', 'lubridate', 'readr', 'purrr'), library, character.only = TRUE))"

WORKDIR /app

# Create sentinel .here file at container app root so here::here() resolves to /app
RUN touch /app/.here

# Copy r_service directory into /app/r_service
COPY . /app/r_service

EXPOSE 8001

ENTRYPOINT ["Rscript", "-e", "pr <- plumber::plumb('/app/r_service/plumber.R'); pr$run(host = '0.0.0.0', port = 8001)"]