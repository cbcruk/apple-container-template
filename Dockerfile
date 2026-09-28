FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=UTC
ARG NODE_MAJOR=22

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg locales tzdata \
      openssh-server sudo gosu \
      zsh git less vim-tiny unzip xz-utils \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen \
    && ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

COPY setup.d/ /tmp/setup.d/
RUN set -e; for f in /tmp/setup.d/*.sh; do [ -e "$f" ] || continue; echo "==> $f"; bash -euo pipefail "$f"; done \
    && rm -rf /tmp/setup.d /var/lib/apt/lists/*

# ubuntu:24.04 ships a "ubuntu" user on UID 1000; remove it so dev can take 1000.
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -u 1000 -s /usr/bin/zsh dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

COPY sshd_config /etc/ssh/sshd_config.d/acx.conf
COPY skel/ /etc/acx-skel/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=$TZ

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
