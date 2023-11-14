import { program } from "commander";
import fs from "fs";
import { Contract, json } from "starknet";
import { contractPath, logName } from "./constants.js";
import { connectStarknet, getDeployLog } from "./utils.js";

program
    .command("addToken")
    .description("Adds a new token with a given address for testnet")
    .option('--zklink <zklink>', 'The zkLink contract address (default get from deploy log)', undefined)
    .requiredOption('--token-id <tokenId>', 'The token id')
    .requiredOption('--token-address <tokenAddress>', 'The token address')
    .option('--token-decimals <tokenDecimals>', 'The token decimals', 18)
    .action(async (options) => {
        await add_token(options);
    });

program
    .command("addBridge")
    .description("Add bridge to zkLink")
    .requiredOption('--bridge <bridge>', 'The bridge address (default get from deploy log)')
    .action(async (options) => {
        await add_bridge(options);
    });

program.parse();

async function add_token(options) {
    let { provider, deployer, governor, netConfig} = await connectStarknet();
    const { deployLogPath, deployLog } = getDeployLog(logName.DEPLOY_ZKLINK_LOG_PREFIX);

    const zklinkAddress = options.zklink === undefined ? deployLog[logName.DEPLOY_LOG_ZKLINK] : options.zklink;
    const tokenId = options.tokenId;
    const tokenAddress = options.tokenAddress;
    const tokenDecimals = options.tokenDecimals;

    console.log("zklink:", zklinkAddress);
    console.log("governor:", governor.address);
    console.log("tokenId:", tokenId);
    console.log("tokenAddress:", tokenAddress);
    console.log("tokenDecimals:", tokenDecimals);
    console.log("Adding new ERC20 token to zklink");

    const zklinkContractSierra = json.parse(fs.readFileSync(contractPath.ZKLINK_SIERRA_PATH).toString("ascii"));
    const zklink = new Contract(zklinkContractSierra.abi, zklinkAddress, provider);

    zklink.connect(governor);
    const call = zklink.populate("addToken", [tokenId, tokenAddress, tokenDecimals]);
    const tx = await zklink.addToken(call.calldata);
    await provider.waitForTransaction(tx.transaction_hash);
    console.log('✅ zklink add new ERC20 token success, tx:', tx.transaction_hash);
}

async function add_bridge(options) {
    let { provider, deployer, governor, netConfig} = await connectStarknet();
    const { deployLogPath, deployLog } = getDeployLog(logName.DEPLOY_ZKLINK_LOG_PREFIX);

    const bridgeAddress = options.bridge;
    const zklinkAddress = deployLog[logName.DEPLOY_LOG_ZKLINK];
    const zklinkContractSierra = json.parse(fs.readFileSync(contractPath.ZKLINK_SIERRA_PATH).toString("ascii"));
    const zklink = new Contract(zklinkContractSierra.abi, zklinkAddress, provider);

    zklink.connect(governor);
    const call = zklink.populate("addBridge", [bridgeAddress]);
    const tx = await zklink.addBridge(call.calldata);
    await provider.waitForTransaction(tx.transaction_hash);
    console.log('✅ zklink add bridge success, tx:', tx.transaction_hash);
}