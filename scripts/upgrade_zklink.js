import { Contract, json} from "starknet";
import fs from "fs";
import { program } from "commander";
import { logName, contractPath, UpgradeStatus, connectionType } from "./constants.js"
import { connectStarknet, getDeployLog, declare_zklink, getContractClass } from "./utils.js"

program
    .command("upgradeZklink")
    .description("Upgrade the Zklink contract")
    .option("--upgrade-verifier <upgradeVerifier>", "Upgrade the verifier", false)
    .option("--upgrade-zklink <upgradeZklink>", "Upgrade the zklink", false)
    .option("--skip-verify <skipVerify>", "Skip the verification", false)
    .action(async (options) => {
        await upgrade_zklink(options);
    });

program.parse();

async function upgrade_zklink(options) {
    const log = getDeployLog(logName.DEPLOY_ZKLINK_LOG_PREFIX);
    const { deployLog, deployLogPath } = log;
    let { provider, deployer, governor, netConfig} = await connectStarknet(connectionType.DECLARE);

    const upgradeVerifier = options.upgradeVerifier;
    const upgradeZklink = options.upgradeZklink;
    const skipVerify = options.skipVerify;
    console.log("deployer: ", deployer.address);
    console.log("governor: ", governor.address);
    console.log("upgrade verifier: ", upgradeVerifier);
    console.log("upgrade zklink: ", upgradeZklink);
    console.log("skip verify: ", skipVerify);

    if (!upgradeVerifier && !upgradeZklink) {
        console.log("Nothing to upgrade");
        return;
    }

    const gateKeeperAddress = deployLog[logName.DEPLOY_LOG_GATEKEEPER];
    if (gateKeeperAddress === undefined) {
        console.log("Gatekeeper address is not found");
        return;
    }
    
    const {sierraContract: gatekeeperContractSierra, casmContract: gatekeeperContractCasm} = getContractClass(contractPath.GATEKEEPER);
    const gatekeeper = new Contract(gatekeeperContractSierra.abi, deployLog[logName.DEPLOY_LOG_GATEKEEPER], provider);

    gatekeeper.connect(deployer);
    let upgradeStatus = await gatekeeper.upgradeStatus();
    let verifierClassHash = deployLog[logName.DEPLOY_LOG_VERIFIER_CLASS_HASH];
    let zklinkClassHash = deployLog[logName.DEPLOY_LOG_ZKLINK_CLASS_HASH];
    // if upgrade status is Idle, then declare contract
    if (upgradeStatus.activeVariant() === UpgradeStatus.IDLE) {
        const declare_options = {
            declareGatekeeper: false,
            declareVerifier: upgradeVerifier,
            declareZklink: upgradeZklink,
            upgrade: true
        };
        await declare_zklink(provider, deployer, log, declare_options);

        if (upgradeVerifier) {
            verifierClassHash = deployLog[logName.DEPLOY_LOG_VERIFIER_CLASS_HASH];
            if (verifierClassHash === undefined) {
                console.log("Zklink class hash is not found");
                return;
            }
        }

        if (upgradeZklink) {
            zklinkClassHash = deployLog[logName.DEPLOY_LOG_ZKLINK_CLASS_HASH]
            if (zklinkClassHash === undefined) {
                console.log("Zklink class hash is not found");
                return;
            }
        }
    }

    // check if upgrade at testnet
    const {sierraContract: zklinkContractSierra, casmContract: zklinkContractCasm} = getContractClass(contractPath.ZKLINK);
    const zklink = new Contract(zklinkContractSierra.abi, deployLog[logName.DEPLOY_LOG_ZKLINK], provider);
    zklink.connect(deployer);
    const noticePeriod = await zklink.getNoticePeriod();
    if (noticePeriod > 0) {
        console.log("Notice period is not zero, can not exec this task");
        return;
    }

    // start upgrade
    if (upgradeStatus.activeVariant() === UpgradeStatus.IDLE) {
        gatekeeper.connect(governor);
        const call = gatekeeper.populate("startUpgrade", [[verifierClassHash, zklinkClassHash]]);
        const tx = await gatekeeper.startUpgrade(call.calldata);
        await provider.waitForTransaction(tx.transaction_hash);
        console.log("Upgrade started at tx", tx.transaction_hash);
        gatekeeper.connect(deployer);
        upgradeStatus = await gatekeeper.upgradeStatus();
    }
    

    if (upgradeStatus.activeVariant() == UpgradeStatus.NOTICE_PERIOD) {
        gatekeeper.connect(governor);
        const call = gatekeeper.populate("finishUpgrade");
        const tx = await gatekeeper.finishUpgrade(call.calldata);
        await provider.waitForTransaction(tx.transaction_hash);
        console.log("Upgrade finished at tx", tx.transaction_hash);
    }
}