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

load_vulkan_library :: () {
    // TODO: this is incredibly jank.
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
}

init_vulkan_device :: (app_name: string, min_vulkan_api_version: u32, required_device_extensions: []string) {
    #if OS != .LINUX {
        print("Unsupported OS\n");
        #assert false;
    }

    load_vulkan_library();
    app_info := VkApplicationInfo.{
        pApplicationName=to_c_string(app_name),
        applicationVersion=VK_MAKE_VERSION(1, 0, 0),
        pEngineName="no_engine",
        engineVersion=VK_MAKE_VERSION(1, 0, 0),
        apiVersion=min_vulkan_api_version,
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

    queue_families: [..]VkQueueFamilyProperties;
    defer array_free(queue_families);

    available_extensions: [..]VkExtensionProperties;
    defer array_free(available_extensions);

    for phys_device: phys_devices {
        props: VkPhysicalDeviceProperties;
        vkGetPhysicalDeviceProperties(phys_device, *props);

        if props.apiVersion < min_vulkan_api_version continue;

        queue_family_count: u32;
        vkGetPhysicalDeviceQueueFamilyProperties(phys_device, *queue_family_count, null);
        array_resize(*queue_families, queue_family_count);
        vkGetPhysicalDeviceQueueFamilyProperties(phys_device, *queue_family_count, queue_families.data);

        has_graphics := false;
        for qfp: queue_families {
            if qfp.queueFlags & .GRAPHICS {
                has_graphics = true;
                break;
            }
        }
        if !has_graphics continue;

        ext_count: u32;
        vkEnumerateDeviceExtensionProperties(phys_device, null, *ext_count, null);
        array_resize(*available_extensions, ext_count);
        vkEnumerateDeviceExtensionProperties(phys_device, null, *ext_count, available_extensions.data);

        found_all_extensions := true;
        for req: required_device_extensions {
            found := false;
            for avail: available_extensions {
                if to_string(avail.extensionName.data) == req {
                    found = true;
                    break;
                }
            }
            if !found {
                found_all_extensions = false;
                break;
            }
        }

        if !found_all_extensions {
            continue;
        }

        score := 0;

        if props.deviceType == .DISCRETE_GPU {
            score += 1;
        }
        if score > best_score {
            best_score = score;
            selected_phys_device = phys_device;
        }
    }

    if !selected_phys_device {
        print("failed to find a suitable GPU!\n");
        exit(1);
    }

    device.physical_device = selected_phys_device;

    props: VkPhysicalDeviceProperties;
    vkGetPhysicalDeviceProperties(device.physical_device, *props);

    device_name := to_string(props.deviceName.data);
    print("Selected Physical Device: %\n", device_name);
    print("Device Type: %\n", props.deviceType);
}

init_device :: (app_name: string) {
    required_extensions :: string.[
        VK_KHR_SWAPCHAIN_EXTENSION_NAME,
        VK_KHR_SPIRV_1_4_EXTENSION_NAME,
        VK_KHR_SYNCHRONIZATION_2_EXTENSION_NAME,
        VK_KHR_CREATE_RENDERPASS_2_EXTENSION_NAME
    ];
    init_vulkan_device(app_name, VK_API_VERSION_1_4, required_extensions);
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
