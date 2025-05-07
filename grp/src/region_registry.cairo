use starknet::ContractAddress;
use super::region_verifier_factory::IRegionVerifierFactoryDispatcher;

#[starknet::interface]
trait IRegionRegistry<TContractState> {
    fn register_region(
        ref self: TContractState,
        name: felt252,
        vertices_x: Array<felt252>,
        vertices_y: Array<felt252>
    ) -> ContractAddress;
}

#[starknet::contract]
mod RegionRegistry {
    use starknet::ContractAddress;
    use super::region_verifier_factory::IRegionVerifierFactoryDispatcher;
    
    #[storage]
    struct Storage {
        factory: ContractAddress
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        factory_address: ContractAddress
    ) {
        self.factory.write(factory_address);
    }
    
    #[external(v0)]
    impl IRegionRegistry of super::IRegionRegistry<ContractState> {
        fn register_region(
            ref self: ContractState,
            name: felt252,
            vertices_x: Array<felt252>,
            vertices_y: Array<felt252>
        ) -> ContractAddress {
            let factory = IRegionVerifierFactoryDispatcher { contract_address: self.factory.read() };
            factory.deploy_region_verifier(vertices_x, vertices_y)
        }
    }
} 