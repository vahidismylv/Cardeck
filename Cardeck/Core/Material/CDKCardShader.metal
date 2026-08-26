//
//  CDKCardShader.metal
//  Cardeck
//
//  Материал карты: диагональный градиент, голографическая радуга, зеркальный блик,
//  зерно и скругление углов внутри шейдера (чтобы не платить за offscreen-проход).
//

#include <metal_stdlib>
using namespace metal;

/// Раскладка совпадает с `CDKCardUniforms` на стороне Swift.
/// Векторы float4 идут первыми: так смещения полей одинаковы в обоих компиляторах.
struct CDKCardUniforms {
    float4 colorA;
    float4 colorB;
    float2 tilt;
    float2 resolution;
    float  time;
    float  cornerRadius;
    float  hologramStrength;
    float  specularStrength;
    float  noiseAmplitude;
    float  flatMode;
};

struct CDKVertexOut {
    float4 position [[position]];
    float2 uv;
};

/// Полноэкранный треугольник без вершинного буфера.
vertex CDKVertexOut cdk_card_vertex(uint vertexID [[vertex_id]]) {
    const float2 corners[3] = { float2(-1.0, -3.0), float2(-1.0, 1.0), float2(3.0, 1.0) };
    float2 p = corners[vertexID];
    CDKVertexOut out;
    out.position = float4(p, 0.0, 1.0);
    // uv с началом координат в левом верхнем углу карты.
    out.uv = float2((p.x + 1.0) * 0.5, 1.0 - (p.y + 1.0) * 0.5);
    return out;
}

/// HSV → RGB без ветвлений.
static inline float3 cdk_hsv_to_rgb(float3 hsv) {
    float3 k = fract(hsv.x + float3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0;
    return hsv.z * mix(float3(1.0), saturate(abs(k) - 1.0), hsv.y);
}

/// Дешёвый хеш-шум: убирает пластиковость плоского градиента.
static inline float cdk_hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

/// Знаковое расстояние до скруглённого прямоугольника (в пикселях).
static inline float cdk_rounded_box_sdf(float2 point, float2 halfSize, float radius) {
    float2 q = abs(point) - (halfSize - radius);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

fragment float4 cdk_card_fragment(CDKVertexOut in [[stage_in]],
                                  constant CDKCardUniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;

    // 1. База: линейный градиент по диагонали.
    float diagonal = saturate((uv.x + uv.y) * 0.5);
    float3 color = mix(u.colorA.rgb, u.colorB.rgb, diagonal);

    if (u.flatMode < 0.5) {
        // 2. Полоса голограммы. Без маски радуга покрывает всю карту и съедает
        //    базовый градиент, поэтому она ограничена мягкой диагональной лентой,
        //    центр которой ездит вместе с наклоном устройства.
        float diagonalPosition = (uv.x + uv.y) * 0.5;
        float bandCenter = 0.5 + clamp(u.tilt.x, -0.7, 0.7) * 0.55;
        float bandOffset = (diagonalPosition - bandCenter) / 0.16;
        float band = exp(-bandOffset * bandOffset);

        // 3. Голограмма: радуга под лентой, screen-блендом.
        float hue = fract(uv.x * 3.0 + u.tilt.x * 1.5 + uv.y * 0.6);
        float3 holo = cdk_hsv_to_rgb(float3(hue, 0.75, 1.0)) * u.hologramStrength * band;
        color = 1.0 - (1.0 - color) * (1.0 - holo);

        // 4. Блик. Одного pow(dot, 32) мало: нормаль меняется по карте медленно,
        //    и вместо полосы получается круглое пятно. Поэтому блик дополнительно
        //    режется узкой лентой — выходит штрих, как на настоящей карте.
        const float3 lightDir = normalize(float3(0.35, -0.45, 0.82));
        float3 normal = normalize(float3(u.tilt + (uv - 0.5) * 0.9, 1.0));
        float streakOffset = bandOffset * 2.6;
        float streak = exp(-streakOffset * streakOffset);
        float specular = pow(saturate(dot(normal, lightDir)), 32.0)
            * u.specularStrength * streak;
        color += float3(specular);

        // 5. Зерно.
        float grain = (cdk_hash(uv * 900.0) - 0.5) * u.noiseAmplitude;
        color += float3(grain);
    }

    color = saturate(color);

    // 6. Скругление углов прямо в шейдере: маска слоя не нужна, offscreen-прохода нет.
    float2 halfSize = u.resolution * 0.5;
    float dist = cdk_rounded_box_sdf(uv * u.resolution - halfSize, halfSize, u.cornerRadius);
    float alpha = saturate(0.5 - dist) * u.colorA.a;

    // CoreAnimation ждёт premultiplied alpha.
    return float4(color * alpha, alpha);
}
