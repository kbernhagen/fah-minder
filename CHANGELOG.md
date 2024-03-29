# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). 


## [Unreleased]

### Changed

- Validate cpus vs config available_cpus
- Support array log messages

---

## [0.2.2] - 2023-04-30

### Fixed

- Delay runloop stop so websocket closes properly
- Removed unusable priority high option


## [0.2.1] - 2023-03-23

### Changed

- Changed output of `get` command to JSON
- Command `help` works without specifying `peer`
- Removed `log` filtering for group
- Cap config cpus to max of info cpus

### Fixed

- `log` command connects to correct group


## [0.2.0] - 2023-03-15

### Changed

- Replaced host, port, peer options with peer argument

### Added

- Added command get


## [0.1.4] - 2023-03-12

### Added 

- Added config checkpoint, key, passkey, priority, team, user
- Moved declarations of options verbose, host, port, peer; this affects help messages


## [0.1.3] - 2023-01-22

### Added 

- Added log command
- Added peer name option for resource groups
- Added config cause, cpus, fold-anon, on-idle commands


## [0.1.2] - 2022-10-24

### Changed

- Use notarytool instead of altool to notarize pkg
- Support pkg install to user home (`~/bin`)


## [0.1.1] - 2022-09-29

First release

### Fixed

- Removed version suffix when repo is unchanged from tagged
- Appends version to .zip file


## [0.1.0] - 2022-09-29

Unreleased initial public commit


[unreleased]: https://github.com/kbernhagen/fah-minder/compare/0.2.2...HEAD
[0.2.2]: https://github.com/kbernhagen/fah-minder/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/kbernhagen/fah-minder/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/kbernhagen/fah-minder/compare/0.1.4...0.2.0
[0.1.4]: https://github.com/kbernhagen/fah-minder/compare/0.1.3...0.1.4
[0.1.3]: https://github.com/kbernhagen/fah-minder/compare/0.1.2...0.1.3
[0.1.2]: https://github.com/kbernhagen/fah-minder/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/kbernhagen/fah-minder/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/kbernhagen/fah-minder/releases/tag/0.1.0
