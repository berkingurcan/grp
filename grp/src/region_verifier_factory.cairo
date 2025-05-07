use starknet::ContractAddress;
use starknet::ClassHash;
use starknet::deploy_contract_syscall;

#[starknet::interface]
trait IRegionVerifierFactory<TContractState> {
    fn deploy_region_verifier(
        ref self: TContractState,
        vertices_x: Array<felt252>,
        vertices_y: Array<felt252>
    ) -> ContractAddress;
}

#[starknet::contract]
mod RegionVerifierFactory {
    use starknet::ContractAddress;
    use starknet::ClassHash;
    use starknet::deploy_contract_syscall;
    
    #[storage]
    struct Storage {
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
            vertices_x: Array<felt252>,
            vertices_y: Array<felt252>
        ) -> ContractAddress {
            deploy_contract_syscall(
                self.verifier_class_hash.read(),
                array![vertices_x, vertices_y].span()
            ).unwrap()
        }
    }
} 