import fs from "fs";
import { Provider, CallData, Account, constants } from "starknet";


function buildProvider(networkConfig) {
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

export async function connectStarknet() {
    // read config json file
    const netName = process.env.NET === undefined ? "devnet" : process.env.NET;
    let netConfig = await fs.promises.readFile(`./etc/${netName}.json`, "utf-8");
    netConfig = JSON.parse(netConfig);

    // create provider
    const provider = buildProvider(netConfig.network);

    const deployerConfig = netConfig.network.accounts.deployer;

    const deployer = new Account(provider, deployerConfig.address, deployerConfig.privateKey);
    console.log('✅ Deployer account connected, address =', deployer.address);
    const governor = new Account(provider, netConfig.network.accounts.governor.address, netConfig.network.accounts.governor.privateKey);
    console.log('✅ Governor account connected, address =', governor.address);
    return { provider, deployer, governor, netConfig};
}

export function buildGateKeeperConstructorArgs(abi, master, mainContract) {
    const contractCallData = new CallData(abi);
    const constructorArgs = contractCallData.compile("constructor", [master, mainContract])
    return constructorArgs;
}

export function buildVerifierConstructorArgs(abi, master) {
    const contractCallData = new CallData(abi);
    const constructorArgs = contractCallData.compile("constructor", [master])
    return constructorArgs;
}

export function buildZklinkConstructorArgs(abi, master, verifierAddress, networkGovernor, blockNumber, timestamp, stateHash, commitment, syncHash) {
    const contractCallData = new CallData(abi);
    const constructorArgs = contractCallData.compile("constructor", [
        master,
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

export function getDeployLog(name) {
    const deployLogPath = `log/${name}_${process.env.NET}.log`;
    console.log('deploy log path', deployLogPath);
    if (!fs.existsSync('log')) {
        fs.mkdirSync('log', true);
    }

    let deployLog = {};
    if (fs.existsSync(deployLogPath)) {
        const data = fs.readFileSync(deployLogPath, 'utf8');
        deployLog = JSON.parse(data);
    }
    return {deployLogPath, deployLog};
}

// error type is GatewayError
// error.message looks like this:
//  Class with hash 0x149b1c008b9dc20c66c228f83f75f8a3e5be4255964f54293fc98faa12813e2 is already declared.
export function getClassHashFromError(error) {
    const regex = /0x[0-9a-fA-F]{0,63}/;
    const match = error.message.match(regex);
    if (match) {
        return match[0];
    } else {
        return undefined;
    }
}