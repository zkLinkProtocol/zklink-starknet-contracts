import fs from "fs";
import { Provider, CallData, Account, constants, json } from "starknet";
import { exec } from "child_process";
import { logName, contractPath } from "./constants.js";


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
    const netName = process.env.NET === undefined ? "EXAMPLE" : process.env.NET;
    let netConfig = await fs.promises.readFile(`./etc/${netName}.json`, "utf-8");
    netConfig = JSON.parse(netConfig);

    // create provider
    const provider = buildProvider(netConfig.network);

    const deployerConfig = netConfig.network.accounts.deployer;
    const governorConfig = netConfig.network.accounts.governor;

    const deployer = new Account(provider, deployerConfig.address, deployerConfig.privateKey, deployerConfig.cairoVersion);
    console.log('✅ Deployer account connected, address =', deployer.address);
    const governor = new Account(provider, governorConfig.address, governorConfig.privateKey, governorConfig.cairoVersion);
    console.log('✅ Governor account connected, address =', governor.address);
    return { provider, deployer, governor, netConfig};
}

export function buildFaucetTokenConstructorArgs(abi, name, symbol, decimals, fromTransferFeeRatio, toTransferFeeRatio) {
    const contractCallData = new CallData(abi);
    const constructorArgs = contractCallData.compile("constructor", [name, symbol, decimals, fromTransferFeeRatio, toTransferFeeRatio])
    return constructorArgs;
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

export async function declare_zklink(provider, deployer, log, options) {
    const deployLogPath = log.deployLogPath;
    const deployLog = log.deployLog;

    deployLog[logName.DEPLOY_LOG_DEPLOYER] = deployer.address;
    fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));

    const declareGatekeeper = options.declareGatekeeper;
    const declareVerifier = options.declareVerifier;
    const declareZklink = options.declareZklink;
    const upgrade = options.upgrade;
    console.log("declare gatekeeper: ", declareGatekeeper);
    console.log("declare verifier: ", declareVerifier);
    console.log("declare zklink: ", declareZklink);
    console.log("upgrade: ", upgrade);

    // declare gatekeeper contract
    if (declareGatekeeper) {
        if (!(logName.DEPLOY_LOG_GATEKEEPER_CLASS_HASH in deployLog) || upgrade) {
            let gatekeeperContractClassHash;
            const gatekeeperContractSierra = json.parse(fs.readFileSync(contractPath.GATEKEEPER_SIERRA_PATH).toString("ascii"));
            const gatekeeperContractCasm = json.parse(fs.readFileSync(contractPath.GATEKEEPER_CASM_PATH).toString("ascii"));
    
            try {
                const gatekeeperDeclareResponse = await deployer.declare({ contract: gatekeeperContractSierra, casm: gatekeeperContractCasm });
                await provider.waitForTransaction(gatekeeperDeclareResponse.transaction_hash);
                gatekeeperContractClassHash = gatekeeperDeclareResponse.class_hash;
                console.log('✅ Gatekeeper Contract declared with classHash = ', gatekeeperContractClassHash);
            } catch (error) {
                if (error.errorCode !== 'StarknetErrorCode.CLASS_ALREADY_DECLARED') {
                    throw error;
                }
    
                gatekeeperContractClassHash = getClassHashFromError(error);
                if (gatekeeperContractClassHash === undefined) {
                    console.log('❌ Cannot declare gatekeeper contract class hash:', error);
                    return;
                } else {
                    console.log('✅ Gatekeeper Contract already declared with classHash =', gatekeeperContractClassHash);
                }
            }
            deployLog[logName.DEPLOY_LOG_GATEKEEPER_CLASS_HASH] = gatekeeperContractClassHash;
            fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
        } else {
            console.log('✅ Gatekeeper Contract already declared with classHash =', deployLog[logName.DEPLOY_LOG_GATEKEEPER_CLASS_HASH]);
        }
    }
    

    // declare verifier contract
    if (declareVerifier) {
        if (!(logName.DEPLOY_LOG_VERIFIER_CLASS_HASH in deployLog) || upgrade) {
            let verifierContractClassHash;
            const verifierContractSierra = json.parse(fs.readFileSync(contractPath.VERIFIER_SIERRA_PATH).toString("ascii"));
            const verifierContractCasm = json.parse(fs.readFileSync(contractPath.VERIFIER_CASM_PATH).toString("ascii"));
    
            try {
                const verifierDeclareResponse = await deployer.declare({ contract: verifierContractSierra, casm: verifierContractCasm });
                await provider.waitForTransaction(gatekeeperDeclareResponse.transaction_hash);
                verifierContractClassHash = verifierDeclareResponse.class_hash;
                console.log('✅ Verifier Contract declared with classHash = ', verifierContractClassHash);
            } catch (error) {
                if (error.errorCode !== 'StarknetErrorCode.CLASS_ALREADY_DECLARED') {
                    throw error;
                }
    
                verifierContractClassHash = getClassHashFromError(error);
                if (verifierContractClassHash === undefined) {
                    console.log('❌ Cannot declare verifier contract class hash:', error);
                    return;
                } else {
                    console.log('✅ Verifier Contract already declared with classHash =', verifierContractClassHash);
                }
            }
            deployLog[logName.DEPLOY_LOG_VERIFIER_CLASS_HASH] = verifierContractClassHash;
            fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
        } else {
            console.log('✅ Verifier Contract already declared with classHash =', deployLog[logName.DEPLOY_LOG_VERIFIER_CLASS_HASH]);
        }
    }

    // declare zklink contract
    if (declareZklink) {
        if (!(logName.DEPLOY_LOG_ZKLINK_CLASS_HASH in deployLog) || upgrade) {
            let zklinkContractClassHash;
            const zklinkContractSierra = json.parse(fs.readFileSync(contractPath.ZKLINK_SIERRA_PATH).toString("ascii"));
            const zklinkContractCasm = json.parse(fs.readFileSync(contractPath.ZKLINK_CASM_PATH).toString("ascii"));

            try {
                const zklinkDeclareResponse = await deployer.declare({ contract: zklinkContractSierra, casm: zklinkContractCasm });
                await provider.waitForTransaction(zklinkDeclareResponse.transaction_hash);
                zklinkContractClassHash = zklinkDeclareResponse.class_hash;
                console.log('✅ Zklink Contract declared with classHash = ', zklinkContractClassHash);
            } catch (error) {
                if (error.errorCode !== 'StarknetErrorCode.CLASS_ALREADY_DECLARED') {
                    throw error;
                }

                zklinkContractClassHash = getClassHashFromError(error);
                if (zklinkContractClassHash === undefined) {
                    console.log('❌ Cannot declare zklink contract class hash:', error);
                    return;
                } else {
                    console.log('✅ Zklink Contract already declared with classHash =', zklinkContractClassHash);
                }
            }
            deployLog[logName.DEPLOY_LOG_ZKLINK_CLASS_HASH] = zklinkContractClassHash;
            fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
        } else {
            console.log('✅ Zklink Contract already declared with classHash =', deployLog[logName.DEPLOY_LOG_ZKLINK_CLASS_HASH]);
        }
    }
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

export function executeCommand(command) {
    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error executing command: ${error.message}`);
            console.error(`Command error: ${stderr}`);
            console.error(`Command output: ${stdout}`);
            resolve('');
        } else {
            resolve(stdout);
        }
        });
    });
}