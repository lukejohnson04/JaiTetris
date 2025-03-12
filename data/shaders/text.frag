#version 430 core
out vec4 FragColor;

in vec2 TexCoord;

uniform vec4 color;
uniform sampler2D _texture;

void main()
{
    FragColor = vec4(1, 1, 1, texture(_texture, TexCoord).r);
}
