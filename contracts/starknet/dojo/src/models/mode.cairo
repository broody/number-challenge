use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum ChallengeMode {
    KING_OF_THE_HILL: KingOfTheHill,
    CONDITIONAL_VICTORY: ConditionalVictory,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub struct KingOfTheHill {
    pub extension_time: u64,
    pub king: ContractAddress,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub struct ConditionalVictory {
    pub slots_required: u8
}

#[generate_trait]
pub impl ChallengeModeImpl of ChallengeModeTrait {
    fn new(mode: ChallengeMode, expiration: u64) -> ChallengeMode {
        match mode {
            ChallengeMode::KING_OF_THE_HILL(params) => {
                assert!(expiration != 0, "King of the Hill must have expiration");

                ChallengeMode::KING_OF_THE_HILL(
                    KingOfTheHill {
                        extension_time: params.extension_time,
                        king: starknet::contract_address_const::<0x0>(),
                    }
                )
            },
            ChallengeMode::CONDITIONAL_VICTORY(_) => {
                mode
            }
        }
    }
}
