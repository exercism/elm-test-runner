FROM node:lts-alpine
 
ENV ELM_VERSION 0.19.1

RUN mkdir /opt/test-runner
RUN mkdir /opt/test-runner/bin

RUN apk --update --no-cache add bash \
  && apk add python3 \
  && node -v \
  && wget https://github.com/elm/compiler/releases/download/${ELM_VERSION}/binary-for-linux-64-bit.gz \
  && gzip -d binary-for-linux-64-bit.gz \
  && mv binary-for-linux-64-bit /usr/local/bin/elm \
  && chmod +x /usr/local/bin/elm

# --unsafe-perm is required here, for some reason I don't understand
# It's a bit of a shame to install elm-test via npm, but install 
# Elm itself by downloading and unzipping. It would be better to 
# be consistent, but installing Elm via npm failed for me.
RUN npm install --unsafe-perm -g elm-test@0.19.1

COPY ./run.sh /opt/test-runner/bin
COPY ./process_results.py /opt/test-runner/bin

ENTRYPOINT [ "sh", "/opt/test-runner/bin/run.sh" ]