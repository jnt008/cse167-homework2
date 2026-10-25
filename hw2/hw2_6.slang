StructuredBuffer<float3> vertices;
StructuredBuffer<float3> vertex_colors;
uniform float4x4 MVP;

struct VertexOutput {
    float4 position : SV_Position;
    float3 color : COLOR0;
};

[shader("vertex")]
VertexOutput vertex_main(uint vid : SV_VertexID) {
    VertexOutput output;
    // Transform the vertex into clip space
    output.position = mul(MVP, float4(vertices[vid], 1.0)); 

    // Get the vertex color 
    output.color = vertex_colors[vid]; 
    return output;
}

[shader("fragment")]
float4 fragment_main(VertexOutput input) : SV_Target {
    // Output the interpolated vertex color
    return float4(input.color, 1.0);
}
