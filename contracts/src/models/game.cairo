use starknet::ContractAddress;
use core::ArrayTrait;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Game {
    #[key]
    game_id: u32,
    #[key]
    player: ContractAddress,
    max_slots: u8,
    max_number: u16,
    min_number: u16,
    remaining_slots: u8,
    next_number: u16,
}

#[generate_trait]
impl GameImpl of GameTrait {
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