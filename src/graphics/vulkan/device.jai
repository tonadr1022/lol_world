Queue :: struct {
    queueFamilyIndex: u32;
    queue: VkQueue;
}

Device :: struct {
    instance: VkInstance;
    physical_device: VkPhysicalDevice;
    debug_messenger: VkDebugUtilsMessengerEXT;
    device: VkDevice;
    surface: VkSurfaceKHR;
    swapchain: Swapchain;

    PerFrame :: struct {
        command_pool: VkCommandPool;
        cmd_buf: VkCommandBuffer;
    }

    per_frames: [FRAMES_IN_FLIGHT]PerFrame;

    MAX_QUEUES :: 1; // only graphics for now

    queues: [MAX_QUEUES]Queue;
    curr_frame_in_flight: u64;
    curr_frame: u64;

}
