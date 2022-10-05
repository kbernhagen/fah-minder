# fah-minder

A macOS utility for the [folding@home](https://foldingathome.org) client version 8.

This is my excuse to learn Swift, so don't expect best practices.

Runs on macOS 10.14 or later.


## Usage

```
OVERVIEW: macOS utility for the folding@home client version 8

USAGE: fah-minder <subcommand>

OPTIONS:
  --version               Show the version.
  --help                  Show help information.

SUBCOMMANDS:
  start                   Start service client.
  stop                    Stop all local clients running as <user>.
  pause                   Send pause to client.
  unpause                 Send unpause to client.
  finish                  Send finish to client; cleared by pause/unpause.
  status                  Show client units, config, info.

  See 'fah-minder help <subcommand>' for detailed help.

EXAMPLES:
  fah-minder status --host other.local

  # ssh tunnel to host "other.local"
  ssh -f -L 8101:localhost:7396 me@other.local sleep 2 \
    && fah-minder status -p 8101

NOTES:
  The client may not support IPv6 addresses.
  By default, the client only listens for connections from localhost.
  To send commands to remote clients, you must set config.xml
  http-addresses to 0.0.0.0:7396 and restart the client. Note that this
  will allow anyone on the local network to mess with your client.
  Not recommended, especially for laptops.
  You might want to use the ssh tunnel instead.
```


## Build Requirements

- Swift 5.3+
- Universal build, sign, and notarize require Xcode 12.2+, macOS 10.15.4+


## Building

Download, build, install to $HOME/bin:

```bash
git clone https://github.com/kbernhagen/fah-minder.git
cd fah-minder
make install
```

There may be warnings when Starscream compiles.

If you wish to build/debug with Xcode, you must first run

```bash
make autorev
```


## Prebuilt

If you download the prebuilt binary zip, you may need to clear the
quarantine bit before you can use it.

    xattr -d com.apple.quarantine ./fah-minder 


## Dependencies

- [ArgumentParser](https://github.com/apple/swift-argument-parser)
- [autorevision](https://autorevision.github.io)
- [Starscream](https://github.com/daltoniam/Starscream)
