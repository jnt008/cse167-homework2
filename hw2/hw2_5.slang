[shader("compute")]
[numthreads(64, 1, 1)]
void clear_buffers(uint tid : SV_DispatchThreadID,
                   uniform uint num_pixels,
                   RWStructuredBuffer<uint> depth_buffer,
                   RWStructuredBuffer<uint> triangle_id_buffer) {
    if (tid >= num_pixels)
        return;

    depth_buffer[tid] = 0xffffffff;
    triangle_id_buffer[tid] = 0xffffffff;
}

[shader("compute")]
[numthreads(64, 1, 1)]
void transform_vertices(
    uint tid : SV_DispatchThreadID,
    uniform uint num_vertices,
    uniform uint vertex_offset,
    uniform float4x4 MVP,
    StructuredBuffer<float3> vertices,
    RWStructuredBuffer<float3> projected_vertices)
{
    if (tid >= num_vertices)
        return;

    uint i = vertex_offset + tid;
    float4 p = mul(MVP, float4(vertices[i], 1.0));
    projected_vertices[i] = p.xyz / p.w;
}

[shader("compute")]
[numthreads(64, 1, 1)]
void rasterize_depth(
        uint tid : SV_DispatchThreadID,
        uniform uint num_triangles,
        uniform uint width,
        uniform uint height,
        uniform float s,
        uniform float a,
        StructuredBuffer<uint3> faces,
        // A projected vertex store the screen space coordinates
        // in xy, and the inverse depth in z.
        StructuredBuffer<float3> projected_vertices,
        RWStructuredBuffer<uint> depth_buffer) {
        
        // Skip threads that are outside the number of triangles
        if (tid >= num_triangles)
            return; 

        // Get the three vertex indices
        uint3 face = faces[tid]; 

        // Get the projected vertices
        float3 p0 = projected_vertices[face.x]; 
        float3 p1 = projected_vertices[face.y]; 
        float3 p2 = projected_vertices[face.z]; 

        // Calculate the bounding box
        int min_x = max(0, int(floor(min(p0.x, min(p1.x, p2.x))))); 
        int min_y = max(0, int(floor(min(p0.y, min(p1.y, p2.y))))); 

        int max_x = min(int(width) - 1, int(ceil(max(p0.x, max(p1.x, p2.x))))); 
        int max_y = min(int(height) - 1, int(ceil(max(p0.y, max(p1.y, p2.y))))); 

        // Skip triangles outside the screen
        if (min_x > max_x || min_y > max_y)
            return; 

        // Calculate the triangle's signed area
        float area = (p1.x - p0.x) * (p2.y - p0.y) - (p2.x - p0.x) * (p1.y - p0.y); 

        // Skip degenerate triangles
        if (area == 0.0) 
            return; 

        // Loop through pixels in the bounding box
        for (int y = min_y; y <= max_y; y++) {
            for (int x = min_x; x <= max_x; x++) {
                // Get the pixel center
                float2 pixel = float2(float(x) + 0.5, float(y) + 0.5); 

                // Calculate barycentric coordinates
                float w0 = ((p1.x - pixel.x) * (p2.y - pixel.y)
                            - (p2.x - pixel.x) * (p1.y - pixel.y)) / area;
                float w1 = ((p2.x - pixel.x) * (p0.y - pixel.y)
                            - (p0.x - pixel.x) * (p2.y - pixel.y)) / area; 

                float w2 = 1.0 - w0 - w1; 

                // Check if the pixel is inside the triangle
                if (w0 >= 0.0 && w1 >= 0.0 && w2 >= 0.0) {
                    // Interpolate the depth
                    float depth = w0 * p0.z + w1 * p1.z + w2 * p2.z; 

                    // Update the depth buffer
                    uint depth_bits = asuint(depth); 
                    uint index = uint(y) * width + uint(x); 
                    InterlockedMin(depth_buffer[index], depth_bits); 
                }
            }
        }
}

[shader("compute")]
[numthreads(64, 1, 1)]
void rasterize_id(
        uint tid : SV_DispatchThreadID,
        uniform uint num_triangles,
        uniform uint width,
        uniform uint height,
        uniform float s,
        uniform float a,
        StructuredBuffer<uint3> faces,
        StructuredBuffer<float3> projected_vertices,
        RWStructuredBuffer<uint> depth_buffer,
        RWStructuredBuffer<uint> triangle_id_buffer) {
    
        // Skip threads that are outside the number of triangles
        if (tid >= num_triangles)
            return; 

        // Get the three vertex indices
        uint3 face = faces[tid]; 

        // Get the projected vertices
        float3 p0 = projected_vertices[face.x]; 
        float3 p1 = projected_vertices[face.y]; 
        float3 p2 = projected_vertices[face.z]; 

        // Calculate the bounding box
        int min_x = max(0, int(floor(min(p0.x, min(p1.x, p2.x))))); 
        int min_y = max(0, int(floor(min(p0.y, min(p1.y, p2.y))))); 

        int max_x = min(int(width) - 1, int(ceil(max(p0.x, max(p1.x, p2.x))))); 
        int max_y = min(int(height) - 1, int(ceil(max(p0.y, max(p1.y, p2.y))))); 

        // Skip triangles outside the screen
        if (min_x > max_x || min_y > max_y)
            return; 

        // Calculate the triangle's signed area
        float area = (p1.x - p0.x) * (p2.y - p0.y) - (p2.x - p0.x) * (p1.y - p0.y); 

        // Skip degenerate triangles
        if (area == 0.0) 
            return; 

        // Loop through pixels in the bounding box
        for (int y = min_y; y <= max_y; y++) {
            for (int x = min_x; x <= max_x; x++) {
                // Get the pixel center
                float2 pixel = float2(float(x) + 0.5, float(y) + 0.5);

                // Calculate barycentric coordinates
                float w0 = ((p1.x - pixel.x) * (p2.y - pixel.y)
                            - (p2.x - pixel.x) * (p1.y - pixel.y)) / area;
                float w1 = ((p2.x - pixel.x) * (p0.y - pixel.y)
                            - (p0.x - pixel.x) * (p2.y - pixel.y)) / area;

                float w2 = 1.0 - w0 - w1;

                // Check if the pixel is inside the triangle
                if (w0 >= 0.0 && w1 >= 0.0 && w2 >= 0.0) {
                    // Interpolate the depth
                    float depth = w0 * p0.z + w1 * p1.z + w2 * p2.z;

                    // Check if this triangle is the closest
                    uint depth_bits = asuint(depth); 
                    uint index = uint(y) * width + uint(x); 

                    if (depth_bits == depth_buffer[index]) {
                        triangle_id_buffer[index] = tid; 
                    }

                }
            }
        }

}

[shader("compute")]
[numthreads(8, 8, 1)]
void shade(
        uint2 tid : SV_DispatchThreadID,
        uniform uint width,
        uniform uint height,
        uniform float s,
        uniform float a,
        StructuredBuffer<uint3> faces,
        StructuredBuffer<float3> vertex_colors,
        StructuredBuffer<float3> projected_vertices,
        StructuredBuffer<uint> triangle_id_buffer,
        RWTexture2D<float4> image) {
    if (tid.x >= width || tid.y >= height) {
        return;
    }

    // Get the pixel index
    uint index = tid.y * width + tid.x; 

    // Get the triangle ID
    uint tri_id = triangle_id_buffer[index]; 

    // Skip pixels with no triangle
    if (tri_id == 0xffffffff) {
        return; 
    }

    // Get the three vertex indices
    uint3 face = faces[tri_id];

    // Get the projected vertices
    float3 p0 = projected_vertices[face.x];
    float3 p1 = projected_vertices[face.y];
    float3 p2 = projected_vertices[face.z];

    // Get the vertex colors
    float3 c0 = vertex_colors[face.x];
    float3 c1 = vertex_colors[face.y];
    float3 c2 = vertex_colors[face.z];
    
    // Get the pixel center
    float2 pixel = float2(float(tid.x) + 0.5, float(tid.y) + 0.5); 

    // Calculate the triangle's signed area
    float area = (p1.x - p0.x) * (p2.y - p0.y)
                - (p2.x - p0.x) * (p1.y - p0.y); 

    // Skip degenerate triangles
    if (area == 0.0) 
        return; 

    // Calculate barycentric coordinates
    float w0 = ((p1.x - pixel.x) * (p2.y - pixel.y) 
            - (p2.x - pixel.x) * (p1.y - pixel.y)) / area; 

    float w1 = ((p2.x - pixel.x) * (p0.y - pixel.y)
            - (p0.x - pixel.x) * (p2.y - pixel.y)) / area; 

    float w2 = 1.0 - w0 - w1; 

    // Perspective-correct color interpolation
    float inv_depth = w0 * p0.z + w1 * p1.z + w2 * p2.z; 

    if (inv_depth == 0.0) 
        return; 

    float3 color = (w0 * p0.z * c0 + 
                    w1 * p1.z * c1 + 
                    w2 * p2.z * c2) / inv_depth; 

    // Write the pixel color 
    image[tid] = float4(color, 1.0); 
}
