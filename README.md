# quickly

a lightning-fast package manager built for swift developers to help manage swift packages and c libraries.

## install quickly
``` bash
curl -fsSL https://github.com/atpugvaraa/quickly/releases/latest/download/install.sh | bash
```

## why
#### using as a native swift package manager:
swift package manager is not really a package manager. it's a dependency manager. it's not designed to help install and update libraries easily.. based on the principles of bun and brew, quickly aims to cache you swift packages and help you easily import them into your projects. 

#### using c libraries:
using c libraries in swift usually sucks. you have to install the library, find the headers, write a `module.modulemap` manually, and pray the linker finds it.
`quickly` solves this. it installs c libraries and automatically generates the modulemap so you can just `import Raylib` and move on with your life.
it treats everything as a first-class citizen: c libraries, swift packages, and standard binaries.

## features

- **native c-interop**: installs libraries and generates swift-compatible modulemaps automatically (`--lib`).
- **swift packages**: clones dependencies directly from the swift package index (`--spm`).
- **homebrew support**: leverages homebrew's bottle api for binary installations without the bloat.
- **fast**: o(1) lookups using a local catalog cache.
- **smart**: handles binary relocation (fixing `@HOMEBREW_PREFIX`) and dynamic linking automatically.

## manual installation

clone it, build it, and set up the permissions.

```bash
git clone https://github.com/aaravgupta/quickly.git
cd quickly
swift build -c release

sudo mkdir -p /opt/quickly
sudo chown -R $(whoami) /opt/quickly

sudo cp .build/release/ql /usr/local/bin/

```

## usage

### swift packages

installs swift packages directly from the swift package index, detecting the latest tag automatically.

```bash
ql install Alamofire --spm

```

### project injection (the magic)

parses your `Package.swift`, ensures dependencies are cached globally, and hot-swaps them into your Xcode project.

```bash
ql add

```

### standard binaries

installs tools like `wget`, `btop`, or `fastfetch` using homebrew bottles.

```bash
ql install btop

```

### c-library bridge (the main reason this exists)

installs the library and generates a `module.modulemap` for swift projects.

```bash
ql install raylib --lib

```

now you can actually use it:

```swift
import Raylib

```

## how it works

1. **catalog**: caches the entire dependency graph locally so resolution is instant.
2. **cas**: downloads artifacts to a content-addressable store.
3. **cellar**: installs packages into `/opt/quickly/cellar`.
4. **relocator**: patches mach-o headers to fix broken install paths.
5. **linker**: symlinks binaries to `/opt/quickly/bin` and libraries to `/opt/quickly/lib`.

## license

mit and apache-2.0 (swift package index)