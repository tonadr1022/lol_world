ShaderStageDesc :: struct {
    path: string;
}

ComputePipelineDesc :: struct {
    using desc: ShaderStageDesc;
}

GraphicsPipelineDesc :: struct {
    ShaderStages: [2]ShaderStageDesc;
}

Pipeline :: struct {

}
