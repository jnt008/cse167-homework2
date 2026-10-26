StructuredBuffer<float3> vertices;
StructuredBuffer<float3> vertex_normals;
StructuredBuffer<float2> vertex_uvs;
uniform float4x4 MVP;
uniform float4x4 model_matrix;
uniform float3x3 normal_matrix;
uniform float3 light_dir;
uniform float3 light_color;
uniform float3 camera_position;
uniform float3 Ks;
uniform float exponent;
Texture2D<float4> Kd_texture;
SamplerState Kd_sampler;

struct VertexOutput {
    float4 position : SV_Position;
    float3 world_position : TEXCOORD0;
    float3 world_normal : TEXCOORD1;
    float2 uv : TEXCOORD2;
};

[shader("vertex")]
VertexOutput vertex_main(uint vid : SV_VertexID) {
    VertexOutput output;

    // Get vertex position
    float4 p = float4(vertices[vid], 1.0);

    // Transform vertex into clip space
    output.position = mul(MVP, p);

    // Transform vertex into world space
    output.world_position = mul(model_matrix, p).xyz;

    // Transform normal into world space
    output.world_normal = mul(normal_matrix, vertex_normals[vid]);

    // Get texture coordinates
    output.uv = vertex_uvs[vid];

    return output;
}

[shader("fragment")]
float4 fragment_main(VertexOutput input) : SV_Target {

    // Sample diffuse color from texture
    float3 Kd = Kd_texture.Sample(Kd_sampler, input.uv).rgb;

    // Normalize interpolated normal
    float3 n = normalize(input.world_normal);

    // Direction from surface to light
    float3 l = normalize(light_dir);

    // Direction from surface to camera
    float3 v = normalize(camera_position - input.world_position);

    // Ambient lighting
    float3 Ca = 0.2 * Kd;

    // Diffuse lighting
    float n_dot_l = dot(n, l);
    float3 Cd = Kd * light_color * max(0.0, n_dot_l);

    // Specular lighting
    float3 Cs = float3(0.0, 0.0, 0.0);

    if (n_dot_l > 0.0) {
        // Reflection direction
        float3 r = reflect(-l, n);

        // Phong specular highlight
        float r_dot_v = max(0.0, dot(r, v));
        Cs = Ks * light_color * pow(r_dot_v, exponent);
    }

    // Final color
    float3 C = Ca + Cd + Cs;

    return float4(C, 1.0);
}
