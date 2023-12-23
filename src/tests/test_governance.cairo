use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use clone::Clone;
use debug::PrintTrait;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use starknet::testing::{set_caller_address, set_contract_address};

use zklink_starknet_utils::bytes::{Bytes, BytesTrait};

use zklink::contracts::zklink::Zklink;
use zklink::utils::data_structures::DataStructures::RegisteredToken;
use zklink::tests::mocks::zklink_test::ZklinkMock;
use zklink::tests::mocks::verifier_test::VerifierMock;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcher;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcherTrait;
use zklink::tests::mocks::standard_token::StandardToken;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcher;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcherTrait;
use zklink::tests::utils;
use zklink::tests::utils::{Token, deploy};

fn prepare_test_deploy() -> Array<ContractAddress> {
    let defaultSender: ContractAddress = contract_address_const::<0x64656661756c7453656e646572>();
    let governor: ContractAddress = contract_address_const::<0x676f7665726e6f72>();
    let validator: ContractAddress = contract_address_const::<0x76616c696461746f72>();
    let feeAccount: ContractAddress = contract_address_const::<0x6665654163636f756e74>();
    let alice: ContractAddress = contract_address_const::<0x616c696365>();
    let bob: ContractAddress = contract_address_const::<0x626f62>();

    // verifier
    let verifier: ContractAddress = deploy(VerifierMock::TEST_CLASS_HASH, array![]);
    // zklink
    let calldata = array![
        defaultSender.into(), // master
        verifier.into(), // verifier
        defaultSender.into(), // governor
        0, // blockNumber
    ];
    let zklink: ContractAddress = deploy(ZklinkMock::TEST_CLASS_HASH, calldata);

    let address: Array<ContractAddress> = array![
        defaultSender, governor, validator, feeAccount, alice, bob, zklink, verifier
    ];

    address
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_change_governor_success() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let alice: ContractAddress = *address[utils::ADDR_ALICE];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];

    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let oldGovernor: ContractAddress = dispatcher.getGovernor();
    assert(oldGovernor == defaultSender, 'wrong default governor');

    set_contract_address(defaultSender);
    dispatcher.changeGovernor(alice);

    let newGovernor: ContractAddress = dispatcher.getGovernor();
    assert(newGovernor == alice, 'wrong new governor');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H', 'ENTRYPOINT_FAILED'))]
fn test_zklink_change_governor_zero() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];

    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    set_contract_address(defaultSender);
    dispatcher.changeGovernor(contract_address_const::<0x0>());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_add_token_not_governor() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let alice: ContractAddress = *address[utils::ADDR_ALICE];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let tokenId = 1;
    let tokenAddress: ContractAddress = contract_address_const::<0x746f6b656e>();

    set_contract_address(alice);
    dispatcher.addToken(tokenId, tokenAddress, 6);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('I0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_add_token_invalid_tokenId() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let tokenId = 0;
    let tokenAddress: ContractAddress = contract_address_const::<0x746f6b656e>();

    set_contract_address(defaultSender);
    dispatcher.addToken(tokenId, tokenAddress, 6);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('I1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_add_token_invalid_tokenAddress() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let tokenId = 1;
    let tokenAddress: ContractAddress = contract_address_const::<0x0>();

    set_contract_address(defaultSender);
    dispatcher.addToken(tokenId, tokenAddress, 6);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('I3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_add_token_invalid_decimals() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let tokenId = 1;
    let tokenAddress: ContractAddress = contract_address_const::<0x746f6b656e>();

    set_contract_address(defaultSender);
    dispatcher.addToken(tokenId, tokenAddress, 19);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('I2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_add_token_registered_1() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let tokenId = 33;
    let tokenAddress: ContractAddress = deploy(
        StandardToken::TEST_CLASS_HASH, array!['Ether', 'ETH']
    );
    let eth = Token { tokenId, tokenAddress };

    set_contract_address(defaultSender);
    dispatcher.addToken(tokenId, tokenAddress, 8);
    dispatcher.addToken(tokenId, tokenAddress, 8);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('I2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_add_token_registered_2() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let tokenId = 33;
    let tokenAddress: ContractAddress = deploy(
        StandardToken::TEST_CLASS_HASH, array!['Ether', 'ETH']
    );
    let eth = Token { tokenId, tokenAddress };

    set_contract_address(defaultSender);
    dispatcher.addToken(tokenId, tokenAddress, 8);
    dispatcher.addToken(2, tokenAddress, 8);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_add_token_success() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let tokenId = 33;
    let tokenAddress: ContractAddress = deploy(
        StandardToken::TEST_CLASS_HASH, array!['Ether', 'ETH']
    );
    let eth = Token { tokenId, tokenAddress };

    set_contract_address(defaultSender);
    dispatcher.addToken(tokenId, tokenAddress, 8);

    let rt: RegisteredToken = dispatcher.getTokenById(tokenId);
    assert(rt.registered == true, 'wrong registered');
    assert(rt.paused == false, 'wrong paused');
    assert(rt.tokenAddress == tokenAddress, 'wrong tokenAddress');
    assert(rt.decimals == 8, 'wrong decimals');
    let id: u16 = dispatcher.getTokenIdByAddress(tokenAddress);
    assert(id == tokenId, 'wrong tokenId');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_pause_token_not_governor() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let alice: ContractAddress = *address[utils::ADDR_ALICE];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let tokenId = 33;
    let tokenAddress: ContractAddress = deploy(
        StandardToken::TEST_CLASS_HASH, array!['Ether', 'ETH']
    );
    let eth = Token { tokenId, tokenAddress };

    set_contract_address(defaultSender);
    dispatcher.addToken(tokenId, tokenAddress, 6);

    set_contract_address(alice);
    dispatcher.setTokenPaused(tokenId, true);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('K', 'ENTRYPOINT_FAILED'))]
fn test_zklink_pause_token_not_registered() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let alice: ContractAddress = *address[utils::ADDR_ALICE];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let tokenId = 33;
    let tokenAddress: ContractAddress = deploy(
        StandardToken::TEST_CLASS_HASH, array!['Ether', 'ETH']
    );
    let eth = Token { tokenId, tokenAddress };

    set_contract_address(defaultSender);
    dispatcher.setTokenPaused(tokenId, true);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_pause_token_success() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let alice: ContractAddress = *address[utils::ADDR_ALICE];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let tokenId = 33;
    let tokenAddress: ContractAddress = deploy(
        StandardToken::TEST_CLASS_HASH, array!['Ether', 'ETH']
    );
    let eth = Token { tokenId, tokenAddress };

    set_contract_address(defaultSender);
    dispatcher.addToken(tokenId, tokenAddress, 6);
    utils::drop_event(zklink);

    dispatcher.setTokenPaused(tokenId, true);
    utils::assert_event_TokenPausedUpdate(zklink, tokenId, true);

    let rt: RegisteredToken = dispatcher.getTokenById(tokenId);
    assert(rt.paused == true, 'wrong paused');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_set_validator_not_governor() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let alice: ContractAddress = *address[utils::ADDR_ALICE];
    let validator: ContractAddress = *address[utils::ADDR_VALIDATOR];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    set_contract_address(alice);
    dispatcher.setValidator(validator, true);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_set_validator_success() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let validator: ContractAddress = *address[utils::ADDR_VALIDATOR];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    set_contract_address(defaultSender);
    dispatcher.setValidator(validator, true);
    utils::assert_event_ValidatorStatusUpdate(zklink, validator, true);

    dispatcher.setValidator(validator, false);
    utils::assert_event_ValidatorStatusUpdate(zklink, validator, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_set_sync_service_not_governor() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let alice: ContractAddress = *address[utils::ADDR_ALICE];
    let validator: ContractAddress = *address[utils::ADDR_VALIDATOR];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    set_contract_address(alice);
    dispatcher.setSyncService(validator);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_set_sync_service_success() {
    let address = prepare_test_deploy();

    let defaultSender: ContractAddress = *address[utils::ADDR_DEFAULT];
    let validator: ContractAddress = *address[utils::ADDR_VALIDATOR];
    let zklink: ContractAddress = *address[utils::ADDR_ZKLINK];
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    set_contract_address(defaultSender);
    dispatcher.setSyncService(validator);
    utils::assert_event_SetSyncService(zklink, validator);
}
