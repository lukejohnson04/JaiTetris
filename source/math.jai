
v2 :: struct ($T: Type) {
    x, y: T;
}

operator + :: (a: v2($T), b: v2(T)) -> v2(T) {
    result: v2(T);
    result.x = a.x + b.x;
    result.y = a.y + b.y;
    return result;
}

operator - :: (a: v2($T), b: v2(T)) -> v2(T) {
    result: v2(T);
    result.x = a.x - b.x;
    result.y = a.y - b.y;
    return result;
}

operator * :: (a: v2($T), mult: T) -> v2(T) #symmetric {
    result := a;
    result.x *= mult;
    result.y *= mult;
    return result;
}

operator == :: (a: v2($T), b: v2(T)) -> bool {
    return a.x == b.x && a.y == b.y;
}

Rect :: struct {
    x: float32;
    y: float32;
    w: float32;
    h: float32;
}

iRect :: struct {
    x, y, w, h: s64;
}

v2i :: v2(s64);
v2f :: v2(float64);

rect_contains_point :: (using rect: iRect, px: s64, py: s64) -> bool {
    if (!w || !h) {
        return false;
    }
    return (px >= x && px <= x + w && py >= y && py <= y + h);
}

vec4 :: struct {
    r, g, b, a: float32;
}