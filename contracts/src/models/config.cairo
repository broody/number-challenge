use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
struct Config {
    #[key]
    world: felt252, // This is always 0 correpsonding to the world resource.
    game: Option<GameConfig>,
    cost: Option<CreateCost>,
    reward: Option<SlotReward>,
}

#[derive(Drop, Serde, Introspect)]
struct GameConfig {
    max_slots: u8,
    max_number: u16,
    min_number: u16,
}

#[derive(Drop, Serde, Introspect)]
struct CreateCost {
    token: ContractAddress,
    amount: u256,
}

#[derive(Drop, Serde, Introspect)]
struct SlotReward {
    token: ContractAddress,
    levels: Array<RewardLevel>,
}

#[derive(Copy, Drop, Serde, Introspect)]
struct RewardLevel {
    level: u8,
    amount: u256,
}

#[generate_trait]
impl SlotRewardImpl of SlotRewardTrait {
    /// Calculates the reward amount and token for a given level based on the configured reward structure.
    ///
    /// # Arguments
    ///
    /// * `self` - The Config struct containing the reward configuration.
    /// * `level` - The current level for which to determine the reward.
    ///
    /// # Returns
    ///
    /// * `(Option<ContractAddress>, u256)` - A tuple containing:
    ///   - An Option with the reward token's ContractAddress, or None if no reward is configured.
    ///   - The reward amount for the given level.
    ///
    /// # Description
    ///
    /// This function uses a compressed reward level representation where each RewardLevel
    /// in the vector represents the reward for all levels up to and including the specified level.
    /// It iterates through the reward levels to find the appropriate reward for the given level.
    /// If no reward is configured, it returns (None, 0).
    fn compute(self: @SlotReward, level: u8) -> (ContractAddress, u256) {
        let levels_len = self.levels.len();
        let mut i = 0;
        let mut amount = 0;

        loop {
            if i >= levels_len {
                break;
            }
            
            let current_level = *self.levels.at(i);
            if level <= current_level.level {
                amount = current_level.amount;
                break;
            }
            
            i += 1;
        };

        (*self.token, amount)
    }
}