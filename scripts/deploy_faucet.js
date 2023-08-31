import { program } from "commander";
import fs from "fs";
import { contractPath } from "./constants.js";
import { connectStarknet, buildFaucetTokenConstructorArgs, getClassHashFromError } from "./utils.js";
import { json } from "starknet";

program
    .command("deployFaucetToken")
    .description("deploy faucet token")
    .requiredOption('--name <name>', 'The token name')
    .requiredOption('--symbol <symbol>', 'The token symbol')
    .option('--decimals <decimals>', 'The token decimals', 18)
    .option('--from-transfer-fee-ratio', 'The fee ratio taken of from address when transfer', 0)
    .option('--to-transfer-fee-ratio', 'The fee ratio taken of to address when transfer', 0)
    .action(async function (options) {
        await deploy_faucet_token(options);
    });

program.parse();

async function deploy_faucet_token(options) {
    const name = options.name;
    const symbol = options.symbol;
    const decimals = options.decimals;
    const fromTransferFeeRatio = options.fromTransferFeeRatio;
    const toTransferFeeRatio = options.toTransferFeeRatio;

    console.log("name:", name);
    console.log("symbol:", symbol);
    console.log("decimals:", decimals);
    console.log("fromTransferFeeRatio:", fromTransferFeeRatio);
    console.log("toTransferFeeRatio:", toTransferFeeRatio);

    let { provider, deployer, governor, netConfig} = await connectStarknet();

    // declare faucet token
    const ContractSierra = json.parse(fs.readFileSync(contractPath.FAUCET_TOKEN_SIERRA_PATH).toString("ascii"));
    const contractCasm = json.parse(fs.readFileSync(contractPath.FAUCET_TOKEN_CASM_PATH).toString("ascii"));
    let classHash;
    try {
        const declareResponse = await deployer.declare({ contract: ContractSierra, casm: contractCasm });
        await provider.waitForTransaction(declareResponse.transaction_hash);
        classHash = declareResponse.class_hash;
        console.log('✅ Faucet Token Contract declared with classHash = ', classHash);
    } catch (error) {
        if (error.errorCode !== 'StarknetErrorCode.CLASS_ALREADY_DECLARED') {
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

    // deploy faucet token
    const constructorArgs = buildFaucetTokenConstructorArgs(ContractSierra.abi, name, symbol, decimals, fromTransferFeeRatio, toTransferFeeRatio);
    const deployResponse = await deployer.deployContract({ classHash: classHash, constructorCalldata: constructorArgs });
    await provider.waitForTransaction(deployResponse.transaction_hash);

    console.log('✅ Faucet Token Contract deployed at =', deployResponse.contract_address);
}