#scope_file

Renderer :: struct {
    window: *SDL_Window;
}

renderer: Renderer;

#scope_export

gfx_init :: (app_name: string, window: *SDL_Window) -> bool {
    renderer.window = window;
    result := BE.init(app_name, window);
    return result;
}

gfx_shutdown :: () {
    BE.shutdown();
}

gfx_render_frame :: () {
    BE.begin_frame();
    BE.begin_main_cmd_buf();
    BE.end_main_cmd_buf();
    BE.end_frame();
}

#scope_file

#import "SDL";

USE_VULKAN :: true;

#if USE_VULKAN {
    BE :: #import,file "vulkan/module.jai";
} else {
    #assert false, "Only Vulkan is supported currently.";
}

#import "Basic";
