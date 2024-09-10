#[cfg(test)]
mod tests {
    use dojo::model::{Model, ModelTest, ModelIndex, ModelEntityTest};
    use dojo::utils::test::spawn_test_world;
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    use nums::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::{
            name::{Name, name}, game::{Game, GameTrait, game}, slot::{slot, Slot},
            config::{config, Config, GameConfig, SlotReward, SlotRewardTrait, RewardLevel}
        }
    };

    use starknet::ContractAddress;
    use starknet::testing::set_transaction_hash;

    fn STATE() -> (IWorldDispatcher, IActionsDispatcher) {
        let world = spawn_test_world(
            ["nums"].span(),
            array![
                game::TEST_CLASS_HASH,
                config::TEST_CLASS_HASH,
                name::TEST_CLASS_HASH,
                slot::TEST_CLASS_HASH
            ]
                .span()
        );

        let mut actions_dispatcher = IActionsDispatcher {
            contract_address: world
                .deploy_contract('actions', actions::TEST_CLASS_HASH.try_into().unwrap())
        };

        // setup auth
        world.grant_writer(Model::<Game>::selector(), actions_dispatcher.contract_address);
        world.grant_writer(Model::<Config>::selector(), actions_dispatcher.contract_address);
        world.grant_writer(Model::<Slot>::selector(), actions_dispatcher.contract_address);
        world.grant_writer(Model::<Name>::selector(), actions_dispatcher.contract_address);

        (world, actions_dispatcher)
    }

    fn CONFIG(reward_token: ContractAddress) -> Config {
        Config {
            world_resource: 0,
            game: Option::Some(GameConfig { max_slots: 20, max_number: 1000, min_number: 0, }),
            reward: Option::None,
        }
    }

    #[test]
    fn test_create_jackpot() {
        let (_world, mut action_dispatcher) = STATE();

    }
}

