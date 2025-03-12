
intermediate_vao : GLuint;
intermediate_vbo : GLuint;

render_on_startup :: () {
    glGenVertexArrays(1, *intermediate_vao);
    glGenBuffers(1, *intermediate_vbo);
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
