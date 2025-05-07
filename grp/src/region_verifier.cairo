// Minimal Region Verifier Contract for Proof of Concept
// Stores polygon vertices and verifies proofs using the base honk verifier

use super::honk_verifier::UltraKeccakZKHonkVerifier;
use starknet::ContractAddress;

#[starknet::contract]
mod RegionVerifier {
    #[storage]
    struct Storage {
        polygon_vertices_x: Array<felt252>,
        polygon_vertices_y: Array<felt252>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        vertices_x: Array<felt252>,
        vertices_y: Array<felt252>,
    ) {
        self.polygon_vertices_x.write(vertices_x);
        self.polygon_vertices_y.write(vertices_y);
    }

    #[external(v0)]
    fn verify_proof(
        self: @ContractState,
        full_proof_with_hints: Span<felt252>,
    ) -> Option<Span<u256>> {
        // Just call the base verifier's function
        UltraKeccakZKHonkVerifier::verify_ultra_keccak_zk_honk_proof(
            self,
            full_proof_with_hints
        )
    }

    // Optionally, expose a view to get the polygon vertices
    #[view]
    fn get_vertices(self: @ContractState) -> (Array<felt252>, Array<felt252>) {
        (self.polygon_vertices_x.read(), self.polygon_vertices_y.read())
    }
} 