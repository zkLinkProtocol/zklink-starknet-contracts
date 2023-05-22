// zkLink operations tool
// Circuit ops and their pubdata (chunks * bytes)

mod Operations {
    use core::traits::Into;
    use core::traits::TryInto;
    use zklink::utils::bytes::{
        Bytes,
        BytesTrait
    };
    // zkLink circuit operation type
    #[derive(Copy, Drop)]
    enum OpType {
        Noop: (),           // 0
        Deposit: (),        // 1 L1 op
        TransferToNew: (),  // 2 L2 op
        Withdraw: (),       // 3 L2 op
        Transfer: (),       // 4 L2 op
        FullExit: (),       // 5 L1 op
        ChangePubKey: (),   // 6 L2 op
        ForcedExit: (),     // 7 L2 op
        OrderMatching: ()   // 8 L2 op
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

    // Priority operations: Deposit, FullExit
    #[derive(Copy, Drop)]
    struct PriorityOperation {
        hashedPubData: felt252,
        expirationBlock: u64,
        opType: OpType
    }

    trait OperationTrait<T> {
        // Deserialize operation from pubdata
        fn readFromPubdata(pubData: @Bytes) -> (usize, T);
        // Serialize operation to Bytes
        fn writeForPriorityQueue(self: @T) -> Bytes;
    }

    // Deposit operation in pubdata: 59 bytes(with opType)
    const PACKED_DEPOSIT_PUBDATA_BYTES: usize = 59;
    // Deposit operation: 58 bytes(without opType)
    #[derive(Copy, Drop)]
    struct Deposit {
        chainId: u8,        // 1 byte, deposit from which chain that identified by l2 chain id
        accountId: u32,     // 4 bytes, the account id bound to the owner address, ignored at serialization and will be set when the block is submitted
        subAccountId: u8,   // 1 byte, the sub account is bound to account, default value is 0(the global public sub account)
        tokenId: u16,       // 2 bytes, the token that registered to l2
        targetTokenId: u16, // 2 bytes, the token that user increased in l2
        amount: u128,       // 16 bytes, the token amount deposited to l2
        owner: u256,        // 32 bytes, the address that receive deposited token at l2
    }

    impl DepositOperation of OperationTrait<Deposit> {
        fn readFromPubdata(pubData: @Bytes) -> (usize, Deposit) {
            let (offset, chainId) = pubData.read_u8(OP_TYPE_BYTES);
            let (offset, accountId) = pubData.read_u32(offset);
            let (offset, subAccountId) = pubData.read_u8(offset);
            let (offset, tokenId) = pubData.read_u16(offset);
            let (offset, targetTokenId) = pubData.read_u16(offset);
            let (offset, amount) = pubData.read_u128(offset);
            let (offset, owner) = pubData.read_u256(offset);

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
            let mut pubData = BytesTrait::new_empty();

            pubData
        }
    }


}