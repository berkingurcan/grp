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