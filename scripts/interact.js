import { program } from "commander";
import fs from "fs";
import { Contract, json } from "starknet";
import { contractPath, logName, connectionType } from "./constants.js";
import { connectStarknet, getDeployLog, getContractClass } from "./utils.js";

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

program
    .command("mintFaucetToken")
    .description("Mint faucet token")
    .requiredOption('--token <address>', 'The token address')
    .requiredOption('--to <address>', 'The receiver address')
    .requiredOption('--amount <amount>', 'The amount to mint')
    .requiredOption('--decimals <decimals>', 'The token decimals')
    .action(async (options) => {
        await mint_faucet_token(options);
    });

program.parse();

async function add_token(options) {
    let { provider, deployer, governor, netConfig} = await connectStarknet(connectionType.DEPLOY);
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

    const {sierraContract, casmContract} = getContractClass(contractPath.ZKLINK);
    const zklink = new Contract(sierraContract.abi, zklinkAddress, provider);

    zklink.connect(governor);
    const call = zklink.populate("addToken", [tokenId, tokenAddress, tokenDecimals]);
    const tx = await zklink.addToken(call.calldata);
    await provider.waitForTransaction(tx.transaction_hash);
    console.log('✅ zklink add new ERC20 token success, tx:', tx.transaction_hash);
}

async function add_bridge(options) {
    let { provider, deployer, governor, netConfig} = await connectStarknet(connectionType.DEPLOY);
    const { deployLogPath, deployLog } = getDeployLog(logName.DEPLOY_ZKLINK_LOG_PREFIX);

    const bridgeAddress = options.bridge;
    const zklinkAddress = deployLog[logName.DEPLOY_LOG_ZKLINK];
    const {sierraContract, casmContract} = getContractClass(contractPath.ZKLINK);
    const zklink = new Contract(sierraContract.abi, zklinkAddress, provider);

    zklink.connect(governor);
    const call = zklink.populate("setSyncService", [bridgeAddress]);
    const tx = await zklink.setSyncService(call.calldata);
    await provider.waitForTransaction(tx.transaction_hash);
    console.log('✅ zklink add bridge success, tx:', tx.transaction_hash);
}

async function mint_faucet_token(options) {
    let { provider, deployer, governor, netConfig} = await connectStarknet(connectionType.DEPLOY);

    const tokenAddress = options.token;
    const toAddress = options.to;
    const amount = options.amount;
    const decimals = options.decimals;

    console.log("tokenAddress:", tokenAddress);
    console.log("toAddress:", toAddress);
    console.log("amount:", amount);
    console.log("decimals:", decimals);
    console.log("Minting faucet token");

    const {sierraContract, casmContract} = getContractClass(contractPath.FAUCET_TOKEN);
    const faucetToken = new Contract(sierraContract.abi, tokenAddress, provider);

    faucetToken.connect(deployer);
    const call = faucetToken.populate("mintTo", [toAddress, amount]);
    const tx = await faucetToken.mintTo(call.calldata);
    await provider.waitForTransaction(tx.transaction_hash);
    console.log('✅ faucet token mint success, tx:', tx.transaction_hash);
}