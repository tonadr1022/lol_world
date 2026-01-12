APP_NAME :: "lol_world";

window: *SDL_Window;

main :: () {
    print("lol_world!\n");

    if !SDL_Init(.VIDEO) {
        print("Failed to initialize SDL: %\n", to_string(SDL_GetError()));
        exit(1);
    }

    window = SDL_CreateWindow(to_c_string(APP_NAME), 800, 800, .RESIZABLE | .TRANSPARENT | .VULKAN);

    if !window {
        print("Failed to create SDL window: %\n", to_string(SDL_GetError()));
        exit(1);
    }

    gfx_init(APP_NAME, window);

    run();
    shutdown();
}

run :: () { 
    should_quit := false;
    while !should_quit {
        event: SDL_Event;
        while SDL_PollEvent(*event) {
            if event.type == .QUIT {
                should_quit = true;
            }
        }
        gfx_render_frame();
        SDL_Delay(16);
    }
}

shutdown :: () {
   gfx_shutdown();
   SDL_DestroyWindow(window);
   SDL_Quit();
}

#scope_file

#load "graphics/gfx.jai";
#import "Basic";
#import "SDL";
