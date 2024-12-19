#[cfg(test)]
mod tests {
    use nums::{models::{config::{Config, GameConfig, SlotReward, SlotRewardTrait, RewardLevel}}};

    use starknet::ContractAddress;
    fn REWARD(token: ContractAddress) -> SlotReward {
        SlotReward {
            token,
            levels: array![
                RewardLevel { level: 10, amount: 1 },
                RewardLevel { level: 13, amount: 2 },
                RewardLevel { level: 14, amount: 4 },
                RewardLevel { level: 15, amount: 8 },
                RewardLevel { level: 16, amount: 16 },
                RewardLevel { level: 17, amount: 32 },
                RewardLevel { level: 18, amount: 64 },
                RewardLevel { level: 19, amount: 128 },
                RewardLevel { level: 20, amount: 256 },
            ],
        }
    }

    fn CONFIG(reward_token: ContractAddress) -> Config {
        Config {
            world_resource: 0,
            game: Option::Some(GameConfig { max_slots: 20, max_number: 1000, min_number: 0, }),
            reward: Option::Some(REWARD(reward_token)),
        }
    }

    #[test]
    fn test_reward_level() {
        let reward = REWARD(starknet::contract_address_const::<0x1337>());
        let (_, amount) = reward.compute(3);
        assert_eq!(amount, 1);
        let (_, amount) = reward.compute(13);
        assert_eq!(amount, 2);
        let (_, amount) = reward.compute(15);
        assert_eq!(amount, 8);
        let (_, amount) = reward.compute(18);
        assert_eq!(amount, 64);
        let (_, amount) = reward.compute(20);
        assert_eq!(amount, 256);
    }
}

