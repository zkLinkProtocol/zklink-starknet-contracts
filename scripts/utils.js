import fs from "fs";
import { RpcProvider, CallData, Account, json } from "starknet";
import { exec } from "child_process";
import { logName, contractPath, connectionType } from "./constants.js";


function buildProvider(networkConfig, type) {
    let url = undefined;
    if (type === connectionType.DEPLOY) {
        url = networkConfig.deployUrl;
        console.log('Connecting Starknet for deployment...');
    } else if (type === connectionType.DECLARE) {
        url = networkConfig.declareUrl;
        console.log('Connecting Starknet for declaration...');
    }
    let provider = new RpcProvider({ nodeUrl: url });
    console.log(`✅ Connected to ${url}`);
    return provider;
}

export async function connectStarknet(type) {
    // read config json file
    const netName = process.env.NET === undefined ? "EXAMPLE" : process.env.NET;
    let netConfig = await fs.promises.readFile(`./etc/${netName}.json`, "utf-8");
    netConfig = JSON.parse(netConfig);

    // create provider
    const provider = buildProvider(netConfig.network, type);

    const deployerConfig = netConfig.network.accounts.deployer;
    const governorConfig = netConfig.network.accounts.governor;

    const deployer = new Account(provider, deployerConfig.address, deployerConfig.privateKey, deployerConfig.cairoVersion);
    console.log('✅ Deployer account connected, address =', deployer.address);
    const governor = new Account(provider, governorConfig.address, governorConfig.privateKey, governorConfig.cairoVersion);
    console.log('✅ Governor account connected, address =', governor.address);
    return { provider, deployer, governor, netConfig};
}

export function buildFaucetTokenConstructorArgs(abi, name, symbol, decimals) {
    const contractCallData = new CallData(abi);
    const constructorArgs = contractCallData.compile("constructor", [name, symbol, decimals])
    return constructorArgs;
}

export function buildMulticallConstructorArgs(abi) {
    const contractCallData = new CallData(abi);
    const constructorArgs = contractCallData.compile("constructor", [])
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

export function buildZklinkConstructorArgs(abi, master, verifierAddress, networkGovernor, blockNumber) {
    const contractCallData = new CallData(abi);
    const constructorArgs = contractCallData.compile("constructor", [
        master,
        verifierAddress,
        networkGovernor,
        blockNumber,
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
            let {sierraContract, casmContract} = getContractClass(contractPath.GATEKEEPER);

            try {
                const gatekeeperDeclareResponse = await deployer.declare({ contract: sierraContract, casm: casmContract });
                await provider.waitForTransaction(gatekeeperDeclareResponse.transaction_hash);
                gatekeeperContractClassHash = gatekeeperDeclareResponse.class_hash;
                console.log('✅ Gatekeeper Contract declared with classHash = ', gatekeeperContractClassHash);
            } catch (error) {
                if (!error.message.includes('StarkFelt(\\')) {
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
            const {sierraContract, casmContract} = getContractClass(contractPath.VERIFIER);
    
            try {
                const verifierDeclareResponse = await deployer.declare({ contract: sierraContract, casm: casmContract });
                await provider.waitForTransaction(verifierDeclareResponse.transaction_hash);
                verifierContractClassHash = verifierDeclareResponse.class_hash;
                console.log('✅ Verifier Contract declared with classHash = ', verifierContractClassHash);
            } catch (error) {
                if (!error.message.includes('StarkFelt(\\')) {
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
            const {sierraContract, casmContract} = getContractClass(contractPath.ZKLINK);
            try {
                const zklinkDeclareResponse = await deployer.declare({ contract: sierraContract, casm: casmContract });
                await provider.waitForTransaction(zklinkDeclareResponse.transaction_hash);
                zklinkContractClassHash = zklinkDeclareResponse.class_hash;
                console.log('✅ Zklink Contract declared with classHash = ', zklinkContractClassHash);
            } catch (error) {
                if (!error.message.includes('StarkFelt(\\')) {
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
//  Class with hash ClassHash(StarkFelt(\"0x038f7db13bb80ea5f7536a70360ae15499f7036fcb7f8563698c273b3971ed70\")) is already declared.
export function getClassHashFromError(error) {
    const regex = /StarkFelt\(\\"([^"]*)\\/;
    const match = error.message.match(regex);
    if (match) {
        return match[1];
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

// read zklink.starknet_artifacts.json and return sierra and casm path
export function getContractClass(contracName) {
    const zkLink_contracts = json.parse(fs.readFileSync(contractPath.ZKLINK_ARTIFACTS_PATH).toString("ascii")).contracts;
    let sierraPath = "";
    let casmPath = "";
    for (let contract of zkLink_contracts) {
        if (contract.contract_name == contracName) {
            sierraPath = "./target/release/" + contract.artifacts.sierra;
            casmPath = "./target/release/" + contract.artifacts.casm;
        }
    }

    const sierraContract = json.parse(fs.readFileSync(sierraPath).toString("ascii"));
    const casmContract = json.parse(fs.readFileSync(casmPath).toString("ascii"));
    return {sierraContract, casmContract};
}