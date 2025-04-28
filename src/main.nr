mod point_in_polygon;
mod fixed_point;
mod secure_enclave;

// HDOP (Horizontal Dilution of Precision) quality thresholds
// These values represent the quality of GPS data based on HDOP value
global HDOP_EXCELLENT: Field = 1_000_000; // 1.0 (Excellent precision)
global HDOP_GOOD: Field = 2_000_000;      // 2.0 (Good precision)
global HDOP_MODERATE: Field = 4_000_000;  // 4.0 (Moderate precision)
global HDOP_POOR: Field = 8_000_000;      // 8.0 (Poor precision - anything above is rejected)

// Main circuit function for location verification
// Input:
// - lat_point, lng_point: User's GPS coordinates (private)
// - hdop: Horizontal Dilution of Precision value (private)
// - timestamp: Timestamp when the GPS data was collected (private)
// - signature: Digital signature from Secure Enclave (private)
// - public_key: Public key of the Secure Enclave (public)
// - polygon_vertices: Array of polygon vertex coordinates (public)
// - result: Boolean indicating if the point is inside the polygon (public)
fn main(
    lat_point: Field,
    lng_point: Field,
    hdop: Field,
    timestamp: Field,
    signature: [Field; 64],
    public_key_x: pub Field,
    public_key_y: pub Field,
    polygon_vertices_x: [Field; 4],
    polygon_vertices_y: [Field; 4],
    result: pub bool
) {
    // Validate the HDOP value - must be between 0 and HDOP_POOR
    // HDOP must be greater than 0 (negative values don't make sense for HDOP)
    let hdop_int = hdop as u64;
    assert(hdop_int > 0);
    
    // HDOP must be less than or equal to HDOP_POOR (reject poor precision data)
    let hdop_poor_int = HDOP_POOR as u64;
    assert(hdop_int <= hdop_poor_int);
    
    // Verify the GPS data is authenticated by Apple Secure Enclave
    let gps_reading = secure_enclave::SecureGPSReading {
        lat: lat_point,
        lng: lng_point,
        hdop: hdop,
        timestamp: timestamp,
        signature: signature
    };
    
    let secure_enclave_key = secure_enclave::SecureEnclavePublicKey {
        x: public_key_x,
        y: public_key_y
    };
    
    // Verify the signature from Secure Enclave
    let is_signature_valid = secure_enclave::verify_secure_gps(gps_reading, secure_enclave_key);
    assert(is_signature_valid);
    
    // Convert the user's coordinates to a Point
    let user_point = point_in_polygon::Point {
        x: lat_point,  // Already in fixed-point format
        y: lng_point   // Already in fixed-point format
    };
    
    // Create the polygon from the vertex arrays
    let mut polygon: [point_in_polygon::Point; 4] = [
        point_in_polygon::Point { x: 0, y: 0 },
        point_in_polygon::Point { x: 0, y: 0 },
        point_in_polygon::Point { x: 0, y: 0 },
        point_in_polygon::Point { x: 0, y: 0 }
    ];
    
    for i in 0..4 {
        polygon[i] = point_in_polygon::Point { 
            x: polygon_vertices_x[i], 
            y: polygon_vertices_y[i] 
        };
    }
    
    // Verify the location without revealing the exact coordinates
    let computed_result = point_in_polygon::is_point_in_polygon(user_point, polygon);
    assert(computed_result == result);
}

#[test]
fn test_location_verification_with_hdop() {
    // Square with corners at (1,1), (1,3), (3,3), (3,1)
    let polygon_x = [1_000_000, 1_000_000, 3_000_000, 3_000_000];
    let polygon_y = [1_000_000, 3_000_000, 3_000_000, 1_000_000];
    
    // Default timestamp and mock signature for tests
    let timestamp = 1698500000;
    let mock_signature: [Field; 64] = [1; 64]; // Simple non-zero signature
    let public_key_x = 123456789;
    let public_key_y = 987654321;
    
    // Test with a point inside the polygon with excellent HDOP
    let inside_lat = 2_000_000; // 2.0 in fixed-point
    let inside_lng = 2_000_000; // 2.0 in fixed-point
    let excellent_hdop = 1_000_000; // 1.0 HDOP - excellent precision
    main(inside_lat, inside_lng, excellent_hdop, timestamp, mock_signature, public_key_x, public_key_y, polygon_x, polygon_y, true);
    
    // Test with a point inside the polygon with good HDOP
    let good_hdop = 2_000_000; // 2.0 HDOP - good precision
    main(inside_lat, inside_lng, good_hdop, timestamp, mock_signature, public_key_x, public_key_y, polygon_x, polygon_y, true);
    
    // Test with a point outside the polygon with moderate HDOP
    let outside_lat = 4_000_000; // 4.0 in fixed-point
    let outside_lng = 2_000_000; // 2.0 in fixed-point
    let moderate_hdop = 3_500_000; // 3.5 HDOP - moderate precision
    main(outside_lat, outside_lng, moderate_hdop, timestamp, mock_signature, public_key_x, public_key_y, polygon_x, polygon_y, false);
}

#[test]
fn test_hdop_validation() {
    // Square with corners at (1,1), (1,3), (3,3), (3,1)
    let polygon_x = [1_000_000, 1_000_000, 3_000_000, 3_000_000];
    let polygon_y = [1_000_000, 3_000_000, 3_000_000, 1_000_000];
    
    // Default timestamp and mock signature for tests
    let timestamp = 1698500000;
    let mock_signature: [Field; 64] = [1; 64]; // Simple non-zero signature
    let public_key_x = 123456789;
    let public_key_y = 987654321;
    
    // Test with a point inside the polygon with HDOP at the maximum threshold
    let inside_lat = 2_000_000; // 2.0 in fixed-point
    let inside_lng = 2_000_000; // 2.0 in fixed-point
    let max_acceptable_hdop = HDOP_POOR; // 8.0 HDOP - poor but still acceptable
    main(inside_lat, inside_lng, max_acceptable_hdop, timestamp, mock_signature, public_key_x, public_key_y, polygon_x, polygon_y, true);
    
    // The following test should fail due to HDOP being too high
    // Uncomment to test failure case
    // let too_high_hdop = 8_000_001; // Just above the HDOP_POOR threshold
    // main(inside_lat, inside_lng, too_high_hdop, timestamp, mock_signature, public_key_x, public_key_y, polygon_x, polygon_y, true);
    
    // The following test should fail due to negative HDOP
    // Uncomment to test failure case
    // let negative_hdop = -1_000_000; // Negative HDOP (invalid)
    // main(inside_lat, inside_lng, negative_hdop, timestamp, mock_signature, public_key_x, public_key_y, polygon_x, polygon_y, true);
}

#[test]
fn test_boundary_cases() {
    // Square with corners at (1,1), (1,3), (3,3), (3,1)
    let polygon_x = [1_000_000, 1_000_000, 3_000_000, 3_000_000];
    let polygon_y = [1_000_000, 3_000_000, 3_000_000, 1_000_000];
    
    // Default timestamp and mock signature for tests
    let timestamp = 1698500000;
    let mock_signature: [Field; 64] = [1; 64]; // Simple non-zero signature
    let public_key_x = 123456789;
    let public_key_y = 987654321;
    
    // Default HDOP value for all tests
    let hdop = 1_500_000; // 1.5 HDOP - good precision
    
    // Test with a point exactly on the boundary
    let boundary_lat = 1_000_000; // 1.0 in fixed-point
    let boundary_lng = 2_000_000; // 2.0 in fixed-point
    main(boundary_lat, boundary_lng, hdop, timestamp, mock_signature, public_key_x, public_key_y, polygon_x, polygon_y, true);
    
    // Test with a point on a vertex
    let vertex_lat = 1_000_000; // 1.0 in fixed-point
    let vertex_lng = 1_000_000; // 1.0 in fixed-point
    main(vertex_lat, vertex_lng, hdop, timestamp, mock_signature, public_key_x, public_key_y, polygon_x, polygon_y, true);
    
    // Test with a point just inside the boundary
    let just_inside_lat = 1_000_001; // 1.000001 in fixed-point
    let just_inside_lng = 2_000_000; // 2.0 in fixed-point
    main(just_inside_lat, just_inside_lng, hdop, timestamp, mock_signature, public_key_x, public_key_y, polygon_x, polygon_y, true);
    
    // Test with a point just outside the boundary
    let just_outside_lat = 999_999; // 0.999999 in fixed-point
    let just_outside_lng = 2_000_000; // 2.0 in fixed-point
    main(just_outside_lat, just_outside_lng, hdop, timestamp, mock_signature, public_key_x, public_key_y, polygon_x, polygon_y, false);
}

#[test]
fn test_complex_region() {
    // Non-convex quadrilateral (arrow shape) - adjusted for correct orientation
    // Defining it in clockwise order: tip, right wing, back, left wing
    let arrow_x = [2_000_000, 3_000_000, 2_000_000, 1_000_000];
    let arrow_y = [1_000_000, 2_000_000, 3_000_000, 2_000_000];
    
    // Default timestamp and mock signature for tests
    let timestamp = 1698500000;
    let mock_signature: [Field; 64] = [1; 64]; // Simple non-zero signature
    let public_key_x = 123456789;
    let public_key_y = 987654321;
    
    // Default HDOP value for all tests
    let hdop = 2_500_000; // 2.5 HDOP - good to moderate precision
    
    // Test with a point in the center (inside)
    let center_lat = 2_000_000;
    let center_lng = 2_000_000;
    main(center_lat, center_lng, hdop, timestamp, mock_signature, public_key_x, public_key_y, arrow_x, arrow_y, true);
    
    // Test with a point in the upper part (inside)
    let upper_lat = 2_000_000;
    let upper_lng = 2_500_000;
    main(upper_lat, upper_lng, hdop, timestamp, mock_signature, public_key_x, public_key_y, arrow_x, arrow_y, true);
    
    // Test with a point outside but within the bounding box - adjusted coordinates
    let outside_lat = 1_200_000;
    let outside_lng = 1_200_000;
    main(outside_lat, outside_lng, hdop, timestamp, mock_signature, public_key_x, public_key_y, arrow_x, arrow_y, false);
}

#[test]
fn test_real_world_coordinates() {
    // Example: Simplified version of Central Park boundaries in NYC
    // Using approximate coordinates in fixed-point format
    let park_lat = [40_768_000, 40_768_000, 40_800_000, 40_800_000];
    let park_lng = [-73_982_000, -73_949_000, -73_949_000, -73_982_000];
    
    // Default timestamp and mock signature for tests
    let timestamp = 1698500000;
    let mock_signature: [Field; 64] = [1; 64]; // Simple non-zero signature
    let public_key_x = 123456789;
    let public_key_y = 987654321;
    
    // Default HDOP value for all tests - using different values for different scenarios
    let excellent_hdop = 900_000; // 0.9 HDOP - excellent precision
    let good_hdop = 1_800_000; // 1.8 HDOP - good precision
    let moderate_hdop = 3_600_000; // 3.6 HDOP - moderate precision
    
    // Test with a point inside Central Park with excellent precision
    let inside_lat = 40_785_000;
    let inside_lng = -73_965_000;
    main(inside_lat, inside_lng, excellent_hdop, timestamp, mock_signature, public_key_x, public_key_y, park_lat, park_lng, true);
    
    // Test with a point outside Central Park (Times Square area) with good precision
    let times_square_lat = 40_758_000;
    let times_square_lng = -73_985_000;
    main(times_square_lat, times_square_lng, good_hdop, timestamp, mock_signature, public_key_x, public_key_y, park_lat, park_lng, false);
    
    // Test with a point outside but close to the boundary with moderate precision
    let close_lat = 40_767_000;
    let close_lng = -73_965_000;
    main(close_lat, close_lng, moderate_hdop, timestamp, mock_signature, public_key_x, public_key_y, park_lat, park_lng, false);
}

#[test]
fn test_event_geofence() {
    // Example: Virtual concert venue geofence (arbitrary coordinates)
    let venue_lat = [37_330_000, 37_330_000, 37_335_000, 37_335_000];
    let venue_lng = [-121_895_000, -121_890_000, -121_890_000, -121_895_000];
    
    // Default timestamp and mock signature for tests
    let timestamp = 1698500000;
    let mock_signature: [Field; 64] = [1; 64]; // Simple non-zero signature
    let public_key_x = 123456789;
    let public_key_y = 987654321;
    
    // Default HDOP values for different tests
    let excellent_hdop = 800_000; // 0.8 HDOP
    let good_hdop = 1_500_000; // 1.5 HDOP
    let moderate_hdop = 3_000_000; // 3.0 HDOP
    
    // Test with an attendee inside the venue with excellent HDOP
    let attendee_lat = 37_332_000;
    let attendee_lng = -121_892_000;
    main(attendee_lat, attendee_lng, excellent_hdop, timestamp, mock_signature, public_key_x, public_key_y, venue_lat, venue_lng, true);
    
    // Test with multiple attendees at different locations with good HDOP
    let attendee2_lat = 37_331_000;
    let attendee2_lng = -121_893_500;
    main(attendee2_lat, attendee2_lng, good_hdop, timestamp, mock_signature, public_key_x, public_key_y, venue_lat, venue_lng, true);
    
    // Test with someone outside the venue with moderate HDOP
    let outside_lat = 37_329_000;
    let outside_lng = -121_892_000;
    main(outside_lat, outside_lng, moderate_hdop, timestamp, mock_signature, public_key_x, public_key_y, venue_lat, venue_lng, false);
    
    // Test with someone at the entry point (on boundary) with moderate HDOP
    let entry_lat = 37_330_000;
    let entry_lng = -121_892_500;
    main(entry_lat, entry_lng, moderate_hdop, timestamp, mock_signature, public_key_x, public_key_y, venue_lat, venue_lng, true);
}

#[test]
fn test_country_border() {
    // Example: Simplified border region between two countries
    // Note: This is a highly simplified example, real borders would need more complex polygons
    let border_lat = [45_000_000, 45_000_000, 46_000_000, 46_000_000];
    let border_lng = [5_000_000, 6_000_000, 6_000_000, 5_000_000];
    
    // Default timestamp and mock signature for tests
    let timestamp = 1698500000;
    let mock_signature: [Field; 64] = [1; 64]; // Simple non-zero signature
    let public_key_x = 123456789;
    let public_key_y = 987654321;
    
    // Default HDOP value for border tests
    let border_hdop = 1_200_000; // 1.2 HDOP - good precision
    
    // Test with a location in country A
    let country_a_lat = 45_400_000;
    let country_a_lng = 5_400_000;
    main(country_a_lat, country_a_lng, border_hdop, timestamp, mock_signature, public_key_x, public_key_y, border_lat, border_lng, true);
    
    // Test with a location in country B
    let country_b_lat = 44_800_000;
    let country_b_lng = 5_400_000;
    main(country_b_lat, country_b_lng, border_hdop, timestamp, mock_signature, public_key_x, public_key_y, border_lat, border_lng, false);
    
    // Test with a location exactly on the border
    let border_point_lat = 45_000_000;
    let border_point_lng = 5_500_000;
    main(border_point_lat, border_point_lng, border_hdop, timestamp, mock_signature, public_key_x, public_key_y, border_lat, border_lng, true);
}

#[test]
fn test_secure_enclave_verification() {
    // Square with corners at (1,1), (1,3), (3,3), (3,1)
    let polygon_x = [1_000_000, 1_000_000, 3_000_000, 3_000_000];
    let polygon_y = [1_000_000, 3_000_000, 3_000_000, 1_000_000];
    
    // Test GPS reading inside the polygon
    let inside_lat = 2_000_000; // 2.0 in fixed-point
    let inside_lng = 2_000_000; // 2.0 in fixed-point
    let good_hdop = 1_500_000; // 1.5 HDOP - good precision
    let current_timestamp = 1698512345; // Example timestamp
    
    // Mock Secure Enclave signature (would be generated by device in real scenario)
    // In a real implementation, this would be produced by the Apple Secure Enclave
    let mock_signature: [Field; 64] = [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
        17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
        33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48,
        49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64
    ];
    
    // Mock Public key for Secure Enclave (would be device-specific in real scenario)
    let public_key_x = 123456789;
    let public_key_y = 987654321;
    
    // Test valid signature and location inside polygon
    main(
        inside_lat, 
        inside_lng, 
        good_hdop, 
        current_timestamp, 
        mock_signature,
        public_key_x,
        public_key_y,
        polygon_x, 
        polygon_y, 
        true
    );
    
    // Test with invalid signature (all zeros) - should fail
    // Uncomment to test failure case
    /*
    let invalid_signature: [Field; 64] = [0; 64];
    main(
        inside_lat, 
        inside_lng, 
        good_hdop, 
        current_timestamp, 
        invalid_signature,
        public_key_x,
        public_key_y,
        polygon_x, 
        polygon_y, 
        true
    );
    */
}
