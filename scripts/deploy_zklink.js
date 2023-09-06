import { Contract, json, cairo } from "starknet";
import fs from "fs";
import { program } from "commander";
import { logName, contractPath } from "./constants.js"
import { connectStarknet, getDeployLog, buildVerifierConstructorArgs, buildZklinkConstructorArgs, buildGateKeeperConstructorArgs, declare_zklink } from "./utils.js";


program
    .command("deployZklink")
    .description("Deploy zklink and verifier contract")
    .option('--governor <governor>', 'Governor address')
    .option('--validator <validator>', 'Validator address')
    .option('--fee-account <feeAccount>', 'Fee account address')
    .option('--block-number <blockNumber>', 'Block number', 0)
    .option('--timestamp <timestamp>', 'Timestamp', 0)
    .requiredOption('--genesis-root <genesisRoot>', 'Gemesis root')
    .option('--commitment <commitment>', 'Commitment', "0x0000000000000000000000000000000000000000000000000000000000000000")
    .option('--sync-hash <syncHash>', 'Sync hash', "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470")
    .option('--skip-verify', 'Skip verification', false)
    .option('--force', 'Force redeploy', false)
    .action(async (options) => {
        await deploy_zklink(options);
    });

async function deploy_zklink(options) {
    const log = getDeployLog(logName.DEPLOY_ZKLINK_LOG_PREFIX);
    const { deployLogPath, deployLog } = log;
    let { provider, deployer, governor, netConfig } = await connectStarknet();

    // declare contracts
    const declare_options = {
        declareGatekeeper: true,
        declareVerifier: true,
        declareZklink: true,
        upgrade: false
    };
    await declare_zklink(provider, deployer, log, declare_options);

    if (options.governor === undefined) {
        options.governor = netConfig.network.accounts.governor.address;
    }

    if (options.validator === undefined) {
        options.validator = netConfig.network.accounts.deployer.address;
    }

    if (options.feeAccount === undefined) {
        options.feeAccount = netConfig.network.accounts.deployer.address;
    }

    deployLog[logName.DEPLOY_LOG_DEPLOYER] = deployer.address;
    deployLog[logName.DEPLOY_LOG_GOVERNOR] = options.governor;
    deployLog[logName.DEPLOY_LOG_VALIDATOR] = options.validator;
    fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
    
    const gatekeeperContractSierra = json.parse(fs.readFileSync(contractPath.GATEKEEPER_SIERRA_PATH).toString("ascii"));
    const verifierContractSierra = json.parse(fs.readFileSync(contractPath.VERIFIER_SIERRA_PATH).toString("ascii"));
    const zklinkContractSierra = json.parse(fs.readFileSync(contractPath.ZKLINK_SIERRA_PATH).toString("ascii"));

    // deploy verifier contract
    if (!(logName.DEPLOY_LOG_VERIFIER in deployLog) || options.force) {
        const verifierConstructorArgs = buildVerifierConstructorArgs(verifierContractSierra.abi, deployer.address);
        const deployResponse = await deployer.deployContract({ classHash: deployLog[logName.DEPLOY_LOG_VERIFIER_CLASS_HASH], constructorCalldata: verifierConstructorArgs });
        await provider.waitForTransaction(deployResponse.transaction_hash);

        console.log('✅ Verifier Contract deployed at =', deployResponse.contract_address);
        deployLog[logName.DEPLOY_LOG_VERIFIER] = deployResponse.contract_address;
        fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
    } else {
        console.log('✅ Verifier Contract already deployed at =', deployLog[logName.DEPLOY_LOG_VERIFIER]);
    }
    
    // deploy zklink contract
    if (!(logName.DEPLOY_LOG_ZKLINK in deployLog) || options.force) {
        const zklinkConstructorArgs = buildZklinkConstructorArgs(
            zklinkContractSierra.abi,
            deployer.address,
            deployLog[logName.DEPLOY_LOG_VERIFIER],
            options.governor,
            options.blockNumber,
            options.timestamp,
            cairo.uint256(options.genesisRoot),
            cairo.uint256(options.commitment),
            cairo.uint256(options.syncHash)
        );

        const deployResponse = await deployer.deployContract({ classHash: deployLog[logName.DEPLOY_LOG_ZKLINK_CLASS_HASH], constructorCalldata: zklinkConstructorArgs });
        const tx = await provider.waitForTransaction(deployResponse.transaction_hash);
        console.log('✅ zklink Contract deployed at =', deployResponse.contract_address);
        deployLog[logName.DEPLOY_LOG_ZKLINK] = deployResponse.contract_address;
        deployLog[logName.DEPLOY_LOG_ZKLINK_TX_HASH] = deployResponse.transaction_hash;
        deployLog[logName.DEPLOY_LOG_ZKLINK_BLOCK_NUMBER] = tx.block_number;
        fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
    } else {
        console.log('✅ zklink Contract already deployed at =', deployLog[logName.DEPLOY_LOG_ZKLINK]);
    }

    // deploy gatekeeper contract
    if (!(logName.DEPLOY_LOG_GATEKEEPER in deployLog) || options.force) {
        const gatekeeperConstructorArgs = buildGateKeeperConstructorArgs(gatekeeperContractSierra.abi, deployer.address, deployLog[logName.DEPLOY_LOG_ZKLINK]);

        const deployResponse = await deployer.deployContract({ classHash: deployLog[logName.DEPLOY_LOG_GATEKEEPER_CLASS_HASH], constructorCalldata: gatekeeperConstructorArgs, salt: "0" });
        await provider.waitForTransaction(deployResponse.transaction_hash);

        console.log('✅ Gatekeeper Contract deployed at =', deployResponse.contract_address);
        deployLog[logName.DEPLOY_LOG_GATEKEEPER] = deployResponse.contract_address;
        fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
    } else {
        console.log('✅ Gatekeeper Contract already deployed at =', deployLog[logName.DEPLOY_LOG_GATEKEEPER]);
    }

    // connect contracts
    const verifier = new Contract(verifierContractSierra.abi, deployLog[logName.DEPLOY_LOG_VERIFIER], provider);
    const zklink = new Contract(zklinkContractSierra.abi, deployLog[logName.DEPLOY_LOG_ZKLINK], provider);
    const gatekeeper = new Contract(gatekeeperContractSierra.abi, deployLog[logName.DEPLOY_LOG_GATEKEEPER], provider);

    // change verifier master from deployer to gatekeeper
    if (!(logName.DEPLOY_LOG_VERIFIER_TRANSFER_MASTER_TX_HASH in deployLog) || options.force) {
        verifier.connect(deployer);
        const call = verifier.populate("transferMastership", [gatekeeper.address]);
        const tx = await verifier.transferMastership(call.calldata);
        await provider.waitForTransaction(tx.transaction_hash);

        console.log('✅ Verifier Contract master transferred to gatekeeper at tx:', tx.transaction_hash);
        deployLog[logName.DEPLOY_LOG_VERIFIER_TRANSFER_MASTER_TX_HASH] = tx.transaction_hash;
        fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
    }

    // gatekeeper add verifier upgradeable
    if (!(logName.DEPLOY_LOG_VERIFIER_ADDUPGRADEABLE_TX_HASH in deployLog) || options.force) {
        gatekeeper.connect(deployer);
        const call = gatekeeper.populate("addUpgradeable", [deployLog[logName.DEPLOY_LOG_VERIFIER]]);
        const tx = await gatekeeper.addUpgradeable(call.calldata);
        await provider.waitForTransaction(tx.transaction_hash);

        console.log('✅ Gatekeeper Contract add verifier upgradeable at tx:', tx.transaction_hash);
        deployLog[logName.DEPLOY_LOG_VERIFIER_ADDUPGRADEABLE_TX_HASH] = tx.transaction_hash;
        fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
    }

    // change zklink master from deployer to gatekeeper
    if (!(logName.DEPLOY_LOG_ZKLINK_TRANSFER_MASTER_TX_HASH in deployLog) || options.force) {
        zklink.connect(deployer);
        const call = zklink.populate("transferMastership", [gatekeeper.address]);
        const tx = await zklink.transferMastership(call.calldata);
        await provider.waitForTransaction(tx.transaction_hash);
        console.log('✅ zklink Contract master transferred to gatekeeper at tx:', tx.transaction_hash);
        deployLog[logName.DEPLOY_LOG_ZKLINK_TRANSFER_MASTER_TX_HASH] = tx.transaction_hash;
        fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
    }

    // gatekeeper add zklink upgradeable
    if (!(logName.DEPLOY_LOG_ZKLINK_ADDUPGRADEABLE_TX_HASH in deployLog) || options.force) {
        gatekeeper.connect(deployer);
        const call = gatekeeper.populate("addUpgradeable", [deployLog[logName.DEPLOY_LOG_ZKLINK]]);
        const tx = await gatekeeper.addUpgradeable(call.calldata);
        await provider.waitForTransaction(tx.transaction_hash);
        console.log('✅ Gatekeeper Contract add zklink upgradeable at tx:', tx.transaction_hash);
        deployLog[logName.DEPLOY_LOG_ZKLINK_ADDUPGRADEABLE_TX_HASH] = tx.transaction_hash;
        fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
    }

    // change gatekeeper master from deployer to governor
    if (!(logName.DEPLOY_LOG_GATEKEEPER_TRANSFER_MASTER_TX_HASH in deployLog) || options.force) {
        gatekeeper.connect(deployer);
        const call = gatekeeper.populate("transferMastership", [options.governor]);
        const tx = await gatekeeper.transferMastership(call.calldata);
        await provider.waitForTransaction(tx.transaction_hash);
        console.log('✅ Gatekeeper Contract master transferred to governor at tx:', tx.transaction_hash);
        deployLog[logName.DEPLOY_LOG_GATEKEEPER_TRANSFER_MASTER_TX_HASH] = tx.transaction_hash;
        fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
    }

    // zklink set validator
    if (!(logName.DEPLOY_LOG_ZKLINK_SET_VALIDATOR_TX_HASH in deployLog) || options.force) {
        zklink.connect(governor);
        const call = zklink.populate("setValidator", [options.validator, true]);
        const tx = await zklink.setValidator(call.calldata);
        await provider.waitForTransaction(tx.transaction_hash);
        console.log('✅ zklink Contract set validator at tx:', tx.transaction_hash);
        deployLog[logName.DEPLOY_LOG_ZKLINK_SET_VALIDATOR_TX_HASH] = tx.transaction_hash;
        fs.writeFileSync(deployLogPath, JSON.stringify(deployLog, null, 2));
    }
}

program.parse();