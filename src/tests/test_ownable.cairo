use starknet::{ContractAddress, contract_address_const};
use starknet::testing::set_contract_address;
use debug::PrintTrait;
use zklink::contracts::zklink::Zklink;
use zklink::contracts::zklink::IZklinkDispatcher;
use zklink::contracts::zklink::IZklinkDispatcherTrait;
use zklink::contracts::verifier::Verifier;
use zklink::contracts::verifier::IVerifierDispatcher;
use zklink::contracts::verifier::IVerifierDispatcherTrait;
use zklink::tests::utils;

fn deploy_zklink() -> (ContractAddress, ContractAddress) {
    let deployer: ContractAddress =
        contract_address_const::<0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d>();
    set_contract_address(deployer);

    let verifier: ContractAddress = utils::deploy(
        Verifier::TEST_CLASS_HASH, array![deployer.into()]
    );

    let calldata = array![
        deployer.into(), // master
        verifier.into(), // verifier
        2, // governor
        0, // blockNumber
        0, // timestamp
        utils::GENESIS_ROOT.low.into(), // stateHash low
        utils::GENESIS_ROOT.high.into(), // stateHash high
        0, // commitment low
        0, // commitment high
        utils::EMPTY_STRING_KECCAK.low.into(), // syncHash low
        utils::EMPTY_STRING_KECCAK.high.into(), // syncHash high
    ];
    let zklink = utils::deploy(Zklink::TEST_CLASS_HASH, calldata);
    (verifier, zklink)
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_ownable_check_mastership_in_constructor() {
    let (verifier, zklink) = deploy_zklink();
    let verifier_dispatcher = IVerifierDispatcher { contract_address: verifier };
    let zklink_dispatcher = IZklinkDispatcher { contract_address: zklink, };
    let deployer: ContractAddress =
        contract_address_const::<0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d>();

    assert(verifier_dispatcher.getMaster() == deployer, 'mastership1');
    assert(zklink_dispatcher.getMaster() == deployer, 'mastership2');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1d', 'ENTRYPOINT_FAILED'))]
fn test_zklink_ownable_zklink_transfer_mastership_zero() {
    let (verifier, zklink) = deploy_zklink();
    let verifier_dispatcher = IVerifierDispatcher { contract_address: verifier };
    let zklink_dispatcher = IZklinkDispatcher { contract_address: zklink, };
    let deployer: ContractAddress =
        contract_address_const::<0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d>();

    zklink_dispatcher.transferMastership(contract_address_const::<0>());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1d', 'ENTRYPOINT_FAILED'))]
fn test_zklink_ownable_verifier_transfer_mastership_zero() {
    let (verifier, zklink) = deploy_zklink();
    let verifier_dispatcher = IVerifierDispatcher { contract_address: verifier };
    let zklink_dispatcher = IZklinkDispatcher { contract_address: zklink, };
    let deployer: ContractAddress =
        contract_address_const::<0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d>();

    verifier_dispatcher.transferMastership(contract_address_const::<0>());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1c', 'ENTRYPOINT_FAILED'))]
fn test_zklink_ownable_zklink_transfer_mastership_invalid_sender() {
    let (verifier, zklink) = deploy_zklink();
    let verifier_dispatcher = IVerifierDispatcher { contract_address: verifier };
    let zklink_dispatcher = IZklinkDispatcher { contract_address: zklink, };
    let deployer: ContractAddress =
        contract_address_const::<0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d>();
    let newMaster: ContractAddress = contract_address_const::<0x64656661756c7453656e646572>();

    zklink_dispatcher.transferMastership(newMaster);
    assert(zklink_dispatcher.getMaster() == newMaster, 'mastership1');

    zklink_dispatcher.transferMastership(deployer);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1c', 'ENTRYPOINT_FAILED'))]
fn test_zklink_ownable_verifier_transfer_mastership_invalid_sender() {
    let (verifier, zklink) = deploy_zklink();
    let verifier_dispatcher = IVerifierDispatcher { contract_address: verifier };
    let zklink_dispatcher = IZklinkDispatcher { contract_address: zklink, };
    let deployer: ContractAddress =
        contract_address_const::<0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d>();
    let newMaster: ContractAddress = contract_address_const::<0x64656661756c7453656e646572>();

    verifier_dispatcher.transferMastership(newMaster);
    assert(verifier_dispatcher.getMaster() == newMaster, 'mastership1');

    verifier_dispatcher.transferMastership(deployer);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_ownable_transfer_mastership_back_success() {
    let (verifier, zklink) = deploy_zklink();
    let verifier_dispatcher = IVerifierDispatcher { contract_address: verifier };
    let zklink_dispatcher = IZklinkDispatcher { contract_address: zklink, };
    let deployer: ContractAddress =
        contract_address_const::<0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d>();
    let newMaster: ContractAddress = contract_address_const::<0x64656661756c7453656e646572>();

    // zklink
    zklink_dispatcher.transferMastership(newMaster);
    assert(zklink_dispatcher.getMaster() == newMaster, 'mastership1');

    // verifier
    verifier_dispatcher.transferMastership(newMaster);
    assert(verifier_dispatcher.getMaster() == newMaster, 'mastership2');

    set_contract_address(newMaster);

    // zklink
    zklink_dispatcher.transferMastership(deployer);
    assert(zklink_dispatcher.getMaster() == deployer, 'mastership3');

    // verifier
    verifier_dispatcher.transferMastership(deployer);
    assert(verifier_dispatcher.getMaster() == deployer, 'mastership4');
}
