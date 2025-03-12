
Character :: struct {
    texture : GLuint;
    size : v2i;
    bearing : v2i;
    advance : u32;
}

characters: [256] Character;

draw_text :: (text: string, position: v2i) {
    xpos := position.x;
    ypos := position.y;
    for text {
        ch := *characters[it];
        x := xpos + ch.bearing.x;
        y := ypos - ch.bearing.y;
        w := ch.size.x;
        h := ch.size.y;
        glBindTexture(GL_TEXTURE_2D, ch.texture);
        draw_texture(.{0, 0, xx w, xx h}, .{xx x, xx y, xx w, xx h}, v2i.{xx w, xx h});
        xpos += ch.advance >> 6;
    }
}