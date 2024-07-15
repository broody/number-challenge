
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
        models::{game::{Game, GameTrait, game}, slot::{slot, Slot}, config::{config, Config, GameConfig, SlotReward, SlotRewardTrait, RewardLevel} }
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

    fn STATE() -> (IWorldDispatcher, IActionsDispatcher, IERC20BalanceMockDispatcher) {
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
                    'erc20', erc20_balance_mock::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
                )
        };

        let mut actions_dispatcher = IActionsDispatcher {
            contract_address: world
                .deploy_contract(
                    'actions', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span()
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
    
        (world, actions_dispatcher, erc20_balance_mock_dispatcher)
    }

    fn CONFIG(reward_token: ContractAddress) -> Config {
        Config {
            world: 0,
            game: Option::Some(GameConfig {
                max_slots: 20,
                max_number: 1000,
                min_number: 0,
            }),
            reward: Option::None,
        }
    }

    #[test]
    fn test_create_jackpot() {
        let (_world, mut action_dispatcher, mut erc20_balance_dispatcher) = STATE();

        let config = CONFIG(erc20_balance_dispatcher.contract_address);
        action_dispatcher.set_config(config);

    }
}

