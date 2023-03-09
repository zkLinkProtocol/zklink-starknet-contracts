# zklink-starknet-contracts
zklink starknet core contracts, cairo1.0 compatible

## Installing dependencies
### Installing Cairo1.0
You should install [Rust](https://www.rust-lang.org/tools/install) first.
```shell
# Install stable Rust
rustup override set stable && rustup update

# You can varity version in release directory
mkdir -p ~/.cairo/release
cd ~/.cairo

# Choice your own version
wget https://github.com/starkware-libs/cairo/archive/refs/tags/v1.0.0-alpha.3.zip
unzip v1.0.0-alpha.3.zip -d release

cd release/cairo-1.0.0-alpha.3
cargo build --all --release

# Make soft link
cd ~/.cairo
ln -s release/cairo-1.0.0-alpha.3/target/release bin

# or .bashrc, depend on your shell
echo 'export PATH=$PATH:~/.cairo/bin' >> ~/.zshrc
source ~/.zshrc
```

After installation, you can find command such as `cairo-test`.

**If you need upgrade, just download the latest source code into `release`, build it, and remove the soft link to the newest**

### Installing Scarb

**TODO: move scarb to nile-rs when it already.**

[scarb](https://github.com/software-mansion/scarb/releases) is the Cairo package manager. It can manages your dependencies, compiles your projects and works as an extensible platform assisting in development.

**For now, scarb only support specify cairo version. If you upgrade cairo, you may should upgrade scarb as well.**

```shell
mkdir ~/.scarb
cd ~/.scarb

# Choice your own version
wget https://github.com/software-mansion/scarb/releases/download/v0.1.0-rc.0/scarb-v0.1.0-rc.0-x86_64-unknown-linux-gnu.tar.gz

# Make soft-link for upgrade later
tar xvf scarb-v0.1.0-rc.0-x86_64-unknown-linux-gnu.tar.gz
ln -s scarb-v0.1.0-rc.0-x86_64-unknown-linux-gnu/bin bin

# Or .bashrc, depend on your shell
echo 'export PATH=$PATH:~/.scarb/bin' >> ~/.zshrc
source ~/.zshrc # or .bashrc
```

After installation, you can use `scarb --version ` to check installation.

It can change the soft-link for upgrade.

## VSCode extension

```shell
# Go the latest cairo source code you have
cd ~/.cairo/release/cairo-1.0.0-alpha.3/vscode-cairo
npm install --global @vscode/vsce
npm install
vsce package
code --install-extension cairo1*.vsix
```

Open VSCode after installtion，and set`Language Server Path`, which should be`~/.cairo/bin/cairo-language-server`.

![image](https://raw.githubusercontent.com/zkcarter/picBed/main/markdown/extSettings.png)
