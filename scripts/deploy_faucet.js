import { program } from "commander";
import fs from "fs";
import { connectStarknet, buildFaucetTokenConstructorArgs, getClassHashFromError, getContractClass, getDeployLog } from "./utils.js";
import { logName, contractPath } from "./constants.js"

program
    .command("deployFaucetToken")
    .description("deploy faucet token")
    .requiredOption('--name <name>', 'The token name')
    .requiredOption('--symbol <symbol>', 'The token symbol')
    .option('--decimals <decimals>', 'The token decimals', 18)
    .action(async function (options) {
        await deploy_faucet_token(options);
    });

program.parse();

async function deploy_faucet_token(options) {
    const { deployLogPath, deployLog } = getDeployLog(logName.DEPLOY_FAUCET_TOKEN_LOG_PREFIX);
    const name = options.name;
    const symbol = options.symbol;
    const decimals = options.decimals;

    console.log("name:", name);
    console.log("symbol:", symbol);
    console.log("decimals:", decimals);

    let { provider, deployer, governor, netConfig} = await connectStarknet();

    // declare faucet token
    const {sierraContract, casmContract} = getContractClass(contractPath.FAUCET_TOKEN);

    let classHash = deployLog[logName.DEPLOY_LOG_FAUCET_TOKEN_CLASS_HASH];
    if (!(logName.DEPLOY_LOG_FAUCET_TOKEN_CLASS_HASH in deployLog)) {
        try {
            const declareResponse = await deployer.declare({ contract: sierraContract, casm: casmContract });
            await provider.waitForTransaction(declareResponse.transaction_hash);
            classHash = declareResponse.class_hash;
            console.log('✅ Faucet Token Contract declared with classHash = ', classHash);
        } catch (error) {
            if (!error.message.includes('is already declared.')) {
                throw error;
            }
    
            classHash = getClassHashFromError(error);
            if (classHash === undefined) {
                console.log('❌ Cannot declare gatekeeper contract class hash:', error);
                return;
            } else {
                console.log('✅ Faucet Token Contract already declared with classHash =', classHash);
            }
        }
    }
    deployLog[logName.DEPLOY_LOG_FAUCET_TOKEN_CLASS_HASH] = classHash;
    fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));

    // deploy faucet token
    const constructorArgs = buildFaucetTokenConstructorArgs(sierraContract.abi, name, symbol, decimals);
    const deployResponse = await deployer.deployContract({ classHash: classHash, constructorCalldata: constructorArgs });
    await provider.waitForTransaction(deployResponse.transaction_hash);

    console.log('✅ Faucet Token Contract deployed at =', deployResponse.contract_address);
}