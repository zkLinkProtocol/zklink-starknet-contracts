# Setting up development environment

- [Setting up development environment](#setting-up-development-environment)
  - [Installing prerequisites](#installing-prerequisites)
  - [Installing development tools](#installing-development-tools)
    - [Installing `scarb`](#installing-scarb)
    - [Installing `starkli`](#installing-starkli)
  - [Configuring `VSCode` as an Editor](#configuring-vscode-as-an-editor)

## Installing prerequisites

In order to install and use `cairo`, install the following:

- [Rust](https://www.rust-lang.org/tools/install)
- [NPM and Node 16+](https://www.npmjs.com/package/npm)

## Installing development tools

### Installing `scarb`

[scarb](https://github.com/software-mansion/scarb/releases) is the Cairo package manager. It can manage your dependencies, compiles your projects and works as an extensible platform assisting in development.

**For now, scarb only supports specific cairo1 version. If you upgrade cairo, you should upgrade scarb as well.**

```shell
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v 2.3.1
```

**If you need upgrade, just run the installation scripts with new version again, and checkout to the newest tag, and rebuild the project.**

After that, open a new shell and check that the following command returns a version number:

```
scarb --version
```

### Installing `starkli`

[starkli](https://github.com/xJonathanLEI/starkli) is a CLI for Starknet wriiten in Rust. You can install it using below scripts:

```
curl https://get.starkli.sh | sh
```

Once `starkliup` is installed, you can then install or update `starkli` simply by running the `starkliup` command without arguments:

```
starkliup
```

Behind the scene, `starkliup` downloads prebuilt binaries (built from GitHub Actions) so you don't need a Rust installation to use it.

Check out the [Starkli book](https://book.starkli.rs/installation) for more installation options.

## Configuring `VSCode` as an Editor

Now, `cairo` just support `VSCode` as an Editor.

First, you should install Node.js 18 LTS:

```
sudo apt remove nodejs
sudo apt update
sudo apt install curl dirmngr apt-transport-https lsb-release ca-certificates vim
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs
```

Second, remember to rebuild the language server:

```
cargo build --bin cairo-language-server --release
```

Third, installing vscode-cairo support:

```shell
cd ~/.cairo/vscode-cairo
npm install --global @vscode/vsce
npm install
vsce package
code --install-extension cairo1*.vsix
```

Last, open `VSCode` after installation，and set `Language Server Path`, which should be`~/.cairo/target/release/cairo-language-server`.

<img src="https://raw.githubusercontent.com/zkcarter/picBed/main/markdown/extSettings.png" alt="image" style="zoom: 50%;" />
