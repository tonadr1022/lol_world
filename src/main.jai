VulkanDevice :: struct {
    instance: VkInstance;
    physical_device: VkPhysicalDevice;
    device: VkDevice;
}

APP_NAME :: "lol_world";

device: VulkanDevice;

vk_check :: (result: VkResult) {
    if (result != .SUCCESS) {
        print("Vulkan error: %\n", enum_value_to_name(result));
        exit(1);
    }
}

init_device :: (app_name: string) {
    #if OS != .LINUX {
        print("Unsupported OS\n");
        #assert false;
    }
    libvulkan := dlopen("libvulkan.so.1", RTLD_NOW | RTLD_LOCAL);
    if !libvulkan {
        libvulkan = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
    }
    if !libvulkan {
        print("Failed to load Vulkan library\n");
        exit(1);
    }
    vkGetInstanceProcAddr := dlsym(libvulkan, "vkGetInstanceProcAddr");
    if !vkGetInstanceProcAddr {
        print("Failed to load vkGetInstanceProcAddr\n");
        exit(1);
    }
    vk_load_global_functions(cast(*void)vkGetInstanceProcAddr);

    app_info := VkApplicationInfo.{
        pApplicationName=to_c_string(app_name),
        applicationVersion=VK_MAKE_VERSION(1, 0, 0),
        pEngineName="no_engine",
        engineVersion=VK_MAKE_VERSION(1, 0, 0),
        apiVersion=VK_API_VERSION_1_2,
    };

    inst_info := VkInstanceCreateInfo.{pApplicationInfo=*app_info};

    vk_check(vkCreateInstance(*inst_info, null, *device.instance));
    vk_load_instance_functions(device.instance);
    phys_device_count: u32 = 0;
    vk_check(vkEnumeratePhysicalDevices(device.instance, *phys_device_count, null));
    phys_devices: [..]VkPhysicalDevice;
    array_resize(*phys_devices, phys_device_count);
    vk_check(vkEnumeratePhysicalDevices(device.instance, *phys_device_count, phys_devices.data));
    selected_phys_device: VkPhysicalDevice;
    best_score := 0;
    for phys_device: phys_devices {
        props: VkPhysicalDeviceProperties;
        vkGetPhysicalDeviceProperties(phys_device, *props);
        score := 0;
        if props.deviceType == .DISCRETE_GPU {
            score += 1000;
        }
        score += props.limits.maxImageDimension2D;
    }

}

main :: () {
    print("lol_world\n");
    init_device(APP_NAME);
}

//#import,file "../modules/volk/bindings.jai";
#scope_file 

#import "System";
#import "POSIX";
#import "Vulkan";
#import "Basic";
#import "Reflection";
