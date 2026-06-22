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

### 🚧 C-Library Bridge & `pkg-config` (The reason `quickly` exists)

`quickly` was built specifically to be the backbone of [QuickUI](https://github.com/atpugvaraa/QuickUI) — an upcoming framework bringing sweet SwiftUI-like syntax (like `@main` macros and `@ViewBuilder`) to Raylib.

To make QuickUI a seamless experience, we needed a robust way to scaffold projects and inject C-libraries without breaking Swift Package Manager rules. `quickly` handles these C dependencies cleanly using `pkg-config`. 

When you scaffold a QuickUI project:
```bash
ql package init --name MyGame .
```
it automatically downloads the required C-libraries (like Raylib) directly into the isolated `/opt/quickly/cellar` without polluting your global system.

### running with `ql run`

Because the C-libraries live in the cellar, running bare `swift run` might fail unless you've globally installed the library (e.g. via `brew install raylib`).

**This is why `ql run` exists!**

```bash
ql run
```

when you invoke `ql run`, quickly automatically injects `PKG_CONFIG_PATH=/opt/quickly/cellar/...` into the environment before calling the swift compiler. SPM instantly discovers the headers and static libraries natively, enabling clean, reproducible builds without hardcoding unsafe paths in your `Package.swift`.

## how it works

1. **catalog**: caches the entire dependency graph locally so resolution is instant.
2. **cas**: downloads artifacts to a content-addressable store.
3. **cellar**: installs packages into `/opt/quickly/cellar`.
4. **relocator**: patches mach-o headers to fix broken install paths.
5. **linker**: symlinks binaries to `/opt/quickly/bin` and libraries to `/opt/quickly/lib`.

## license

mit and apache-2.0 (swift package index)
