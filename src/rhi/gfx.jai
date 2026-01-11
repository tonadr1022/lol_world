gfx_init :: (app_name: string, window: *SDL_Window) -> bool {
    result := Device.init(app_name, window);
    return result;
}

gfx_shutdown :: () {
    Device.shutdown();
}

#scope_file

#import "SDL";

USE_VULKAN :: true;

#if USE_VULKAN {
    Device :: #import,file "vulkan/module.jai";
} else {
    #assert false, "Only Vulkan is supported currently.";
}
