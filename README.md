# zkLink Starknet Contracts

zkLink starknet core contracts, which is `cairo1` compatible.

- [zkLink Starknet Contracts](#zklink-starknet-contracts)
  - [Setting up development environment](#setting-up-development-environment)
  - [Work with `zklink-starknet-contracts`](#work-with-zklink-starknet-contracts)
    - [Install Dependencies](#install-dependencies)
    - [Build and Test](#build-and-test)
    - [Deploy](#deploy)

## Setting up development environment

This section will introduce how to setup zkLink Starknet Contracts development environment.

You can find the docs [here](docs/setup_environment.md)

## Work with `zklink-starknet-contracts`

### Install Dependencies

`zklink-starknet-contracts` use [starknet.js](https://github.com/0xs34n/starknet.js) as SDK. You should run follow command to install dependencies:

```
npm install
```

### Build and Test

To build an test `zklink-starknet-contracts`, you should run the following command in the root of this project:

```bash
# build
scarb build

# test
scarb test
```

### Deploy

- [Setting up an account](https://book.starkli.rs/accounts)
- [Deploy zklink contract](docs/deploy.md)
