FROM node:lts-alpine

# Working directory as specified by exercism
WORKDIR /opt/test-runner

# Copy package.json for npm install
COPY package.json ./

# Install bash and python for the conversion script globally
RUN apk --update --no-cache add bash curl python3 \
  # Install elm and elm-test locally (need package.json)
  && npm install \
  # Retrieve elm packages for offline usage, create a .elm/ directory
  && curl -LJ https://github.com/exercism/elm-test-runner/files/4113689/elm_home.tar.gz | tar xz

# Copy necessary files
COPY process_results.py ./
COPY bin/run.sh bin/run.sh

ENTRYPOINT [ "bash", "bin/run.sh" ]
