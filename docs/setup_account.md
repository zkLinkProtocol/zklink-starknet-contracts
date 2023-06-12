# Setting up an account in Starknet

- [Setting up an account in Starknet](#setting-up-an-account-in-starknet)
  - [Setting up environment variables](#setting-up-environment-variables)
  - [Setting up an account](#setting-up-an-account)

## Setting up environment variables

The following commands must run every time you open a new terminal to interact with Starknet. Setting them saves you time when using the CLI within the same terminal session.

```
# Use Starknet testnet/mainnet
# mainnet: alpha-mainnet
# testnet: alpha-goerli
export STARKNET_NETWORK=alpha-goerli
# Set the default wallet implementation to be used by the CLI
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
```

## Setting up an account

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