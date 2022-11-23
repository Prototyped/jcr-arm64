FROM --platform=linux/arm64/v8 public.ecr.aws/debian/debian:testing-slim AS testing

COPY artifactory.gpg /usr/share/keyrings/artifactory.gpg
COPY elasticsearch-keyring.gpg /usr/share/keyrings/elasticsearch-keyring.gpg
COPY fix-artifactory-list.pl /usr/local/bin/fix-artifactory-list.pl
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
    echo 'deb [arch=amd64, signed-by=/usr/share/keyrings/artifactory.gpg] https://releases.jfrog.io/artifactory/artifactory-debs buster main' > /etc/apt/sources.list.d/artifactory.list; \
    echo 'deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/oss-8.x/apt stable main' > /etc/apt/sources.list.d/elastic-8.x.list; \
    echo 'APT::Update::Post-Invoke { "/usr/local/bin/fix-artifactory-list.pl" };' > /etc/apt/apt.conf.d/40cleanup-artifactory-list; \
    echo 'DPkg::Post-Invoke { "/usr/local/bin/artifactory-rehack.sh" };' > /etc/apt/apt.conf.d/05artifactory-rehack; \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

RUN set -ex; \
    DEBIAN_FRONTEND=noninteractive; \
    export DEBIAN_FRONTEND; \
    apt -y update; \
    apt -y install --no-install-recommends openjdk-17-jdk-headless libxml2 libxml2-utils logrotate nodejs curl ca-certificates tzdata locales filebeat perl jfrog-artifactory-jcr binfmt-support qemu-user qemu-user-binfmt file tini libc6:amd64 libcom-err2:amd64 libcrypt1:amd64 libgcc-s1:amd64 libgssapi-krb5-2:amd64 libidn2-0:amd64 libk5crypto3:amd64 libkeyutils1:amd64 libkrb5-3:amd64 libkrb5support0:amd64 libnsl2:amd64 libnss-nis:amd64 libnss-nisplus:amd64 libssl3:amd64 libtirpc3:amd64 libunistring2:amd64 python3-venv python3-pip python3-wheel libaio1 libaio1:amd64 unzip sudo procps psmisc lsof strace htop less vim-tiny; \
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
    ln -s /usr/lib/aarch64-linux-gnu/libxml2.so.2 /opt/jfrog/artifactory/app/third-party/libxml2/lib/libxml2.so; \
    ln -s /usr/lib/aarch64-linux-gnu/libxml2.so.2 /opt/jfrog/artifactory/app/third-party/libxml2/lib/libxml2.so.2; \
    ln -s /usr/lib/aarch64-linux-gnu/libxml2.so.2 /opt/jfrog/artifactory/app/third-party/libxml2/lib/libxml2.so.2.9.12; \
    ln -s /usr/bin/xmllint /usr/bin/xmlcatalog /opt/jfrog/artifactory/app/third-party/libxml2/bin/; \
    ln -s /usr/share/filebeat/bin/filebeat /opt/jfrog/artifactory/app/third-party/filebeat/; \
    ln -s /sbin/logrotate /opt/jfrog/artifactory/app/third-party/logrotate/; \
    ln -s /usr/bin/node /opt/jfrog/artifactory/app/third-party/node/bin/; \
    ln -s /usr/local/bin/yq /opt/jfrog/artifactory/app/third-party/yq/; \
    rm -rf /opt/jfrog/artifactory/app/third-party/java; \
    ln -s /usr/lib/jvm/java-17-openjdk-arm64 /opt/jfrog/artifactory/app/third-party/java; \
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
    ln -s /usr/lib/aarch64-linux-gnu/libaio.so.1 /var/opt/jfrog/artifactory.orig/bootstrap/artifactory/tomcat/lib/libaio.so; \
    ln -s /usr/lib/aarch64-linux-gnu/libaio.so.1 /var/opt/jfrog/artifactory.orig/bootstrap/artifactory/tomcat/lib/libaio.so.1; \
    curl -LSso /tmp/instantclient-basic-linux.arm64-19.10.0.0.0dbru.zip https://download.oracle.com/otn_software/linux/instantclient/191000/instantclient-basic-linux.arm64-19.10.0.0.0dbru.zip; \
    echo "0cd9ed1f6d01026a3990ecfbb84816d8d5da35fc1dbc9f25f28327a79d013ac6  /tmp/instantclient-basic-linux.arm64-19.10.0.0.0dbru.zip" > /tmp/oracle-instant-client.sha256sum; \
    sha256sum -c /tmp/oracle-instant-client.sha256sum; \
    rm -f /tmp/oracle-instant-client.sha256sum; \
    unzip -d /opt /tmp/instantclient-basic-linux.arm64-19.10.0.0.0dbru.zip; \
    echo /opt/instantclient_19_10 > /etc/ld.so.conf.d/oracle-instant-client.conf; \
    rm -f /tmp/instantclient-basic-linux.arm64-19.10.0.0.0dbru.zip; \
    chown -R artifactory:artifactory /opt/instantclient_19_10/network/admin; \
    curl -LSso /tmp/instantclient-sqlplus-linux.arm64-19.10.0.0.0dbru.zip https://download.oracle.com/otn_software/linux/instantclient/191000/instantclient-sqlplus-linux.arm64-19.10.0.0.0dbru.zip; \
    echo "8877328a31e102f8ec02a37d47e471a36478ee4f78d15bcf6d271cd8c5989f44  /tmp/instantclient-sqlplus-linux.arm64-19.10.0.0.0dbru.zip" > /tmp/oracle-sql-plus.sha256sum; \
    sha256sum -c /tmp/oracle-sql-plus.sha256sum; \
    unzip -d /opt /tmp/instantclient-sqlplus-linux.arm64-19.10.0.0.0dbru.zip; \
    rm -f /tmp/instantclient-sqlplus-linux.arm64-19.10.0.0.0dbru.zip; \
    curl -LSso /tmp/ojdbc10-full.tar.gz https://download.oracle.com/otn-pub/otn_software/jdbc/1916/ojdbc10-full.tar.gz; \
    echo "6af7414e94732fbfb807312bbc3f4092bb54c189ae41f40fc130b8e3c1946f8a  /tmp/ojdbc10-full.tar.gz" > /tmp/ojdbc10.sha256sum; \
    sha256sum -c /tmp/ojdbc10.sha256sum; \
    rm -f /tmp/ojdbc10.sha256sum; \
    tar -C /opt -xzpf /tmp/ojdbc10-full.tar.gz; \
    ln -s /opt/ojdbc10-full/dms.jar /opt/ojdbc10-full/ojdbc10.jar /opt/ojdbc10-full/ojdbc10dms.jar /opt/ojdbc10-full/ons.jar /opt/ojdbc10-full/oraclepki.jar /opt/ojdbc10-full/orai18n.jar /opt/ojdbc10-full/osdt_cert.jar /opt/ojdbc10-full/osdt_core.jar /opt/ojdbc10-full/simplefan.jar /opt/ojdbc10-full/ucp.jar /opt/ojdbc10-full/xdb.jar /opt/ojdbc10-full/*policy /var/opt/jfrog/artifactory.orig/bootstrap/artifactory/tomcat/lib/; \
    ldconfig; \
    curl -LSso /tmp/instantclient-basic-linux.x64-21.8.0.0.0dbru.zip https://download.oracle.com/otn_software/linux/instantclient/218000/instantclient-basic-linux.x64-21.8.0.0.0dbru.zip; \
    echo "ea77954b53fa04ae078d15b7da04407f7561c22a0bf49c2a0558b183aeaac560  /tmp/instantclient-basic-linux.x64-21.8.0.0.0dbru.zip" > /tmp/oracle-instant-client-amd64.sha256sum; \
    sha256sum -c /tmp/oracle-instant-client-amd64.sha256sum; \
    unzip -d /opt /tmp/instantclient-basic-linux.x64-21.8.0.0.0dbru.zip; \
    rm -f /tmp/instantclient-basic-linux.x64-21.8.0.0.0dbru.zip; \
    mv /opt/instantclient_21_8 /opt/instantclient_21_8_amd64; \
    chown -R artifactory:artifactory /opt/instantclient_21_8_amd64/network/admin

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
