
#[cfg(test)]
mod tests {
    use starknet::ContractAddress;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_transaction_hash;
    use core::Option;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::test_utils::spawn_test_world;

    use nums::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::{game::{Game, GameTrait, game}, slot::{slot, Slot}, config::{config, Config, GameConfig, CreateCost, SlotReward, SlotRewardTrait, RewardLevel} }
    };

    use token::components::token::erc20::erc20_allowance::{
        erc_20_allowance_model, ERC20AllowanceModel,
    };

    use token::components::token::erc20::erc20_balance::{erc_20_balance_model, ERC20BalanceModel,};
    use token::components::token::erc20::erc20_balance::erc20_balance_component::{
        ERC20BalanceImpl, InternalImpl as ERC20BalanceInternalImpl
    };

    use token::components::tests::mocks::erc20::erc20_balance_mock::{
        erc20_balance_mock, IERC20BalanceMockDispatcher, IERC20BalanceMockDispatcherTrait
    };
    use token::tests::constants::{ADMIN, ZERO, OWNER, OTHER, SPENDER, RECIPIENT, VALUE, SUPPLY};
    use token::tests::utils;

    fn STATE() -> (IWorldDispatcher, IERC20BalanceMockDispatcher) {
        let world = spawn_test_world(
            array![
                erc_20_allowance_model::TEST_CLASS_HASH, 
                erc_20_balance_model::TEST_CLASS_HASH,
                game::TEST_CLASS_HASH,
                config::TEST_CLASS_HASH,
                slot::TEST_CLASS_HASH
            ]
        );

        // deploy contract
        let mut erc20_balance_mock_dispatcher = IERC20BalanceMockDispatcher {
            contract_address: world
                .deploy_contract(
                    'salt', erc20_balance_mock::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
                )
        };

        // setup auth
        world
            .grant_writer(
                selector!("ERC20AllowanceModel"), erc20_balance_mock_dispatcher.contract_address
            );
        world
            .grant_writer(
                selector!("ERC20BalanceModel"), erc20_balance_mock_dispatcher.contract_address
        );

        // initialize contracts
        erc20_balance_mock_dispatcher.initializer(SUPPLY, OWNER());

        // drop all events
        utils::drop_all_events(erc20_balance_mock_dispatcher.contract_address);
        utils::drop_all_events(world.contract_address);
    
        (world, erc20_balance_mock_dispatcher)
    }

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
            world: 0,
            game: Option::Some(GameConfig {
                max_slots: 20,
                max_number: 1000,
                min_number: 0,
            }),
            cost: Option::None,
            reward: Option::Some(REWARD(reward_token)),
        }
    }

    #[test]
    fn test_reward_level() {
        let reward = REWARD(starknet::contract_address_const::<0x1337>());
        let (_, amount) = reward.compute(3); assert_eq!(amount, 1);
        let (_, amount) = reward.compute(13); assert_eq!(amount, 2);
        let (_, amount) = reward.compute(15); assert_eq!(amount, 8);
        let (_, amount) = reward.compute(18); assert_eq!(amount, 64);
        let (_, amount) = reward.compute(20); assert_eq!(amount, 256);
    }

    // #[test]
    // fn test_nums_token() {
    //     let (_world, mut erc20_balance_mock) = STATE();

    // }
}

