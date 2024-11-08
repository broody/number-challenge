#[cfg(test)]
mod tests {
    use dojo::model::ModelStorage;
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait};

    use nums::{
        systems::{
            game_actions::{game_actions, IGameActionsDispatcher, IGameActionsDispatcherTrait}
        },
        models::{
            game::{Game, GameTrait, m_Game}, slot::m_Slot, name::{Name, m_Name},
            config::{Config, GameConfig, m_Config}
        }
    };

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "nums", resources: [
                TestResource::Model(m_Game::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Slot::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Name::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Config::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Event(
                    game_actions::e_GameCreated::TEST_CLASS_HASH.try_into().unwrap()
                ),
                TestResource::Event(game_actions::e_Inserted::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(
                    ContractDefTrait::new(game_actions::TEST_CLASS_HASH, "game_actions")
                        .with_writer_of([dojo::utils::bytearray_hash(@"nums")].span())
                )
            ].span()
        };

        ndef
    }

    fn CONFIG() -> Config {
        Config {
            world_resource: 0,
            game: Option::Some(GameConfig { max_slots: 20, max_number: 1000, min_number: 0, }),
            reward: Option::None,
        }
    }


    #[test]
    fn test_config() {
        let ndef = namespace_def();
        let world = spawn_test_world([ndef].span());
        let (contract_address, _) = world.dns(@"game_actions").unwrap();
        let game_actions = IGameActionsDispatcher { contract_address };

        game_actions.set_config(CONFIG());
    }

    #[test]
    #[should_panic]
    fn test_config_unauthorized() {
        let ndef = namespace_def();
        let world = spawn_test_world([ndef].span());
        let (contract_address, _) = world.dns(@"game_actions").unwrap();
        let game_actions = IGameActionsDispatcher { contract_address };

        let unauthorized_caller = starknet::contract_address_const::<0x1337>();
        starknet::testing::set_contract_address(unauthorized_caller);

        game_actions.set_config(CONFIG());
    }

    #[test]
    fn test_create_game() {
        let caller = starknet::contract_address_const::<0x0>();
        let ndef = namespace_def();
        let world = spawn_test_world([ndef].span());
        let (contract_address, _) = world.dns(@"game_actions").unwrap();
        let game_actions = IGameActionsDispatcher { contract_address };
        game_actions.set_config(CONFIG());

        let (game_id, first_number) = game_actions.create_game(Option::None);
        let game: Game = world.read_model((game_id, caller));

        let remaining = game.remaining_slots;
        assert(game.next_number == first_number, 'next number create is wrong');

        // set transaction hash so seed is "random"
        starknet::testing::set_transaction_hash(42);

        let next_number = game_actions.set_slot(game_id, 6);
        let game: Game = world.read_model((game_id, caller));
        assert(game.next_number == next_number, 'next number set slot is wrong');
        assert(game.remaining_slots == remaining - 1, 'remaining slots is wrong');

        if next_number > first_number {
            game_actions.set_slot(game_id, 7);
        } else {
            game_actions.set_slot(game_id, 5);
        }
    }

    #[test]
    fn test_is_valid() {
        let mut game = Game {
            game_id: 0_u32,
            player: starknet::contract_address_const::<0x0>(),
            max_slots: 20_u8,
            remaining_slots: 20_u8,
            max_number: 1000_u16,
            min_number: 0_u16,
            next_number: 42_u16,
            jackpot_id: Option::None,
        };

        let mut nums = ArrayTrait::<u16>::new();
        nums.append(100_u16);
        assert(game.is_valid(@nums), 'valid game is invalid');

        nums.append(200_u16);
        nums.append(500_u16);
        assert(game.is_valid(@nums), 'valid game is invalid');

        nums.append(5_u16);
        assert(!game.is_valid(@nums), 'invalid game is valid');
    }

    #[test]
    fn test_set_name() {
        let caller = starknet::contract_address_const::<0x0>();
        let ndef = namespace_def();
        let world = spawn_test_world([ndef].span());
        let (contract_address, _) = world.dns(@"game_actions").unwrap();
        let game_actions = IGameActionsDispatcher { contract_address };

        game_actions.set_config(CONFIG());

        let (game_id, _) = game_actions.create_game(Option::None);
        game_actions.set_name(game_id, 'test_name');

        let name: Name = world.read_model((game_id, caller));
        assert!(name.name == 'test_name', "name is wrong");
    }
}
