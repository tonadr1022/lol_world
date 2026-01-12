Swapchain :: struct {
    swapchain: VkSwapchainKHR;
    width, height: u32;
    format: VkFormat;
    images: [5]VkImage;
    img_cnt: u32;
}

swapchain_recreate :: (device: *Device, old_swapchain: *Swapchain, curr_width_px: u32, curr_height_px: u32, vsync_enabled: bool) -> bool {
    capabilities: VkSurfaceCapabilitiesKHR;
    vk_check(vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device.physical_device, device.surface, *capabilities));

    selected_surface_format: VkSurfaceFormatKHR;
    {
        surface_format_cnt: u32;
        vk_check(vkGetPhysicalDeviceSurfaceFormatsKHR(device.physical_device, device.surface, *surface_format_cnt, null));
        formats: [20]VkSurfaceFormatKHR;
        if surface_format_cnt > 20 {
            print("Vulkan: swapchain_init: Too many surface formats.\n");
            return false;
        }
        vk_check(vkGetPhysicalDeviceSurfaceFormatsKHR(device.physical_device, device.surface, *surface_format_cnt, formats.data));

        for 0..surface_format_cnt-1 {
            format := formats[it];
            if format.format == .B8G8R8A8_SRGB && format.colorSpace == .SRGB_NONLINEAR {
                selected_surface_format = format;
                break;
            }
        }

        if selected_surface_format.format == .UNDEFINED {
            selected_surface_format = formats[0];
        }
    }

    selected_presentation_mode: VkPresentModeKHR;
    {
        presentation_mode_cnt: u32;
        vk_check(vkGetPhysicalDeviceSurfacePresentModesKHR(device.physical_device, device.surface, *presentation_mode_cnt, null));
        modes: [10]VkPresentModeKHR;
        if presentation_mode_cnt > 10 {
            print("Vulkan: swapchain_init: Too many presentation modes.\n");
            return false;
        }
        vk_check(vkGetPhysicalDeviceSurfacePresentModesKHR(device.physical_device, device.surface, *presentation_mode_cnt, modes.data));
        selected_presentation_mode = .FIFO;
        for 0..presentation_mode_cnt-1 {
            mode := modes[it];
            if mode == .IMMEDIATE && !vsync_enabled {
                selected_presentation_mode = mode;
                break;
            }
            if mode == .MAILBOX && vsync_enabled {
                selected_presentation_mode = mode;
                break;
            }
        }
    }

    width, height: u32;
    {
        if capabilities.currentExtent.width != U32_MAX {
            width = capabilities.currentExtent.width;
            height = capabilities.currentExtent.height;
        } else {
            width = clamp(curr_width_px, capabilities.minImageExtent.width, capabilities.maxImageExtent.width);
            height = clamp(curr_height_px, capabilities.minImageExtent.height, capabilities.maxImageExtent.height);

        }
    }

    img_count: u32 = capabilities.minImageCount + 1;
    if capabilities.maxImageCount > 0 && img_count > capabilities.maxImageCount {
        img_count = capabilities.maxImageCount;
    }

    cinfo := VkSwapchainCreateInfoKHR.{
        surface=device.surface,
        minImageCount=img_count,
        imageFormat=selected_surface_format.format,
        imageColorSpace=selected_surface_format.colorSpace,
        imageExtent=.{width, height},
        imageArrayLayers=1,
        imageUsage=.COLOR_ATTACHMENT,
        imageSharingMode=.EXCLUSIVE,
        preTransform=capabilities.currentTransform,
        compositeAlpha=.OPAQUE,
        presentMode=selected_presentation_mode,
        clipped=VK_TRUE,
        oldSwapchain=old_swapchain.swapchain,
    };

    new_swap := *device.swapchain;
    new_swap.width = width;
    new_swap.height = height;
    new_swap.swapchain = null;
    new_swap.format = selected_surface_format.format;

    vk_check(vkCreateSwapchainKHR(device.device, *cinfo, null, *new_swap.swapchain));

    vk_check(vkGetSwapchainImagesKHR(device.device, new_swap.swapchain, *new_swap.img_cnt, null));
    vk_check(vkGetSwapchainImagesKHR(device.device, new_swap.swapchain, *new_swap.img_cnt, new_swap.images.data));

    return true;
}

swapchain_init :: (device: *Device, curr_framebuffer_width_px: u32, curr_framebuffer_height_px: u32, vsync_enabled: bool) -> bool {
    old_swapchain := device.swapchain;
    return swapchain_recreate(device, *old_swapchain, curr_framebuffer_width_px, curr_framebuffer_height_px, vsync_enabled);
}

#scope_file

#import "Math";
#import "Vulkan";
