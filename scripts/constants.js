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
const DEPLOY_LOG_ZKLINK_VERIFIED = "zkLinkVerified";
const DEPLOY_LOG_ZKLINK_TRANSFER_MASTER_TX_HASH = "zkLinktransferMasterTxHash";
const DEPLOY_LOG_ZKLINK_ADDUPGRADEABLE_TX_HASH = "zkLinkAddUpgradeableTxHash";
const DEPLOY_LOG_ZKLINK_SET_VALIDATOR_TX_HASH = "zkLinkSetValidatorTxHash";
const DEPLOY_LOG_GATEKEEPER = "gatekeeper";
const DEPLOY_LOG_GATEKEEPER_CLASS_HASH = "gatekeeperClassHash";
const DEPLOY_LOG_GATEKEEPER_VERIFIED = "gatekeeperVerified";
const DEPLOY_LOG_GATEKEEPER_TRANSFER_MASTER_TX_HASH = "gatekeepertransferMasterTxHash";


// path
const GATEKEEPER_SIERRA_PATH = "./target/release/zklink_UpgradeGateKeeper.sierra.json";
const GATEKEEPER_CASM_PATH = "./target/release/zklink_UpgradeGateKeeper.casm.json";
const VERIFIER_SIERRA_PATH = "./target/release/zklink_Verifier.sierra.json";
const VERIFIER_CASM_PATH = "./target/release/zklink_Verifier.casm.json";
const ZKLINK_SIERRA_PATH = "./target/release/zklink_Zklink.sierra.json";
const ZKLINK_CASM_PATH = "./target/release/zklink_Zklink.casm.json";
const FAUCET_TOKEN_SIERRA_PATH = "./target/release/zklink_FaucetToken.sierra.json";
const FAUCET_TOKEN_CASM_PATH = "./target/release/zklink_FaucetToken.casm.json";
const ZKLINK_CONSTANTS_PATH = "./src/utils/constants.cairo";

// command
const COMMAND_BUILD = "scarb --release build";

export var command = {
    COMMAND_BUILD
}

export var contractPath = {
    GATEKEEPER_SIERRA_PATH,
    GATEKEEPER_CASM_PATH,
    VERIFIER_SIERRA_PATH,
    VERIFIER_CASM_PATH,
    ZKLINK_SIERRA_PATH,
    ZKLINK_CASM_PATH,
    ZKLINK_CONSTANTS_PATH,
    FAUCET_TOKEN_SIERRA_PATH,
    FAUCET_TOKEN_CASM_PATH
}

export var logName = {
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
    DEPLOY_LOG_ZKLINK_VERIFIED,
    DEPLOY_LOG_ZKLINK_TRANSFER_MASTER_TX_HASH,
    DEPLOY_LOG_ZKLINK_ADDUPGRADEABLE_TX_HASH,
    DEPLOY_LOG_ZKLINK_SET_VALIDATOR_TX_HASH,
    DEPLOY_LOG_GATEKEEPER,
    DEPLOY_LOG_GATEKEEPER_CLASS_HASH,
    DEPLOY_LOG_GATEKEEPER_VERIFIED,
    DEPLOY_LOG_GATEKEEPER_TRANSFER_MASTER_TX_HASH
};