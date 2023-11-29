import { program } from "commander";
import fs from "fs";
import { logName, contractPath } from "./constants.js";
import { connectStarknet, buildMulticallConstructorArgs, getClassHashFromError, getContractClass, getDeployLog } from "./utils.js";

program
    .command("deployMulticall")
    .description("deploy multicall contract")
    .option('--skip-verify', 'Skip verification', false)
    .option('--force', 'Force redeploy', false)
    .action(async function (options) {
        await deploy_multicall(options);
    });

program.parse();

async function deploy_multicall(options) {
    const { deployLogPath, deployLog } = getDeployLog(logName.DEPLOY_MULTICALL_LOG_PREFIX);
    let { provider, deployer, governor, netConfig } = await connectStarknet();

    // declare multicall contract
    const {sierraContract, casmContract} = getContractClass(contractPath.MULTICALL);

    let classHash = deployLog[logName.DEPLOY_LOG_MULTICALL_CLASS_HASH];
    if (!(logName.DEPLOY_LOG_FAUCET_TOKEN_CLASS_HASH in deployLog)) {
        try {
            const declareResponse = await deployer.declare({ contract: sierraContract, casm: casmContract });
            await provider.waitForTransaction(declareResponse.transaction_hash);
            classHash = declareResponse.class_hash;
            console.log('✅ Multicall Contract declared with classHash = ', classHash);
        } catch (error) {
            if (!error.message.includes('is already declared.')) {
                throw error;
            }
    
            classHash = getClassHashFromError(error);
            if (classHash === undefined) {
                console.log('❌ Cannot declare gatekeeper contract class hash:', error);
                return;
            } else {
                console.log('✅ Multicall Contract already declared with classHash =', classHash);
            }
        }
    }
    deployLog[logName.DEPLOY_LOG_MULTICALL_CLASS_HASH] = classHash;
    fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));

    // deploy multicall
    const constructorArgs = buildMulticallConstructorArgs(sierraContract.abi);
    const deployResponse = await deployer.deployContract({ classHash: classHash, constructorCalldata: constructorArgs });
    let tx = await provider.waitForTransaction(deployResponse.transaction_hash);
    while (tx.block_number === undefined) {
        await new Promise(resolve => setTimeout(resolve, 60000));
        tx = await provider.waitForTransaction(deployResponse.transaction_hash);
    }
    console.log('tx block number', tx.block_number);
    console.log('✅ Multicall Contract deployed at =', deployResponse.contract_address);
    deployLog[logName.DEPLOY_LOG_MULTICALL] = deployResponse.contract_address;
    deployLog[logName.DEPLOY_LOG_MULTICALL_TX_HASH] = deployResponse.transaction_hash;
    deployLog[logName.DEPLOY_LOG_MULTICALL_BLOCK_NUMBER] = tx.block_number;
    fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
}