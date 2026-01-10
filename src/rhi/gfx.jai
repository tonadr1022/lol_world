gfx_init :: (app_name: string) {
    init_device(app_name);
}

#scope_file

USE_VULKAN :: true;

#if USE_VULKAN {
    #import,file "vulkan/module.jai";
} else {
    #assert false, "Only Vulkan is supported currently.";
}
