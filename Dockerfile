FROM --platform=linux/arm64/v8 docker.io/arm64v8/debian:trixie-slim AS trixie

COPY artifactory.gpg /usr/share/keyrings/artifactory.gpg
COPY elasticsearch-keyring.gpg /usr/share/keyrings/elasticsearch-keyring.gpg
COPY artifactory-rehack.sh /usr/local/bin/artifactory-rehack.sh

RUN set -ex; \
    DEBIAN_FRONTEND=noninteractive; \
    export DEBIAN_FRONTEND; \
    apt -y update; \
    apt -y install --no-install-recommends ca-certificates lz4; \
    apt -y dist-upgrade; \
    apt -y autoremove; \
    apt -y clean; \
    dpkg --add-architecture amd64; \
    echo 'deb [arch=amd64, signed-by=/usr/share/keyrings/artifactory.gpg] https://releases.jfrog.io/artifactory/artifactory-debs bookworm main' > /etc/apt/sources.list.d/artifactory.list; \
    echo 'deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/oss-8.x/apt stable main' > /etc/apt/sources.list.d/elastic-8.x.list; \
    echo 'deb [arch=arm64] https://deb.debian.org/debian bookworm main' > /etc/apt/sources.list.d/bookworm.list; \
    echo 'deb [arch=arm64] https://deb.debian.org/debian-security/ bookworm-security main' >> /etc/apt/sources.list.d/bookworm.list; \
    echo 'Package: qemu*' > /etc/apt/preferences.d/qemu; \
    echo 'Pin: release n=bookworm' >> /etc/apt/preferences.d/qemu; \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/qemu; \
    echo 'DPkg::Post-Invoke { "/usr/local/bin/artifactory-rehack.sh" };' > /etc/apt/apt.conf.d/05artifactory-rehack; \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

RUN set -ex; \
    DEBIAN_FRONTEND=noninteractive; \
    export DEBIAN_FRONTEND; \
    apt -y update; \
    apt -y install --no-install-recommends openjdk-21-jdk-headless libxml2 libxml2-utils logrotate nodejs curl ca-certificates tzdata locales filebeat perl binfmt-support qemu-user qemu-user-binfmt file tini libc6:amd64 libcom-err2:amd64 libcrypt1:amd64 libgcc-s1:amd64 libgssapi-krb5-2:amd64 libidn2-0:amd64 libk5crypto3:amd64 libkeyutils1:amd64 libkrb5-3:amd64 libkrb5support0:amd64 libnsl2:amd64 libnss-nis:amd64 libnss-nisplus:amd64 libssl3:amd64 libtirpc3:amd64 libunistring5:amd64 python3-venv python3-pip python3-wheel libaio1t64 libaio1t64:amd64 unzip sudo procps psmisc lsof strace htop less vim-tiny jfrog-artifactory-jcr; \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*; \
    echo en_GB.UTF-8 UTF-8 > /etc/locale.gen; \
    locale-gen; \
    ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime; \
    curl -LSso /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.30.4/yq_linux_arm64; \
    chmod 755 /usr/local/bin/yq; \
    find /opt/jfrog/artifactory/app/third-party/filebeat /opt/jfrog/artifactory/app/third-party/libxml2 /opt/jfrog/artifactory/app/third-party/logrotate /opt/jfrog/artifactory/app/third-party/node /opt/jfrog/artifactory/app/third-party/yq -type f \( -perm -0100 -o -name \*.so\* \) -print0 | \
        xargs -0 file | \
        grep -F x86-64 | \
        cut -f1 -d: | \
        while read f; \
        do dpkg-divert --local --rename --divert "$f.amd64" --add "$f"; \
        done; \
    find /opt/jfrog/artifactory/app/third-party/java '!' -type d -print | \
        while read f; \
        do t="${f#/opt/jfrog/artifactory/app/third-party/java/}"; \
           v="/opt/jfrog/artifactory/app/third-party/java.amd64/$t"; \
           w="${v%/*}"; \
           mkdir -p "$w"; \
           dpkg-divert --local --rename --divert "$v" --add "$f"; \
        done; \
    find /opt/jfrog/artifactory/app -type f -perm -0100 \! -path \*.amd64\* \! -name \*.amd64 -print0 | \
        xargs -0 file | \
        grep -F x86-64 | \
        cut -f1 -d: | \
        while read f; \
        do dpkg-divert --local --rename --divert "$f.orig" --add "$f"; \
        echo '#!/bin/sh' > "$f"; \
        echo 'exec qemu-x86_64 "${0}.orig" "$@"' >> "$f"; \
        chmod 755 "$f"; \
        done; \
    ln -s /usr/lib/aarch64-linux-gnu/libxml2.so.2 /opt/jfrog/artifactory/app/third-party/libxml2/lib/libxml2.so; \
    ln -s /usr/lib/aarch64-linux-gnu/libxml2.so.2 /opt/jfrog/artifactory/app/third-party/libxml2/lib/libxml2.so.2; \
    ln -s /usr/lib/aarch64-linux-gnu/libxml2.so.2 /opt/jfrog/artifactory/app/third-party/libxml2/lib/libxml2.so.2.9.12; \
    ln -s /usr/bin/xmllint /usr/bin/xmlcatalog /opt/jfrog/artifactory/app/third-party/libxml2/bin/; \
    ln -s /usr/share/filebeat/bin/filebeat /opt/jfrog/artifactory/app/third-party/filebeat/; \
    ln -s /sbin/logrotate /opt/jfrog/artifactory/app/third-party/logrotate/; \
    ln -s /usr/bin/node /opt/jfrog/artifactory/app/third-party/node/bin/; \
    ln -s /usr/local/bin/yq /opt/jfrog/artifactory/app/third-party/yq/; \
    rm -rf /opt/jfrog/artifactory/app/third-party/java; \
    ln -s /usr/lib/jvm/java-21-openjdk-arm64 /opt/jfrog/artifactory/app/third-party/java; \
    find /opt/jfrog/artifactory/app/third-party -name \*.amd64 -print0 | xargs -0 rm -rf; \
    /usr/local/bin/artifactory-rehack.sh; \
    mv /var/opt/jfrog/artifactory /var/opt/jfrog/artifactory.orig; \
    chown -R artifactory:artifactory /var/opt/jfrog/artifactory.orig

RUN set -ex; \
    python3 -m venv /opt/oci; \
    /opt/oci/bin/pip3 install wheel; \
    /opt/oci/bin/pip3 install oci-cli; \
    rm -rf /root/.cache

RUN set -ex; \
    mkdir -p /var/opt/jfrog/artifactory; \
    chown artifactory:artifactory /var/opt/jfrog/artifactory

COPY --chown=artifactory:artifactory system.yaml /opt/jfrog/artifactory/system.yaml
COPY load-secrets.sh /usr/local/bin/load-secrets.sh
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENV OCI_CLI_AUTH=instance_principal
VOLUME /var/opt/jfrog/artifactory
ENTRYPOINT ["/bin/tini", "--"]
CMD ["/docker-entrypoint.sh"]
WORKDIR /opt/jfrog/artifactory
