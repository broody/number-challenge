#[cfg(test)]
mod tests {
    use dojo::model::{Model, ModelTest, ModelIndex, ModelEntityTest};
    use dojo::utils::test::spawn_test_world;
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    const START_BLOCK_TIME: u64 = 100;
    const EXTENSION_TIME: u64 = 100;
    const EXPIRATION_TIME: u64 = 200;

    use nums::{
        systems::{
            game_actions::{game_actions, IGameActionsDispatcher, IGameActionsDispatcherTrait},
            jackpot_actions::{jackpot_actions, IJackpotActionsDispatcher, IJackpotActionsDispatcherTrait}
        },
        models::{
            name::{Name, name}, game::{Game, GameTrait, game}, slot::{slot, Slot},
            config::{config, Config, GameConfig, SlotReward, SlotRewardTrait, RewardLevel},
            jackpot::jackpot::{jackpot, Jackpot},
            jackpot::mode::{JackpotMode, KingOfTheHill, ConditionalVictory},
            jackpot::token::{ Token, TokenType},
        }
    };

    use starknet::ContractAddress;
    use starknet::testing::set_transaction_hash;

    fn PLAYER_ONE() -> ContractAddress {
        starknet::contract_address_const::<0xdead>()
    }

    fn PLAYER_TWO() -> ContractAddress {
        starknet::contract_address_const::<0xbeef>()
    }

    fn STATE() -> (IWorldDispatcher, u32, IGameActionsDispatcher, IJackpotActionsDispatcher) {
        let world = spawn_test_world(
            ["nums"].span(),
            array![
                game::TEST_CLASS_HASH,
                config::TEST_CLASS_HASH,
                name::TEST_CLASS_HASH,
                slot::TEST_CLASS_HASH,
                jackpot::TEST_CLASS_HASH
            ]
                .span()
        );

        let mut game_actions = IGameActionsDispatcher {
            contract_address: world
                .deploy_contract('game_actions', game_actions::TEST_CLASS_HASH.try_into().unwrap())
        };

        let mut jackpot_actions = IJackpotActionsDispatcher {
            contract_address: world
                .deploy_contract('jackpot_actions', jackpot_actions::TEST_CLASS_HASH.try_into().unwrap())
        };

        // setup auth
        world.grant_writer(Model::<Game>::selector(), game_actions.contract_address);
        world.grant_writer(Model::<Config>::selector(), game_actions.contract_address);
        world.grant_writer(Model::<Slot>::selector(), game_actions.contract_address);
        world.grant_writer(Model::<Name>::selector(), game_actions.contract_address);
        world.grant_writer(Model::<Jackpot>::selector(), jackpot_actions.contract_address);

        game_actions.set_config(CONFIG());

        starknet::testing::set_contract_address(PLAYER_ONE());
        starknet::testing::set_block_timestamp(START_BLOCK_TIME);

        let jackpot_id = jackpot_actions.create_king_of_the_hill(
            'hello world', 
            expiration: EXPIRATION_TIME,
            powerups: false,
            token: Token {
                id: Option::None,
                address: starknet::contract_address_const::<0xdeadbeef>(),
                ty: TokenType::ERC20,
                total: 0x123,
            },
            extension_time: EXTENSION_TIME,
            transfer: false,
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
        let (world, jackpot_id, mut game_actions, mut jackpot_actions) = STATE();
        let jackpot = get!(world, (jackpot_id), Jackpot);
        assert(jackpot.winner == Option::None, 'no winner');
        assert(!jackpot.claimed, 'jackpot should not be claimed');
        assert(jackpot.expiration == EXPIRATION_TIME, 'expiration should not change');

        let (game_id, first_number) = game_actions.create_game(Option::Some(jackpot_id));
        let next_number = game_actions.set_slot(game_id, 6);

        jackpot_actions.king_me(game_id);

        let jackpot = get!(world, (jackpot_id), Jackpot);
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

        let jackpot = get!(world, (jackpot_id), Jackpot);
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
        let (_, jackpot_id, mut game_actions, mut jackpot_actions) = STATE();
        let (game_id, _) = game_actions.create_game(Option::Some(jackpot_id));

        jackpot_actions.king_me(game_id);
        jackpot_actions.king_me(game_id);
    }

    #[test]
    #[should_panic(expected: ('Jackpot already expired', 'ENTRYPOINT_FAILED'))]
    fn test_king_me_expired() {
        let (_, jackpot_id, mut game_actions, mut jackpot_actions) = STATE();
        let (game_id, _) = game_actions.create_game(Option::Some(jackpot_id));

        starknet::testing::set_block_timestamp(EXPIRATION_TIME + 1);

        jackpot_actions.king_me(game_id);
    }

    #[test]
    fn test_claim_king_of_the_hill() {
        let (world, jackpot_id, mut game_actions, mut jackpot_actions) = STATE();
        let (game_id, _) = game_actions.create_game(Option::Some(jackpot_id));
        game_actions.set_slot(game_id, 6);
        jackpot_actions.king_me(game_id);
        starknet::testing::set_block_timestamp(EXPIRATION_TIME + EXTENSION_TIME + 1);
        jackpot_actions.claim(game_id, false);

        let jackpot = get!(world, (jackpot_id), Jackpot);
        assert(jackpot.claimed, 'should be claimed');
        assert(jackpot.winner == Option::Some(PLAYER_ONE()), 'winner should be player')
    }

    #[test]
    #[should_panic(expected: ('no slots filled', 'ENTRYPOINT_FAILED'))]
    fn test_claim_king_not_winner() {
        let (_, jackpot_id, mut game_actions, mut jackpot_actions) = STATE();
        let (game_id, _) = game_actions.create_game(Option::Some(jackpot_id));
        game_actions.set_slot(game_id, 6);
        jackpot_actions.king_me(game_id);
        starknet::testing::set_block_timestamp(EXPIRATION_TIME + EXTENSION_TIME + 1);
        starknet::testing::set_contract_address(PLAYER_TWO());

        jackpot_actions.claim(game_id, false);
    }

    #[test]
    #[should_panic(expected: ('cannot claim yet', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_claim_king_yet() {
        let (_, jackpot_id, mut game_actions, mut jackpot_actions) = STATE();
        let (game_id, _) = game_actions.create_game(Option::Some(jackpot_id));
        game_actions.set_slot(game_id, 6);
        jackpot_actions.king_me(game_id);
        jackpot_actions.claim(game_id, false);
    }
}

