#scope_export

Window :: struct {
    sdl_window: *SDL_Window;
}

window_init :: (window: *Window, app_name: string, width: s32, height: s32) -> bool {
    if !SDL_Init(.VIDEO) {
        print("Failed to initialize SDL: %\n", to_string(SDL_GetError()));
        return false;
    }

    window.sdl_window = SDL_CreateWindow(to_c_string(app_name), width, height, .RESIZABLE | GFX_SDL_EXTRA_INIT_FLAGS | .TRANSPARENT);

    if !window.sdl_window {
        print("Failed to create SDL window: %\n", to_string(SDL_GetError()));
        return false;
    }

    return true;
}

#scope_file

#import "SDL";
#import "Basic";
#import,file "rhi/gfx.jai";
