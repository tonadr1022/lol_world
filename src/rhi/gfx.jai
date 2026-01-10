gfx_init :: (app_name: string, window: *Window) -> bool {
    result := init_device(app_name);
    return result;
}

#if USE_VULKAN {
    GFX_SDL_EXTRA_INIT_FLAGS :: SDL_WindowFlags.VULKAN;
}

#scope_file

#import "SDL";

USE_VULKAN :: true;

#if USE_VULKAN {
    #import,file "vulkan/module.jai";
} else {
    #assert false, "Only Vulkan is supported currently.";
}
