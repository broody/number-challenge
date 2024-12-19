use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct Config {
    #[key]
    pub world_resource: felt252,
    pub game: Option<GameConfig>,
    pub reward: Option<SlotReward>,
}

#[derive(Drop, Serde, Introspect)]
pub struct GameConfig {
    pub max_slots: u8,
    pub max_number: u16,
    pub min_number: u16,
}

#[derive(Drop, Serde, Introspect)]
pub struct SlotReward {
    pub token: ContractAddress,
    pub levels: Array<RewardLevel>,
}

#[derive(Copy, Drop, Serde, Introspect)]
pub struct RewardLevel {
    pub level: u8,
    pub amount: u16,
}

#[generate_trait]
pub impl SlotRewardImpl of SlotRewardTrait {
    /// Calculates the reward amount and token for a given level based on the configured reward
    /// structure.
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
    fn compute(self: @SlotReward, level: u8) -> (ContractAddress, u16) {
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
