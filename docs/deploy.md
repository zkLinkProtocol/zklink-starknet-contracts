# Deploy zkLink Starknet Contracts

- [Deploy zkLink Starknet Contracts](#deploy-zklink-starknet-contracts)
  - [Config deployment](#config-deployment)
    - [Start Starknet Devnet Node(Option)](#start-starknet-devnet-nodeoption)
  - [Deploy command](#deploy-command)
    - [Deploy ZkLink](#deploy-zklink)

## Config deployment

The example configuration file path is `etc/example.json`

```json
{
    "network": {
        "name": "testnet",
        "url": "https://alpha4.starknet.io",
        "accounts": {
            "deployer": {
                "address": "",
                "privateKey": ""
            },
            "governor": {
                "address": "",
                "privateKey": ""
            }
        }
    },
    "macro": {
        "BLOCK_PERIOD": "1 seconds",
        "UPGRADE_NOTICE_PERIOD": 0,
        "PRIORITY_EXPIRATION": 0,
        "CHAIN_ID": 1,
        "ENABLE_COMMIT_COMPRESSED_BLOCK": true,
        "MIN_CHAIN_ID": 1,
        "MAX_CHAIN_ID": 4,
        "ALL_CHAINS": 15
    }
}
```

`macro` is an object and define some macro variables which will replace in zkLink starknet contract.

- `CHAIN_ID` is the id defined in zkLink network(not the blockchain id). You need to set the `CHAIN_ID` according to the actual deployment situation.
- `ENABLE_COMMIT_COMPRESSED_BLOCK` is switch to enable block committed with compressed mode.
- `BLOCK_PERIOD` is average the block generation time, for example, in ethereum mainnet it's value is `12 seconds`.
- `UPGRADE_NOTICE_PERIOD` is the contract upgrade lock time, when deploy in local development you could set this value to zero, and then we can upgrade contract immediately.
- `PRIORITY_EXPIRATION` is how long we wait for priority operation to handle by zklink.

`macro` also has three variables about constraints on `CHAIN_ID`:

- MIN_CHAIN_ID, the min chain id of zkLink network , and **SHOULD** be 1.
- MAX_CHAIN_ID, the max chain id of zkLink network.
- ALL_CHAINS, the supported chain ids flag.

You should set `MAX_CHAIN_ID` and `ALL_CHAINS` according to the actual deployment situation. For example, the initial deployment we support two chains: 1 and 2, so `MAX_CHAIN_ID` should be 2 and `ALL_CHAINS` should be 3(`1 << 0 | 1 << 2`). The second deployment we support another chain: 3, and `MAX_CHAIN_ID` should be updated to 3 and `ALL_CHAINS` should be updated to 7(`1 << 0 | 1 << 1 | 1 << 2`).

`network` contains Starknet network configurations:

- `name`: Starknet networknet, includes `devnet/testnet/mainnet`;
- `url` : Starknet rpc url that scripts connected to. You can find the url [here](https://docs.starknet.io/documentation/tools/CLI/commands/#setting_custom_endpoints)
-  `accounts` : infomations about `deployer` and `governor`, which is needed by deployment. Thus Starknet account is AA, so you should put `privateKey` and `address` at the same time. You may need to set `deployer` different with `governor` when deploying to testnet to do some authority tests.
  - `deployer`: who deploying contracts, can same with `governor`.
  - `governor`: who has the management authority of the contract. 

The `NET` env variable determines the chain configuration used for deploy commands. Before deploy you should create a config file with the example config file:

```shell
cd etc
cp -f example.json devnet.json
```

And run the follow command:

```shell
NET=devnet npm run deploy
```

### Start Starknet Devnet Node(Option)

If you want deploy zkLink starknet contract on devnet, you should start the starknet devnet node.

The follow command will fork Testnet data when you start devnet node, and you can use the testnet account in the environment.

```shell
starknet-devnet --seed 0 --accounts 0 --fork-network alpha-goerli
```

> If your computer's CPU architecture is **NOT** x86, you should add argument `--sierra-compiler-path` with above command
>
> ```bash
> starknet-devnet --seed 0 --accounts 0 --fork-network alpha-goerli --sierra-compiler-path ~/.cairo/target/release
> ```

Devnet network config looks like this:

```json
"network": {
    "name": "devnet",
    "url": "http://127.0.0.1:5050",
    ...
}
```

## Deploy command

### Deploy ZkLink

```
NET=<network name> npm run deploy
```
