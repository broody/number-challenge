use starknet::{ContractAddress, get_caller_address};
use nums::models::jackpot::mode::JackpotMode;
use nums::models::jackpot::token::Token;

#[derive(Copy, Drop, Serde, PartialEq)]
#[dojo::model]
pub struct Jackpot {
    #[key]
    pub jackpot_id: u32,
    pub title: felt252,
    pub creator: ContractAddress,
    pub mode: JackpotMode,
    pub expiration: u64,
    pub powerups: bool,
    pub token: Token,
    pub winner: Option<ContractAddress>,
    pub claimed: bool, // gql lacks ability to filter on winner Option, use bool for filtering on active jackpots
    pub verified: bool,
}


#[generate_trait]
pub impl JackpotImpl of JackpotTrait {
    /// Determines if the jackpot can be claimed based on the current game state.
    /// 
    /// # Arguments
    /// * `self` - A reference to the Jackpot struct.
    /// * `nums` - An array of numbers representing the current game state.
    /// 
    /// # Returns
    /// * `bool` - True if the jackpot can be claimed, false otherwise.
    fn can_claim(self: @Jackpot, nums: @Array<u16>) -> bool {
        match self.mode {
            JackpotMode::CONDITIONAL_VICTORY(condition) => {
                if nums.len() >= (*condition.slots_required).into() {
                    return true;
                }
                
                return false;
            },
            JackpotMode::KING_OF_THE_HILL(condition) => {
                if *condition.king == get_caller_address() {
                    return true;
                }
                
                return false;
            },
        }
    }
}