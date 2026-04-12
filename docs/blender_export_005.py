"""Blender Character Export - #005 空慧禅师（少林方丈）"""
import bpy
import os
import math

# 清空
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

CHAR_NAME = "空慧禅师"
OUTPUT = "/root/.openclaw/workspace-ui/minimax-output/空慧禅师_粗模.glb"

COLORS = {
    "暗赭红":  (0.545, 0.180, 0.180, 1.0),   # #8B2E2E
    "赤金":    (0.788, 0.635, 0.153, 1.0),   # #C9A227
    "土褐":    (0.361, 0.290, 0.227, 1.0),   # #5C4A3A
    "肤":      (0.820, 0.740, 0.660, 1.0),   # 老年肤色
    "白眉":    (0.85, 0.85, 0.8, 1.0),
}

def mat(name, color, metallic=0.0, roughness=0.5):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    nodes = m.node_tree.nodes; links = m.node_tree.links
    nodes.clear()
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (0,0)
    bsdf.inputs['Base Color'].default_value = color
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    out = nodes.new('ShaderNodeOutputMaterial')
    out.location = (300,0)
    links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    return m

skin = mat("Skin", COLORS["肤"], roughness=0.8)
gold = mat("Gold", COLORS["赤金"], metallic=0.9, roughness=0.2)
robe = mat("Robe", COLORS["暗赭红"], roughness=0.7)
inner = mat("Inner", COLORS["土褐"], roughness=0.8)

# 头部 - 国字脸，老年
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.13, location=(0,0,1.78))
head = bpy.context.active_object
head.name = f"{CHAR_NAME}_Head"
head.scale = (1.0, 0.85, 1.05)  # 国字脸
bpy.ops.object.transform_apply(scale=True)
head.data.materials.append(skin)

# 光头戒疤（6枚，顶面）
for i in range(6):
    angle = i * (2 * math.pi / 6)
    x = 0.05 * math.sin(angle)
    y = 0.05 * math.cos(angle)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.01, depth=0.005, location=(x, y, 1.91))
    scar = bpy.context.active_object
    scar.name = f"{CHAR_NAME}_Scar{i}"
    scar.data.materials.append(mat("Scar", (0.75, 0.65, 0.6, 1.0), roughness=0.9))

# 眉毛（花白）
brow_mat = mat("Brow", COLORS["白眉"], roughness=0.9)
for sx in [0.05, -0.05]:
    bpy.ops.mesh.primitive_cube_add(size=1, location=(sx, 0.11, 1.84))
    b = bpy.context.active_object
    b.name = f"{CHAR_NAME}_Brow"
    b.scale = (0.04, 0.01, 0.005)
    b.rotation_euler = (0, 0, 0.2 if sx > 0 else -0.2)
    bpy.ops.object.transform_apply(scale=True)
    b.data.materials.append(brow_mat)

# 躯干 - 袈裟
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,1.35))
torso = bpy.context.active_object
torso.name = f"{CHAR_NAME}_Torso"
torso.scale = (0.28, 0.18, 0.38)
bpy.ops.object.transform_apply(scale=True)
torso.data.materials.append(robe)

# 袈裟金边（背部简化 - 袈裟披覆）
bpy.ops.mesh.primitive_plane_add(size=0.5, location=(0, -0.18, 1.3))
kasaya = bpy.context.active_object
kasaya.name = f"{CHAR_NAME}_Kasaya"
kasaya.rotation_euler = (math.pi/2, 0, 0)
kasaya.scale = (0.5, 0.7, 1)
bpy.ops.object.transform_apply(scale=True)
kasaya.data.materials.append(robe)

# 金边装饰
bpy.ops.mesh.primitive_torus_add(major_radius=0.22, minor_radius=0.008, location=(0, -0.19, 1.2))
trim = bpy.context.active_object
trim.name = f"{CHAR_NAME}_GoldTrim"
trim.rotation_euler = (math.pi/2, 0, 0)
trim.data.materials.append(gold)

# 腰部（僧袍）
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,0.98))
waist = bpy.context.active_object
waist.name = f"{CHAR_NAME}_Waist"
waist.scale = (0.22, 0.15, 0.22)
bpy.ops.object.transform_apply(scale=True)
waist.data.materials.append(inner)

# 腿
for sx in [0.12, -0.12]:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.9, location=(sx,0,0.45))
    leg = bpy.context.active_object
    leg.name = f"{CHAR_NAME}_Leg"
    leg.data.materials.append(inner)

# 手臂
for sx in [0.3, -0.3]:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.38, location=(sx,0,1.48))
    u = bpy.context.active_object
    u.name = f"{CHAR_NAME}_ArmUpper"
    u.data.materials.append(robe)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.045, depth=0.38, location=(sx*1.08,0,1.1))
    l = bpy.context.active_object
    l.name = f"{CHAR_NAME}_ArmLower"
    l.data.materials.append(robe)

# 锡杖（九环，165cm = 1.65m）
# 杖身
bpy.ops.mesh.primitive_cylinder_add(radius=0.018, depth=1.6, location=(0.32, 0.12, 1.2))
staff = bpy.context.active_object
staff.name = f"{CHAR_NAME}_Staff"
staff.rotation_euler = (0.1, 0, 0.15)
staff.data.materials.append(mat("Staff", (0.5, 0.45, 0.4, 1.0), metallic=0.7, roughness=0.4))

# 九环（杖身右侧，等距分布）
ring_mat = mat("Ring", COLORS["赤金"], metallic=0.9, roughness=0.2)
for i in range(9):
    y = 0.6 - i * 0.15
    bpy.ops.mesh.primitive_torus_add(major_radius=0.035, minor_radius=0.006, location=(0.35, y, 1.2))
    ring = bpy.context.active_object
    ring.name = f"{CHAR_NAME}_Ring{i}"
    ring.rotation_euler = (0, math.pi/2, 0)
    ring.data.materials.append(ring_mat)

# 杖首（简化火焰/莲花座）
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.04, location=(0.34, 0.68, 1.33))
tip = bpy.context.active_object
tip.name = f"{CHAR_NAME}_StaffTip"
tip.data.materials.append(gold)

os.makedirs("/root/.openclaw/workspace-ui/minimax-output", exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUTPUT, export_format='GLB')
print(f"导出完成: {OUTPUT}")
