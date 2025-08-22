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

ENTRYPOINT ["docker-sftp-entrypoint"]
