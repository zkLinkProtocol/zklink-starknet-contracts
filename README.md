# zkLink Starknet Contracts

zkLink starknet core contracts, which is `cairo1` compatible.

- [zkLink Starknet Contracts](#zklink-starknet-contracts)
  - [Setting up development environment](#setting-up-development-environment)
  - [Work with `zklink-starknet-contracts`](#work-with-zklink-starknet-contracts)
    - [Build and Test](#build-and-test)
    - [Deploy zkLink Starknet Contracts on Devnet](#deploy-zklink-starknet-contracts-on-devnet)
    - [Deploy zkLink Starknet Contracts on Testnet](#deploy-zklink-starknet-contracts-on-testnet)
    - [Deploy zkLink Starknet Contracts on mainnet](#deploy-zklink-starknet-contracts-on-mainnet)

## Setting up development environment

This section will introduce how to setup zkLink Starknet Contracts development environment.

You can find the docs [here](docs/setup_environment.md)

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

### Deploy zkLink Starknet Contracts on Devnet

You can find how to deploy zkLink Starknet Contracts on testnet [here](docs/deploy_devnet.md).

### Deploy zkLink Starknet Contracts on Testnet

You can find how to deploy zkLink Starknet Contracts on testnet [here](docs/deploy_testnet.md).

### Deploy zkLink Starknet Contracts on mainnet

You can find how to deploy zkLink Starknet Contracts on testnet [here](docs/deploy_mainnet.md).
