#[cfg(test)]
mod tests {
    use dojo::model::ModelStorage;
    use dojo::world::{WorldStorageTrait, WorldStorage};
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait};

    use starknet::ContractAddress;

    use nums::{
        systems::{
            game_actions::{game_actions, IGameActionsDispatcher, IGameActionsDispatcherTrait},
            jackpot_actions::{jackpot_actions, IJackpotActionsDispatcher, IJackpotActionsDispatcherTrait}
        },
        models::{
            game::m_Game, slot::m_Slot,
            config::{m_Config, Config, GameConfig},
            jackpot::jackpot::{m_Jackpot, Jackpot},
            jackpot::mode::JackpotMode,
        }
    };

    const START_BLOCK_TIME: u64 = 100;
    const EXTENSION_TIME: u64 = 100;
    const EXPIRATION_TIME: u64 = 200;
    const NO_EXPIRATION_TIME: u64 = 0;
    const NO_EXTENSION_TIME: u64 = 0;

    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "nums", resources: [
                TestResource::Model(m_Game::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Slot::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Config::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Model(m_Jackpot::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Event(game_actions::e_GameCreated::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Event(game_actions::e_Inserted::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Event(jackpot_actions::e_JackpotCreated::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Event(jackpot_actions::e_JackpotClaimed::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Event(jackpot_actions::e_KingCrowned::TEST_CLASS_HASH.try_into().unwrap()),
                TestResource::Contract(
                    ContractDefTrait::new(game_actions::TEST_CLASS_HASH, "game_actions")
                        .with_writer_of([dojo::utils::bytearray_hash(@"nums")].span())
                ),
                TestResource::Contract(
                    ContractDefTrait::new(jackpot_actions::TEST_CLASS_HASH, "jackpot_actions")
                        .with_writer_of([dojo::utils::bytearray_hash(@"nums")].span())
                )
            ].span()
        };

        ndef
    }

    fn PLAYER_ONE() -> ContractAddress {
        starknet::contract_address_const::<0xdead>()
    }

    fn PLAYER_TWO() -> ContractAddress {
        starknet::contract_address_const::<0xbeef>()
    }

    fn KING_OF_THE_HILL_STATE(start_time: u64, expiration: u64, extension: u64) -> (WorldStorage, u32, IGameActionsDispatcher, IJackpotActionsDispatcher) {
        let ndef = namespace_def();
        let world = spawn_test_world([ndef].span());
        let (game_actions_address, _) = world.dns(@"game_actions").unwrap();
        let (jackpot_actions_address, _) = world.dns(@"jackpot_actions").unwrap();

        let mut game_actions = IGameActionsDispatcher { contract_address: game_actions_address };
        let mut jackpot_actions = IJackpotActionsDispatcher { contract_address: jackpot_actions_address };

        game_actions.set_config(CONFIG());

        starknet::testing::set_contract_address(PLAYER_ONE());
        starknet::testing::set_block_timestamp(START_BLOCK_TIME);

        let jackpot_id = jackpot_actions.create_king_of_the_hill(
            'hello world', 
            expiration: EXPIRATION_TIME,
            powerups: false,
            token: Option::None,
            extension_time: EXTENSION_TIME,
        );

        (world, jackpot_id, game_actions, jackpot_actions)
    }

    fn CONFIG() -> Config {
        Config {
            world_resource: 0,
            game: Option::Some(GameConfig { max_slots: 20, max_number: 1000, min_number: 0, }),
            reward: Option::None,
        }
    }

    #[test]
    fn test_create_king_of_the_hill() {
        let (world, jackpot_id, mut game_actions, mut jackpot_actions) = KING_OF_THE_HILL_STATE(START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME);
        let jackpot: Jackpot = world.read_model(jackpot_id);
        assert(jackpot.winner == Option::None, 'no winner');
        assert(!jackpot.claimed, 'jackpot should not be claimed');
        assert(jackpot.expiration == EXPIRATION_TIME, 'expiration should not change');

        let (game_id, first_number) = game_actions.create_game(Option::Some(jackpot_id));
        let next_number = game_actions.set_slot(game_id, 6);

        jackpot_actions.king_me(game_id);
        let jackpot: Jackpot = world.read_model(jackpot_id);
        let king_of_the_hill = match jackpot.mode {
            JackpotMode::KING_OF_THE_HILL(koth) => koth,
            _ => panic!("Not a King of the Hill jackpot")
        };

        assert(jackpot.expiration == EXPIRATION_TIME + EXTENSION_TIME, 'expiration extends 300');
        assert(king_of_the_hill.king == PLAYER_ONE(), 'player should be king');
        assert(king_of_the_hill.remaining_slots == 19, 'remaining have deducted');

        if next_number > first_number {
            game_actions.set_slot(game_id, 7);
        } else {
            game_actions.set_slot(game_id, 5);
        }

        jackpot_actions.king_me(game_id);

        let jackpot: Jackpot = world.read_model(jackpot_id);
        let king_of_the_hill = match jackpot.mode {
            JackpotMode::KING_OF_THE_HILL(koth) => koth,
            _ => panic!("Not a King of the Hill jackpot")
        };
        assert(jackpot.expiration == EXPIRATION_TIME + (EXTENSION_TIME*2), 'expiration extends 400');
        assert(king_of_the_hill.king == PLAYER_ONE(), 'player should be king');
        assert(king_of_the_hill.remaining_slots == 18, 'remaining have deducted');
    }

    #[test]
    #[should_panic(expected: ('No improvement or already king', 'ENTRYPOINT_FAILED'))]
    fn test_king_me_multiple() {
        let (_, jackpot_id, mut game_actions, mut jackpot_actions) = KING_OF_THE_HILL_STATE(START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME);
        let (game_id, _) = game_actions.create_game(Option::Some(jackpot_id));

        jackpot_actions.king_me(game_id);
        jackpot_actions.king_me(game_id);
    }

    #[test]
    #[should_panic(expected: ('Jackpot already expired', 'ENTRYPOINT_FAILED'))]
    fn test_king_me_expired() {
        let (_, jackpot_id, mut game_actions, mut jackpot_actions) = KING_OF_THE_HILL_STATE(START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME);
        let (game_id, _) = game_actions.create_game(Option::Some(jackpot_id));

        starknet::testing::set_block_timestamp(EXPIRATION_TIME + 1);

        jackpot_actions.king_me(game_id);
    }

    #[test]
    fn test_claim_king_of_the_hill() {
        let (world, jackpot_id, mut game_actions, mut jackpot_actions) = KING_OF_THE_HILL_STATE(START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME);
        let (game_id, _) = game_actions.create_game(Option::Some(jackpot_id));
        game_actions.set_slot(game_id, 6);
        jackpot_actions.king_me(game_id);
        starknet::testing::set_block_timestamp(EXPIRATION_TIME + EXTENSION_TIME + 1);
        jackpot_actions.claim(game_id);

        let jackpot: Jackpot = world.read_model(jackpot_id);
        assert(jackpot.claimed, 'should be claimed');
        assert(jackpot.winner == Option::Some(PLAYER_ONE()), 'winner should be player')
    }

    #[test]
    #[should_panic(expected: ('no slots filled', 'ENTRYPOINT_FAILED'))]
    fn test_claim_king_not_winner() {
        let (_, jackpot_id, mut game_actions, mut jackpot_actions) = KING_OF_THE_HILL_STATE(START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME);
        let (game_id, _) = game_actions.create_game(Option::Some(jackpot_id));
        game_actions.set_slot(game_id, 6);
        jackpot_actions.king_me(game_id);
        starknet::testing::set_block_timestamp(EXPIRATION_TIME + EXTENSION_TIME + 1);
        starknet::testing::set_contract_address(PLAYER_TWO());

        jackpot_actions.claim(game_id);
    }

    #[test]
    #[should_panic(expected: ('cannot claim yet', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_claim_king_yet() {
        let (_, jackpot_id, mut game_actions, mut jackpot_actions) = KING_OF_THE_HILL_STATE(START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME);
        let (game_id, _) = game_actions.create_game(Option::Some(jackpot_id));
        game_actions.set_slot(game_id, 6);
        jackpot_actions.king_me(game_id);
        jackpot_actions.claim(game_id);
    }
}

