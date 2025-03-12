
window : *SDL_Window;
TILE_SIZE :: 32;
WINDOW_WIDTH :: MAP_WIDTH * TILE_SIZE + 160;
WINDOW_HEIGHT :: MAP_HEIGHT * TILE_SIZE;
VSYNC :: true;

// Simple entry point layer for the program.
// The main game loop is in update_and_render in game.jai
main :: () {
    if SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0 {
        print("Failed to initialize SDL!\n");
        return;
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, cast(s32) SDL_GL_CONTEXT_PROFILE_CORE);

    window = SDL_CreateWindow("Hello",
                              SDL_WINDOWPOS_UNDEFINED,
                              SDL_WINDOWPOS_UNDEFINED,
                              WINDOW_WIDTH,
                              WINDOW_HEIGHT,
                              SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);

    glContext : SDL_GLContext = SDL_GL_CreateContext(window);
    if !glContext {
        print("Error making SDL GL context!\n");
    }

    SDL_GL_MakeCurrent(window, glContext);
    gl_load(*gl);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    {
        err := glGetError();
        if err != GL_NO_ERROR {
            print("Error: %\n", err);
            return;
        }
    }

    SDL_GL_SetSwapInterval(cast(s32) VSYNC);
    screenSurface := SDL_GetWindowSurface(window);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    on_startup();

    running := true;

    while running {
        poll_input(*running);
        update_and_render(*running);
    }

    SDL_DestroyWindow(window);
    SDL_Quit();
}

#import "Windows";
#import "Basic";
#import "String";
#import "SDL";
#import "GL";
#import "File";
#import "Simp";
#import "Random";
#import "Math";

#import "freetype-2.12.1";

#load "source/math.jai";
#load "source/input.jai";
#load "source/game.jai";
#load "source/render/shader.jai";
#load "source/render/text.jai";
#load "source/render/render.jai";