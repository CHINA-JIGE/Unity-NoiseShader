
bool IsInsideBox(float3 p, float3 box_center, float3 box_size)
{
    box_size *= 0.5f;
    float3 offset = abs(p - box_center);
    return offset.x < box_size.x && offset.y < box_size.y && offset.z < box_size.z;
}

float WhiteNoise3D(int seed, int i, int j, int k)
{
    //return (51237 * sin((i * 15367 + j * 66374 + seed * 36275) % 425767) + (seed * 12352 + 24556)) % 1.0f;
    //float r = sin((float(i) * 157.024f + sin(float(j) * 66.525f) * 214.0f + 214.126f * float(seed)) * 21.25f);
    float r = frac(cos(44.54f * k + 232.02f * sin(dot(float2(i, cos(j)), float2(float(seed) + 12.9898, float(seed) + 78.233))) * 45.5453));
    return r;
}

float HashVoxel(int seed, int3 voxelIdx)
{
    float r = WhiteNoise3D(seed, voxelIdx.x, voxelIdx.y, voxelIdx.z);
    r = r * 2.0f - 1.0f;//[-1, 1]
    return r;
}

float3 ComputeGradient(int seed, int3 voxelIdx)
{
    float3 gradient = float3(
        HashVoxel(seed * 123 + 345, voxelIdx), 
        HashVoxel(seed * 456 + 234, voxelIdx),
        HashVoxel(seed * 789 + 123, voxelIdx));
    return normalize(gradient);
}

// smooth interpolation for perlin noise
float SmoothLerp(float min, float max, float t)
{
    t = t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
    return min + t * (max - min);
}

static const int3 voxelVertexIdx[8] = 
{
    {0,0,0},
    {0,0,1},
    {0,1,0},
    {0,1,1},
    {1,0,0},
    {1,0,1},
    {1,1,0},
    {1,1,1}
};

float PerlinNoise3D(int seed, float3 p, float voxelSize)
{
    p /= voxelSize;
    int3 voxelIdx = floor(p);
    float dp[8]; //dot product of <dist_vec, gradient>
    for (int i = 0; i < 8; ++i)
    {
        int3 currentVoxelIdx = (voxelIdx + voxelVertexIdx[i]);
        float3 gradient = ComputeGradient(seed, currentVoxelIdx ); // compute random gradient at cube vertex //% tilingPatternSize
        float3 vertex_coord = float3(currentVoxelIdx); //compute actual coord of cube vertex
        dp[i] = dot((p - vertex_coord), gradient);
    }

    // tri-linear interpolation
    float3 v00 = voxelIdx;
    float3 t = (p - v00);

    // float res = SmoothLerp(SmoothLerp(dp00, dp10, tx), SmoothLerp(dp01, dp11, tx), ty);
    // float res = lerp(lerp(lerp(dp[0], dp[4], t.x), lerp(dp[1], dp[5], t.x), t.z), lerp(lerp(dp[2], dp[6], t.x), lerp(dp[3], dp[7], t.x), t.z), t.y);
    float res = SmoothLerp(SmoothLerp(SmoothLerp(dp[0], dp[4], t.x), SmoothLerp(dp[1], dp[5], t.x), t.z), SmoothLerp(SmoothLerp(dp[2], dp[6], t.x), SmoothLerp(dp[3], dp[7], t.x), t.z), t.y);
    return res;
}

// perlin noise with Fractal Brownian Motion (add some self-similarity?)
float PerlinNoise3D_FBM6(int seed, float3 p, float voxelSize)
{
    // fBM : https://www.iquilezles.org/www/articles/fbm/fbm.htm
    // https://www.shadertoy.com/view/lsl3RH
    // https://www.shadertoy.com/view/XslGRr
    float3x3 mat = { //some rotation matrix
                    0.8f, 0.6f, 0,
                    -0.6f, 0.8f, 0,
                    0,  0,  1.0f
                };

    float f = 0.0f;
    int numFbmSteps = 6;
    float multiplier[6] = { 2.02f, 2.03f, 2.01f, 2.04f, 2.01f, 2.02f };
    float amp = 1.0f;
    for (int i = 0; i < numFbmSteps; ++i)
    {
        f += amp * PerlinNoise3D(seed, p, voxelSize);
        p = mul(mat, p) * multiplier[i];//2.0f
        amp *= 0.5f;
    }
    return f;
}


float WorleyNoise3D(int seed, float3 p, float gridSize, int tilingPatternSize)
{
    p /= gridSize;//normalized coord
    int3 voxelIdx = floor(p);
    
    // visit current and neighbour cell
    float minDist = 100000.0f;
    for (int i = -1; i <= 2; ++i)
    {
        for (int j = -1; j <= 2; ++j)
        {
            for (int k = -1; k <= 2; ++k)
            {
                float3 offset = ComputeGradient(seed, (voxelIdx + float3(i,j,k)) % tilingPatternSize);
                float3 v = voxelIdx + float3(i,j,k);
                minDist = min(minDist, length(p - v - offset));
            }
        }
    }
    return minDist;
}

float WorleyNoise3D_FBM4(int seed, float3 p, float gridSize, int tilingPatternSize)
{
    float f = 0.0f;
    int numFbmSteps = 4;
    float amp = 0.5f;
    for (int i = 0; i < numFbmSteps; ++i)
    {
        f += amp * WorleyNoise3D(seed, p, gridSize, tilingPatternSize);
        amp *= 0.5f;
        //gridSize *= 0.4f;
        p *= 2.0f;
    }
    return f / 0.96875f;

}