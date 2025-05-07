use starknet::ContractAddress;
use super::honk_verifier::UltraKeccakZKHonkVerifier;

#[starknet::interface]
trait IRegionVerifier<TContractState> {
    fn verify_location(
        self: @TContractState,
        lat_point: felt252,
        lng_point: felt252,
        hdop: felt252,
        result: bool
    ) -> Option<Span<felt252>>;
}

#[starknet::contract]
mod RegionVerifier {
    use super::UltraKeccakZKHonkVerifier;
    
    #[storage]
    struct Storage {
        polygon_vertices_x: Array<felt252>,
        polygon_vertices_y: Array<felt252>
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        vertices_x: Array<felt252>,
        vertices_y: Array<felt252>
    ) {
        self.polygon_vertices_x.write(vertices_x);
        self.polygon_vertices_y.write(vertices_y);
    }
    
    #[external(v0)]
    impl IRegionVerifier of super::IRegionVerifier<ContractState> {
        fn verify_location(
            self: @ContractState,
            lat_point: felt252,
            lng_point: felt252,
            hdop: felt252,
            result: bool
        ) -> Option<Span<felt252>> {
            let vertices_x = self.polygon_vertices_x.read();
            let vertices_y = self.polygon_vertices_y.read();
            
            UltraKeccakZKHonkVerifier::verify_ultra_keccak_zk_honk_proof(
                lat_point,
                lng_point,
                hdop,
                vertices_x,
                vertices_y,
                result
            )
        }
    }
} 