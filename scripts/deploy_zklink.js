import { Provider, Account, Contract, json, constants, CallData, cairo } from "starknet";
import fs from "fs";
import { logName } from "./deploy_log_name.js"

function getProvider(networkConfig) {
    let provider = null;
    if (networkConfig.name === "devnet") {
        provider = new Provider({ sequencer: { baseUrl: networkConfig.url } });
        console.log('✅ Connected to devnet.');
    } else if (networkConfig.name === "testnet") {
        provider = new Provider({ sequencer: { network: constants.NetworkName.SN_GOERLI } });
        console.log('✅ Connected to testnet.');
    } else if (networkConfig.name === "mainnet") {
        provider = Provider({ sequencer: { network: constants.NetworkName.SN_MAIN } });
        console.log('✅ Connected to mainnet.');
    } else {
        throw new Error(`Unknown network name: ${networkConfig.name}`);
    }
    return provider;
}

function getZklinkConstructorArgs(abi, verifierAddress, networkGovernor, blockNumber, timestamp, stateHash, commitment, syncHash) {
    const contractArrayCallData = new CallData(abi);
    const constructorArgs = contractArrayCallData.compile("constructor", [
        verifierAddress,
        networkGovernor,
        blockNumber,
        timestamp,
        stateHash,
        commitment,
        syncHash
    ])
    return constructorArgs;
}

async function main() {
    // read config json file
    const netName = process.env.NET === undefined ? "devnet" : process.env.NET;
    let netConfig = await fs.promises.readFile(`./etc/${netName}.json`, "utf-8");
    netConfig = JSON.parse(netConfig);

    // create provider
    const provider = getProvider(netConfig.network);

    const deployerConfig = netConfig.network.accounts.deployer;
    const governorConfig = netConfig.network.accounts.governor;
    const deployer = new Account(provider, deployerConfig.address, deployerConfig.privateKey);
    console.log('✅ Deployer account connected, address=', deployer.address);

    // Declare & deploy contract
    const contractSierra = json.parse(fs.readFileSync("./target/dev/zklink_Zklink.sierra.json").toString("ascii"));
    const contractCasm = json.parse(fs.readFileSync("./target/dev/zklink_Zklink.casm.json").toString("ascii"));

    // declare zklink contract
    const declareResponse = await deployer.declare({ contract: contractSierra, casm: contractCasm });
    const contractClassHash = declareResponse.class_hash;
    console.log('✅ zklink Contract declared with classHash =', contractClassHash);

    // waite declaration tx to be confirmed
    await provider.waitForTransaction(declareResponse.transaction_hash);

    // deploy zklink contract
    const constructorArgs = getZklinkConstructorArgs(contractSierra.abi, governorConfig.address, governorConfig.address, 0, 0, cairo.uint256(0), cairo.uint256(0), cairo.uint256(0));
    const { transaction_hash: th2, address } = await deployer.deployContract({ classHash: contractClassHash, constructorCalldata: constructorArgs, salt: "0" });
    await provider.waitForTransaction(th2);

    // Connect the new contract instance
    if (address) {
        const zklink = new Contract(contractSierra.abi, address, provider);
        console.log('✅ zklink Contract connected at =', zklink.address);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });