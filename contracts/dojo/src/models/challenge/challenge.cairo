use starknet::{ContractAddress, get_caller_address};
use nums::models::challenge::mode::ChallengeMode;
use nums::models::challenge::token::Token;

#[derive(Copy, Drop, Serde, PartialEq)]
#[dojo::model]
pub struct Challenge {
    #[key]
    pub challenge_id: u32,
    pub title: felt252,
    pub creator: ContractAddress,
    pub mode: ChallengeMode,
    pub expiration: u64,
    pub powerups: bool,
    pub token: Option<Token>,
    pub winner: Option<ContractAddress>,
    pub claimed: bool, // gql lacks ability to filter on winner Option, use bool for filtering on active challenges
    pub verified: bool,
}


#[generate_trait]
pub impl ChallengeImpl of ChallengeTrait {
    /// Determines if the challenge can be claimed based on the current game state.
    ///
    /// # Arguments
    /// * `self` - A reference to the Challenge struct.
    /// * `nums` - An array of numbers representing the current game state.
    ///
    /// # Returns
    /// * `bool` - True if the challenge can be claimed, false otherwise.
    fn can_claim(self: @Challenge, nums: @Array<u16>) -> bool {
        match self.mode {
            ChallengeMode::CONDITIONAL_VICTORY(condition) => {
                if nums.len() >= (*condition.slots_required).into() {
                    return true;
                }

                return false;
            },
            ChallengeMode::KING_OF_THE_HILL(condition) => {
                if *condition.king == get_caller_address() {
                    return true;
                }

                return false;
            },
        }
    }
}
