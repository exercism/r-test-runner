FROM rocker/r-ubuntu:22.04

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    jq \
    r-cran-testthat \
    r-cran-tidyverse \
  && apt-get purge --auto-remove -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY . /opt/test-runner
WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
