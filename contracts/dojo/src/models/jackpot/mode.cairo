use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum JackpotMode {
    KING_OF_THE_HILL: KingOfTheHill,
    CONDITIONAL_VICTORY: ConditionalVictory,
}

#[derive(Copy, Drop, Serde,PartialEq,  Introspect)]
pub struct KingOfTheHill {
    pub extension_time: u64,
    pub king: ContractAddress,
    pub remaining_slots: u8,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub struct ConditionalVictory {
    pub slots_required: u8
}

#[generate_trait]
pub impl JackpotModeImpl of JackpotModeTrait {
    fn new(mode: JackpotMode, max_slots: u8, expiration: u64) -> JackpotMode {
        match mode {
            JackpotMode::KING_OF_THE_HILL(params) => {
                assert!(expiration != 0, "King of the Hill must have expiration");

                JackpotMode::KING_OF_THE_HILL(
                    KingOfTheHill {
                        extension_time: params.extension_time,
                        king: starknet::contract_address_const::<0x0>(),
                        remaining_slots: max_slots,
                    }
                )
            },
            JackpotMode::CONDITIONAL_VICTORY(params) => {
                assert!(
                    params.slots_required <= max_slots,
                    "slots_required exceeds max_slots"
                );

                mode
            }
        }
    }
}
