
compile_shader :: (source: string, type: GLenum) -> id: GLuint {
    shader : GLuint = glCreateShader(type);
    glShaderSource(shader, 1, *source.data, null);
    glCompileShader(shader);

    success : s32;
    glGetShaderiv(shader, GL_COMPILE_STATUS, *success);
    if !success {
        info_log : [256] u8;
        glGetShaderInfoLog(shader, 256, null, xx *info_log);
        print("%", cast(string) info_log);
    }

    return shader;
}

create_shader_program :: (vert_path: string, frag_path: string) -> GLuint {

    vert_code := read_entire_file(vert_path);
    frag_code := read_entire_file(frag_path);
    
    vert_shader := compile_shader(vert_code, GL_VERTEX_SHADER);
    frag_shader := compile_shader(frag_code, GL_FRAGMENT_SHADER);

    shader_program := glCreateProgram();
    glAttachShader(shader_program, vert_shader);
    glAttachShader(shader_program, frag_shader);
    glLinkProgram(shader_program);

    success : s32;
    glGetProgramiv(shader_program, GL_LINK_STATUS, *success);
    if !success {
        print("Failed to link shader program!\n");
    }

    glDeleteShader(vert_shader);
    glDeleteShader(frag_shader);

    return shader_program;
}
