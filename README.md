# apple-container-template

A template for an isolated personal dev environment on [apple/container](https://github.com/apple/container), managed with the `acx` script. Each container is its own lightweight VM. There are no host mounts: only the home directory (`/home/dev`) lives on a named volume. You connect over SSH, including VS Code Remote-SSH.

> Requires macOS 26 on Apple Silicon. apple/container has no Docker API (`docker.sock`), so Dev Containers, compose, and testcontainers are out of scope.

## Getting started

1. Click **Use this template** on GitHub to create your own repository.
2. Install apple/container.

   ```sh
   brew install container
   container system start --enable-kernel-install
   ```

3. Copy the config and edit it. `acx.env` is gitignored.

   ```sh
   cp acx.env.example acx.env
   ```

4. Start the environment and connect.

   ```sh
   ./acx start     # creates the image, volume and SSH key if missing, starts the container, updates ~/.ssh/config
   ssh acx-dev
   ```

## Customizing

| What                           | Where                                  | Applied by                                                         |
| ------------------------------ | -------------------------------------- | ------------------------------------------------------------------ |
| Name, CPUs, memory, home size  | `acx.env`                              | `./acx rebuild` for CPUs/memory; home size only for a new volume   |
| Timezone, Node version         | `acx.env` (`ACX_TZ`, `ACX_NODE_MAJOR`) | `./acx rebuild`                                                    |
| System tools                   | `setup.d/*.sh`                         | `./acx rebuild`                                                    |
| Dotfiles                       | `skel/`                                | **New volumes only** (seeded once)                                 |

### setup.d

Scripts run as root during the image build, in name order. Each runs with `bash -euo pipefail` and receives the build args (`TZ`, `NODE_MAJOR`) as environment variables.

- `00-packages.sh` — apt package list. Adding packages here is the simplest option.
- `10-node.sh` — Node (NodeSource) + corepack (pnpm)
- `20-uv.sh` — uv

Delete what you don't need. To add a tool, add a file such as `30-go.sh`.

### skel

Initial dotfiles copied into `/home/dev`. They are copied only once, when the volume is first created (`~/.dev-seeded`). After that, edit them inside the volume. The default shell is zsh and the username is fixed to `dev`.

## Data lifetime

| Written to                         | `stop/start` | `rebuild`            | `container volume rm <volume>` |
| ---------------------------------- | ------------ | -------------------- | ------------------------------ |
| `setup.d/`, `Dockerfile`           | kept         | updated by the build | kept                           |
| `/` (`sudo apt install`, etc.)     | kept         | **lost**             | kept                           |
| `/home/dev/**`                     | kept         | kept                 | **lost**                       |

Put system tools you want to keep in `setup.d/`. Put user tools in the home directory (`uv tool install`, `pnpm add -g`). For one-off apt installs inside the container, run `sudo apt-get update` first, because the image ships without apt lists.

## Commands

```sh
./acx start | stop | status | ip
./acx ssh               # connect over ssh
./acx shell             # login shell via container exec
./acx run '<cmd>'       # run a command as dev
./acx rebuild           # rebuild the image and recreate the container (home kept)
./acx destroy           # remove the container (home kept)
./acx snapshot <name>   # copy the whole home volume (the container pauses during the copy)
./acx restore <name>    # asks for confirmation, creates a pre-restore-* safety copy, then overwrites
./acx snapshots | snapshot-rm <name>
```

## Multiple environments

Create another config file and select it with `ACX_ENV_FILE`. The volume, snapshot prefix, SSH key, and `~/.ssh/config` block all derive from the name, so environments stay separate.

```sh
printf 'ACX_NAME=work-dev\nACX_MEMORY=4g\n' > work.env
ACX_ENV_FILE=work.env ./acx start     # work-home volume, ssh work-dev
```

Values are resolved in this order: environment variables, then the config file, then defaults. The config file takes one `KEY=value` per line; trailing comments are not supported.

## Updating from the template

A repository created from a template is not linked to the original. Only four files are shared: `acx`, `entrypoint.sh`, `sshd_config`, and `Dockerfile`. To update, copy those four files from the template. Keep your personal changes in `acx.env`, `setup.d/`, and `skel/`, not in the shared files.

## Notes

- The IP changes every time the container restarts (in 1.4.1 this includes `stop/start`). `acx` rewrites its managed `~/.ssh/config` block each time. Host keys live on the volume (`~/.acx/hostkeys`), so recreating the container doesn't trigger host key warnings.
- `ACX_CPUS` is enforced as a cgroup limit. The VM exposes one extra vCPU, so `nproc` reports one more than the setting.
- Exclude files from the build context with `.dockerignore`; `.containerignore` is ignored. To add a new file to the image, also add it to the `.dockerignore` allowlist.
- Full removal: `./acx destroy` → `container volume rm <volume>` → `container image rm <image>` → delete `~/.ssh/<name>_ed25519*` and the `# >>> <name> BEGIN >>>` block in `~/.ssh/config`.
