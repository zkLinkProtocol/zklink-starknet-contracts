- [Deploy zkLink Starknet Contracts on devnet](#deploy-zklink-starknet-contracts-on-devnet)
  - [Start Starknet Devnet Node](#start-starknet-devnet-node)
  - [Setting up environment variables](#setting-up-environment-variables)
  - [Compile and declare a contract](#compile-and-declare-a-contract)
  - [Deploy a contract](#deploy-a-contract)

### Deploy zkLink Starknet Contracts on devnet

#### Start Starknet Devnet Node

The follow command will give you 3 account every time when you start devnet node and keep account without changes.

```shell
starknet-devnet --seed 0 --accounts 3
```

You should add one of the three account into `~/.starknet_accounts/` and named `dev`:

```json
{
    "alpha-goerli": {
        "testnet_deployer": {
            "private_key": "0x268a28dd90948d1c869a7a3281bb0e286fd590397b163f44272563b18fccb85",
            "public_key": "0x139e31265ce9d09993a2bd7263a28c1e1fff7c2765608fca5f627f08f17adcf",
            "salt": "0x28188ed97060794ca7b8655234ea607bd556cd69d2ee5b292925fbb617c993b",
            "address": "0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d",
            "deployed": true
        },
        "dev": {
            "private_key": "0xe3e70682c2094cac629f6fbed82c07cd",
            "public_key": "0x7e52885445756b313ea16849145363ccb73fb4ab0440dbac333cf9d13de82b9",
            "address": "0x7e00d496e324876bbc8531f2d9a82bf154d1a04a50218ee74cdd372f75a551a",
            "deployed": true
        }
    }
}
```

#### Setting up environment variables

The following commands must run every time you open a new terminal to interact with Starknet. Setting them saves you time when using the CLI within the same terminal session.

```
# Use Starknet testnet
export STARKNET_NETWORK=alpha-goerli
# Set the default wallet implementation to be used by the CLI
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
```

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

You will see something like:

```Bash
Sending the transaction with max_fee: 0.000132 ETH (131904173791637 WEI).
Declare transaction was sent.
Contract class hash: 0x8ceb9796d2809438d1e992b8ac17cfe83d0cf5944dbad948a370e0b5d5924f
Transaction hash: 0x334f16d9da30913c4a30194057793379079f35efa6bf5753bc6e724a591e9f0
```

#### Deploy a contract

Using the above generated class hash, deploy the contract:

```Bash
starknet deploy --class_hash 0x8ceb9796d2809438d1e992b8ac17cfe83d0cf5944dbad948a370e0b5d5924f --inputs x x x --account dev --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

You will see something like:

```Bash
Sending the transaction with max_fee: 0.000197 ETH (197273405375932 WEI).
Invoke transaction for contract deployment was sent.
Contract address: 0x03a5cac216edec20350e1fd8369536fadebb20b83bfceb0c33aab0175574d35d
Transaction hash: 0x7895267b3e967e1c9c2f7da145e323bed60dfdd1b8ecc8efd243c9d587d579a
```