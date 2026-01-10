gfx_init :: (app_name: string) -> bool {
    result := init_device(app_name);
    return result;
}

#scope_file

USE_VULKAN :: true;

#if USE_VULKAN {
    #import,file "vulkan/module.jai";
} else {
    #assert false, "Only Vulkan is supported currently.";
}
