- [Deploy zkLink Starknet Contracts on devnet](#deploy-zklink-starknet-contracts-on-devnet)
  - [Setting up environment variables](#setting-up-environment-variables)
  - [Setting up an Testnet account](#setting-up-an-testnet-account)
  - [Start Starknet Devnet Node](#start-starknet-devnet-node)
  - [Compile and declare a contract](#compile-and-declare-a-contract)
  - [Deploy a contract](#deploy-a-contract)

### Deploy zkLink Starknet Contracts on devnet

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

#### Setting up an Testnet account

Here we need to create a Testnet account. This account can be used on both Testnet and Devnet. 

The specific steps to create a Testnet account can be found [here](deploy_testnet.md#setting-up-an-account).

#### Start Starknet Devnet Node

The follow command will fork Testnet data when you start devnet node, and you can use the testnet account in the environment.

```shell
starknet-devnet --seed 0 --accounts 0 --fork-network alpha-goerli
```

> If your computer's CPU architecture is **NOT** x86, you should add argument `--sierra-compiler-path` with above command
>
> ```bash
> starknet-devnet --seed 0 --accounts 0 --fork-network alpha-goerli --sierra-compiler-path ~/.cairo/target/release
> ```

#### Compile and declare a contract

Compile the Starknet contract using the following command:

```shell
scarb build
```

On Starknet, the deployment process is in two steps:

- Declaring the class of your contract, or sending your contract’s code to the network
- Deploying a contract, or creating an instance of the code you previously declared

Let’s start with declaring the code.

```shell
starknet declare --contract target/dev/zklink_Zklink.sierra.json  --account testnet  --compiler_args "--add-pythonic-hints --allowed-libfuncs-list-name experimental_v0.1.0" --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

You will get the `Contract class hash` if declare success.

#### Deploy a contract

Using the above generated class hash, deploy the contract:

```Bash
starknet deploy --class_hash <Contract class hash> --inputs 0x1234 0x4321 0 0 0 0 0 0 0 0 --account testnet --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

You will get `Contract address` if success.
