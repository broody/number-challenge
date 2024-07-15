#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_transaction_hash;
    use core::Option;

    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::test_utils::spawn_test_world;

    use nums::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::{game::{Game, GameTrait, game}, slot::{Slot, slot}, name::{Name, name}, config::{Config, GameConfig, config}}
    };

    pub fn CONFIG() -> Config {
        Config {
            world: 0,
            game: Option::Some(GameConfig {
                max_slots: 20,
                max_number: 1000,
                min_number: 0,
            }),
            cost: Option::None,
            reward: Option::None,
        }
    }


    #[test]
    fn test_config() {
        let mut models = array![game::TEST_CLASS_HASH, slot::TEST_CLASS_HASH];
        let world = spawn_test_world(models);

        let contract_address = world.deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.set_config(CONFIG());
    }

    #[test]
    #[should_panic]
    fn test_config_unauthorized() {
        let mut models = array![game::TEST_CLASS_HASH, slot::TEST_CLASS_HASH];
        let world = spawn_test_world(models);

        let contract_address = world.deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let actions_system = IActionsDispatcher { contract_address };

        let unauthorized_caller = starknet::contract_address_const::<0x1337>();
        starknet::testing::set_contract_address(unauthorized_caller);

        actions_system.set_config(CONFIG());
    }

    #[test]
    fn test_create() {
        let caller = starknet::contract_address_const::<0x0>();
        let mut models = array![game::TEST_CLASS_HASH, slot::TEST_CLASS_HASH];
        let world = spawn_test_world(models);

        let contract_address = world.deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.set_config(CONFIG());

        let (game_id, first_number) = actions_system.create();
        let game = get!(world, (game_id, caller), Game);
        let remaining = game.remaining_slots;
        assert(game.next_number == first_number, 'next number create is wrong');

        // set transaction hash so seed is "random"
        set_transaction_hash(42);

        let next_number = actions_system.set_slot(game_id, 6);
        let game = get!(world, (game_id, caller), Game);
        assert(game.next_number == next_number, 'next number set slot is wrong');
        assert(game.remaining_slots == remaining - 1, 'remaining slots is wrong');

        if next_number > first_number {
            actions_system.set_slot(game_id, 7);
        } else {
            actions_system.set_slot(game_id, 5);
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
        let mut models = array![game::TEST_CLASS_HASH, name::TEST_CLASS_HASH];
        let world = spawn_test_world(models);

        let contract_address = world.deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap(), array![].span());
        let actions_system = IActionsDispatcher { contract_address };

        actions_system.set_config(CONFIG());

        let (game_id, _) = actions_system.create();
        actions_system.set_name(game_id, 'test_name');
        
        let name = get!(world, (game_id, caller), Name);
        assert!(name.name == 'test_name', "name is wrong");
    }
}
