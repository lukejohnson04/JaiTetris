#version 430 core
out vec4 FragColor;

in vec2 TexCoord;

uniform vec4 colorMod;
uniform vec4 colorAdd;
uniform sampler2D _texture;
uniform bool grayscale;

void main()
{
    vec4 color = texture(_texture, TexCoord) * colorMod;
    color += colorAdd;
    if (grayscale) {
        float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
        FragColor = vec4(vec3(gray), color.a);
    } else {
        FragColor = color;
    }
}
