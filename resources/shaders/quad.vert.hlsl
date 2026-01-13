#include "root_sig.h"
#include "shared_quad.h"

[RootSignature(ROOT_SIGNATURE)] float4 main(uint vert_id : SV_VertexID) : SV_Target0 {
    VOut o;
    o.uv = float2(vert_id << 1) & 2, vert_id & 2);
    o.position = float4(o.uv * 2.0 - 1.0, 0.1, 1.0);
}
