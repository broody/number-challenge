use nums_common::challenge_mode::ChallengeMode;

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub struct ChallengeMessage {
    pub id: u32,
    pub expiration: u64,
    pub mode: ChallengeMode,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub struct ConfigMessage {}
