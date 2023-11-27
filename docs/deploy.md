# Deploy zkLink Starknet Contracts

- [Deploy zkLink Starknet Contracts](#deploy-zklink-starknet-contracts)
  - [Config deployment](#config-deployment)
  - [Deploy command](#deploy-command)
    - [Deploy zkLink main contract](#deploy-zklink-main-contract)
    - [Upgrade zkLink](#upgrade-zklink)
    - [Deploy zkLink L2 gateway contract](#deploy-zklink-l2-gateway-contract)
    - [Upgrade zkLink L2 gateway](#upgrade-zklink-l2-gateway)
    - [Deploy zkLink Lzbridge](#deploy-zklink-lzbridge)
    - [Deploy zkLink multicall](#deploy-zklink-multicall)
    - [Deploy facucet token(testnet only)](#deploy-facucet-tokentestnet-only)
    - [Interacting with zkLink contracts](#interacting-with-zklink-contracts)

## Config deployment

The example configuration file path is `etc/example.json`

```json
{
    "network": {
        "name": "devnet",
        "url": "http://127.0.0.1",
        "accounts": {
            "deployer": {
                "address": "",
                "privateKey": "",
                "cairoVersion": ""
            },
            "governor": {
                "address": "",
                "privateKey": "",
                "cairoVersion": ""
            }
        }
    },
    "macro": {
        "BLOCK_PERIOD": "1 seconds",
        "UPGRADE_NOTICE_PERIOD": 0,
        "PRIORITY_EXPIRATION": 0,
        "CHAIN_ID": 1,
        "MAX_CHAIN_ID": 4,
        "ALL_CHAINS": 15,
        "MASTER_CHAIN_ID": 2
    }
}
```

`macro` is an object and define some macro variables which will replace in zkLink starknet contract.

- `CHAIN_ID` is the id defined in zkLink network(not the blockchain id). You need to set the `CHAIN_ID` according to the actual deployment situation.
- `BLOCK_PERIOD` is average the block generation time, for example, in ethereum mainnet its value is `12 seconds`.
- `UPGRADE_NOTICE_PERIOD` is the contract upgrade lock time, when deploy in local development you could set this value to zero, and then we can upgrade contract immediately.
- `PRIORITY_EXPIRATION` is how long we wait for priority operation to handle by zklink.

`macro` also has three variables about constraints on `CHAIN_ID`:
- MAX_CHAIN_ID, the max chain id of zkLink network.
- MASTER_CHAIN_ID, the chain id of master chain.

You should set `MAX_CHAIN_ID` and `MASTER_CHAIN_ID` according to the actual deployment situation. For example, the initial deployment we support two chains: 1 and 2, so `MAX_CHAIN_ID` should be 2 and `ALL_CHAINS` should be 3(`1 << 0 | 1 << 2`). The second deployment we support another chain: 3, and `MAX_CHAIN_ID` should be updated to 3 and `ALL_CHAINS` should be updated to 7(`1 << 0 | 1 << 1 | 1 << 2`).

`network` contains Starknet network configurations:

- `name`: Starknet networknet, includes `devnet/testnet/mainnet`;
- `url` : Starknet rpc url that scripts connected to. You can find the url [here](https://docs.starknet.io/documentation/tools/CLI/commands/#setting_custom_endpoints)
-  `accounts` : infomations about `deployer` and `governor`, which is needed by deployment. Thus Starknet account is AA, so you should put `privateKey` and `address` at the same time. You may need to set `deployer` different with `governor` when deploying to testnet to do some authority tests. `cairoVersion` is the contract Cairo version of account, option is `0` or `1`.
  - `deployer`: who deploying contracts, can same with `governor`.
  - `governor`: who has the management authority of the contract. 

The `NET` env variable determines the chain configuration used for deploy commands. Before deploy you should create a config file with the example config file:

```shell
cd etc
cp -f example.json devnet.json
```

And run the following command will compiling zklink starknet contracts:

```shell
NET=devnet npm run build
```

## Deploy command

### Deploy zkLink main contract

```sh
NET=<network name> npm run deployZklink -- --help
```

### Upgrade zkLink

```sh
NET=<network name> npm run upgradeZklink -- --help
```

### Deploy zkLink L2 gateway contract

```sh
NET=<network name> npm run deployL2Gateway -- --help
```

### Upgrade zkLink L2 gateway

```sh
NET=<network name> npm run upgradeL2Gateway -- --help
```

### Deploy zkLink Lzbridge

```sh
NET=<network name> npm run deployLZBridge -- --help
```

### Deploy zkLink multicall

```sh
NET=<network name> npm run deployMulticall -- --help
```

### Deploy facucet token(testnet only)

```sh
NET=<network name> npm run deployFaucetToken -- --help
```

### Interacting with zkLink contracts

- Add Token

```sh
NET=<network name> npm run addToken -- --help
```

- Add Bridge

```sh
NET=<network name> npm run addBridge -- --help
```

- Set L1 gateway to zkLink

```sh
NET=<network name> npm run setL1RemoteGateway -- --help
```

- Set L2 gateway to zkLink

```sh
NET=<network name> npm run setL2RemoteGateway -- --help
```

- Set zkLink to L2 gatway

```sh
NET=<network name> npm run setL2GatewayToZkLink -- --help
```

- Set destinations

```sh
NET=<network name> npm run setDestinations -- --help
```

- Set chain id map

```sh
NET=<network name> npm run setChainIdMap -- --help
```

- Mint faucet token(testnet only)

```sh
NET=<network name> npm run mintFaucetToken -- --help
```

- Transfer ownership of UpgradeGatekeeper

```sh
NET=<network name> npm run transferMastershipOfUpgradeGatekeeper -- --help
```

- Change zkLink governor

```sh
NET=<network name> npm run changeGovernorOfZkLink -- --help
```