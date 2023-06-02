# zkLink Starknet Contracts

zkLink starknet core contracts, which is `cairo1` compatible.

- [zkLink Starknet Contracts](#zklink-starknet-contracts)
  - [Setting up local development environment](#setting-up-local-development-environment)
    - [Installing prerequisites](#installing-prerequisites)
    - [Installing the `cairo-lang` CLI](#installing-the-cairo-lang-cli)
    - [Installing the `cairo` Cairo 1 compiler](#installing-the-cairo-cairo-1-compiler)
    - [Installing development tools](#installing-development-tools)
      - [Installing `scarb`](#installing-scarb)
      - [Installing `nile-rs`](#installing-nile-rs)
      - [Installing `protostar`](#installing-protostar)
      - [Installing `starknet-devnet`](#installing-starknet-devnet)
    - [Configuring `VSCode` as an Editor](#configuring-vscode-as-an-editor)
  - [Work with `zklink-starknet-contracts`](#work-with-zklink-starknet-contracts)
    - [Build and Test](#build-and-test)
    - [Deploy on localhost](#deploy-on-localhost)
      - [Start Starknet Devnet Node](#start-starknet-devnet-node)
      - [Setting up environment variables](#setting-up-environment-variables)
      - [Setting up an account](#setting-up-an-account)
      - [Compile and declare a contract](#compile-and-declare-a-contract)
      - [Deploy a contract](#deploy-a-contract)
    - [Deploy on Testnet](#deploy-on-testnet)
      - [Setting up environment variables](#setting-up-environment-variables-1)
      - [Setting up an account](#setting-up-an-account-1)
      - [Compile and declare a contract](#compile-and-declare-a-contract-1)
      - [Deploy a contract](#deploy-a-contract-1)
    - [Deploy on mainnet](#deploy-on-mainnet)

## Setting up local development environment

This section will cover those steps:

- Installing prerequisites
- Installing the `cairo-lang` CLI
- Installing the `cairo` Cairo 1 compiler
- Installing development tools:`Scarb`,`nile-rs`,`protostar`and`starknet-devnet`
- Configuring `VSCode` as an Editor

### Installing prerequisites

In order to install and use `cairo` and `cairo-lang`, install the following:

- [Python 3.9+](https://www.python.org/downloads/release/python-390/)
- [Rust](https://www.rust-lang.org/tools/install)

### Installing the `cairo-lang` CLI

**Step 1: Set up your virtual environment**

We use `pyenv` manage python versions, which will compile python from source code. You need install python dependencies.

For Ubuntu:

```bash
sudo apt update
sudo apt install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

For macOS:

If you haven't done so, install Xcode Command Line Tools (`xcode-select --install`) and [Homebrew](http://brew.sh/). Then:

```bash
brew install openssl readline sqlite3 xz zlib tcl-tk
```

Run the following commands for installing `pyenv` and configuring virtual environment:

```bash
# Install pyenv
curl https://pyenv.run | bash

# Add the following to your .bashrc or .zshrc
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Restart your terminal and run the following commands
pyenv install 3.9.0
pyenv virtualenv 3.9.0 cairo_venv
pyenv activate cairo_venv
```

Either way, make sure the `venv` is activated – you should see (`cairo_venv`) in the command line prompt.

**Step 2: Install the necessary dependencies**

On Ubuntu, for example, you will have to first run:

```Bash
sudo apt install -y libgmp3-dev
```

On Mac, you can use brew:

```Bash
brew install gmp
```

Finally, install the following dependencies. **Note: you should install those in `cairo_venv`!**

```bash
pip install ecdsa fastecdsa sympy
```

There might be some other libraries which are not direct dependencies, but they might be indirect dependencies that you would need to install based on your operating system.

**Step 3: Install `cairo-lang` CLI**

If you had `cairo-lang` installed previously, uninstall it and install the latest version.

```bash
# Uninstall the previous version
pip uninstall cairo-lang
# Install locally
pip install cairo-lang
```

Once you have installed the cairo lang package, make sure to test your installation by running the following command:

```
starknet --version
```

### Installing the `cairo` Cairo 1 compiler

**Step1: Clone the cairo repository and set it up using the following instructions**

```shell
# Go to your $HOME directory
cd ~/
# Clone the `cairo` Cairo 1 compiler to a folder called .cairo in your home directory
git clone https://github.com/starkware-libs/cairo .cairo

# Checkout into the working branch and generate the release binaries
cd .cairo/
git checkout tags/v1.0.0-alpha.6
cargo build --all --release
```

**If you need upgrade, just run `git pull`, checkout to the newest tag, and rebuild the project.**

**Step 2: Add Cairo 1.0 executables to your path**

Now that we have built the Cairo 1.0 binaries, we need to add them to the `PATH` environment variable. Add the following in your `.bashrc` or `.zshrc`:

```bash
# Add the below command to your .bashrc or .zshrc
export PATH="$HOME/.cairo/target/release:$PATH"
```

After that, open a new shell and check that the following command returns a version number:

```Bash
cairo-compile --version
```

### Installing development tools

#### Installing `scarb`

[scarb](https://github.com/software-mansion/scarb/releases) is the Cairo package manager. It can manages your dependencies, compiles your projects and works as an extensible platform assisting in development.

**For now, scarb only support specify cairo1 version. If you upgrade cairo, you may should upgrade scarb as well.**

```shell
# Go to your $HOME directory
cd ~/
# Clone the `scarb` to a folder called .scarb in your home directory
git clone git@github.com:software-mansion/scarb.git .scarb

# Checkout into the working branch and generate the release binaries
cd .scarb/
git checkout tags/v0.1.0
cargo build --all --release

# Add the below command to your .bashrc or .zshrc
export PATH="$HOME/.scarb/target/release:$PATH"
```

**If you need upgrade, just run `git pull`, checkout to the newest tag, and rebuild the project.**

After that, open a new shell and check that the following command returns a version number:

```
scarb --version
```

#### Installing `nile-rs`

[Nile](https://github.com/OpenZeppelin/nile-rs) is a CLI tool to develop or interact with StarkNet projects written in Cairo. This is an ongoing effort to migrate the existing tool written in Python to Rust, for compatibility with the new Cairo1 compiler.

```bash
# Go to your $HOME directory
cd ~/
# Clone the `nile-rs` to a folder called .nile-rs in your home directory
git clone git@github.com:OpenZeppelin/nile-rs.git .nile-rs

# generate the release binaries
cd .nile-rs/
cargo build --all --release

# Add the below command to your .bashrc or .zshrc
export PATH="$HOME/.nile-rs/target/release:$PATH"
```

**If you need upgrade, just run `git pull` and rebuild the project.**

After that, open a new shell and check that the following command returns a version number:

```bash
nile-rs -V
```

#### Installing `protostar`

[protostar](https://docs.swmansion.com/protostar/) is a toolchain for developing Starknet smart contracts that helps with tasks such as dependencies management.

To installing `protostar` run the following command:

```
curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash
```

After that, open a new shell and check that the following command returns `cairo`, `cairo-lang` and `protostar` versions like this:

```bash
➜  ~ pyenv activate cairo_venv
(cairo_venv) ➜  ~ protostar -v
Protostar version: 0.10.0
Cairo-lang version: 0.11.0.1
Cairo 1 compiler version: 1.0.0a6
18:22:56 [INFO] Execution time: 1.25 s
```

To upgrade Protostar, run:

```
protostar upgrade
```

#### Installing `starknet-devnet`

**You should execute follow command in previous `cairo_env` environment.**

```
pip install starknet-devnet
```

### Configuring `VSCode` as an Editor

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

## Work with `zklink-starknet-contracts`

First of all, you should active the cairo python virtual environment before you work with `zklink-starknet-contracts`.

```bash
pyenv active cairo_env
```

### Build and Test

To build an test `zklink-starknet-contracts`, you should run the following command in the root of this project:

```bash
# build
scarb build

# test
scarb run test
```

### Deploy on localhost

#### Start Starknet Devnet Node

The follow command will give you 3 account every time when you start devnet node and keep account without changes.

```shell
starknet-devnet --seed 0 --accounts 3
```

#### Setting up environment variables

The following commands must run every time you open a new terminal to interact with Starknet. Setting them saves you time when using the CLI within the same terminal session.

```
# Use Starknet testnet
export STARKNET_NETWORK=alpha-goerli
# Set the default wallet implementation to be used by the CLI
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
```

#### Setting up an account

You need to set up your CLI with an account contract and fund it.

The Starknet account declared through the CLI are stored on your machine in folder `~/.starknet_accounts/`.

```Bash
# Creating a new account.
starknet new_account --account dev --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

Your terminal will return your account’s address.

```Bash
Account address: 0x00d9d851f600d539a9f7811de4d9613a6b3c2634f8c0386a305c03216bd67559
Public key: 0x0293d6625d860b9a37a0319d1e3c1eecc27685075cbeaae4ef29ed717d93c58b
Move the appropriate amount of funds to the account, and then deploy the account
by invoking the 'starknet deploy_account' command.

NOTE: This is a modified version of the OpenZeppelin account contract. The signature is computed
differently.
```

And deploy the account.

```Bash
# Deploying your account
starknet deploy_account --account dev --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

Your sample output should look something like this:

```Bash
Sending the transaction with max_fee: 0.000568 ETH (568383605914463 WEI).
Sent deploy account contract transaction.
Contract address: 0x03f42fc2355be54197a8b270ff2cb8e2eb7902e777b3498f8ad58c6c147cce60
Transaction hash: 0x3d15e05389ecd1ff65555220be57f0ab43729877b20ca086048276917ed2838
```

Monitor the transaction until it passes the "PENDING" state.

#### Compile and declare a contract

Compile the Starknet contract using the following command:

```shell
scarb build
# or
starknet-compile --allowed-libfuncs-list-name experimental_v0.1.0 -c zklink::contracts::zklink::Zklink . ./target/dev/zklink_Zklink.sierra.json
```

On Starknet, the deployment process is in two steps:

- Declaring the class of your contract, or sending your contract’s code to the network
- Deploying a contract, or creating an instance of the code you previously declared

Let’s start with declaring the code.

```shell
# TODO: use protostar
starknet declare --contract target/dev/zklink_Zklink.sierra.json  --account dev  --compiler_args "--add-pythonic-hints --allowed-libfuncs-list-name experimental_v0.1.0" --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

> *The above command may fail if you are using code that has already been declared by someone else! Please make sure to add custom code to your contract to create a new contract class.*

You will see something like:

```Bash
Sending the transaction with max_fee: 0.000132 ETH (131904173791637 WEI).
Declare transaction was sent.
Contract class hash: 0x8ceb9796d2809438d1e992b8ac17cfe83d0cf5944dbad948a370e0b5d5924f
Transaction hash: 0x334f16d9da30913c4a30194057793379079f35efa6bf5753bc6e724a591e9f0
```

The transaction hash allows you to track when the network will have received your contract’s code. Once this transaction has moved to "PENDING", you can deploy an instance of your contract.

#### Deploy a contract

Using the above generated class hash, deploy the contract:

```Bash
starknet deploy --class_hash 0x8ceb9796d2809438d1e992b8ac17cfe83d0cf5944dbad948a370e0b5d5924f --inputs x x x --account dev --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

> If you run into any fee related issues, please add the flag `--max_fee 100000000000000000` to your CLI commands to set an arbitrary high gas limit for your deploy transaction.

You will see something like:

```Bash
Sending the transaction with max_fee: 0.000197 ETH (197273405375932 WEI).
Invoke transaction for contract deployment was sent.
Contract address: 0x03a5cac216edec20350e1fd8369536fadebb20b83bfceb0c33aab0175574d35d
Transaction hash: 0x7895267b3e967e1c9c2f7da145e323bed60dfdd1b8ecc8efd243c9d587d579a
```

Monitor the deploy transaction. Once it has passed "PENDING", your contract has been successfully deployed!

### Deploy on Testnet

#### Setting up environment variables

The following commands must run every time you open a new terminal to interact with Starknet. Setting them saves you time when using the CLI within the same terminal session.

```
# Use Starknet testnet
export STARKNET_NETWORK=alpha-goerli
# Set the default wallet implementation to be used by the CLI
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
# Set the path to the cairo 1 compiler binary. Adapt this path to fit your installation if needed
export CAIRO_COMPILER_DIR=~/.cairo/target/release/
# Compiler arguments
export CAIRO_COMPILER_ARGS="--add-pythonic-hints --allowed-libfuncs-list-name experimental_v0.1.0"
```

#### Setting up an account

You need to set up your CLI with an account contract and fund it.

> *Starknet accounts are smart contracts. As such, creating one involves sending a transaction, and takes a bit longer than creating an EOA on other networks. You can learn more in the* [accounts](https://docs.starknet.io/documentation/architecture_and_concepts/Account_Abstraction/introduction/) *section of the documentation.*

This process will involve three steps:

- Generating your account address locally
- Funding it
- Deploying it

The Starknet account declared through the CLI are stored on your machine in folder `~/.starknet_accounts/`.

```Bash
# Creating a new account.
starknet new_account --account account_name
```

Your terminal will return your account’s address.

```Bash
Account address: 0x00d9d851f600d539a9f7811de4d9613a6b3c2634f8c0386a305c03216bd67559
Public key: 0x0293d6625d860b9a37a0319d1e3c1eecc27685075cbeaae4ef29ed717d93c58b
Move the appropriate amount of funds to the account, and then deploy the account
by invoking the 'starknet deploy_account' command.

NOTE: This is a modified version of the OpenZeppelin account contract. The signature is computed
differently.
```

Next step is to fund it.

- Use the [faucet](https://faucet.goerli.starknet.io/) to get some funds and send them to the account
- Bridge funds using [Starkgate](https://goerli.starkgate.starknet.io/)

However you chose to do it, please make sure that the funding transaction reaches the "PENDING" status before moving on. You can look for it on [Starkscan](https://testnet.starkscan.co/) or [Voyager](https://goerli.voyager.online/)

```Bash
# Deploying your account
starknet deploy_account --account account_name
```

Your sample output should look something like this:

```Bash
Sending the transaction with max_fee: 0.000568 ETH (568383605914463 WEI).
Sent deploy account contract transaction.
Contract address: 0x03f42fc2355be54197a8b270ff2cb8e2eb7902e777b3498f8ad58c6c147cce60
Transaction hash: 0x3d15e05389ecd1ff65555220be57f0ab43729877b20ca086048276917ed2838
```

Monitor the transaction until it passes the "PENDING" state.

#### Compile and declare a contract

Compile the Starknet contract using the following command:

```shell
scarb build
# or
starknet-compile --allowed-libfuncs-list-name experimental_v0.1.0 -c zklink::contracts::zklink::Zklink . ./target/dev/zklink_Zklink.sierra.json
```

On Starknet, the deployment process is in two steps:

- Declaring the class of your contract, or sending your contract’s code to the network
- Deploying a contract, or creating an instance of the code you previously declared

Let’s start with declaring the code.

```shell
# TODO: use protostar
starknet declare --contract target/dev/zklink_Zklink.sierra.json  --account testnet_deployer  --compiler_args "--add-pythonic-hints --allowed-libfuncs-list-name experimental_v0.1.0"
```

> *The above command may fail if you are using code that has already been declared by someone else! Please make sure to add custom code to your contract to create a new contract class.*

You will see something like:

```Bash
Sending the transaction with max_fee: 0.000132 ETH (131904173791637 WEI).
Declare transaction was sent.
Contract class hash: 0x8ceb9796d2809438d1e992b8ac17cfe83d0cf5944dbad948a370e0b5d5924f
Transaction hash: 0x334f16d9da30913c4a30194057793379079f35efa6bf5753bc6e724a591e9f0
```

The transaction hash allows you to track when the network will have received your contract’s code. Once this transaction has moved to "PENDING", you can deploy an instance of your contract.

#### Deploy a contract

Using the above generated class hash, deploy the contract:

```Bash
starknet deploy --class_hash 0x8ceb9796d2809438d1e992b8ac17cfe83d0cf5944dbad948a370e0b5d5924f --account testnet_deployer
```

> If you run into any fee related issues, please add the flag `--max_fee 100000000000000000` to your CLI commands to set an arbitrary high gas limit for your deploy transaction.

You will see something like:

```Bash
Sending the transaction with max_fee: 0.000197 ETH (197273405375932 WEI).
Invoke transaction for contract deployment was sent.
Contract address: 0x03a5cac216edec20350e1fd8369536fadebb20b83bfceb0c33aab0175574d35d
Transaction hash: 0x7895267b3e967e1c9c2f7da145e323bed60dfdd1b8ecc8efd243c9d587d579a
```

Monitor the deploy transaction. Once it has passed "PENDING", your contract has been successfully deployed!

### Deploy on mainnet

TODO
