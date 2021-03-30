
float3 ColorDodgeBlend(float3 foreground, float3 background)
{
    float3 c = background / clamp(float3(1.0, 1.0, 1.0) - foreground, 0.1, 1.0);// / clamp(1.0f - cloudNoiseDetail2, 0.05f, 1.0f) + starColor;
    c = lerp(c, float3(1, 1, 1), 0.2f * clamp(c - 1.0, 0, 1.0));
    return c;
}

bool IsInside(float2 p, float2 rect_center, float2 rect_size)
{
    float2 bottomLeft = rect_center - rect_size * 0.5f;
    float2 topRight = bottomLeft + rect_size;
    return p.x > bottomLeft.x && p.x < topRight.x && p.y > bottomLeft.y && p.y < topRight.y;
}

float WhiteNoise(int seed, int i, int j)
{
    //return (51237 * sin((i * 15367 + j * 66374 + seed * 36275) % 425767) + (seed * 12352 + 24556)) % 1.0f;
    //float r = sin((float(i) * 157.024f + sin(float(j) * 66.525f) * 214.0f + 214.126f * float(seed)) * 21.25f);
    float r = frac(sin(dot(float2(i, cos(j)), float2(float(seed) + 12.9898, float(seed) + 78.233))) * 43758.5453);
    return r;
}

float HashGrid(int seed, int i, int j)
{
    float r = WhiteNoise(seed, i, j);
    r = r * 2.0f - 1.0f;
    return r;
}

float HashGridID2(int seed, int i, int j)
{
    //return (51237 * sin((i * 15367 + j * 66374 + seed * 36275) % 425767) + (seed * 12352 + 24556)) % 1.0f;
    //float r = sin((float(i) * 157.024f + sin(float(j) * 66.525f) * 214.0f + 214.126f * float(seed)) * 21.25f);
    float r = frac(sin(dot(float2(i, cos(j)), float2(float(seed) + 12.9898, float(seed) + 78.233))) * 43758.5453);
    r = frac(r) * 2.0f - 1.0f;
    return r;
}

//
float2 DirToUv(float3 dir)
{
    // dir = normalize(dir);
    float2 uv = float2(0.0f, 0.0f);
    if (length(dir.xz) == 0.0f)
    {
        uv = float2(0.5f, 0.5f * (dir.z + 1.0f));
    }
    else
    {
        float lenXZ = length(dir.xz);
        float theta = atan2(dir.z, dir.x);
        float phi = atan(dir.y / length(lenXZ));
        uv = float2(0.5f + (theta / (2.0f * 3.1415926f)), 0.5f + (phi / 3.1415926f));
        uv.x = ((uv.x - 0.5f)) + 0.5f;//scale for uv to adapt to the circumference of each Y
    }

    return uv;
}

float2 ComputeGradient(int seed, int gridX, int gridY)
{
    float2 gradient = float2(HashGrid(seed * 123 + 345, gridX, gridY), HashGrid(seed * 456 + 234, gridX, gridY));
    return normalize(gradient);
}

// for worley noise
float2 ComputeWorleyCellOffset(int seed, int gridX, int gridY)
{
    float2 gradient = float2(HashGrid(seed * 123 + 345, gridX, gridY), HashGrid(seed * 456 + 234, gridX, gridY));
    return 0.5f * gradient;
}

// smooth interpolation for perlin noise
float SmoothLerp(float min, float max, float t)
{
    t = t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
    return min + t * (max - min);
}

float PerlinNoise(int seed, float2 p, float gridSize)
{
    p /= gridSize;
    int gridX = floor(p.x);// / gridSize);
    int gridY = floor(p.y);// / gridSize);
    float2 gradient00 = ComputeGradient(seed, gridX, gridY);
    float2 gradient01 = ComputeGradient(seed, gridX, gridY + 1);
    float2 gradient10 = ComputeGradient(seed, gridX + 1, gridY);
    float2 gradient11 = ComputeGradient(seed, gridX + 1, gridY + 1);

    float2 v00 = float2(gridX, gridY);// * gridSize;
    float2 v01 = float2(gridX, gridY + 1);// * gridSize;
    float2 v10 = float2(gridX + 1, gridY);// * gridSize;
    float2 v11 = float2(gridX + 1, gridY + 1);// * gridSize;

    float dp00 = dot((p - v00), gradient00);
    float dp01 = dot((p - v01), gradient01);
    float dp10 = dot((p - v10), gradient10);
    float dp11 = dot((p - v11), gradient11);

    // bilinear interpolation
    float tx = (p.x - v00.x);// / gridSize;
    float ty = (p.y - v00.y);// / gridSize;
    float res = SmoothLerp(SmoothLerp(dp00, dp10, tx), SmoothLerp(dp01, dp11, tx), ty);
    // float res = lerp(lerp(dp00, dp10, tx), lerp(dp01, dp11, tx), ty);

    return res;
}

float PerlinNoiseTiling(int seed, float2 p, float gridSize, int tilingSize)
{
    // tilingSize = 8;
    p /= gridSize;
    int gridX = floor(p.x);// / gridSize);
    int gridY = floor(p.y);// / gridSize);  
    int gridXP1 = (gridX + 1);
    int gridYP1 = (gridY + 1);
    
    float2 gradient00 = ComputeGradient(seed, gridX % tilingSize, gridY % tilingSize);
    float2 gradient01 = ComputeGradient(seed, gridX % tilingSize, gridYP1 % tilingSize );
    float2 gradient10 = ComputeGradient(seed, gridXP1 % tilingSize, gridY % tilingSize);
    float2 gradient11 = ComputeGradient(seed, gridXP1 % tilingSize , gridYP1 % tilingSize);

    float2 v00 = float2(gridX, gridY);// * gridSize;
    float2 v01 = float2(gridX, gridYP1);// * gridSize;
    float2 v10 = float2(gridXP1, gridY);// * gridSize;
    float2 v11 = float2(gridXP1, gridYP1);// * gridSize;

    float dp00 = dot((p - v00), gradient00);
    float dp01 = dot((p - v01), gradient01);
    float dp10 = dot((p - v10), gradient10);
    float dp11 = dot((p - v11), gradient11);

    // bilinear interpolation
    float tx = (p.x - v00.x);// / gridSize;
    float ty = (p.y - v00.y);// / gridSize;
    float res = SmoothLerp(SmoothLerp(dp00, dp10, tx), SmoothLerp(dp01, dp11, tx), ty);
    // float res = lerp(lerp(dp00, dp10, tx), lerp(dp01, dp11, tx), ty);

    return res;
}

// perlin noise with Fractal Brownian Motion (add some self-similarity?)
float PerlinNoiseFBM6(int seed, float2 p, float gridSize)
{
    // const float aspect = 2.0f;
    // p.x *= aspect;
    // fBM : https://www.iquilezles.org/www/articles/fbm/fbm.htm
    // https://www.shadertoy.com/view/lsl3RH
    // https://www.shadertoy.com/view/XslGRr
    //Vector4 deltaVec = new Vector4(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), 0.0f, 0.0f); ;// new Vector4(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), 0.0f, 0.0f);
    float2x2 mat = { //some rotation matrix
                    0.8f, 0.6f,
                    -0.6f, 0.8f
                };

    float f = 0.0f;
    int numFbmSteps = 6;
    float multiplier[6] = { 2.02f, 2.03f, 2.01f, 2.04f, 2.01f, 2.02f };
    // float multiplier[6] = { 1.02f, 2.03f, 3.01f, 2.04f, 3.01f, 3.02f };
    float amp = 1.0f;
    for (int i = 0; i < numFbmSteps; ++i)
    {
        f += amp * PerlinNoise(seed, p, gridSize);
        p = mul(mat, p) * multiplier[i];//(2.0f + Random.Range(0.0f, 0.05f));//brownian motion applied to sample coord
        // p *= multiplier[i];
        amp *= 0.5f;
    }
    return f / 0.96875f;
}

// perlin noise with Fractal Brownian Motion (add some self-similarity?)
float PerlinNoiseTilingFBM6(int seed, float2 p, float gridSize)
{
    // const float aspect = 2.0f;
    // p.x *= aspect;
    // fBM : https://www.iquilezles.org/www/articles/fbm/fbm.htm
    // https://www.shadertoy.com/view/lsl3RH
    // https://www.shadertoy.com/view/XslGRr
    //Vector4 deltaVec = new Vector4(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), 0.0f, 0.0f); ;// new Vector4(Random.Range(-1.0f, 1.0f), Random.Range(-1.0f, 1.0f), 0.0f, 0.0f);
    float2x2 mat = { //some rotation matrix
                    0.8f, 0.6f,
                    -0.6f, 0.8f
                };

    float f = 0.0f;
    int numFbmSteps = 6;
    float multiplier[6] = { 2.02f, 2.03f, 2.01f, 2.04f, 2.01f, 2.02f };
    // float multiplier[6] = { 1.02f, 2.03f, 3.01f, 2.04f, 3.01f, 3.02f };
    float amp = 1.0f;
    for (int i = 0; i < numFbmSteps; ++i)
    {
        f += amp * PerlinNoiseTiling(seed, p, gridSize, 10);
        p = mul(mat, p) * multiplier[i];//(2.0f + Random.Range(0.0f, 0.05f));//brownian motion applied to sample coord
        // p *= multiplier[i];
        amp *= 0.5f;
    }
    return f / 0.96875f;
}

float WorleyNoise(int seed, float2 p, float gridSize)
{
    p /= gridSize;//normalized coord
    int gridX = floor(p.x);
    int gridY = floor(p.y);
    
    // visit current and neighbour cells
    float minDist = 100000.0f;
    for (int i = -1; i <= 1; ++i)
    {
        for (int j = -1; j <= 1; ++j)
        {
            float2 offset = ComputeWorleyCellOffset(seed, gridX + i, gridY + j);//offset from cell center
            float2 v = float2(gridX + i, gridY + j) + float2(0.5f, 0.5f);//cell center
            minDist = min(minDist, length(p - v - offset));
        }
    }
    return minDist;
}

float WorleyNoiseFBM4(int seed, float2 p, float gridSize)
{
    float f = 0.0f;
    int numFbmSteps = 4;
    float amp = 0.5f;
    for (int i = 0; i < numFbmSteps; ++i)
    {
        f += amp * WorleyNoise(seed, p, gridSize);
        amp *= 0.5f;
        //gridSize *= 0.4f;
        p *= 2.0f;
    }
    return f;

}

float ValueNoise(int seed, float2 p, float gridSize)
{
    p /= gridSize;
    int gridX = floor(p.x);// / gridSize);
    int gridY = floor(p.y);// / gridSize);

    float2 v00 = float2(gridX, gridY);// * gridSize;
    float2 v01 = float2(gridX, gridY + 1);// * gridSize;
    float2 v10 = float2(gridX + 1, gridY);// * gridSize;
    float2 v11 = float2(gridX + 1, gridY + 1);// * gridSize;

    float value00 = WhiteNoise(seed, gridX, gridY);
    float value10 = WhiteNoise(seed, gridX + 1, gridY);
    float value01 = WhiteNoise(seed, gridX, gridY + 1);
    float value11 = WhiteNoise(seed, gridX + 1, gridY + 1);

    // bilinear interpolation
    float tx = (p.x - v00.x);// / gridSize;
    float ty = (p.y - v00.y);// / gridSize;
    float res = SmoothLerp(SmoothLerp(value00, value10, tx), SmoothLerp(value01, value11, tx), ty);
    
    float3 c = float3(res, res, res);
    return c;
}

float ValueNoiseFBM4(int seed, float2 p, float gridSize)
{
    float f = 0.0f;
    int numFbmSteps = 4;
    float amp = 0.5f;
    for (int i = 0; i < numFbmSteps; ++i)
    {
        f += amp * ValueNoise(seed, p, gridSize);
        amp *= 0.5f;
        //gridSize *= 0.4f;
        p *= 2.0f;
    }
    return f / 0.96875f;

}