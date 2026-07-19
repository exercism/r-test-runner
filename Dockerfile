# target: r-minimal:latest
FROM rhub/r-minimal:4.6-patched@sha256:20fc0cc6ab3992676d25a8e4f932e2ec1109abc140360a3025ce24f4c2cacd87

RUN apk --update add jq

RUN installr -d \
    -t "curl-dev libxml2-dev linux-headers gfortran fontconfig-dev fribidi-dev harfbuzz-dev freetype-dev libpng-dev tiff-dev" \
    -a "libcurl libxml2 fontconfig fribidi harfbuzz freetype libpng tiff libjpeg icu-libs" \
    tidyverse  \
    testthat

COPY . /opt/test-runner
WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
