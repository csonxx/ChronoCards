"""Blender Character Export - #003 光明右使"""
import bpy, os, math

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

CHAR_NAME = "光明右使"
OUTPUT = "/root/.openclaw/workspace-ui/minimax-output/光明右使_粗模.glb"

C = {
    "铜甲":  (0.361, 0.290, 0.227, 1.0),  # #5C4A3A
    "刀":    (0.239, 0.239, 0.239, 1.0),  # #3D3D3D
    "肤":    (0.780, 0.680, 0.580, 1.0),
    "铁":    (0.35, 0.35, 0.38, 1.0),
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

skin = mat("Skin", C["肤"], roughness=0.7)
armor = mat("Armor", C["铜甲"], metallic=0.6, roughness=0.5)
steel = mat("Steel", C["铁"], metallic=0.9, roughness=0.3)
blade = mat("Blade", C["刀"], metallic=0.95, roughness=0.2)

# 头部 - 短兵头发，圆盾护颈
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.12, location=(0,0,1.85))
h = bpy.context.active_object
h.name = f"{CHAR_NAME}_Head"
h.scale = (0.95, 0.88, 1.0)
bpy.ops.object.transform_apply(scale=True)
h.data.materials.append(skin)

# 短头发
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.13, location=(0,0,1.95))
hair = bpy.context.active_object
hair.name = f"{CHAR_NAME}_Hair"
hair.scale = (1, 1, 0.3)
bpy.ops.object.transform_apply(scale=True)
hair.data.materials.append(mat("Hair", (0.08,0.08,0.1,1), roughness=0.9))

# 肩甲
for sx in [0.28, -0.28]:
    bpy.ops.mesh.primitive_cube_add(size=1, location=(sx,0,1.62))
    sp = bpy.context.active_object
    sp.name = f"{CHAR_NAME}_ShoulderPlate"
    sp.scale = (0.14, 0.18, 0.08)
    bpy.ops.object.transform_apply(scale=True)
    sp.data.materials.append(armor)

# 躯干 - 铜甲
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,1.35))
t = bpy.context.active_object
t.name = f"{CHAR_NAME}_Torso"
t.scale = (0.28, 0.18, 0.4)
bpy.ops.object.transform_apply(scale=True)
t.data.materials.append(armor)

# 胸甲细节
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0.08,1.4))
pc = bpy.context.active_object
pc.name = f"{CHAR_NAME}_ChestPlate"
pc.scale = (0.16, 0.06, 0.15)
bpy.ops.object.transform_apply(scale=True)
pc.data.materials.append(steel)

# 腰
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,0.96))
w = bpy.context.active_object
w.name = f"{CHAR_NAME}_Waist"
w.scale = (0.22, 0.15, 0.2)
bpy.ops.object.transform_apply(scale=True)
w.data.materials.append(armor)

# 腿甲
for sx in [0.12, -0.12]:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.9, location=(sx,0,0.45))
    lg = bpy.context.active_object
    lg.name = f"{CHAR_NAME}_Leg"
    lg.data.materials.append(armor)

# 手臂甲
for sx in [0.3, -0.3]:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.055, depth=0.36, location=(sx,0,1.48))
    u = bpy.context.active_object
    u.name = f"{CHAR_NAME}_ArmUpper"
    u.data.materials.append(armor)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.045, depth=0.36, location=(sx*1.08,0,1.12))
    l = bpy.context.active_object
    l.name = f"{CHAR_NAME}_ArmLower"
    l.data.materials.append(armor)

# 斩马刀（右手，巨大刀身）
# 刀柄
bpy.ops.mesh.primitive_cylinder_add(radius=0.015, depth=0.28, location=(0.35,0,1.3))
hilt = bpy.context.active_object
hilt.name = f"{CHAR_NAME}_SwordHilt"
hilt.rotation_euler = (0, 0, -0.3)
hilt.data.materials.append(mat("Hilt", (0.2,0.15,0.1,1), roughness=0.8))
# 刀鞘
bpy.ops.mesh.primitive_cylinder_add(radius=0.022, depth=0.8, location=(0.32,0.03,1.0))
scab = bpy.context.active_object
scab.name = f"{CHAR_NAME}_Scabbard"
scab.rotation_euler = (0, 0, -0.25)
scab.data.materials.append(steel)
# 刀身（超长宽刀）
bpy.ops.mesh.primitive_cube_add(size=1, location=(0.38,0.04,1.55))
bl = bpy.context.active_object
bl.name = f"{CHAR_NAME}_Blade"
bl.scale = (0.015, 0.08, 0.75)
bl.rotation_euler = (0, 0, -0.25)
bpy.ops.object.transform_apply(scale=True)
bl.data.materials.append(blade)

# 圆盾（左手）
bpy.ops.mesh.primitive_cylinder_add(radius=0.22, depth=0.03, location=(-0.3,0.08,1.35))
sh = bpy.context.active_object
sh.name = f"{CHAR_NAME}_Shield"
sh.rotation_euler = (math.pi/2, 0, 0)
sh.data.materials.append(steel)
# 盾心
bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.04, location=(-0.3,0.08,1.35))
shk = bpy.context.active_object
shk.name = f"{CHAR_NAME}_ShieldBoss"
shk.rotation_euler = (math.pi/2, 0, 0)
shk.data.materials.append(mat("Boss", C["刀"], metallic=0.9, roughness=0.2))

os.makedirs("/root/.openclaw/workspace-ui/minimax-output", exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUTPUT, export_format='GLB')
print(f"导出完成: {OUTPUT}")
