FROM arm32v7/ubuntu:16.04

# Set up insecure default key
RUN mkdir -m 0750 /root/.android
ADD files/insecure_shared_adbkey /root/.android/adbkey
ADD files/insecure_shared_adbkey.pub /root/.android/adbkey.pub
ADD files/adb /opt/platform-tools/adb

ENV TINI_VERSION 0.18.0
RUN set -x \
    && apt-get update && apt-get install -y ca-certificates curl \
        --no-install-recommends \
    && curl -fSL "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-armhf" -o /usr/local/bin/tini \
    && curl -fSL "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-armhf.asc" -o /usr/local/bin/tini.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 \
    && gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini \
    && rm -r "$GNUPGHOME" /usr/local/bin/tini.asc \
    && chmod +x /usr/local/bin/tini \
    && tini -h \
    && apt-get purge --auto-remove -y ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Expose default ADB port
EXPOSE 5037

# Set up PATH
ENV PATH $PATH:/opt/platform-tools

# Hook up tini as the default init system for proper signal handling
ENTRYPOINT ["tini", "--"]

# Start the server by default
CMD ["adb", "-a", "-P", "5037", "server", "nodaemon"]
