#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Wave distortion based on horizontal scroll offset.
/// `progress` — how far from center (−1…1), used to amplify the wave.
/// `time` — current time for subtle animation.
[[ stitchable ]] float2 waveDistort(float2 position, float2 size, float progress, float time) {
    float2 uv = position / size;
    // Amplitude grows near edges
    float amp = abs(progress) * 14.0;
    // Sine wave driven by y coordinate and time
    float wave = sin(uv.y * 7.0 + time * 2.0) * amp;
    // Horizontal stretch in the direction of scroll
    float stretchX = progress * uv.x * 8.0;
    return position + float2(wave + stretchX, 0.0);
}

/// Chromatic aberration: splits R and B channels horizontally based on scroll progress.
/// Creates a subtle holographic look on cards as they leave the center.
[[ stitchable ]] half4 chromaticSplit(float2 position, SwiftUI::Layer layer, float progress) {
    float shift = progress * 4.0;
    half4 r = layer.sample(position + float2(shift, 0));
    half4 g = layer.sample(position);
    half4 b = layer.sample(position - float2(shift, 0));
    return half4(r.r, g.g, b.b, g.a);
}

/// Cylindrical barrel warp applied to the whole ScrollView.
/// Takes the rendered 2D content and projects it onto a virtual cylinder,
/// so horizontal lines curve down at the edges and content looks wrapped
/// around a drum — exactly like Telegram's archive/folders swipe effect.
///
/// `size`     — full width/height of the warped view
/// `strength` — 0 = no warp, 1 = strong barrel curve
/// Warping loupe — круглая «лупа» в заданной точке.
/// Пиксели внутри радиуса притягиваются к центру (увеличение),
/// за пределами — рендерятся без изменений.
///
/// `center`   — координата центра лупы (в px)
/// `radius`   — радиус линзы (в px)
/// `strength` — 0 = нет увеличения, 1 = сильный fisheye
[[ stitchable ]] half4 warpLoupe(float2 position, SwiftUI::Layer layer,
                                 float2 center, float radius, float strength) {
    float2 delta = position - center;
    float dist = length(delta);
    if (dist >= radius) {
        return layer.sample(position);
    }
    float n = dist / radius;                  // 0…1
    // Мягкий fisheye: сильнее у центра, слабее к краю
    float factor = 1.0 - strength * (1.0 - n * n);
    float2 src = center + delta * factor;
    return layer.sample(src);
}

/// True cylindrical perspective: плоская полоса натягивается на вертикальный цилиндр.
/// Inverse mapping через asin — горизонталь сжимается к краям (как реальная проекция),
/// плюс парабольный Y-dip для "уходящей вдаль" кромки.
[[ stitchable ]] float2 cylinderDistort(float2 position, float2 size, float strength) {
    float hw       = size.x * 0.5;
    float nx       = (position.x - hw) / hw;            // -1 … 1

    // Центральные 95% плоские; искажение включается на внешних 2.5% с каждой стороны.
    float edge     = smoothstep(0.95, 1.00, abs(nx));
    if (edge <= 0.0) return position;

    float maxAng   = 1.05 * strength;                   // ~60° при strength=1
    float sinMax   = sin(maxAng);
    float clamped  = clamp(nx * sinMax, -0.9995, 0.9995);
    float theta    = asin(clamped);
    float srcNx    = theta / maxAng;
    float warpedX  = hw + srcNx * hw;

    // Вертикальное сжатие относительно центра — кромка выглядит уходящей в глубину,
    // но без визуального смещения по Y (центр карточки остаётся на месте).
    float cy       = size.y * 0.5;
    float vScale   = 1.0 - nx * nx * 0.12 * strength;
    float warpedY  = cy + (position.y - cy) / vScale;

    // Клэмпим, чтобы шейдер не сэмплировал за пределами layer'a (иначе чёрные дыры).
    warpedX = clamp(warpedX, 0.0, size.x);
    warpedY = clamp(warpedY, 0.0, size.y);

    // Плавный переход: flat → cylindrical по мере приближения к кромке.
    return mix(position, float2(warpedX, warpedY), edge);
}

/// Цилиндрическая проекция у верхней кромки экрана.
/// Контент внутри `warpBand` пикселей от верха сжимается к верху как поверхность цилиндра,
/// которая заворачивается в глубину. Ниже полосы всё остаётся плоским.
[[ stitchable ]] float2 topCylinderDistort(float2 position, float2 size, float warpBand, float strength) {
    if (position.y >= warpBand) return position;
    float t        = position.y / warpBand;             // 0 сверху, 1 на границе
    float maxAng   = 1.40 * strength;                   // ~80° при strength=1
    float sinMax   = sin(maxAng);
    float clamped  = clamp(t * sinMax, -0.9995, 0.9995);
    float theta    = asin(clamped);
    float surfT    = theta / maxAng;                    // 0 … 1 на поверхности цилиндра
    float srcY     = clamp(surfT * warpBand, 0.0, size.y);
    return float2(position.x, srcY);
}

[[ stitchable ]] half4 cylinderWarp(float2 position, SwiftUI::Layer layer, float2 size, float strength) {
    // Normalize x to -1…1 around horizontal center
    float nx = (position.x / size.x - 0.5) * 2.0;
    // Parabolic vertical dip at the edges (the hallmark of barrel distortion)
    float curveY = nx * nx * size.y * 0.08 * strength;
    // Vertical compression toward the edges (cylinder receding)
    float vScale = 1.0 - nx * nx * 0.06 * strength;

    float cy = size.y * 0.5;
    float2 src;
    src.x = position.x;
    src.y = cy + (position.y - cy) / vScale - curveY;
    // Clamp: if we'd sample outside the layer, pull back to the nearest edge
    src.y = clamp(src.y, 0.0, size.y);
    return layer.sample(src);
}

/// Soft glow that brightens the card when it's in the center.
/// `focus` is 1.0 at center, 0 at edges.
/// Signature matches SwiftUI's `.colorEffect`: (position, color) -> color
[[ stitchable ]] half4 focusGlow(float2 position, half4 color, float focus) {
    half3 boost = color.rgb * (1.0h + half(focus) * 0.25h);
    return half4(boost, color.a);
}
