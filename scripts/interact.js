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
    .option('--standard <standard>', 'The token is a standard ERC20 token', true)
    .action(async (options) => {
        await add_token(options);
    });

program.parse();

async function add_token(options) {
    let { provider, deployer, governor, netConfig} = await connectStarknet();
    const { deployLogPath, deployLog } = getDeployLog(logName.DEPLOY_ZKLINK_LOG_PREFIX);

    const zklinkAddress = options.zklink === undefined ? deployLog[logName.DEPLOY_LOG_ZKLINK] : options.zklink;
    const tokenId = options.tokenId;
    const tokenAddress = options.tokenAddress;
    const tokenDecimals = options.tokenDecimals;
    const standard = options.standard;

    console.log("zklink:", zklinkAddress);
    console.log("governor:", governor.address);
    console.log("tokenId:", tokenId);
    console.log("tokenAddress:", tokenAddress);
    console.log("tokenDecimals:", tokenDecimals);
    console.log("standard:", standard);
    console.log("Adding new ERC20 token to zklink");

    const zklinkContractSierra = json.parse(fs.readFileSync(contractPath.ZKLINK_SIERRA_PATH).toString("ascii"));
    const zklink = new Contract(zklinkContractSierra.abi, zklinkAddress, provider);

    zklink.connect(governor);
    const call = zklink.populate("addToken", [tokenId, tokenAddress, tokenDecimals, standard]);
    const tx = await zklink.addToken(call.calldata);
    await provider.waitForTransaction(tx.transaction_hash);
    console.log('✅ zklink add new ERC20 token success, tx:', tx.transaction_hash);
}