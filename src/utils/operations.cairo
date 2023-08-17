// zkLink operations tool
// Circuit ops and their pubdata (chunks * bytes)

mod Operations {
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;
    use starknet::{
        Store, StorageBaseAddress, SyscallResult, storage_read_syscall, storage_write_syscall,
        storage_address_from_base_and_offset, ContractAddress
    };
    use zklink::utils::bytes::{Bytes, BytesTrait, ReadBytes, };
    use zklink::utils::math::{u256_to_u160, };

    // zkLink circuit operation type
    #[derive(Copy, Drop, PartialEq, Serde, starknet::Store)]
    enum OpType {
        Noop: (), // 0
        Deposit: (), // 1 L1 op
        TransferToNew: (), // 2 L2 op
        Withdraw: (), // 3 L2 op
        Transfer: (), // 4 L2 op
        FullExit: (), // 5 L1 op
        ChangePubKey: (), // 6 L2 op
        ForcedExit: (), // 7 L2 op
        OrderMatching: () // 8 L2 op
    }

    impl OpTypeReadBytes of ReadBytes<OpType> {
        fn read(bytes: @Bytes, offset: usize) -> (usize, OpType) {
            let (new_offset, opType) = bytes.read_u8(offset);
            let opType = opType.try_into().unwrap();
            (new_offset, opType)
        }
    }

    impl OpTypeIntoU8 of Into<OpType, u8> {
        fn into(self: OpType) -> u8 {
            match self {
                OpType::Noop(_) => 0,
                OpType::Deposit(_) => 1,
                OpType::TransferToNew(_) => 2,
                OpType::Withdraw(_) => 3,
                OpType::Transfer(_) => 4,
                OpType::FullExit(_) => 5,
                OpType::ChangePubKey(_) => 6,
                OpType::ForcedExit(_) => 7,
                OpType::OrderMatching(_) => 8
            }
        }
    }

    impl U8TryIntoOpType of TryInto<u8, OpType> {
        fn try_into(self: u8) -> Option<OpType> {
            if self == 0 {
                Option::Some(OpType::Noop(()))
            } else if self == 1 {
                Option::Some(OpType::Deposit(()))
            } else if self == 2 {
                Option::Some(OpType::TransferToNew(()))
            } else if self == 3 {
                Option::Some(OpType::Withdraw(()))
            } else if self == 4 {
                Option::Some(OpType::Transfer(()))
            } else if self == 5 {
                Option::Some(OpType::FullExit(()))
            } else if self == 6 {
                Option::Some(OpType::ChangePubKey(()))
            } else if self == 7 {
                Option::Some(OpType::ForcedExit(()))
            } else if self == 8 {
                Option::Some(OpType::OrderMatching(()))
            } else {
                Option::None(())
            }
        }
    }

    // Operation element lengths in byte(s)
    // op: u8, 1 byte
    const OP_TYPE_BYTES: usize = 1;
    // chainId: u8, 1 byte
    const CHAIN_BYTES: usize = 1;
    // token: u16, 2 bytes
    const TOKEN_BYTES: usize = 2;
    // nonce: u32, 4 bytes
    const NONCE_BYTES: usize = 4;
    // address: u256, 32 bytes
    const ADDRESS_BYTES: usize = 32;
    // fee: u16, 2 bytes
    const FEE_BYTES: usize = 2;
    // accountId: u32, 4 bytes
    const ACCOUNT_ID_BYTES: usize = 4;
    // subAccountId: u8, 1 byte
    const SUB_ACCOUNT_ID_BYTES: usize = 1;
    // amount: u128, 16 bytes
    const AMOUNT_BYTES: usize = 16;
    // pubKeyHash: felt252, 20 bytes
    const PUBKEY_HASH_BYTES: usize = 20;

    // Priority operations: Deposit, FullExit
    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct PriorityOperation {
        hashedPubData: felt252,
        expirationBlock: u64,
        opType: OpType
    }

    impl PriorityOperationDefault of Default<PriorityOperation> {
        #[always_inline]
        fn default() -> PriorityOperation {
            PriorityOperation { hashedPubData: 0, expirationBlock: 0, opType: OpType::Noop(()) }
        }
    }

    trait OperationTrait<T> {
        // Deserialize operation from pubdata
        fn readFromPubdata(pubData: @Bytes) -> (usize, T);
        // Serialize operation to Bytes
        fn writeForPriorityQueue(self: @T) -> Bytes;
        // Checks the peration is same as operation in priority queue
        fn checkPriorityOperation(self: @T, priorityOperation: @PriorityOperation);
    }

    // Deposit operation: 58 bytes(59 with opType)
    #[derive(Copy, Drop, Serde)]
    struct Deposit {
        chainId: u8, // 1 byte, deposit from which chain that identified by L2 chain id
        accountId: u32, // 4 bytes, the account id bound to the owner address, ignored at serialization and will be set when the block is submitted
        subAccountId: u8, // 1 byte, the sub account is bound to account, default value is 0(the global public sub account)
        tokenId: u16, // 2 bytes, the token that registered to L2
        targetTokenId: u16, // 2 bytes, the token that user increased in L2
        amount: u128, // 16 bytes, the token amount deposited to L2
        owner: felt252, // 32 bytes, the address that receive deposited token at L2
    }

    impl DepositOperation of OperationTrait<Deposit> {
        fn readFromPubdata(pubData: @Bytes) -> (usize, Deposit) {
            // uint8 opType, present in pubdata, ignored at serialization
            let mut offset = OP_TYPE_BYTES;
            let (offset, chainId) = pubData.read_u8(offset);
            let (offset, accountId) = pubData.read_u32(offset);
            let (offset, subAccountId) = pubData.read_u8(offset);
            let (offset, tokenId) = pubData.read_u16(offset);
            let (offset, targetTokenId) = pubData.read_u16(offset);
            let (offset, amount) = pubData.read_u128(offset);
            let (offset, owner) = pubData.read_felt252(offset);

            let deposit = Deposit {
                chainId: chainId,
                accountId: accountId,
                subAccountId: subAccountId,
                tokenId: tokenId,
                targetTokenId: targetTokenId,
                amount: amount,
                owner: owner
            };
            (offset, deposit)
        }

        fn writeForPriorityQueue(self: @Deposit) -> Bytes {
            let opType = OpType::Deposit(());
            let mut pubData = BytesTrait::new_empty();
            pubData.append_u8(opType.into());
            pubData.append_u8(*self.chainId);
            pubData.append_u32(0); // accountId (ignored during hash calculation)
            pubData.append_u8(*self.subAccountId);
            pubData.append_u16(*self.tokenId);
            pubData.append_u16(*self.targetTokenId);
            pubData.append_u128(*self.amount);
            pubData.append_felt252(*self.owner);

            pubData
        }

        // Checks the peration is same as operation in priority queue
        fn checkPriorityOperation(self: @Deposit, priorityOperation: @PriorityOperation) {
            assert(*priorityOperation.opType == OpType::Deposit(()), 'OP: not deposit');
            assert(
                u256_to_u160(self.writeForPriorityQueue().keccak()) == *priorityOperation
                    .hashedPubData,
                'OP: invalid deposit hash'
            );
        }
    }

    // FullExit operation: 58 bytes(59 with opType)
    #[derive(Copy, Drop, Serde)]
    struct FullExit {
        chainId: u8, // 1 byte, withdraw to which chain that identified by L2 chain id
        accountId: u32, // 4 bytes, the account id to withdraw from
        subAccountId: u8, // 1 byte, the sub account is bound to account, default value is 0(the global public sub account)
        owner: ContractAddress, // 32 bytes, the address that own the account at L2
        tokenId: u16, // 2 bytes, the token that withdraw to l1
        srcTokenId: u16, // 2 bytes, the token that deducted in L2
        amount: u128, // 16 bytes, the token amount that fully withdrawn to owner, ignored at serialization and will be set when the block is submitted
    }

    impl FullExitOperation of OperationTrait<FullExit> {
        fn readFromPubdata(pubData: @Bytes) -> (usize, FullExit) {
            // uint8 opType, present in pubdata, ignored at serialization
            let mut offset = OP_TYPE_BYTES;
            let (offset, chainId) = pubData.read_u8(offset);
            let (offset, accountId) = pubData.read_u32(offset);
            let (offset, subAccountId) = pubData.read_u8(offset);
            let (offset, owner) = pubData.read_address(offset);
            let (offset, tokenId) = pubData.read_u16(offset);
            let (offset, srcTokenId) = pubData.read_u16(offset);
            let (offset, amount) = pubData.read_u128(offset);

            let fullExit = FullExit {
                chainId: chainId,
                accountId: accountId,
                subAccountId: subAccountId,
                owner: owner,
                tokenId: tokenId,
                srcTokenId: srcTokenId,
                amount: amount
            };
            (offset, fullExit)
        }

        fn writeForPriorityQueue(self: @FullExit) -> Bytes {
            let opType = OpType::FullExit(());
            let mut pubData = BytesTrait::new_empty();
            pubData.append_u8(opType.into());
            pubData.append_u8(*self.chainId);
            pubData.append_u32(*self.accountId);
            pubData.append_u8(*self.subAccountId);
            pubData.append_address(*self.owner);
            pubData.append_u16(*self.tokenId);
            pubData.append_u16(*self.srcTokenId);
            pubData.append_u128(0); // amount (ignored during hash calculation)

            pubData
        }

        // Checks the peration is same as operation in priority queue
        fn checkPriorityOperation(self: @FullExit, priorityOperation: @PriorityOperation) {
            assert(*priorityOperation.opType == OpType::FullExit(()), 'OP: not fullExit');
            assert(
                u256_to_u160(self.writeForPriorityQueue().keccak()) == *priorityOperation
                    .hashedPubData,
                'OP: invalid fullExit hash'
            );
        }
    }

    // Withdraw operation: 63 bytes(68 with opType)
    #[derive(Copy, Drop, Serde)]
    struct Withdraw {
        chainId: u8, // 1 byte, which chain the withdraw happened
        accountId: u32, // 4 bytes, the account id to withdraw from
        subAccountId: u8, // 1 byte, the sub account to withdraw from
        tokenId: u16, // 2 bytes, the token that to withdraw
        amount: u128, // 16 bytes, the token amount to withdraw
        owner: ContractAddress, // 32 bytes, the address to receive token
        nonce: u32, // 4 bytes, the sub account nonce
        fastWithdrawFeeRate: u16, // 2 bytes, fast withdraw fee rate taken by acceptor
        fastWithdraw: u8, // 1 byte, 0 means normal withdraw, 1 means fast withdraw
    }

    impl WithdrawOperation of OperationTrait<Withdraw> {
        // Withdraw operation pubdata looks like this:
        //  opType, u8, ignored at serialization
        //  chainId,
        //  accountId,
        //  subAccountId,
        //  tokenId,
        //  srcTokenId, u16, ignored at serialization
        //  amount,
        //  fee, u16, ignored at serialization
        //  owner,
        //  nonce,
        //  fastWithdrawFeeRate
        fn readFromPubdata(pubData: @Bytes) -> (usize, Withdraw) {
            // uint8 opType, present in pubdata, ignored at serialization
            let offset = OP_TYPE_BYTES;
            let (offset, chainId) = pubData.read_u8(offset);
            let (offset, accountId) = pubData.read_u32(offset);
            let (offset, subAccountId) = pubData.read_u8(offset);
            let (offset, tokenId) = pubData.read_u16(offset);
            // uint16 srcTokenId, the token that decreased in L2, present in pubdata, ignored at serialization
            let offset = offset + TOKEN_BYTES;
            let (offset, amount) = pubData.read_u128(offset);
            // uint16 fee, present in pubdata, ignored at serialization
            let offset = offset + FEE_BYTES;
            let (offset, owner) = pubData.read_address(offset);
            let (offset, nonce) = pubData.read_u32(offset);
            let (offset, fastWithdrawFeeRate) = pubData.read_u16(offset);
            let (offset, fastWithdraw) = pubData.read_u8(offset);

            let withdraw = Withdraw {
                chainId: chainId,
                accountId: accountId,
                subAccountId: subAccountId,
                tokenId: tokenId,
                amount: amount,
                owner: owner,
                nonce: nonce,
                fastWithdrawFeeRate: fastWithdrawFeeRate,
                fastWithdraw: fastWithdraw
            };
            (offset, withdraw)
        }

        // Do nothing
        fn writeForPriorityQueue(self: @Withdraw) -> Bytes {
            BytesTrait::new_empty()
        }
        // Do nothing
        fn checkPriorityOperation(self: @Withdraw, priorityOperation: @PriorityOperation) {}
    }

    // ForcedExit operation: 64 Bytes(68 with opType)
    #[derive(Copy, Drop, Serde)]
    struct ForcedExit {
        chainId: u8, // 1 byte, which chain the force exit happened
        initiatorAccountId: u32, // 4 bytes, the account id of initiator
        initiatorSubAccountId: u8, // 1 byte, the sub account id of initiator
        initiatorNonce: u32, // 4 bytes, the sub account nonce of initiator
        targetAccountId: u32, // 4 bytes, the account id of target
        tokenId: u16, // 2 bytes, the token that to withdraw
        amount: u128, // 16 bytes, the token amount to withdraw
        target: ContractAddress // 32 bytes, the address to receive token
    }

    impl ForcedExitOperatoin of OperationTrait<ForcedExit> {
        // ForcedExit operation pubdata looks like this:
        //  opType, u8, ignored at serialization
        //  chainId,
        //  initiatorAccountId,
        //  initiatorSubAccountId,
        //  initiatorNonce,
        //  targetAccountId,
        //  targetSubAccountId, u8, ignored at serialization
        //  tokenId,
        //  srcTokenId, u16, ignored at serialization
        //  amount,
        //  target
        fn readFromPubdata(pubData: @Bytes) -> (usize, ForcedExit) {
            let offset = OP_TYPE_BYTES;
            let (offset, chainId) = pubData.read_u8(offset);
            let (offset, initiatorAccountId) = pubData.read_u32(offset);
            let (offset, initiatorSubAccountId) = pubData.read_u8(offset);
            let (offset, initiatorNonce) = pubData.read_u32(offset);
            let (offset, targetAccountId) = pubData.read_u32(offset);
            // targetSubAccountId, u8, ignored at serialization
            let offset = offset + SUB_ACCOUNT_ID_BYTES;
            let (offset, tokenId) = pubData.read_u16(offset);
            // srcTokenId, u16, ignored at serialization
            let offset = offset + TOKEN_BYTES;
            let (offset, amount) = pubData.read_u128(offset);
            let (offset, target) = pubData.read_address(offset);

            let forcedExit = ForcedExit {
                chainId: chainId,
                initiatorAccountId: initiatorAccountId,
                initiatorSubAccountId: initiatorSubAccountId,
                initiatorNonce: initiatorNonce,
                targetAccountId: targetAccountId,
                tokenId: tokenId,
                amount: amount,
                target: target
            };
            (offset, forcedExit)
        }

        // Do nothing
        fn writeForPriorityQueue(self: @ForcedExit) -> Bytes {
            BytesTrait::new_empty()
        }

        // Do nothing
        fn checkPriorityOperation(self: @ForcedExit, priorityOperation: @PriorityOperation) {}
    }

    // ChangePubKey operation: 61 bytes(67 with opType)
    #[derive(Copy, Drop, Serde)]
    struct ChangePubKey {
        chainId: u8, // 1 byte, which chain to verify(only one chain need to verify for gas saving)
        accountId: u32, // 4 bytes, the account that to change pubkey
        pubKeyHash: felt252, // 20 bytes, hash of the new rollup pubkey
        owner: ContractAddress, // 32 bytes, the owner that own this account
        nonce: u32, // 4 bytes, the account nonce
    }

    impl ChangePubKeyOperation of OperationTrait<ChangePubKey> {
        // ChangePubKey operation pubdata looks like this:
        //  opType, u8, ignored at serialization
        //  chainId,
        //  accountId,
        //  subAccountId, u8, ignored at serialization
        //  pubKeyHash,
        //  owner,
        //  nonce,
        //  tokenId, u16, ignored at serialization
        //  fee, u16, ignored at serialization
        fn readFromPubdata(pubData: @Bytes) -> (usize, ChangePubKey) {
            let offset = OP_TYPE_BYTES;
            let (offset, chainId) = pubData.read_u8(offset);
            let (offset, accountId) = pubData.read_u32(offset);
            // subAccountId, u8, ignored at serialization
            let offset = offset + SUB_ACCOUNT_ID_BYTES;
            let (offset, pubKeyHash) = pubData.read_felt252_packed(offset, PUBKEY_HASH_BYTES);
            let (offset, owner) = pubData.read_address(offset);
            let (offset, nonce) = pubData.read_u32(offset);

            let changePubKey = ChangePubKey {
                chainId: chainId,
                accountId: accountId,
                pubKeyHash: pubKeyHash,
                owner: owner,
                nonce: nonce
            };
            (offset, changePubKey)
        }

        // Do nothing
        fn writeForPriorityQueue(self: @ChangePubKey) -> Bytes {
            BytesTrait::new_empty()
        }

        // Do nothing
        fn checkPriorityOperation(self: @ChangePubKey, priorityOperation: @PriorityOperation) {}
    }
}
