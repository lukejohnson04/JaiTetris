
Character :: struct {
    texture : GLuint;
    size : v2i;
    bearing : v2i;
    advance : u32;
}

characters: [128] Character;

load_font_data :: () {
    ft: FT_Library;
    if FT_Init_FreeType(*ft) {
        print("Failed to init freetype!\n");
        return;
    }

    face: FT_Face;
    if FT_New_Face(ft, "data/m5x7.ttf", 0, *face) {
        print("Failed to load font face!\n");
        return;
    }

    FT_Set_Pixel_Sizes(face, 0, 48);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, face.glyph.bitmap.pitch);

    for 0..127 {
        if FT_Load_Char(face, xx it, FT_LOAD_RENDER) {
            print("Failed to load % char!\n", it);
            continue;
        }

        texture: GLuint;
        glGenTextures(1, *texture);
        glBindTexture(GL_TEXTURE_2D, texture);
        if glGetError() != GL_NO_ERROR {
            print("Error when creating glyph: %\n", glGetError());
            return;
        }

        glTexImage2D(
            GL_TEXTURE_2D,
            0,
            GL_RED,
            face.glyph.bitmap.width,
            face.glyph.bitmap.rows,
            0,
            GL_RED,
            GL_UNSIGNED_BYTE,
            face.glyph.bitmap.buffer
        );

        error := glGetError();
        if error != GL_NO_ERROR {
            print("Error when generating texture: %\n", error);
            return;
        }

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        character := *characters[it];
        character.texture = texture;
        character.size = .{face.glyph.bitmap.width, face.glyph.bitmap.rows};
        character.bearing = .{face.glyph.bitmap_left, face.glyph.bitmap_top};
        character.advance = xx face.glyph.advance.x;
    }
    FT_Done_Face(face);
    FT_Done_FreeType(ft);
}

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
