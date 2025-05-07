use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::ClassHash;
use starknet::deploy_contract_syscall;

#[starknet::interface]
trait IRegionVerifierFactory<TContractState> {
    fn deploy_region_verifier(
        ref self: TContractState,
        region_id: felt252,
        vertices_x: Array<felt252>,
        vertices_y: Array<felt252>
    ) -> ContractAddress;
    
    fn get_region_verifier(
        self: @TContractState,
        region_id: felt252
    ) -> ContractAddress;
    
    fn get_verifier_class_hash(self: @TContractState) -> ClassHash;
}

#[starknet::contract]
mod RegionVerifierFactory {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::ClassHash;
    use starknet::deploy_contract_syscall;
    
    #[storage]
    struct Storage {
        region_registry: LegacyMap::<felt252, ContractAddress>,
        verifier_class_hash: ClassHash
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        verifier_class_hash: ClassHash
    ) {
        self.verifier_class_hash.write(verifier_class_hash);
    }
    
    #[external(v0)]
    impl IRegionVerifierFactory of super::IRegionVerifierFactory<ContractState> {
        fn deploy_region_verifier(
            ref self: ContractState,
            region_id: felt252,
            vertices_x: Array<felt252>,
            vertices_y: Array<felt252>
        ) -> ContractAddress {
            // Check if region already exists
            let existing_verifier = self.region_registry.read(region_id);
            assert(existing_verifier == 0, 'Region already exists');
            
            // Deploy new region verifier contract
            let contract_address = deploy_contract_syscall(
                self.verifier_class_hash.read(),
                array![region_id, vertices_x, vertices_y].span()
            ).unwrap();
            
            // Register the new contract
            self.region_registry.write(region_id, contract_address);
            
            contract_address
        }
        
        fn get_region_verifier(
            self: @ContractState,
            region_id: felt252
        ) -> ContractAddress {
            let verifier = self.region_registry.read(region_id);
            assert(verifier != 0, 'Region does not exist');
            verifier
        }
        
        fn get_verifier_class_hash(self: @ContractState) -> ClassHash {
            self.verifier_class_hash.read()
        }
    }
} 