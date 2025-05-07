use starknet::ContractAddress;
use starknet::get_caller_address;
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
    
    fn get_region_id(self: @TContractState) -> felt252;
    fn get_polygon_vertices(self: @TContractState) -> (Array<felt252>, Array<felt252>);
}

#[starknet::contract]
mod RegionVerifier {
    use super::UltraKeccakZKHonkVerifier;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    
    #[storage]
    struct Storage {
        region_id: felt252,
        polygon_vertices_x: Array<felt252>,
        polygon_vertices_y: Array<felt252>
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        region_id: felt252,
        vertices_x: Array<felt252>,
        vertices_y: Array<felt252>
    ) {
        self.region_id.write(region_id);
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
            
            // Call the base verifier's function
            UltraKeccakZKHonkVerifier::verify_ultra_keccak_zk_honk_proof(
                lat_point,
                lng_point,
                hdop,
                vertices_x,
                vertices_y,
                result
            )
        }
        
        fn get_region_id(self: @ContractState) -> felt252 {
            self.region_id.read()
        }
        
        fn get_polygon_vertices(self: @ContractState) -> (Array<felt252>, Array<felt252>) {
            (self.polygon_vertices_x.read(), self.polygon_vertices_y.read())
        }
    }
} 