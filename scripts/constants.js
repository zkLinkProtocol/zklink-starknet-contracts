// consumed in deploy_zklink.js
const DEPLOY_ZKLINK_LOG_PREFIX = 'deploy';
const DEPLOY_LOG_DEPLOYER = "deployer";
const DEPLOY_LOG_GOVERNOR = "governor";
const DEPLOY_LOG_VALIDATOR = "validator";
const DEPLOY_LOG_VERIFIER_CLASS_HASH = "verifierClassHash";
const DEPLOY_LOG_VERIFIER = "verifier";
const DEPLOY_LOG_VERIFIER_VERIFIED = "verifierVerified";
const DEPLOY_LOG_VERIFIER_TRANSFER_MASTER_TX_HASH = "verifiertransferMasterTxHash";
const DEPLOY_LOG_VERIFIER_ADDUPGRADEABLE_TX_HASH = "verifierAddUpgradeableTxHash";
const DEPLOY_LOG_ZKLINK_CLASS_HASH = "zkLinkClassHash";
const DEPLOY_LOG_ZKLINK = "zkLink";
const DEPLOY_LOG_ZKLINK_TX_HASH = "zkLinkTxHash";
const DEPLOY_LOG_ZKLINK_BLOCK_NUMBER = "zkLinkBlockNumber";
const DEPLOY_LOG_ZKLINK_VERIFIED = "zkLinkVerified";
const DEPLOY_LOG_ZKLINK_TRANSFER_MASTER_TX_HASH = "zkLinktransferMasterTxHash";
const DEPLOY_LOG_ZKLINK_ADDUPGRADEABLE_TX_HASH = "zkLinkAddUpgradeableTxHash";
const DEPLOY_LOG_ZKLINK_SET_VALIDATOR_TX_HASH = "zkLinkSetValidatorTxHash";
const DEPLOY_LOG_GATEKEEPER = "gatekeeper";
const DEPLOY_LOG_GATEKEEPER_CLASS_HASH = "gatekeeperClassHash";
const DEPLOY_LOG_GATEKEEPER_VERIFIED = "gatekeeperVerified";
const DEPLOY_LOG_GATEKEEPER_TRANSFER_MASTER_TX_HASH = "gatekeepertransferMasterTxHash";

// multicall
const DEPLOY_MULTICALL_LOG_PREFIX = 'deploy_multicall';
const DEPLOY_LOG_MULTICALL_CLASS_HASH = "multicallClassHash";
const DEPLOY_LOG_MULTICALL = "multicall";
const DEPLOY_LOG_MULTICALL_TX_HASH = "multicallTxHash";
const DEPLOY_LOG_MULTICALL_BLOCK_NUMBER = "multicallBlockNumber";
const DEPLOY_LOG_MULTICALL_VERIFIED = "multicallVerified";

// faucet token
const DEPLOY_FAUCET_TOKEN_LOG_PREFIX = 'deploy_token';
const DEPLOY_LOG_FAUCET_TOKEN_CLASS_HASH = "faucetTokenClassHash";

// path
const ZKLINK_CONSTANTS_PATH = "./src/utils/constants.cairo";
const ZKLINK_ARTIFACTS_PATH = "./target/release/zklink.starknet_artifacts.json";
const ZKLINK = "Zklink";
const VERIFIER = "Verifier";
const GATEKEEPER = "UpgradeGateKeeper";
const MULTICALL = "Multicall";
const FAUCET_TOKEN = "FaucetToken";

// upgrade status
const IDLE = "Idle";
const NOTICE_PERIOD = "NoticePeriod";

// command
const COMMAND_BUILD = "scarb --release build";

export var UpgradeStatus = {
    IDLE,
    NOTICE_PERIOD
}

export var command = {
    COMMAND_BUILD
}

export var contractPath = {
    ZKLINK_CONSTANTS_PATH,
    ZKLINK_ARTIFACTS_PATH,
    ZKLINK,
    VERIFIER,
    GATEKEEPER,
    MULTICALL,
    FAUCET_TOKEN
}

export var logName = {
    // deploy zklink
    DEPLOY_ZKLINK_LOG_PREFIX,
    DEPLOY_LOG_DEPLOYER,
    DEPLOY_LOG_GOVERNOR,
    DEPLOY_LOG_VALIDATOR,
    DEPLOY_LOG_VERIFIER_CLASS_HASH,
    DEPLOY_LOG_VERIFIER,
    DEPLOY_LOG_VERIFIER_VERIFIED,
    DEPLOY_LOG_VERIFIER_TRANSFER_MASTER_TX_HASH,
    DEPLOY_LOG_VERIFIER_ADDUPGRADEABLE_TX_HASH,
    DEPLOY_LOG_ZKLINK_CLASS_HASH,
    DEPLOY_LOG_ZKLINK,
    DEPLOY_LOG_ZKLINK_TX_HASH,
    DEPLOY_LOG_ZKLINK_BLOCK_NUMBER,
    DEPLOY_LOG_ZKLINK_VERIFIED,
    DEPLOY_LOG_ZKLINK_TRANSFER_MASTER_TX_HASH,
    DEPLOY_LOG_ZKLINK_ADDUPGRADEABLE_TX_HASH,
    DEPLOY_LOG_ZKLINK_SET_VALIDATOR_TX_HASH,
    DEPLOY_LOG_GATEKEEPER,
    DEPLOY_LOG_GATEKEEPER_CLASS_HASH,
    DEPLOY_LOG_GATEKEEPER_VERIFIED,
    DEPLOY_LOG_GATEKEEPER_TRANSFER_MASTER_TX_HASH,
    // deploy multicall
    DEPLOY_MULTICALL_LOG_PREFIX,
    DEPLOY_LOG_MULTICALL_CLASS_HASH,
    DEPLOY_LOG_MULTICALL,
    DEPLOY_LOG_MULTICALL_TX_HASH,
    DEPLOY_LOG_MULTICALL_BLOCK_NUMBER,
    DEPLOY_LOG_MULTICALL_VERIFIED,
    // deploy faucet token
    DEPLOY_FAUCET_TOKEN_LOG_PREFIX,
    DEPLOY_LOG_FAUCET_TOKEN_CLASS_HASH
};