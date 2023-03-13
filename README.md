# fah-minder

A macOS utility for the [folding@home](https://foldingathome.org) client version 8.

This is my excuse to learn Swift, so don't expect best practices.

Runs on macOS 10.14 or later.


## Usage

`fah-minder .`

```
OVERVIEW: macOS utility for the folding@home client version 8

USAGE: fah-minder [-v] <peer> <subcommand>

ARGUMENTS:
  <peer>                  [host][:port][/group]  use "." for localhost

OPTIONS:
  -v, --verbose
  --version               Show the version.
  --help                  Show help information.

SUBCOMMANDS:
  start                   Start service client.
  stop                    Stop all local clients running as <user>.
  pause                   Send pause to client.
  unpause                 Send unpause to client.
  finish                  Send finish to client; cleared by pause/unpause.
  status                  Show client units, config, info.
  log                     Show client log. Use control-c to stop.
  config                  Set client config values.

  See 'fah-minder . help <subcommand>' for detailed help.

EXAMPLES:
  fah-minder . finish
  fah-minder /my-p-cores config priority normal
  # ssh tunnel to host "other.local"
  ssh -f -L 8101:localhost:7396 me@other.local sleep 2 \
    && fah-minder :8101 status

NOTES:
  By default, the client only listens for connections from localhost.
```

`fah-minder . help config`

```
OVERVIEW: Set client config values.

USAGE: fah-minder [-v] <peer> config <subcommand>

OPTIONS:
  --version               Show the version.
  --help                  Show help information.

SUBCOMMANDS:
  cause                   Set client config cause preference.
  checkpoint              Set client config checkpoint.
  cpus                    Set client config cpus.
  fold-anon               Set client config fold-anon.
  key                     Set client config key.
  on-idle                 Set client config on-idle.
  passkey                 Set client config passkey.
  priority                Set client config priority preference.
  team                    Set client config team.
  user                    Set client config user.

  See 'fah-minder . help config <subcommand>' for detailed help.
```

## Build Requirements

- Swift 5.5+, Xcode 13+, macOS 11.3+


## Building

Download, build, install to `$HOME/bin`:

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
