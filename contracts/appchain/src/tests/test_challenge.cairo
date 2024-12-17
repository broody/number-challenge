#[cfg(test)]
mod tests {
    use dojo::model::ModelStorage;
    use dojo::world::{WorldStorageTrait, WorldStorage};
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDef, ContractDefTrait, WorldStorageTestTrait};

    use starknet::ContractAddress;

    use nums::{
        systems::{
            game_actions::{game_actions, IGameActionsDispatcher, IGameActionsDispatcherTrait},
            challenge_actions::{
                challenge_actions, IChallengeActionsDispatcher, IChallengeActionsDispatcherTrait
            }
        },
        models::{
            game::m_Game, slot::m_Slot, config::{m_Config, Config, GameConfig},
            challenge::challenge::{m_Challenge, Challenge}, challenge::mode::ChallengeMode,
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
                TestResource::Model(m_Game::TEST_CLASS_HASH),
                TestResource::Model(m_Slot::TEST_CLASS_HASH),
                TestResource::Model(m_Config::TEST_CLASS_HASH),
                TestResource::Model(m_Challenge::TEST_CLASS_HASH),
                TestResource::Event(
                    game_actions::e_GameCreated::TEST_CLASS_HASH
                ),
                TestResource::Event(game_actions::e_Inserted::TEST_CLASS_HASH),
                TestResource::Event(
                    challenge_actions::e_ChallengeCreated::TEST_CLASS_HASH
                ),
                TestResource::Event(
                    challenge_actions::e_ChallengeClaimed::TEST_CLASS_HASH
                ),
                TestResource::Event(
                    challenge_actions::e_KingCrowned::TEST_CLASS_HASH
                ),
                TestResource::Contract(
                    game_actions::TEST_CLASS_HASH
                ),
                TestResource::Contract(
                    challenge_actions::TEST_CLASS_HASH
                )
            ].span()
        };

        ndef
    }

    fn contract_def() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"nums", @"game_actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"nums")].span()),
            ContractDefTrait::new(@"nums", @"challenge_actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"nums")].span())
        ].span()
    }

    fn spawn_nums_world() -> WorldStorage {
        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_def());

        world
    }


    fn PLAYER_ONE() -> ContractAddress {
        starknet::contract_address_const::<0xdead>()
    }

    fn PLAYER_TWO() -> ContractAddress {
        starknet::contract_address_const::<0xbeef>()
    }

    fn KING_OF_THE_HILL_STATE(
        start_time: u64, expiration: u64, extension: u64
    ) -> (WorldStorage, u32, IGameActionsDispatcher, IChallengeActionsDispatcher) {
        let world = spawn_nums_world();
        let (game_actions_address, _) = world.dns(@"game_actions").unwrap();
        let (challenge_actions_address, _) = world.dns(@"challenge_actions").unwrap();

        let mut game_actions = IGameActionsDispatcher { contract_address: game_actions_address };
        let mut challenge_actions = IChallengeActionsDispatcher {
            contract_address: challenge_actions_address
        };

        game_actions.set_config(CONFIG());

        starknet::testing::set_contract_address(PLAYER_ONE());
        starknet::testing::set_block_timestamp(START_BLOCK_TIME);

        let challenge_id = challenge_actions
            .create_king_of_the_hill(
                'hello world',
                expiration: EXPIRATION_TIME,
                powerups: false,
                token: Option::None,
                extension_time: EXTENSION_TIME,
            );

        (world, challenge_id, game_actions, challenge_actions)
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
        let (world, challenge_id, mut game_actions, mut challenge_actions) = KING_OF_THE_HILL_STATE(
            START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME
        );
        let challenge: Challenge = world.read_model(challenge_id);
        assert(challenge.winner == Option::None, 'no winner');
        assert(!challenge.claimed, 'challenge should not be claimed');
        assert(challenge.expiration == EXPIRATION_TIME, 'expiration should not change');

        let (game_id, first_number) = game_actions.create_game(Option::Some(challenge_id));
        let next_number = game_actions.set_slot(game_id, 6);

        challenge_actions.king_me(game_id);
        let challenge: Challenge = world.read_model(challenge_id);
        let king_of_the_hill = match challenge.mode {
            ChallengeMode::KING_OF_THE_HILL(koth) => koth,
            _ => panic!("Not a King of the Hill challenge")
        };

        assert(challenge.expiration == EXPIRATION_TIME + EXTENSION_TIME, 'expiration extends 300');
        assert(king_of_the_hill.king == PLAYER_ONE(), 'player should be king');
        assert(king_of_the_hill.remaining_slots == 19, 'remaining have deducted');

        if next_number > first_number {
            game_actions.set_slot(game_id, 7);
        } else {
            game_actions.set_slot(game_id, 5);
        }

        challenge_actions.king_me(game_id);

        let challenge: Challenge = world.read_model(challenge_id);
        let king_of_the_hill = match challenge.mode {
            ChallengeMode::KING_OF_THE_HILL(koth) => koth,
            _ => panic!("Not a King of the Hill challenge")
        };
        assert(
            challenge.expiration == EXPIRATION_TIME + (EXTENSION_TIME * 2), 'expiration extends 400'
        );
        assert(king_of_the_hill.king == PLAYER_ONE(), 'player should be king');
        assert(king_of_the_hill.remaining_slots == 18, 'remaining have deducted');
    }

    #[test]
    #[should_panic(expected: ('No improvement or already king', 'ENTRYPOINT_FAILED'))]
    fn test_king_me_multiple() {
        let (_, challenge_id, mut game_actions, mut challenge_actions) = KING_OF_THE_HILL_STATE(
            START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME
        );
        let (game_id, _) = game_actions.create_game(Option::Some(challenge_id));

        challenge_actions.king_me(game_id);
        challenge_actions.king_me(game_id);
    }

    #[test]
    #[should_panic(expected: ('Challenge already expired', 'ENTRYPOINT_FAILED'))]
    fn test_king_me_expired() {
        let (_, challenge_id, mut game_actions, mut challenge_actions) = KING_OF_THE_HILL_STATE(
            START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME
        );
        let (game_id, _) = game_actions.create_game(Option::Some(challenge_id));

        starknet::testing::set_block_timestamp(EXPIRATION_TIME + 1);

        challenge_actions.king_me(game_id);
    }

    #[test]
    fn test_claim_king_of_the_hill() {
        let (world, challenge_id, mut game_actions, mut challenge_actions) = KING_OF_THE_HILL_STATE(
            START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME
        );
        let (game_id, _) = game_actions.create_game(Option::Some(challenge_id));
        game_actions.set_slot(game_id, 6);
        challenge_actions.king_me(game_id);
        starknet::testing::set_block_timestamp(EXPIRATION_TIME + EXTENSION_TIME + 1);
        challenge_actions.claim(game_id);

        let challenge: Challenge = world.read_model(challenge_id);
        assert(challenge.claimed, 'should be claimed');
        assert(challenge.winner == Option::Some(PLAYER_ONE()), 'winner should be player')
    }

    #[test]
    #[should_panic(expected: ('no slots filled', 'ENTRYPOINT_FAILED'))]
    fn test_claim_king_not_winner() {
        let (_, challenge_id, mut game_actions, mut challenge_actions) = KING_OF_THE_HILL_STATE(
            START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME
        );
        let (game_id, _) = game_actions.create_game(Option::Some(challenge_id));
        game_actions.set_slot(game_id, 6);
        challenge_actions.king_me(game_id);
        starknet::testing::set_block_timestamp(EXPIRATION_TIME + EXTENSION_TIME + 1);
        starknet::testing::set_contract_address(PLAYER_TWO());

        challenge_actions.claim(game_id);
    }

    #[test]
    #[should_panic(expected: ('cannot claim yet', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_claim_king_yet() {
        let (_, challenge_id, mut game_actions, mut challenge_actions) = KING_OF_THE_HILL_STATE(
            START_BLOCK_TIME, EXPIRATION_TIME, EXTENSION_TIME
        );
        let (game_id, _) = game_actions.create_game(Option::Some(challenge_id));
        game_actions.set_slot(game_id, 6);
        challenge_actions.king_me(game_id);
        challenge_actions.claim(game_id);
    }
}

