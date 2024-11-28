use core::array::ArrayTrait;
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub game_id: u32,
    #[key]
    pub player: ContractAddress,
    pub max_slots: u8,
    pub max_number: u16,
    pub min_number: u16,
    pub remaining_slots: u8,
    pub next_number: u16,
    pub finished: bool,
    pub jackpot_id: Option<u32>,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Reward {
    #[key]
    pub game_id: u32,
    #[key]
    pub player: ContractAddress,
    pub total: u32
}

#[generate_trait]
pub impl GameImpl of GameTrait {
    /// Checks if the elements in the given array of slots are in ascending order.
    ///
    /// # Arguments
    /// * `self` - A reference to the current game instance.
    /// * `nums` - An array of `u16` numbers representing the slots to be checked.
    ///
    /// # Returns
    /// A boolean value indicating whether the elements in the slots array are in ascending order.
    fn is_valid(self: @Game, nums: @Array<u16>) -> bool {
        let mut idx = nums.len();
        let mut valid = true;
        loop {
            idx -= 1;
            if idx == 0 {
                break;
            }

            if *nums.at(idx) < *nums.at(idx - 1) {
                valid = false;
                break;
            }
        };

        valid
    }

    fn level(self: @Game) -> u8 {
        (*self.max_slots - *self.remaining_slots)
    }
}
