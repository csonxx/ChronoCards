"""Blender Character Export - #004 玩家化身"""
import bpy, os, math

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

CHAR_NAME = "玩家化身"
OUTPUT = "/root/.openclaw/workspace-ui/minimax-output/玩家化身_粗模.glb"

C = {
    "粗布":  (0.55, 0.48, 0.38, 1.0),   # 粗布黄褐
    "肤":    (0.820, 0.740, 0.660, 1.0),
    "暗":    (0.25, 0.22, 0.18, 1.0),  # 腰带暗色
}

def mat(name, color, metallic=0.0, roughness=0.9):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    n, l = m.node_tree.nodes, m.node_tree.links
    n.clear()
    bsdf = n.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (0,0)
    bsdf.inputs['Base Color'].default_value = color
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    out = n.new('ShaderNodeOutputMaterial'); out.location = (300,0)
    l.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    return m

skin = mat("Skin", C["肤"], roughness=0.8)
cloth = mat("Cloth", C["粗布"], roughness=0.9)
belt_mat = mat("Belt", C["暗"], roughness=0.7)

# 基础素体 - 可自定义，体型中性
# 头部（中性脸）
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.11, location=(0,0,1.83))
h = bpy.context.active_object
h.name = f"{CHAR_NAME}_Head"
h.scale = (0.9, 0.82, 1.0)
bpy.ops.object.transform_apply(scale=True)
h.data.materials.append(skin)

# 简单短发（可替换）
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.115, location=(0,0.01,1.9))
hp = bpy.context.active_object
hp.name = f"{CHAR_NAME}_Hair"
hp.scale = (1, 1, 0.35)
bpy.ops.object.transform_apply(scale=True)
hp.data.materials.append(mat("Hair", (0.1,0.1,0.1,1), roughness=0.9))

# 躯干 - 粗布素衣
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,1.38))
t = bpy.context.active_object
t.name = f"{CHAR_NAME}_Torso"
t.scale = (0.24, 0.14, 0.36)
bpy.ops.object.transform_apply(scale=True)
t.data.materials.append(cloth)

# 腰带（无门派标识，可自定义贴图）
bpy.ops.mesh.primitive_torus_add(major_radius=0.13, minor_radius=0.012, location=(0,0.1,1.2))
blt = bpy.context.active_object
blt.name = f"{CHAR_NAME}_Belt"
blt.rotation_euler = (math.pi/2, 0, 0)
blt.data.materials.append(belt_mat)

# 腰部（粗布）
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,0.98))
w = bpy.context.active_object
w.name = f"{CHAR_NAME}_Waist"
w.scale = (0.2, 0.13, 0.18)
bpy.ops.object.transform_apply(scale=True)
w.data.materials.append(cloth)

# 腿
for sx in [0.1, -0.1]:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.065, depth=0.9, location=(sx,0,0.45))
    bpy.context.active_object.name = f"{CHAR_NAME}_Leg"
    bpy.context.active_object.data.materials.append(cloth)

# 手臂（粗布袖）
for sx in [0.26, -0.26]:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.048, depth=0.35, location=(sx,0,1.47))
    u = bpy.context.active_object
    u.name = f"{CHAR_NAME}_ArmUpper"
    u.data.materials.append(cloth)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.35, location=(sx*1.06,0,1.12))
    l = bpy.context.active_object
    l.name = f"{CHAR_NAME}_ArmLower"
    l.data.materials.append(cloth)

# 空手（无武器，可自定义）
# 手形预留位置
for sx in [0.28, -0.28]:
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.035, location=(sx*1.12,0.05,0.95))
    hd = bpy.context.active_object
    hd.name = f"{CHAR_NAME}_Hand"
    hd.scale = (0.8, 0.6, 1.2)
    bpy.ops.object.transform_apply(scale=True)
    hd.data.materials.append(skin)

os.makedirs("/root/.openclaw/workspace-ui/minimax-output", exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUTPUT, export_format='GLB')
print(f"导出完成: {OUTPUT}")
