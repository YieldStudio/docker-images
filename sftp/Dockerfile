FROM alpine:latest

# Steps done in one RUN layer:
# - Install upgrades and new packages
# - OpenSSH needs /var/run/sshd to run
# - Remove generic host keys, entrypoint generates unique keys
RUN apk update && apk upgrade && \
    apk add bash shadow openssh-server-pam openssh-sftp-server s3fs-fuse && \
    rm -rf /var/cache/apk/* && \
    ln -s /usr/sbin/sshd.pam /usr/sbin/sshd && \
    mkdir -p /var/run/sshd && \
    rm -f /etc/ssh/ssh_host_*key*

COPY --chmod=755 common/ /

EXPOSE 22

ENV S3FS_PARALLEL_COUNT="5"
ENV S3FS_MULTIPART_SIZE="128"

HEALTHCHECK \
  --interval=15s \
  --timeout=5s \
  --start-period=15s \
  --retries=2 \
  CMD [ "/usr/local/bin/healthcheck.sh" ]

ENTRYPOINT ["docker-sftp-entrypoint"]
