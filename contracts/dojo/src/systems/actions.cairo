use nums::models::config::Config;
use starknet::ContractAddress;
use nums::models::jackpot::JackpotType;

#[dojo::interface]
pub trait IActions {
    fn create_jackpot(
        ref world: IWorldDispatcher, 
        threshold_offset: u8,
        token_type: JackpotType,
        token_address: ContractAddress,
        token_total: u256,
        token_id: Option<u256>,
        fee: u256,
        fee_address: ContractAddress,
        fee_recipient: Option<ContractAddress>,
        enable_powerups: bool,
    ) -> u32;
    fn claim_jackpot(ref world: IWorldDispatcher, game_id: u32);
    fn create_game(ref world: IWorldDispatcher, jackpot_id: Option<u32>) -> (u32, u16);
    fn set_config(ref world: IWorldDispatcher, config: Config);
    fn set_slot(ref world: IWorldDispatcher, game_id: u32, target_idx: u8) -> u16;
    fn set_name(ref world: IWorldDispatcher, game_id: u32, name: felt252);
}

#[dojo::contract]
pub mod actions {
    use core::array::ArrayTrait;
    use nums::interfaces::token::{ITokenDispatcher, ITokenDispatcherTrait};
    use nums::interfaces::token::{INumsTokenDispatcher, INumsTokenDispatcherTrait};
    use nums::models::config::{Config, SlotReward, SlotRewardTrait};
    use nums::models::game::{Game, GameTrait};
    use nums::models::jackpot::{Jackpot, JackpotType};
    use nums::models::name::Name;
    use nums::models::slot::Slot;
    use nums::utils::random::{Random, RandomImpl};

    use starknet::{ContractAddress, get_caller_address};
    use super::IActions;

    const WORLD: felt252 = 0;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    #[dojo::model]
    pub struct Inserted {
        #[key]
        game_id: u32,
        #[key]
        player: ContractAddress,
        index: u8,
        number: u16,
        next_number: u16,
        remaining_slots: u8
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    #[dojo::model]
    pub struct Created {
        #[key]
        game_id: u32,
        #[key]
        player: ContractAddress,
        max_slots: u8,
        max_number: u16,
        min_number: u16,
        jackpot_id: Option<u32>,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    #[dojo::model]
    pub struct Rewarded {
        #[key]
        game_id: u32,
        #[key]
        player: ContractAddress,
        token: ContractAddress,
        amount: u256,
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn set_config(ref world: IWorldDispatcher, config: Config) {
            let owner = get_caller_address();
            assert!(world.is_owner(WORLD, owner), "Unauthorized owner");
            assert!(config.world_resource == WORLD, "Invalid config state");

            set!(world, (config));
        }

        fn create_jackpot(
            ref world: IWorldDispatcher,
            threshold_offset: u8,
            token_type: JackpotType,
            token_address: ContractAddress,
            token_total: u256,
            token_id: Option<u256>,
            fee: u256,
            fee_address: ContractAddress,
            fee_recipient: Option<ContractAddress>,
            enable_powerups: bool,
        ) -> u32 {
            if fee_recipient.is_some() {
                panic!("Fee recipient not implemented");
            }

            if token_type != JackpotType::ERC20 {
                panic!("Only ERC20 tokens are supported");
            }

            ITokenDispatcher { contract_address: token_address }
                .transfer(get_caller_address(), token_total);

            let jackpot_id = world.uuid();
            set!(
                world,
                (Jackpot {
                    jackpot_id, 
                    threshold_offset,
                    winner: Option::None, 
                    token_type, 
                    token_address,
                    token_total,
                    token_id,
                    fee,
                    fee_total: 0,
                    fee_address,
                    fee_recipient,
                    enable_powerups,
                })
            );

            jackpot_id
        }

        /// Creates a new game instance, initializes its state, and emits a creation event.
        ///
        /// # Arguments
        /// * `world` - A reference to the world dispatcher used to interact with the game state.
        ///
        /// # Returns
        /// A tuple containing the game ID and the first random number for the game.
        fn create_game(ref world: IWorldDispatcher, jackpot_id: Option<u32>) -> (u32, u16) {
            let config = get!(world, (WORLD), Config).game.expect('Game config not set');
            let game_id = world.uuid();
            let player = get_caller_address();
            let mut rand = RandomImpl::new(world);
            let next_number = rand.between::<u16>(config.min_number + 1, config.max_number);

            set!(
                world,
                (
                    Game {
                        game_id,
                        player,
                        max_slots: config.max_slots,
                        remaining_slots: config.max_slots,
                        max_number: config.max_number,
                        min_number: config.min_number,
                        next_number,
                        jackpot_id,
                    },
                )
            );

            emit!(
                world,
                Created {
                    game_id,
                    player,
                    max_slots: config.max_slots,
                    max_number: config.max_number,
                    min_number: config.min_number,
                    jackpot_id,
                }
            );

            if let Option::Some(jackpot_id) = jackpot_id {
                let jackpot = get!(world, (jackpot_id), Jackpot);
                assert!(jackpot.winner.is_none(), "Jackpot already won");
                // TODO: Transfer fee token
            }

            (game_id, next_number)
        }

        /// Sets a number in the specified slot for a game. It ensures the slot is valid and not
        /// already filled, updates the game state, and emits an event indicating the slot has been
        /// filled.
        ///
        /// # Arguments
        /// * `world` - A reference to the world dispatcher used to interact with the game state.
        /// * `game_id` - The identifier of the game.
        /// * `target_idx` - The index of the slot to be set.
        ///
        /// # Returns
        /// The next random number to be used in the game.
        fn set_slot(ref world: IWorldDispatcher, game_id: u32, target_idx: u8) -> u16 {
            let player = get_caller_address();
            let mut game = get!(world, (game_id, player), Game);

            assert!(game.player == player, "Unauthorized player");
            assert!(target_idx < game.max_slots, "Invalid slot");

            // Build up nums array and insert target
            let mut nums = ArrayTrait::<u16>::new();
            let mut idx = 0_u8;
            loop {
                let slot = get!(world, (game_id, player, idx), Slot);
                if slot.number != 0 {
                    // Check if we're trying to insert into a filled slot
                    assert!(target_idx != idx, "Slot already filled");
                    nums.append(slot.number);
                }

                if target_idx == idx {
                    nums.append(game.next_number);
                }

                idx += 1_u8;
                if idx == game.max_slots {
                    break;
                }
            };

            // Check ordering of new nums array
            assert!(game.is_valid(@nums), "Invalid game state");

            // Update game state
            let target_number = game.next_number;
            let mut rand = RandomImpl::new(world);
            let next_number = next_random(rand, @nums, game.min_number, game.max_number);
            game.next_number = next_number;
            game.remaining_slots -= 1;

            set!(world, (game, Slot { game_id, player, index: target_idx, number: target_number }));

            emit!(
                world,
                Inserted {
                    game_id,
                    player,
                    index: target_idx,
                    number: target_number,
                    next_number,
                    remaining_slots: game.remaining_slots
                }
            );

            // Slot reward
            if let Option::Some(reward) = get!(world, (WORLD), Config).reward {
                let (address, amount) = reward.compute(game.level());
                INumsTokenDispatcher { contract_address: address }.reward(player, amount);

                emit!(world, Rewarded { game_id, player, token: address, amount });
            }

            next_number
        }

        /// Sets the player's name for a specific game. Ensures that the player is authorized and
        /// that the name has not been set before.
        ///
        /// # Arguments
        /// * `world` - A reference to the world dispatcher used to interact with the game state.
        /// * `game_id` - The identifier of the game.
        /// * `name` - The new name to be set for the player.
        fn set_name(ref world: IWorldDispatcher, game_id: u32, name: felt252) {
            let player = get_caller_address();
            let mut name_model = get!(world, (game_id, player), Name);
            assert!(name_model.player == player, "Unauthorized player");
            assert!(name_model.name == 0, "Name already set");

            name_model.name = name;
            set!(world, (name_model));
        }


        /// Claims the jackpot for a specific game. Ensures that the player is authorized and that
        /// the jackpot has not been claimed before.
        /// Transfers the jackpot token to the player and updates the jackpot state.
        /// 
        /// # Arguments
        /// * `world` - A reference to the world dispatcher used to interact with the game state.
        /// * `game_id` - The identifier of the game.
        fn claim_jackpot(ref world: IWorldDispatcher, game_id: u32) {
            let player = get_caller_address();
            let game = get!(world, (game_id, player), Game);
            let jackpot_id = game.jackpot_id.expect('Jackpot not defined');
            let mut jackpot = get!(world, (jackpot_id), Jackpot);
            assert!(jackpot.winner.is_none(), "Jackpot already won");

            let mut nums = ArrayTrait::<u16>::new();
            let mut idx = 0_u8;
            loop {
                let slot = get!(world, (game_id, player, idx), Slot);
                if slot.number != 0 {
                    nums.append(slot.number);
                }

                idx += 1_u8;
                if idx == (game.max_slots - jackpot.threshold_offset ) {
                    break;
                }
            };

            assert!(game.is_valid(@nums), "Invalid game state");

            // TODO: support erc721 and erc1155 jackpot types
            ITokenDispatcher { contract_address: jackpot.token_address }
                .transfer(game.player, jackpot.token_total);

            jackpot.winner = Option::Some(game.player);
            set!(world, (jackpot));
        }
    }

    /// Generates a random `u16` number between `min` and `max` that is not already present in the
    /// given array `nums`.
    /// If the generated number is found in the array, it recursively generates a new random number
    /// until a unique one is found.
    ///
    /// # Arguments
    /// * `rand` - A `Random` object used to generate random numbers.
    /// * `nums` - An array of `u16` numbers to check for duplicates.
    /// * `min` - The minimum value for the random number range.
    /// * `max` - The maximum value for the random number range.
    ///
    /// # Returns
    /// A unique random `u16` number between `min` and `max`.
    fn next_random(mut rand: Random, mut nums: @Array<u16>, min: u16, max: u16) -> u16 {
        let random = rand.between::<u16>(min, max);
        let mut reroll = false;
        let mut idx = 0_u32;
        loop {
            if idx == nums.len() {
                break;
            }

            if *nums.at(idx) == random {
                reroll = true;
                break;
            }

            idx += 1;
        };

        match reroll {
            true => next_random(rand, nums, min, max),
            false => random
        }
    }
}

