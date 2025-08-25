# SFTP

Easy to use SFTP ([SSH File Transfer Protocol](https://en.wikipedia.org/wiki/SSH_File_Transfer_Protocol)) server with [OpenSSH](https://en.wikipedia.org/wiki/OpenSSH).

# Usage

- Define users in (1) command arguments, (2) `SFTP_USERS` environment variable
  or (3) in file mounted as `/etc/sftp/users.conf` (syntax:
  `user:pass[:e][:uid[:gid[:dir1[,dir2]...]]] ...`, see below for examples)
  - Set UID/GID manually for your users if you want them to make changes to
    your mounted volumes with permissions matching your host filesystem.
  - Directory names at the end will be created under user's home directory with
    write permission, if they aren't already present.
- Mount volumes
  - The users are chrooted to their home directory, so you can mount the
    volumes in separate directories inside the user's home directory
    (/home/user/**mounted-directory**) or just mount the whole **/home** directory.
    Just remember that the users can't create new files directly under their
    own home directory, so make sure there are at least one subdirectory if you
    want them to upload files.
  - For consistent server fingerprint, mount your own host keys (i.e. `/etc/ssh/ssh_host_*`)

# Examples

## Simplest docker run example

```
docker run -p 22:22 -d yieldstudio/sftp foo:pass:::upload
```

User "foo" with password "pass" can login with sftp and upload files to a folder called "upload". No mounted directories or custom UID/GID. Later you can inspect the files and use `--volumes-from` to mount them somewhere else (or see next example).

## Sharing a directory from your computer

Let's mount a directory and set UID:

```
docker run \
    -v <host-dir>/upload:/home/foo/upload \
    -p 2222:22 -d yieldstudio/sftp \
    foo:pass:1001
```

### Using Docker Compose:

```
sftp:
    image: yieldstudio/sftp
    volumes:
        - <host-dir>/upload:/home/foo/upload
    ports:
        - "2222:22"
    command: foo:pass:1001
```

### Logging in

The OpenSSH server runs by default on port 22, and in this example, we are forwarding the container's port 22 to the host's port 2222. To log in with the OpenSSH client, run: `sftp -P 2222 foo@<host-ip>`

## Store users in config

```
docker run \
    -v <host-dir>/users.conf:/etc/sftp/users.conf:ro \
    -v mySftpVolume:/home \
    -p 2222:22 -d yieldstudio/sftp
```

<host-dir>/users.conf:

```
foo:123:1001:100
bar:abc:1002:100
baz:xyz:1003:100
```

## Providing your own SSH host key (recommended)

This container will generate new SSH host keys at first run. To avoid that your users get a MITM warning when you recreate your container (and the host keys changes), you can mount your own host keys.

```
docker run \
    -v <host-dir>/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key \
    -v <host-dir>/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key \
    -v <host-dir>/share:/home/foo/share \
    -p 2222:22 -d yieldstudio/sftp \
    foo::1001
```

You can also setup the host keys with `SSH_ED25519_KEY` and `SSH_RSA_KEY` environment variables (base64 encoded).

```
docker run \
    -e SSH_ED25519_KEY=$(cat <host-dir>/ssh_host_ed25519_key | base64) \
    -e SSH_RSA_KEY=$(cat <host-dir>/ssh_host_rsa_key | base64) \
    -v <host-dir>/share:/home/foo/share \
    -p 2222:22 -d yieldstudio/sftp \
    foo::1001
```

Tip: you can generate your keys with these commands:

```
ssh-keygen -t ed25519 -f ssh_host_ed25519_key < /dev/null
ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key < /dev/null
```

**NOTE:** Using `mount` requires that your container runs with the `CAP_SYS_ADMIN` capability turned on. [See this answer for more information](https://github.com/yieldstudio/sftp/issues/60#issuecomment-332909232).



## S3FS Mounting

You can mount an S3 bucket using s3fs with the following environment variables:

- `S3FS_ENABLED`: enable S3FS mounting (`true` or `1`)
- `AWS_BUCKET`: S3 bucket name
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`: AWS credentials
- `S3FS_CREDENTIALS`: alternative, format `access_key:secret_key`
- `AWS_ENDPOINT`: S3 endpoint URL (default: https://s3.amazonaws.com)
- `AWS_DEFAULT_REGION`: AWS region (default: us-east-1)
- `S3FS_ARGS`: additional s3fs options (e.g. `allow_other,use_path_request_style,nocopyapi`)
- `S3FS_PARALLEL_COUNT`: number of parallel threads (default: 15)
- `S3FS_MULTIPART_SIZE`: multipart size (default: 128)
- `S3FS_DEBUG`: enable debug mode (`true` or `1`)
- `S3FS_ROOTDIR`: root directory for s3fs (default: /opt/s3fs)
- `S3FS_MOUNT`: mount point in the container (default: /opt/s3fs/bucket)
- `S3FS_AUTHFILE`: path to the authentication file (default: /opt/s3fs/passwd-s3fs)
- `AWS_USE_PATH_STYLE_ENDPOINT`, `S3FS_ALLOW_OTHER`, `S3FS_NO_COPY_API`: boolean options for mounting

Example:

```
docker run \
    -e S3FS_ENABLED=true \
    -e AWS_BUCKET=<your-bucket-name> \
    -e AWS_ACCESS_KEY_ID=<your-access-key-id> \
    -e AWS_SECRET_ACCESS_KEY=<your-secret-access-key> \
    -e S3FS_ALLOW_OTHER=true \
    -e S3FS_NO_COPY_API=true \
    -e S3FS_PARALLEL_COUNT=15 \
    -e S3FS_MULTIPART_SIZE=128 \
    -p 2222:22 -d yieldstudio/sftp \
    foo::1001
```

### Scaleway S3

For Scaleway S3, add the custom endpoint:

```
docker run \
    -e S3FS_ENABLED=true \
    -e AWS_BUCKET=<your-bucket-name> \
    -e AWS_ACCESS_KEY_ID=<your-access-key-id> \
    -e AWS_SECRET_ACCESS_KEY=<your-secret-access-key> \
    -e AWS_ENDPOINT="https://s3.<region>.scw.cloud" \
    -e AWS_USE_PATH_STYLE_ENDPOINT=true \
    -e S3FS_ALLOW_OTHER=true \
    -e S3FS_NO_COPY_API=true \
    -e S3FS_PARALLEL_COUNT=15 \
    -e S3FS_MULTIPART_SIZE=128 \
    -e SFTP_USERS="foo::1001" \
    -p 2222:22 -d yieldstudio/sftp
```