[shader("compute")]
[numthreads(8, 8, 1)]
void compute_main(uint2 tid : SV_DispatchThreadID,
                  uniform float2 sp0,
                  uniform float2 sp1,
                  uniform float2 sp2,
                  uniform int2 aabb_min,
                  uniform float3 color,
                  RWTexture2D<float4> image) {
    int2 ipixel = int2(tid) + int2(aabb_min);
    uint width, height;
    image.GetDimensions(width, height);
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
        image[ipixel] = float4(color, 1.0); 
    }
}
