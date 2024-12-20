use starknet::ContractAddress;
use nums_common::challenge_mode::ChallengeMode;

// Subset of Challenge model for Appchain from Starknet's Challenge model
#[derive(Copy, Drop, Serde, PartialEq)]
#[dojo::model]
pub struct Challenge {
    #[key]
    pub id: u32,
    pub mode: ChallengeMode,
    pub expiration: u64,
    pub winner: Option<ContractAddress>,
}