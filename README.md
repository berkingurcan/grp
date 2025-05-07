# GRP Zero-Knowledge Proof Location Verification

A zero-knowledge proof system built with Noir and Aztec for verifying if a user is within a geographical zone without revealing their exact GPS coordinates.

## Overview

This project implements a privacy-preserving location verification system using zero-knowledge proofs. It allows proving that a user is within a defined geographical area (polygon) without disclosing their exact coordinates.

The core functionality uses the Ray Casting Algorithm to determine if a point is inside a polygon, implemented with fixed-point arithmetic to handle GPS coordinates in Noir.

## Features

- Privacy-preserving location verification
- Point-in-Polygon verification with Ray Casting Algorithm
- Fixed-point arithmetic implementation for GPS coordinates
- HDOP (Horizontal Dilution of Precision) validation to detect fake GPS data
- Zero-knowledge proofs with Noir/Aztec

## Prerequisites

- [Noir](https://noir-lang.org/)
- [Cario](https://book.cairo-lang.org)

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd zkp-location-verification

# Install dependencies
# (Add appropriate commands here)
```

## Usage

### Building the Project

```bash
nargo build
```

### Running Tests

```bash
nargo test
```

### Creating a Proof

```bash
# Example command to create a proof
nargo prove --witness witness.json
```

### Verifying a Proof

```bash
# Example command to verify a proof
nargo verify --proof proof.json
```

## Project Structure

- `src/fixed_point.nr`: Implementation of fixed-point arithmetic for GPS coordinates
- `src/point_in_polygon.nr`: Ray Casting Algorithm for Point-in-Polygon verification
- `src/main.nr`: Main circuit for the zero-knowledge proof system
- `grp/src/honk_verifier.cairo`: Cairo contract auto-generated from the Noir circuit for proof verification
- `grp/src/region_verifier.cairo`: Minimal Cairo contract for region-specific verification, storing polygon vertices and calling the base verifier

## Architecture: Noir Circuit & Cairo Contracts

### 1. Noir Circuit
- The Noir circuit (`src/main.nr`) defines the zero-knowledge logic for verifying if a user's (private) coordinates are inside a (public) polygon, with HDOP validation.
- The circuit exposes a `main` function that takes:
  - User's latitude, longitude, and HDOP (private)
  - Polygon vertices (public)
  - Result (public boolean)
- The circuit is compiled and used to generate proofs off-chain.

### 2. Cairo Contracts
- `honk_verifier.cairo`: The base verifier contract, auto-generated from the Noir circuit, which verifies proofs on-chain.
- `region_verifier.cairo`: A minimal contract for each region (polygon). Each instance stores its polygon vertices in storage and exposes a `verify_proof` function. This function calls the base verifier to check the proof.
- To support multiple regions, deploy a separate `RegionVerifier` contract for each region, each initialized with its own polygon vertices.

#### Minimal Region Verifier Flow
1. Deploy a `RegionVerifier` contract for each region, passing the polygon vertices to the constructor.
2. When a user wants to prove they are inside a region:
   - The user generates a proof off-chain using the Noir circuit, with the region's polygon vertices as public inputs.
   - The frontend submits the proof to the corresponding `RegionVerifier` contract's `verify_proof` function.
   - The contract verifies the proof using the base verifier logic and returns the result.

## Notes for Frontend Developers

- **Proof Generation:**
  - Use the Noir circuit to generate proofs off-chain. The public inputs must match the polygon vertices stored in the target `RegionVerifier` contract.
  - The proof must include all required witness and hint data as expected by the Cairo verifier.

- **Contract Interaction:**
  - For each region, obtain the address of the deployed `RegionVerifier` contract (each region has its own contract instance).
  - Call the `verify_proof` function on the contract, passing the proof data as a `Span<felt252>`.
  - The contract will return `Some(public_inputs)` if the proof is valid, or `None` if invalid.

- **Polygon Vertices:**
  - You can fetch the polygon vertices for a region using the `get_vertices` view function on the contract to ensure the frontend uses the correct public inputs for proof generation.

- **Deployment:**
  - For a proof-of-concept, deploy each region contract manually with its polygon vertices.
  - For production, consider a factory or registry pattern to manage regions and contracts.


## How It Works

### Fixed-Point Arithmetic

Since Noir doesn't support floating-point operations, the system uses fixed-point arithmetic with a scaling factor of 10^6 (6 decimal places) to represent GPS coordinates accurately.

### Ray Casting Algorithm

The Ray Casting Algorithm works by counting the number of times a ray starting from the point and going in any fixed direction intersects with the polygon's edges. If the count is odd, the point is inside; if even, it's outside.

### HDOP Validation

HDOP (Horizontal Dilution of Precision) validation is implemented to detect and filter out potentially fake GPS data:

- Excellent precision: HDOP ≤ 1.0
- Good precision: HDOP ≤ 2.0
- Moderate precision: HDOP ≤ 4.0
- Poor precision: HDOP ≤ 8.0
- Rejected: HDOP > 8.0

The circuit rejects any location data with HDOP values above the "Poor" threshold, adding an additional layer of security against GPS spoofing.

### Zero-Knowledge Verification

The circuit takes private inputs (user's coordinates and HDOP value) and public inputs (polygon vertices), and outputs only a boolean result indicating whether the point is inside the polygon, without revealing the exact location.

## Examples

### Defining a Geofence

```noir
// Define a square polygon (coordinates scaled by 10^6)
let polygon_x = [1_000_000, 1_000_000, 3_000_000, 3_000_000];
let polygon_y = [1_000_000, 3_000_000, 3_000_000, 1_000_000];
```

### Verifying Location

```noir
// Check if a point is inside the polygon and has acceptable HDOP
let inside_lat = 2_000_000; // 2.0 in fixed-point
let inside_lng = 2_000_000; // 2.0 in fixed-point
let hdop = 1_500_000; // 1.5 HDOP - good precision
main(inside_lat, inside_lng, hdop, polygon_x, polygon_y, true);
```

## Security Considerations

- The system never reveals the user's exact coordinates
- Only the result of the location check is made public
- HDOP validation helps prevent GPS spoofing attacks
- The verification is done within a zero-knowledge circuit

## Future Work

- Support for more complex polygons
- Optimizations for circuit efficiency
- Additional GPS data validation methods
- Additional privacy features

## License

[Add license information here]

## Contributing

[Add contribution guidelines here]