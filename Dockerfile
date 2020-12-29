FROM node:lts-alpine AS builder

# Working directory as specified by exercism
WORKDIR /opt/test-runner

# Install curl to download executables
RUN apk add --update --no-cache curl

# Create a directory for binaries
RUN mkdir bin
ENV PATH="/opt/test-runner/bin:${PATH}"

# Install jq
RUN curl -L -o bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 \
  && chmod +x bin/jq

# Install elm
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz \
  && gunzip -c elm.gz > bin/elm \
  && chmod +x bin/elm

# Install elm-test-rs
RUN curl -L -o elm-test-rs_linux.zip https://github.com/mpizenberg/elm-test-rs/releases/download/v0.4.1/elm-test-rs_linux.zip \
  && unzip elm-test-rs_linux.zip \
  && cp elm-test-rs_linux/elm-test-rs bin \
  && chmod +x bin/elm-test-rs

# Build the elm cache in both .elm/ and elm-stuff/
ENV ELM_HOME="/opt/test-runner/.elm"
RUN curl -L -o elm.json https://raw.githubusercontent.com/exercism/elm/master/template/elm.json \
  && mkdir src \
  && elm-test-rs init \
  && elm-test-rs || true

# Pack together things to copy to the runner container
RUN ls -l elm-stuff/tests-0.19.1/
RUN tar cf cache.tar bin elm-stuff .elm elm.json

# Lightweight runner container
FROM node:lts-alpine
WORKDIR /opt/test-runner
COPY --from=builder /opt/test-runner/cache.tar .
COPY bin/run.sh bin/run.sh
ENTRYPOINT [ "bin/run.sh" ]
