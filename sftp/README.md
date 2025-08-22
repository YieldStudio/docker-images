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

You can mount an S3 bucket using s3fs. You need to provide your AWS credentials and the bucket name as environment variables. You also need to install s3fs in the container. You can do this by creating a custom Dockerfile that extends the yieldstudio/sftp image.

```
docker run \
    -e ENABLE_S3FS=true \
    -e AWS_S3_BUCKET=<your-bucket-name> \
    -e AWS_S3_ACCESS_KEY_ID=<your-access-key-id> \
    -e AWS_S3_SECRET_ACCESS_KEY=<your-secret-access-key> \
    -p 2222:22 -d yieldstudio/sftp \
    foo::1001
```

### Scaleway S3

If you are using Scaleway S3, you need to provide the endpoint as well.

```
docker run \
    -e ENABLE_S3FS=true \
    -e AWS_S3_BUCKET=<your-bucket-name> \
    -e AWS_S3_ACCESS_KEY_ID=<your-access-key-id> \
    -e AWS_S3_SECRET_ACCESS_KEY=<your-secret-access-key> \
    -e AWS_S3_URL="https://s3.<region>.scw.cloud" \
    -e S3FS_ARGS="allow_other,use_path_request_style,nocopyapi,parallel_count=15,multipart_size=128" \
    -e SFTP_USERS="foo::1001" \
    -p 2222:22 -d yieldstudio/sftp
```