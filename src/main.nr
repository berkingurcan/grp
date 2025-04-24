mod point_in_polygon;

// Main circuit function for location verification
// Input:
// - lat_point, lng_point: User's GPS coordinates (private)
// - polygon_vertices: Array of polygon vertex coordinates (public)
// - result: Boolean indicating if the point is inside the polygon (public)
fn main(
    lat_point: Field,
    lng_point: Field,
    polygon_vertices_x: [Field; 4],
    polygon_vertices_y: [Field; 4],
    result: pub bool
) {
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
fn test_location_verification() {
    // Square with corners at (1,1), (1,3), (3,3), (3,1)
    let polygon_x = [1_000_000, 1_000_000, 3_000_000, 3_000_000];
    let polygon_y = [1_000_000, 3_000_000, 3_000_000, 1_000_000];
    
    // Test with a point inside the polygon
    let inside_lat = 2_000_000; // 2.0 in fixed-point
    let inside_lng = 2_000_000; // 2.0 in fixed-point
    main(inside_lat, inside_lng, polygon_x, polygon_y, true);
    
    // Test with a point outside the polygon
    let outside_lat = 4_000_000; // 4.0 in fixed-point
    let outside_lng = 2_000_000; // 2.0 in fixed-point
    main(outside_lat, outside_lng, polygon_x, polygon_y, false);
}
