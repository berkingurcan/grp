// Fixed-point arithmetic for GPS coordinates
// Since Noir doesn't support floating-point, we'll use fixed-point arithmetic
// For GPS coordinates, we'll use a scaling factor of 10^6 (6 decimal places)

// Scale factor for converting floating-point to fixed-point
global SCALE_FACTOR: Field = 1_000_000;

// Convert a coordinate to fixed-point representation
fn to_fixed_point(value: Field, decimal_places: u64) -> Field {
    // Calculate 10^decimal_places
    let mut scale = 1;
    for _ in 0..decimal_places {
        scale *= 10;
    }
    value * scale
}

// Convert from fixed-point back to regular representation (for testing)
fn from_fixed_point(value: Field, decimal_places: u64) -> Field {
    // Calculate 10^decimal_places
    let mut scale = 1;
    for _ in 0..decimal_places {
        scale *= 10;
    }
    value / scale
}

// Fixed-point addition
fn add(a: Field, b: Field) -> Field {
    a + b
}

// Fixed-point subtraction
fn subtract(a: Field, b: Field) -> Field {
    a - b
}

// Fixed-point multiplication (need to adjust scale)
fn multiply(a: Field, b: Field) -> Field {
    (a * b) / SCALE_FACTOR
}

// Fixed-point division (need to adjust scale)
fn divide(a: Field, b: Field) -> Field {
    (a * SCALE_FACTOR) / b
}

// Compare if a > b
fn greater_than(a: Field, b: Field) -> bool {
    let a_int = a as u64;
    let b_int = b as u64;
    a_int > b_int
}

// Compare if a >= b
fn greater_than_or_equal(a: Field, b: Field) -> bool {
    let a_int = a as u64;
    let b_int = b as u64;
    a_int >= b_int
}

// Compare if a < b
fn less_than(a: Field, b: Field) -> bool {
    let a_int = a as u64;
    let b_int = b as u64;
    a_int < b_int
}

// Compare if a <= b
fn less_than_or_equal(a: Field, b: Field) -> bool {
    let a_int = a as u64;
    let b_int = b as u64;
    a_int <= b_int
}

#[test]
fn test_fixed_point_conversion() {
    // Test to_fixed_point
    assert(to_fixed_point(12, 6) == 12_000_000);
    assert(to_fixed_point(0, 6) == 0);
    assert(to_fixed_point(123456, 3) == 123456000);
    
    // Test from_fixed_point
    assert(from_fixed_point(12_000_000, 6) == 12);
    assert(from_fixed_point(0, 6) == 0);
    assert(from_fixed_point(123456000, 3) == 123456);
    
    // Test roundtrip conversion
    let original = 42;
    let fixed = to_fixed_point(original, 6);
    let roundtrip = from_fixed_point(fixed, 6);
    assert(original == roundtrip);
}

#[test]
fn test_fixed_point_arithmetic() {
    // Test values (representing 3.5 and 1.5 in fixed point with 6 decimal places)
    let a = 3_500_000;
    let b = 1_500_000;
    
    // Test addition
    assert(add(a, b) == 5_000_000); // 3.5 + 1.5 = 5.0
    
    // Test subtraction
    assert(subtract(a, b) == 2_000_000); // 3.5 - 1.5 = 2.0
    
    // Test multiplication
    assert(multiply(a, b) == 5_250_000); // 3.5 * 1.5 = 5.25
    
    // Test division
    
    // Edge case - multiplication with zero
    assert(multiply(a, 0) == 0);
    
    // Edge case - large numbers
    let large_a = 999_999_999;
    let large_b = 2_000_000;
    assert(multiply(large_a, large_b) == 1_999_999_998); // (999.999999 * 2.0) = 1999.999998
}

#[test]
fn test_fixed_point_comparisons() {
    // Test values
    let a = 3_500_000; // 3.5
    let b = 1_500_000; // 1.5
    let c = 3_500_000; // 3.5
    
    // Test greater than
    assert(greater_than(a, b));
    assert(!greater_than(b, a));
    assert(!greater_than(a, c));
    
    // Test greater than or equal
    assert(greater_than_or_equal(a, b));
    assert(greater_than_or_equal(a, c));
    assert(!greater_than_or_equal(b, a));
    
    // Test less than
    assert(less_than(b, a));
    assert(!less_than(a, b));
    assert(!less_than(a, c));
    
    // Test less than or equal
    assert(less_than_or_equal(b, a));
    assert(less_than_or_equal(a, c));
    assert(!less_than_or_equal(a, b));
    
    // Test with very close values
    let d = 3_500_001; // 3.500001
    assert(less_than(a, d));
    assert(greater_than(d, a));
}

#[test]
fn test_gps_coordinate_scenarios() {
    // Test with real-world GPS coordinate values
    
    let sf_lat = 37_774_900; // 37.7749
    let sf_lng = 122_419_400; // 122.4194
    
    let ny_lat = 40_712_800; // 40.7128
    let ny_lng = 74_006_000; // 74.0060
    
    // Test comparison of coordinates
    assert(greater_than(ny_lat, sf_lat)); // New York is north of San Francisco
    assert(less_than(ny_lng, sf_lng)); // New York is east of San Francisco
    
    // Test distance calculation components (simplified)
    let lat_diff = subtract(ny_lat, sf_lat);
    assert(lat_diff == 2_937_900); // Difference in latitude
    
    let lng_diff = subtract(sf_lng, ny_lng);
    assert(lng_diff == 48_413_400); // Difference in longitude
} 