
color_shader : GLuint;
texture_shader : GLuint;
text_shader : GLuint;

mat_projection : Matrix4;
mat_view : Matrix4;
mat_model : Matrix4;

texture_block : Texture;
texture_gui : Texture;

MAP_WIDTH :: 10;
MAP_HEIGHT :: 20;
tiles : [MAP_WIDTH][MAP_HEIGHT] int;

current_piece_pos : v2i;
current_piece_type : Piece_Type;
next_piece_type : Piece_Type;
hold_piece_type : Piece_Type;
holding_piece := false;
just_held_piece := false;

piece_preview_y_level : int;

current_piece : [16]int;

score := 0;

Piece_Type :: enum {
    O;
    I;
    S;
    Z;
    L;
    J;
    T;
}

pieces : [#run enum_highest_value(Piece_Type) + 1][16]int;
piece_pos_dimensions : [#run enum_highest_value(Piece_Type) + 1] int;

init_textures :: () {
    texture_block = make_texture("data/sprites.png");
    texture_gui = make_texture("data/gui.png");
}

make_texture :: (path: string) -> Texture {
    result : Texture;
    texture_load_from_file(*result, path);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    return result;
}

reset_game :: () {
    set_current_piece(get_random_piece());
    next_piece_type = get_random_piece();
    holding_piece = false;
    just_held_piece = false;

    for col: 0..MAP_WIDTH-1 {
        for row: 0..MAP_HEIGHT-1 {
            tiles[col][row] = -1;
        }
    }
    predict_placement();
}

on_startup :: () {
    render_on_startup();
    init_textures();

    color_shader = create_shader_program("data/shaders/color.vert", "data/shaders/color.frag");
    texture_shader = create_shader_program("data/shaders/texture.vert", "data/shaders/texture.frag");
    text_shader = create_shader_program("data/shaders/text.vert", "data/shaders/text.frag");

    mat_projection = orthographic_projection_matrix(0, WINDOW_WIDTH, WINDOW_HEIGHT, 0, -1, 1);
    mat_projection = transpose(mat_projection);
    mat_model = Matrix4_Identity;
    mat_view = Matrix4_Identity;

    {
        time := current_time_monotonic();
        seed := to_microseconds(time);
        random_seed(<< (cast(*u64) *seed));
    }

    // Note: I was really struggling with 2d arrays at first lol
    // so this is pretty awkward... I understand how I can do 2D
    // arrays now but I would really appreciate feedback on a more
    // elegant way to initialize the piece data!
    pieces[Piece_Type.O] = .[
        0,0,0,0,
        0,1,1,0,
        0,1,1,0,
        0,0,0,0
    ];
    piece_pos_dimensions[Piece_Type.O] = 4;

    pieces[Piece_Type.I] = .[
        0,0,1,0,
        0,0,1,0,
        0,0,1,0,
        0,0,1,0
    ];
    piece_pos_dimensions[Piece_Type.I] = 4;

    pieces[Piece_Type.S] = .[
        0,0,0,
        0,1,1,
        1,1,0,
        0,0,0,0,0,0,0
    ];

    piece_pos_dimensions[Piece_Type.S] = 3;

    pieces[Piece_Type.Z] = .[
        0,0,0,
        1,1,0,
        0,1,1,
        0,0,0,0,0,0,0
    ];
    piece_pos_dimensions[Piece_Type.Z] = 3;

    pieces[Piece_Type.L] = .[
        0,1,0,
        0,1,0,
        0,1,1,
        0,0,0,0,0,0,0
    ];
    piece_pos_dimensions[Piece_Type.L] = 3;

    pieces[Piece_Type.J] = .[
        0,1,0,
        0,1,0,
        1,1,0,
        0,0,0,0,0,0,0
    ];
    piece_pos_dimensions[Piece_Type.J] = 3;

    pieces[Piece_Type.T] = .[
        0,1,0,
        1,1,1,
        0,0,0,
        0,0,0,0,0,0,0
    ];
    piece_pos_dimensions[Piece_Type.T] = 3;

    // init font data
    load_font_data();

    reset_game();
}

gain_score_for_line_clear :: (lines_cleared: int) {
    increment := 0;
    if lines_cleared == {
        case 1; increment = 40;
        case 2; increment = 100;
        case 3; increment = 300;
        case 4; increment = 1200;
    }
    score += increment;
}

FRAME_TIME : float32 : 1.0 / 60.0;
last_frame_time : s64 = 0;
global_clock : s64 = 0;

tick_timer : float32;
drop_rate : float32 : 1.0 / 3.0;
repeat_rate : float32 : 1.0 / 10.0;
repeat_timer : float32;

sleep_till_next_update :: () {
    delay_time := last_frame_time + (FRAME_TIME * 1000) - SDL_GetTicks();
    SDL_Delay(cast(u32) ifx delay_time > 0 then delay_time);
    global_clock = SDL_GetTicks();
    last_frame_time = global_clock;
}

set_current_piece :: (type: Piece_Type) {
    current_piece_type = type;
    memcpy(current_piece.data, pieces[type].data, size_of(int) * 16);
    current_piece_pos = v2i.{3, 0};
}

predict_placement :: () {
    piece_preview_y_level = current_piece_pos.y;
    dimensions := piece_pos_dimensions[current_piece_type];
    while prediction_complete := true {
        for pos: 0..(dimensions*dimensions-1) {
            if current_piece[pos] == 0 continue;

            row := pos / dimensions;
            col := pos % dimensions;

            coord := v2i.{current_piece_pos.x + col, piece_preview_y_level + row};
            // check if there's a tile beside it
            if coord.y >= MAP_HEIGHT || tiles[coord.x][coord.y] != -1 {
                piece_preview_y_level -= 1;
                return;
            }
        }
        piece_preview_y_level += 1;
    }
}

move_current_piece :: (move: v2i) -> bool, bool {
    success_x, success_y := true;
    dimensions := piece_pos_dimensions[current_piece_type];
    if move.x != 0 {
        for pos: 0..(dimensions*dimensions-1) {
            if current_piece[pos] == 0 continue;

            row := pos / dimensions;
            col := pos % dimensions;

            coord := v2i.{current_piece_pos.x + col + move.x, current_piece_pos.y + row};
            // check if there's a tile beside it
            if coord.x >= MAP_WIDTH || coord.x < 0 || tiles[coord.x][coord.y] != -1 {
                success_x = false;
                break;
            }
        }
        if success_x {
            current_piece_pos.x += move.x;
        }
    }

    if move.y != 0 {
        for pos: 0..(dimensions*dimensions-1) {
            if current_piece[pos] == 0 continue;

            row := pos / dimensions;
            col := pos % dimensions;

            coord := v2i.{current_piece_pos.x + col, current_piece_pos.y + row + move.y};
            // check if there's a tile beside it
            if coord.y >= MAP_HEIGHT || tiles[coord.x][coord.y] != -1 {
                success_y = false;
                break;
            }
        }
        if success_y {
            current_piece_pos.y += move.y;
        }
    }
    return success_x, success_y;
}

rotate_current_piece :: (clockwise : bool) -> bool {
    rotated : [16]int;

    dimensions := piece_pos_dimensions[current_piece_type];

    // transpose
    for row: 0..dimensions-1 {
        for col: 0..dimensions-1 {
            rotated[row*dimensions + col] = current_piece[col*dimensions + row];
        }
    }

    if clockwise {
        // reverse each row
        for row: 0..(dimensions-1) {
            for col: 0..(dimensions-1)/2 {
                temp_val := rotated[row*dimensions + col];
                rotated[row*dimensions + col] = rotated[row*dimensions + dimensions-1-col];
                rotated[row*dimensions + dimensions-1-col] = temp_val;
            }
        }
    } else {
        // reverse each column
        for col: 0..(dimensions-1) {
            for row: 0..(dimensions-1)/2 {
                temp_val := rotated[row*dimensions + col];
                rotated[row*dimensions + col] = rotated[(dimensions-row-1)*dimensions + col];
                rotated[(dimensions-row-1)*dimensions + col] = temp_val;
            }
        }
    }

    // check if our rotation makes the piece collide with something.
    // In that case, we should adjust the position of the piece accordingly.
    adjust_x := 0;
    for pos: 0..(dimensions*dimensions - 1) {
        if rotated[pos] == 0 continue;

        row := pos / dimensions;
        col := pos % dimensions;
        coord := v2i.{current_piece_pos.x + col, current_piece_pos.y + row};

        if coord.x < 0 {
            adjust_x = 1;
            break;
        } else if coord.x > MAP_WIDTH-1 {
            adjust_x = -1;
            break;
        }
    }

    // Check if the piece is overlapping with a tile. If this is true, since
    // we've already checked for other overlaps, it is now shown to be impossible
    // for this rotation to take place.
    for pos: 0..(dimensions*dimensions - 1) {
        if rotated[pos] == 0 continue;

        row := pos / dimensions;
        col := pos % dimensions;
        coord := v2i.{current_piece_pos.x + col + adjust_x, current_piece_pos.y + row};

        if tiles[coord.x][coord.y] != -1 {
            return false;
        }
    }

    current_piece_pos.x += adjust_x;

    memcpy(current_piece.data, rotated.data, size_of(int) * 16);

    return true;
}

get_random_piece :: () -> Piece_Type {
    low, high := enum_range(Piece_Type);
    return cast(Piece_Type) (random_get() % cast(u64)(high+1));
}

land_piece :: () {
    // on landing
    dimensions := piece_pos_dimensions[current_piece_type];
    // land on ground
    for pos: 0..(dimensions*dimensions-1) {
        if current_piece[pos] == 0 continue;

        row := pos / dimensions;
        col := pos % dimensions;
        coord := v2i.{current_piece_pos.x + col, current_piece_pos.y + row};
        tiles[coord.x][coord.y] = cast(int) current_piece_type;
    }

    // check if we cleared any lines
    cleared_lines := 0;
    for row: 0..MAP_HEIGHT-1 {
        cleared := true;
        for col: 0..MAP_WIDTH-1 {
            if tiles[col][row] == -1 then {cleared = false; break;}
        }
        if cleared {
            cleared_lines += 1;
            for col: 0..MAP_WIDTH-1 {
                tiles[col][row] = -1;
            }
            for #v2 < inner_row: 0..row {
                for col: 0..MAP_WIDTH-1 {
                    if inner_row == 0 {
                        tiles[col][inner_row] = -1;
                    } else {
                        tiles[col][inner_row] = tiles[col][inner_row-1];
                    }
                }
            }
        }
    }
    gain_score_for_line_clear(cleared_lines);
    set_current_piece(next_piece_type);
    next_piece_type = get_random_piece();
    predict_placement();
}

update_and_render :: (running : *bool) {
    if input.is_pressed[SDL_SCANCODE_ESCAPE] {
        running.* = false;
    }

    // Update begin
    input_dir := v2i.{0,0};
    tick_timer += FRAME_TIME;

    if input.just_pressed[SDL_SCANCODE_C] {
        if just_held_piece == false {
            // hold piece
            if holding_piece == false {
                hold_piece_type = current_piece_type;
                holding_piece = true;
                set_current_piece(next_piece_type);
                next_piece_type = get_random_piece();
            } else {
                temp_piece := current_piece_type;
                set_current_piece(hold_piece_type);
                hold_piece_type = temp_piece;
            }
            just_held_piece = true;
        }
    }

    if input.is_pressed[SDL_SCANCODE_D] {
        input_dir.x += 1;
    }

    if input.is_pressed[SDL_SCANCODE_A] {
        input_dir.x -= 1;
    }

    if input.is_pressed[SDL_SCANCODE_S] {
        input_dir.y += 1;
    }

    move_dir := v2i.{0, 0};
    if input_dir != v2i.{0,0} {
        repeat_timer -= FRAME_TIME;
        if repeat_timer <= 0 {
            move_dir = input_dir;
            if move_dir.y != 0 {
                tick_timer = 0;
            }
            repeat_timer = repeat_rate;
        }
    } else {
        repeat_timer = 0;
    }

    if tick_timer > drop_rate {
        tick_timer -= drop_rate;
        move_dir.y = 1;
    }

    need_to_update_prediction := false;
    if input.just_pressed[SDL_SCANCODE_E] {
        need_to_update_prediction |= rotate_current_piece(true);
    } else if input.just_pressed[SDL_SCANCODE_Q] {
        need_to_update_prediction |= rotate_current_piece(false);
    }

    // hard drop
    finished_piece := false;
    if input.just_pressed[SDL_SCANCODE_LSHIFT] {
        // bring piece all the way to the bottom
        success_x, success_y := true;
        while success_y == true {
            success_x, success_y = move_current_piece(v2i.{0,1});
        }

        // land the piece
        land_piece();
        finished_piece = true;
        just_held_piece = false;
    }

    if finished_piece == false {
        success_x, success_y := move_current_piece(move_dir);
        need_to_update_prediction |= success_x;
        if success_y == false {
            land_piece();
            just_held_piece = false;
        } else if need_to_update_prediction {
            predict_placement();
        }
    }

    // Render begin
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram(texture_shader);
    proj := glGetUniformLocation(texture_shader, "projection");
    view := glGetUniformLocation(texture_shader, "view");
    model := glGetUniformLocation(texture_shader, "model");
    glUniformMatrix4fv(proj, 1, GL_FALSE, xx *mat_projection);
    glUniformMatrix4fv(view, 1, GL_FALSE, xx *mat_view);
    glUniformMatrix4fv(model, 1, GL_FALSE, xx *mat_model);
    glUniform4f(glGetUniformLocation(texture_shader, "colorMod"),1,1,1,1);
    glUniform4f(glGetUniformLocation(texture_shader, "colorAdd"),0,0,0,0);

    loc_texture := glGetUniformLocation(texture_shader, "_texture");
    loc_colorMod := glGetUniformLocation(texture_shader, "colorMod");
    loc_grayscale := glGetUniformLocation(texture_shader, "grayscale");

    glBindTexture(GL_TEXTURE_2D, texture_block.gl_handle);
    glUniform1i(loc_texture, 0);
    glUniform1i(loc_grayscale, 0);
    
    for col: 0..MAP_WIDTH-1 {
        for row: 0..MAP_HEIGHT-1 {
            if tiles[col][row] != -1 {
                src : Rect = .{cast(float32)tiles[col][row] * 16, 0, 16, 16};
                dest : Rect = .{cast(float32)col * TILE_SIZE, cast(float32)row * TILE_SIZE, TILE_SIZE, TILE_SIZE};
                draw_texture(src, dest, .{texture_block.width, texture_block.height});
            }
        }
    }

    dimensions := piece_pos_dimensions[current_piece_type];
    glUniform4f(loc_colorMod, 1, 1, 1, 0.5);
    glUniform1i(loc_grayscale, 1);
    // draw prediction of where piece will be
    for pos: 0..(dimensions*dimensions-1) {
        if current_piece[pos] == 0 continue;

        row := pos / dimensions;
        col := pos % dimensions;

        coord := v2i.{current_piece_pos.x + col, piece_preview_y_level + row};
        src : Rect = .{cast(float32)current_piece_type * 16, 0, 16, 16};
        dest : Rect = .{cast(float32)coord.x * TILE_SIZE, cast(float32)coord.y * TILE_SIZE, TILE_SIZE, TILE_SIZE};
        draw_texture(src, dest, .{texture_block.width, texture_block.height});
    }

    glUniform4f(loc_colorMod, 1, 1, 1, 1);
    glUniform1i(loc_grayscale, 0);
    {
        for pos: 0..(dimensions*dimensions-1) {
            if current_piece[pos] == 0 continue;

            row := pos / dimensions;
            col := pos % dimensions;

            coord := v2i.{current_piece_pos.x + col, current_piece_pos.y + row};
            
            src : Rect = .{cast(float32)current_piece_type * 16, 0, 16, 16};
            dest : Rect = .{cast(float32)coord.x * TILE_SIZE, cast(float32)coord.y * TILE_SIZE, TILE_SIZE, TILE_SIZE};
            draw_texture(src, dest, .{texture_block.width, texture_block.height});
        }
    }

    // draw gui
    glBindTexture(GL_TEXTURE_2D, texture_gui.gl_handle);
    glUniform1i(loc_texture, 0);
    gui_size := v2i.{texture_gui.width, texture_gui.height};
    draw_texture(Rect.{0, 0, xx gui_size.x, xx gui_size.y},
                Rect.{WINDOW_WIDTH-160, 0, xx gui_size.x, xx gui_size.y},
                gui_size);

    // draw next piece and hold piece preview
    glBindTexture(GL_TEXTURE_2D, texture_block.gl_handle);
    glUniform1i(loc_texture, 0);

    {
        // next piece
        next_piece_dimensions := piece_pos_dimensions[next_piece_type];        
        for pos: 0..(next_piece_dimensions*next_piece_dimensions-1) {
            if pieces[next_piece_type][pos] == 0 continue;

            row := pos / next_piece_dimensions;
            col := pos % next_piece_dimensions;

            preview_pos := v2i.{MAP_WIDTH*TILE_SIZE + 160/2 + (col-2)*16, 32 + row*16};

            src : Rect = .{cast(float32)next_piece_type * 16, 0, 16, 16};
            dest : Rect = .{cast(float32)preview_pos.x, cast(float32)preview_pos.y, 16, 16};
            draw_texture(src, dest, .{texture_block.width, texture_block.height});
        }
    }

    // hold piece
    if holding_piece {
        hold_piece_dimensions := piece_pos_dimensions[hold_piece_type];        
        for pos: 0..(hold_piece_dimensions*hold_piece_dimensions-1) {
            if pieces[hold_piece_type][pos] == 0 continue;

            row := pos / hold_piece_dimensions;
            col := pos % hold_piece_dimensions;

            preview_pos := v2i.{MAP_WIDTH*TILE_SIZE + 160/2 + (col-2)*16, 32 + row*16 + 80};

            src : Rect = .{cast(float32)hold_piece_type * 16, 0, 16, 16};
            dest : Rect = .{cast(float32)preview_pos.x, cast(float32)preview_pos.y, 16, 16};
            draw_texture(src, dest, .{texture_block.width, texture_block.height});
        }
    }

    // Draw score
    glUseProgram(text_shader);
    glUniformMatrix4fv(glGetUniformLocation(text_shader, "projection"), 1, GL_FALSE, xx *mat_projection);
    glUniformMatrix4fv(glGetUniformLocation(text_shader, "view"), 1, GL_FALSE, xx *mat_view);
    glUniformMatrix4fv(glGetUniformLocation(text_shader, "model"), 1, GL_FALSE, xx *mat_model);
    glUniform4f(glGetUniformLocation(text_shader, "color"), 1, 1, 1, 1);
    score_string := sprint("%", score);
    draw_text(score_string, .{400, 200});

    SDL_GL_SwapWindow(window);
    sleep_till_next_update();
    reset_temporary_storage();
}
