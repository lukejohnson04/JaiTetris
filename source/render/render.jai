
intermediate_vao : GLuint;
intermediate_vbo : GLuint;

render_on_startup :: () {
    glGenVertexArrays(1, *intermediate_vao);
    glGenBuffers(1, *intermediate_vbo);
}

draw_quad :: (dest: Rect) {
    x1 := dest.x;
    x2 := (dest.x+dest.w);
    y1 := dest.y;
    y2 := (dest.y+dest.h);

    /*
    x1 := dest.x / WINDOW_WIDTH;
    x2 := (dest.x+dest.w) / WINDOW_WIDTH;
    y1 := dest.y / WINDOW_HEIGHT;
    y2 := (dest.y+dest.h) / WINDOW_HEIGHT;
*/
    /*
    x1 *= WINDOW_WIDTH;
    x2 *= WINDOW_WIDTH;
    y1 *= WINDOW_HEIGHT;
    y2 *= WINDOW_HEIGHT;
*/
    vertices := float32.[
        x2, y1, 0,
        x2, y2, 0,
        x1, y2, 0,
        x1, y1, 0
    ];

    glBindVertexArray(intermediate_vao);
    glBindBuffer(GL_ARRAY_BUFFER, intermediate_vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(float32) * vertices.count, vertices.data, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(float32), xx null);
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glBindVertexArray(0);
}

draw_texture :: (source: Rect, dest: Rect, tex: *Texture) {
    u1, u2, v1, v2 : float32;
    u1 = source.x / tex.width;
    u2 = (source.x + source.w) / tex.width;
    v1 = source.y / tex.height;
    v2 = (source.y + source.h) / tex.height;

    vertices := float32.[
        dest.x,         dest.y,         0,  u1, v1,
        dest.x+dest.w,  dest.y,         0,  u2, v1,
        dest.x+dest.w,  dest.y+dest.h,  0,  u2, v2,
        dest.x,         dest.y+dest.h,  0,  u1, v2
    ];

    glBindVertexArray(intermediate_vao);
    glBindBuffer(GL_ARRAY_BUFFER, intermediate_vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(float32) * 20, *vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * size_of(float32), null);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * size_of(float32), xx (3 * size_of(float32)));
    glEnableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glBindVertexArray(0);
}

draw_texture :: (source: Rect, dest: Rect, texture_size: v2i) {
    u1, u2, v1, v2 : float32;
    u1 = source.x / texture_size.x;
    u2 = (source.x + source.w) / texture_size.x;
    v1 = source.y / texture_size.y;
    v2 = (source.y + source.h) / texture_size.y;

    vertices := float32.[
        dest.x,         dest.y,         0,  u1, v1,
        dest.x+dest.w,  dest.y,         0,  u2, v1,
        dest.x+dest.w,  dest.y+dest.h,  0,  u2, v2,
        dest.x,         dest.y+dest.h,  0,  u1, v2
    ];

    glBindVertexArray(intermediate_vao);
    glBindBuffer(GL_ARRAY_BUFFER, intermediate_vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(float32) * 20, *vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * size_of(float32), null);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * size_of(float32), xx (3 * size_of(float32)));
    glEnableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glBindVertexArray(0);
}
