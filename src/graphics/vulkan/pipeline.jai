create_graphics_pipeline :: (desc: *GraphicsPipelineDesc) -> Pipeline {
    return {};
}

create_compute_pipeline :: (desc: *ComputePipelineDesc) -> Pipeline {
    // read file into string
    file, open := file_open(desc.path);
    if !open {
        print("Vulkan: Failed to open shader file: %\n", desc.path);
    }
    words: [..]u32;
    length, ok := file_length(file);
    assert(ok);
    array_resize(*words, length / type_info(u32).runtime_size);
    ok, bytes_read := file_read(file, words.data, length);
    if !ok {
        print("Vulkan: Failed to load shader file: %\n", desc.path);
    }
    return {};
}

#scope_file

load_spirv_shader :: () {

}

#import "File";
#import "Basic";
#load "../rhi/pipeline.jai";
