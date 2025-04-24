// Ray Casting Algorithm for Point-in-Polygon
// This algorithm determines whether a point is inside a polygon
// by counting the number of times a ray from the point crosses the polygon boundary

// Define a Point structure for GPS coordinates
pub struct Point {
    pub x: Field,  // Latitude (fixed-point)
    pub y: Field,  // Longitude (fixed-point)
}

// Helper functions for comparing Fields by handling internal constraints in Noir
fn is_lt(a: Field, b: Field) -> bool {
    // Convert to integers for comparison
    let a_int = a as u64;
    let b_int = b as u64;
    a_int < b_int
}

fn is_lte(a: Field, b: Field) -> bool {
    // Convert to integers for comparison
    let a_int = a as u64;
    let b_int = b as u64;
    a_int <= b_int
}

fn is_gt(a: Field, b: Field) -> bool {
    // Convert to integers for comparison
    let a_int = a as u64;
    let b_int = b as u64;
    a_int > b_int
}

fn is_gte(a: Field, b: Field) -> bool {
    // Convert to integers for comparison
    let a_int = a as u64;
    let b_int = b as u64;
    a_int >= b_int
}

// Function to check if a point is inside a polygon using Ray Casting Algorithm
// Returns true if the point is inside the polygon, false otherwise
pub fn is_point_in_polygon(point: Point, polygon: [Point; _]) -> bool {
    let n = polygon.len();
    
    // If polygon has less than 3 vertices, point cannot be inside
    let mut inside = false;
    
    if n >= 3 {
        // Count the number of intersections
        let mut count = 0;
        
        for i in 0..n {
            // Get current vertex and next vertex (wrapping around to first vertex)
            let current = polygon[i];
            let next = polygon[(i + 1) % n];
            
            // Check if the ray from the point to the right intersects with this edge
            
            // Check if point.y is between current.y and next.y
            let current_y_lte_point_y = is_lte(current.y, point.y);
            let point_y_lt_next_y = is_lt(point.y, next.y);
            let next_y_lte_point_y = is_lte(next.y, point.y);
            let point_y_lt_current_y = is_lt(point.y, current.y);
            
            let y_in_range_1 = current_y_lte_point_y & point_y_lt_next_y;
            let y_in_range_2 = next_y_lte_point_y & point_y_lt_current_y;
            let y_in_range = y_in_range_1 | y_in_range_2;
            
            if y_in_range {
                // Calculate the x-coordinate of the intersection point
                // Using the equation: x = current.x + (point.y - current.y) * (next.x - current.x) / (next.y - current.y)
                
                let y_diff = point.y - current.y;
                let edge_x_diff = next.x - current.x;
                let edge_y_diff = next.y - current.y;
                
                // Avoid division by zero (when edge is horizontal)
                if edge_y_diff != 0 {
                    // Fixed-point multiplication and division
                    // We're using a SCALE_FACTOR of 1_000_000 (defined in fixed_point.nr)
                    let SCALE_FACTOR = 1_000_000;
                    
                    let factor = (y_diff * SCALE_FACTOR) / edge_y_diff;
                    let intersection_x = current.x + (factor * edge_x_diff) / SCALE_FACTOR;
                    
                    // If intersection is to the right of the point, count it
                    let is_to_right = is_gt(intersection_x, point.x);
                    if is_to_right {
                        count += 1;
                    }
                }
            }
        }
        
        // If count is odd, point is inside polygon
        inside = count % 2 == 1;
    }
    
    inside
}

#[test]
fn test_point_in_polygon() {
    // Test with a simple square polygon
    // Coordinates are scaled by SCALE_FACTOR (1,000,000)
    
    // Square with corners at (1,1), (1,3), (3,3), (3,1)
    let polygon = [
        Point { x: 1_000_000, y: 1_000_000 },
        Point { x: 1_000_000, y: 3_000_000 },
        Point { x: 3_000_000, y: 3_000_000 },
        Point { x: 3_000_000, y: 1_000_000 }
    ];
    
    // Test point inside: (2,2)
    let inside_point = Point { x: 2_000_000, y: 2_000_000 };
    assert(is_point_in_polygon(inside_point, polygon));
    
    // Test point outside: (4,2)
    let outside_point = Point { x: 4_000_000, y: 2_000_000 };
    assert(!is_point_in_polygon(outside_point, polygon));
    
    // Test point on boundary: (1,2)
    let boundary_point = Point { x: 1_000_000, y: 2_000_000 };
    assert(is_point_in_polygon(boundary_point, polygon));
}