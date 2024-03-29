FROM node:lts-alpine AS builder

# Working directory as specified by exercism
WORKDIR /opt/test-runner

# Install curl to download executables
RUN apk add --update --no-cache curl tinyproxy sed

# Create a directory for binaries
RUN mkdir bin && cp /usr/bin/tinyproxy /bin/sed bin
ENV PATH="/opt/test-runner/bin:${PATH}"

# Install jq
RUN curl -L -o bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 \
  && chmod +x bin/jq

# Install elm
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz \
  && gunzip -c elm.gz > bin/elm \
  && chmod +x bin/elm

# Install elm-test-rs
RUN curl -L -o elm-test-rs_linux.tar.gz https://github.com/mpizenberg/elm-test-rs/releases/download/v3.0/elm-test-rs_linux.tar.gz \
  && tar xf elm-test-rs_linux.tar.gz \
  && mv elm-test-rs bin

# Build the elm cache in both .elm/ and elm-stuff/
ENV ELM_HOME="/opt/test-runner/.elm"
RUN curl -L -o elm.json https://raw.githubusercontent.com/exercism/elm/main/template/elm.json \
  && mkdir src \
  && elm-test-rs init \
  && elm-test-rs || true
RUN tar cf cache.tar elm-stuff .elm elm.json

# Build the test code extractor
COPY extract-test-code extract-test-code
RUN cd extract-test-code \
  && elm make --optimize src/Main.elm --output=src/main.js \
  && cd src \
  && cp cli.js main.js ../../bin

# Pack together things to copy to the runner container
COPY bin/run.sh bin/run.sh
COPY bin/smoke_test.sh bin/smoke_test.sh

# Lightweight runner container
FROM node:lts-alpine
WORKDIR /opt/test-runner
ENV PATH="/opt/test-runner/bin:${PATH}"
COPY --from=builder /opt/test-runner/bin bin
COPY --from=builder /opt/test-runner/cache.tar .
ENTRYPOINT [ "bin/run.sh" ]
