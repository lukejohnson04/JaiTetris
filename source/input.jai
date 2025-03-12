Input_State :: struct {
    is_pressed : [256] bool;
    just_pressed : [256] bool;
    just_released : [256] bool;

    mouse_just_pressed : bool;
    mouse_just_released: bool;
    mouse_pressed : bool;

    mouse_motion : v2i;
}

input := Input_State.{};

poll_input :: (running : *bool) {
    memset(*input.just_pressed, 0, size_of(bool) * 256);
    memset(*input.just_released, 0, size_of(bool) * 256);
    input.mouse_just_pressed = false;
    input.mouse_just_released = false;

    e : SDL_Event;
    while SDL_PollEvent(*e) {
        if e.type == SDL_KEYDOWN && e.key.repeat == 0 {
            input.just_pressed[e.key.keysym.scancode] = true;
            input.is_pressed[e.key.keysym.scancode] = true;
        } else if e.type == SDL_KEYUP {
            input.just_released[e.key.keysym.scancode] = true;
            input.is_pressed[e.key.keysym.scancode] = false;
        }

        if e.type == SDL_MOUSEBUTTONDOWN && e.button.button == SDL_BUTTON_LEFT {
            input.mouse_pressed = true;
            input.mouse_just_pressed = true;
        } else if e.type == SDL_MOUSEBUTTONUP && e.button.button == SDL_BUTTON_LEFT {
            input.mouse_pressed = false;
            input.mouse_just_released = true;
        } else if e.type == SDL_MOUSEMOTION {
            input.mouse_motion.x = e.motion.xrel;
            input.mouse_motion.y = e.motion.yrel;
        }

        if e.type == SDL_QUIT {
            <<running = false;
            return;
        }
    }
}

get_mouse_position :: () -> s32, s32 {
    mouse_x, mouse_y : s32;
    SDL_GetMouseState(*mouse_x, *mouse_y);
    return mouse_x, mouse_y;
}
