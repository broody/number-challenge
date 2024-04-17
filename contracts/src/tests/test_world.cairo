#[cfg(test)]
mod tests {
    use starknet::class_hash::Felt252TryIntoClassHash;
    use starknet::testing::set_transaction_hash;

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import test utils
    use number_challenge::{
        systems::{actions::{actions, IActionsDispatcher, IActionsDispatcherTrait}},
        models::{game::{Game, game}, slot::{Slot, slot}}
    };


    #[test]
    #[available_gas(100000000)]
    fn test_create() {
        let caller = starknet::contract_address_const::<0x0>();
        let mut models = array![game::TEST_CLASS_HASH, slot::TEST_CLASS_HASH];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

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
    #[available_gas(100000000)]
    fn test_set_eqaul() {
        let caller = starknet::contract_address_const::<0x0>();
        let mut models = array![game::TEST_CLASS_HASH, slot::TEST_CLASS_HASH];
        let world = spawn_test_world(models);

        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        let (game_id, number) = actions_system.create();

        // next number will always return same number as seed is based on transaction hash

        actions_system.set_slot(game_id, 7);
        let slot = get!(world, (game_id, caller, 7), Slot);
        assert(slot.number == number, 'slot 7 number is wrong');

        actions_system.set_slot(game_id, 6);
        let slot = get!(world, (game_id, caller, 6), Slot);
        assert(slot.number == number, 'slot 6 number is wrong');

        actions_system.set_slot(game_id, 5);
        let slot = get!(world, (game_id, caller, 5), Slot);
        assert(slot.number == number, 'slot 5 number is wrong');
    }
}
