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
- [Aztec Network](https://aztec.network/)

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