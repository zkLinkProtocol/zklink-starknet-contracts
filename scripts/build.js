import { program } from "commander";
import fs from "fs";
import { executeCommand } from "./utils.js";
import { command, contractPath } from "./constants.js";

program
    .command("build")
    .description("replace zklink contract constants and compile")
    .action(async () => {
        await build();
    });

program.parse();

function parseBlockPeriod(blockPeriod) {
    const regex = /^(\d+)\s+seconds?$/i;
    const match = blockPeriod.match(regex);
    
    if (match) {
        return parseInt(match[1], 10);
    } else {
        throw new Error(`Invalid block period: ${blockPeriod}`);
    }
}

function writeZklinkConstants(configs) {
    fs.readFile(contractPath.ZKLINK_CONSTANTS_PATH, 'utf8', (err, data) => {
        if (err) {
            console.error(err);
            return;
        }

        // BLOCK_PERIOD
        let result = data.replace(/(const BLOCK_PERIOD: u64 = )(\d+)(;)/, `$1${configs.blockPeriod}$3`);
        // PRIORITY_EXPIRATION
        result = result.replace(/(const PRIORITY_EXPIRATION: u64 = )(\d+)(;)/, `$1${configs.priorityExpiration}$3`);
        // UPGRADE_NOTICE_PERIOD
        result = result.replace(/(const UPGRADE_NOTICE_PERIOD: u64 = )(\d+)(;)/, `$1${configs.upgradeNoticePeriod}$3`);
        // CHAIN_ID
        result = result.replace(/(const CHAIN_ID: u8 = )(\d+)(;)/, `$1${configs.chainId}$3`);
        // MAX_CHAIN_ID
        result = result.replace(/(const MAX_CHAIN_ID: u8 = )(\d+)(;)/, `$1${configs.maxChainId}$3`);
        // ALL_CHAAINS
        result = result.replace(/(const ALL_CHAINS: u256 = )(\d+)(;)/, `$1${configs.allChains}$3`);
        // MASTER_CHAIN_ID
        result = result.replace(/(const MASTER_CHAIN_ID: u8 = )(\d+)(;)/, `$1${configs.chainIndex}$3`);

        fs.writeFile(contractPath.ZKLINK_CONSTANTS_PATH, result, 'utf8', (err) => {
            if (err) {
                console.error(err);
                return;
            }
        });
    });
}

async function build() {
    // read config json file
    const netName = process.env.NET === undefined ? "EXAMPLE" : process.env.NET;
    let netConfig = await fs.promises.readFile(`./etc/${netName}.json`, "utf-8");
    netConfig = JSON.parse(netConfig);

    const blockPeriod = parseBlockPeriod(netConfig.macro.BLOCK_PERIOD);
    const upgradeNoticePeriod = netConfig.macro.UPGRADE_NOTICE_PERIOD;
    const priorityExpiration = netConfig.macro.PRIORITY_EXPIRATION;
    const chainId = netConfig.macro.CHAIN_ID;
    const enableCommitCompressedBlock = netConfig.macro.ENABLE_COMMIT_COMPRESSED_BLOCK ? 1 : 0;
    const minChainId = netConfig.macro.MIN_CHAIN_ID;
    const maxChainId = netConfig.macro.MAX_CHAIN_ID;
    const allChains = netConfig.macro.ALL_CHAINS;
    const chainIndex = 1 << (chainId - 1);

    const configs = {
        blockPeriod,
        upgradeNoticePeriod,
        priorityExpiration,
        chainId,
        enableCommitCompressedBlock,
        minChainId,
        maxChainId,
        allChains,
        chainIndex
    }

    console.log("🔥 Reading and replace zklink constants...");
    console.log("configs:", configs);
    writeZklinkConstants(configs);
    console.log("✅ Replace zklink constants success");

    console.log("Building zklink contract...");
    await executeCommand(command.COMMAND_BUILD)
        .then((stdout) => {
            console.log(stdout)
        }).catch((error) => {
            console.log(error)
        });
    console.log("✅ Build zklink contract success");
}