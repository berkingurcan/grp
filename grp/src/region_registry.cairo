use starknet::ContractAddress;
use starknet::get_caller_address;
use super::region_verifier_factory::IRegionVerifierFactoryDispatcher;

#[starknet::interface]
trait IRegionRegistry<TContractState> {
    fn register_region(
        ref self: TContractState,
        region_id: felt252,
        name: felt252,
        vertices_x: Array<felt252>,
        vertices_y: Array<felt252>
    );
    
    fn get_region_info(
        self: @TContractState,
        region_id: felt252
    ) -> RegionInfo;
    
    fn get_factory_address(self: @TContractState) -> ContractAddress;
}

#[derive(Drop, Serde)]
struct RegionInfo {
    name: felt252,
    verifier: ContractAddress,
    active: bool
}

#[starknet::contract]
mod RegionRegistry {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use super::region_verifier_factory::IRegionVerifierFactoryDispatcher;
    
    #[storage]
    struct Storage {
        regions: LegacyMap::<felt252, RegionInfo>,
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
            region_id: felt252,
            name: felt252,
            vertices_x: Array<felt252>,
            vertices_y: Array<felt252>
        ) {
            // Check if region already exists
            let existing_info = self.regions.read(region_id);
            assert(existing_info.verifier == 0, 'Region already exists');
            
            // Deploy new verifier through factory
            let factory = IRegionVerifierFactoryDispatcher { contract_address: self.factory.read() };
            let verifier_address = factory.deploy_region_verifier(region_id, vertices_x, vertices_y);
            
            // Register region info
            self.regions.write(region_id, RegionInfo {
                name: name,
                verifier: verifier_address,
                active: true
            });
        }
        
        fn get_region_info(
            self: @ContractState,
            region_id: felt252
        ) -> RegionInfo {
            let info = self.regions.read(region_id);
            assert(info.verifier != 0, 'Region does not exist');
            info
        }
        
        fn get_factory_address(self: @ContractState) -> ContractAddress {
            self.factory.read()
        }
    }
} 