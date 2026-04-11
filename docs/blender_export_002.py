"""Blender Character Export - #002 光明左使"""
import bpy, os, math

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

CHAR_NAME = "光明左使"
OUTPUT = "/root/.openclaw/workspace-ui/minimax-output/光明左使_粗模.glb"

C = {
    "漂白":  (0.961, 0.941, 0.910, 1.0),  # #F5F0E8
    "朱红":  (0.608, 0.137, 0.208, 1.0),  # #9B2335
    "铜":    (0.360, 0.270, 0.200, 1.0),
    "肤":    (0.840, 0.750, 0.650, 1.0),
}

def mat(name, color, metallic=0.0, roughness=0.5):
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

skin = mat("Skin", C["肤"], roughness=0.75)
robe = mat("Robe", C["漂白"], roughness=0.6)
accent = mat("Accent", C["朱红"], roughness=0.5)
staff_mat = mat("Staff", C["铜"], metallic=0.5, roughness=0.4)

# 头部 - 谋臣气质，棱角偏软
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.115, location=(0,0,1.83))
h = bpy.context.active_object
h.name = f"{CHAR_NAME}_Head"
h.scale = (0.9, 0.8, 1.05)
bpy.ops.object.transform_apply(scale=True)
h.data.materials.append(skin)

# 发髻（高束）
bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.12, location=(0,0.02,1.98))
bun = bpy.context.active_object
bun.name = f"{CHAR_NAME}_Bun"
bun.data.materials.append(mat("Hair", (0.1,0.1,0.1,1), roughness=0.9))

# 玉簪
bpy.ops.mesh.primitive_cylinder_add(radius=0.008, depth=0.15, location=(0,0.05,2.02))
pin = bpy.context.active_object
pin.name = f"{CHAR_NAME}_JadePin"
pin.rotation_euler = (0.1, 0, 0)
pin.data.materials.append(mat("Jade", (0.3,0.5,0.3,1), metallic=0.3, roughness=0.3))

# 躯干 - 宽袖素袍
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,1.38))
t = bpy.context.active_object
t.name = f"{CHAR_NAME}_Torso"
t.scale = (0.28, 0.16, 0.38)
bpy.ops.object.transform_apply(scale=True)
t.data.materials.append(robe)

# 领口朱红线
bpy.ops.mesh.primitive_torus_add(major_radius=0.12, minor_radius=0.005, location=(0,0.1,1.76))
trim = bpy.context.active_object
trim.name = f"{CHAR_NAME}_CollarTrim"
trim.data.materials.append(accent)

# 腰
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,0.98))
w = bpy.context.active_object
w.name = f"{CHAR_NAME}_Waist"
w.scale = (0.2, 0.14, 0.2)
bpy.ops.object.transform_apply(scale=True)
w.data.materials.append(robe)

# 宽袖（袖口外张）
for sx in [0.35, -0.35]:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.4, location=(sx,0,1.45))
    s = bpy.context.active_object
    s.name = f"{CHAR_NAME}_Sleeve"
    s.data.materials.append(robe)

# 腿
for sx in [0.1, -0.1]:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.9, location=(sx,0,0.45))
    bpy.context.active_object.name = f"{CHAR_NAME}_Leg"
    bpy.context.active_object.data.materials.append(robe)

# 拂尘（左手握持）
bpy.ops.mesh.primitive_cylinder_add(radius=0.012, depth=0.9, location=(-0.3,0.08,1.25))
stk = bpy.context.active_object
stk.name = f"{CHAR_NAME}_WhiskStaff"
stk.rotation_euler = (0.15, 0, 0.1)
stk.data.materials.append(staff_mat)

# 拂尘毛（扇形散开）
for i in range(12):
    angle = (i / 12) * math.pi * 0.6 - math.pi * 0.3
    bx = -0.3 + 0.08 * math.sin(angle)
    by = 0.08 + 0.08 * math.cos(angle)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.004, depth=0.18, location=(bx, by, 1.75))
    br = bpy.context.active_object
    br.name = f"{CHAR_NAME}_WhiskBristle{i}"
    br.rotation_euler = (angle + 0.3, 0, 0.2)
    br.data.materials.append(mat("Bristle", (0.9,0.88,0.8,1), roughness=0.9))

os.makedirs("/root/.openclaw/workspace-ui/minimax-output", exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUTPUT, export_format='GLB')
print(f"导出完成: {OUTPUT}")
