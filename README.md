# LFCS Practice Simulator

A disposable Ubuntu 24.04 virtual machine for practicing Linux Foundation
Certified System Administrator (LFCS) tasks on macOS. The simulator uses QEMU
and cloud-init, keeping the downloaded base image unchanged while all practice
work is stored in a replaceable qcow2 overlay.

## Requirements

- macOS on Apple Silicon (`arm64`) or Intel (`x86_64`)
- [Homebrew](https://brew.sh/)
- QEMU

Install QEMU with:

```sh
brew install qemu
```

## Quick start

Prepare the Ubuntu image and cloud-init seed:

```sh
./scripts/setup.sh
```

Start the VM:

```sh
./scripts/start.sh
```

Cloud-init creates the following lab account:

- Username: `ubuntu`
- Password: `lfcs`
- Hostname: `lfcs`

From another terminal, connect over SSH:

```sh
ssh -p 2222 ubuntu@127.0.0.1
```

The first boot can take a short while before SSH becomes available. To leave
QEMU's graphical console, press <kbd>Control</kbd>+<kbd>A</kbd>, then
<kbd>X</kbd>.

## Reset the environment

Resetting deletes the writable overlay and creates a clean one from the base
image. The downloaded base image is retained:

```sh
./scripts/reset.sh
./scripts/start.sh
```

Any work performed inside the previous VM is permanently discarded by the
reset.

## Configuration

Edit [`config/vm.conf`](config/vm.conf) to change the VM resources, SSH port,
image locations, or overlay size. The defaults are:

| Setting | Default |
| --- | --- |
| Ubuntu release | 24.04 LTS (Noble) |
| CPUs | 2 |
| Memory | 2 GiB |
| Overlay size | 20 GiB |
| SSH host port | 2222 |

The scripts select the matching Ubuntu image and QEMU executable for the host
architecture automatically.

## Project layout

```text
config/vm.conf          VM and path configuration
scripts/setup.sh        Download and validate the base image; build seed ISO
scripts/start.sh        Create the overlay when needed and start QEMU
scripts/reset.sh        Replace the writable overlay with a clean one
seed/data/              cloud-init user and instance metadata
```

Downloaded images, writable instances, and the generated seed ISO are ignored
by Git.

## Security

The VM uses a public development password and passwordless `sudo`. It listens
for SSH only on `127.0.0.1` by default and is intended solely as a disposable
local lab. Do not expose it to an untrusted network or use it for production
work.

## Versioning and license

Releases follow [Semantic Versioning](https://semver.org/). See
[`VERSION`](VERSION) for the current version and [`CHANGELOG.md`](CHANGELOG.md)
for release history.

This project is released under the [Unlicense](LICENSE).
