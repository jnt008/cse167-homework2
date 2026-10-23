[shader("compute")]
[numthreads(8, 8, 1)]
void compute_main(uint2 tid : SV_DispatchThreadID,
                  uniform float2 sp0, // vertex at screen space
                  uniform float2 sp1,
                  uniform float2 sp2,
                  uniform float inv_depth0, // inverse depth in camera space
                  uniform float inv_depth1,
                  uniform float inv_depth2,
                  uniform int2 aabb_min,
                  uniform float3 c0, // vertex color
                  uniform float3 c1,
                  uniform float3 c2,
                  uniform float s,
                  uniform float a,
                  RWTexture2D<float4> color_image,
                  RWTexture2D<float> depth_image) {
    int2 ipixel = int2(tid) + int2(aabb_min);
    uint width, height;
    color_image.GetDimensions(width, height);
    if (ipixel.x < 0 || ipixel.y < 0 || ipixel.x >= width || ipixel.y >= height) {
        return;
    }

    // Get the center of the pixel 
    float2 p = float2(ipixel) + float2(0.5, 0.5); 

    // Calculate the three edges
    float2 e0 = sp1 - sp0; 
    float2 e1 = sp2 - sp1; 
    float2 e2 = sp0 - sp2; 

    // Calculate the edge normals
    float2 n0 = float2(e0.y, -e0.x); 
    float2 n1 = float2(e1.y, -e1.x); 
    float2 n2 = float2(e2.y, -e2.x); 

    // Calculate the edge equations
    float d0 = dot(p - sp0, n0); 
    float d1 = dot(p - sp1, n1); 
    float d2 = dot(p - sp2, n2); 

    // Check if the pixel is inside the triangle 
    if ((d0 >= 0 && d1 >= 0 && d2 >= 0) ||
        (d0 <= 0 && d1 <= 0 && d2 <= 0)) {
        
        // Calculate barycentric coordinates
        float area = e0.x * (sp2.y - sp0.y) - e0.y * (sp2.x - sp0.x); 

        if (abs(area) < 1e-8) {
            return; 
        }
        
        float w0 = (sp1.x - p.x) * (sp2.y - p.y) - (sp1.y - p.y) * (sp2.x - p.x); 
        float w1 = (sp2.x - p.x) * (sp0.y - p.y) - (sp2.y - p.y) * (sp0.x - p.x);
        float w2 = (sp0.x - p.x) * (sp1.y - p.y) - (sp0.y - p.y) * (sp1.x - p.x);

        w0 /= area;
        w1 /= area;
        w2 /= area;
        
        // Interpolate inverse depth
        float inv_depth = w0 * inv_depth0 + w1 * inv_depth1 + w2 * inv_depth2; 

        if (inv_depth <= 0.0) {
            return; 
        }

        float depth = 1.0 / inv_depth; 

        // Check if the pixel is closer
        if (depth < depth_image[ipixel]) {
            
            // Interpolate the vertex colors
            float3 color = (w0 * inv_depth0 * c0 + 
                            w1 * inv_depth1 * c1 + 
                            w2 * inv_depth2 * c2) / inv_depth; 

            // Update the color and depth buffers
            color_image[ipixel] = float4(color, 1.0); 
            depth_image[ipixel] = depth; 
        }
    }
}
