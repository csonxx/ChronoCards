"""Blender Character Export - #001 沈墨渊"""
import bpy
import os

# 清空
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

import math

CHAR_NAME = "沈墨渊"
OUTPUT = "/root/.openclaw/workspace-ui/minimax-output/沈墨渊_粗模.glb"

COLORS = {
    "玄黑":    (0.102, 0.102, 0.102, 1.0),
    "深赭":    (0.169, 0.106, 0.071, 1.0),
    "暗铜":    (0.290, 0.216, 0.157, 1.0),
    "赤金":    (0.788, 0.635, 0.153, 1.0),
    "朱砂":    (0.608, 0.137, 0.208, 1.0),
    "肤":      (0.831, 0.722, 0.588, 1.0),
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

# 肤色
skin = mat("Skin", COLORS["肤"], metallic=0, roughness=0.8)

# 头部
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.12, location=(0,0,2.03))
head = bpy.context.active_object
head.name = f"{CHAR_NAME}_Head"
head.scale = (0.85, 0.75, 1.1)
bpy.ops.object.transform_apply(scale=True)
head.data.materials.append(skin)

# 疤痕
bpy.ops.mesh.primitive_cube_add(size=1, location=(0.1, 0.08, 2.04))
scar = bpy.context.active_object
scar.name = f"{CHAR_NAME}_Scar"
scar.scale = (0.03, 0.004, 0.012)
scar.rotation_euler = (0, 0.5, 0.8)
bpy.ops.object.transform_apply(scale=True)
scar_mat = mat("Scar", (0.82, 0.73, 0.67, 1.0), roughness=0.9)
scar.data.materials.append(scar_mat)

# 躯干
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,1.38))
torso = bpy.context.active_object
torso.name = f"{CHAR_NAME}_Torso"
torso.scale = (0.26, 0.16, 0.38)
bpy.ops.object.transform_apply(scale=True)
torso_mat = mat("Torso", COLORS["深赭"], roughness=0.7)
torso.data.materials.append(torso_mat)

# 腰
bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,1.0))
waist = bpy.context.active_object
waist.name = f"{CHAR_NAME}_Waist"
waist.scale = (0.19, 0.13, 0.22)
bpy.ops.object.transform_apply(scale=True)
waist.data.materials.append(torso_mat)

# 腿
for sx in [0.1, -0.1]:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.9, location=(sx,0,0.45))
    leg = bpy.context.active_object
    leg.name = f"{CHAR_NAME}_Leg"
    leg.data.materials.append(torso_mat)

# 手臂
for sx in [0.28, -0.28]:
    bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.35, location=(sx,0,1.5))
    u = bpy.context.active_object
    u.name = f"{CHAR_NAME}_ArmUpper"
    u.data.materials.append(torso_mat)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.35, location=(sx*1.05,0,1.15))
    l = bpy.context.active_object
    l.name = f"{CHAR_NAME}_ArmLower"
    l.data.materials.append(torso_mat)

# 发冠
crown_mat = mat("Crown", COLORS["暗铜"], metallic=0.75, roughness=0.35)
bpy.ops.mesh.primitive_cylinder_add(radius=0.085, depth=0.06, location=(0,0,2.16))
cb = bpy.context.active_object
cb.name = f"{CHAR_NAME}_Crown"
cb.data.materials.append(crown_mat)
for i, angle in enumerate([-0.3, 0, 0.3]):
    bpy.ops.mesh.primitive_cylinder_add(radius=0.007, depth=0.055, location=(0.03*math.sin(angle), 0.03*math.cos(angle), 2.22))
    f = bpy.context.active_object
    f.name = f"{CHAR_NAME}_CrownFlame{i}"
    f.data.materials.append(crown_mat)

# 圣火令 (六角)
token_mat = mat("Token", COLORS["赤金"], metallic=0.9, roughness=0.25)
bpy.ops.mesh.primitive_cylinder_add(radius=0.042, depth=0.018, vertices=6, location=(-0.3, 0.08, 1.15))
tok = bpy.context.active_object
tok.name = f"{CHAR_NAME}_SacredFireToken"
tok.rotation_euler = (0, math.pi/2, 0)
tok.data.materials.append(token_mat)

# 大氅 (背部简化)
cloak_mat = mat("Cloak", COLORS["暗铜"], metallic=0.2, roughness=0.6)
bpy.ops.mesh.primitive_plane_add(size=0.5, location=(0, -0.16, 1.2))
cl = bpy.context.active_object
cl.name = f"{CHAR_NAME}_Cloak"
cl.rotation_euler = (math.pi/2, 0, 0)
cl.scale = (0.4, 0.6, 1)
bpy.ops.object.transform_apply(scale=True)
cl.data.materials.append(cloak_mat)

# 圣火纹徽章 (背部)
emblem_mat = mat("Emblem", COLORS["朱砂"], metallic=0.3, roughness=0.4)
bpy.ops.mesh.primitive_plane_add(size=0.15, location=(0, -0.17, 1.3))
em = bpy.context.active_object
em.name = f"{CHAR_NAME}_BackEmblem"
em.rotation_euler = (math.pi/2, 0, 0)
em.data.materials.append(emblem_mat)

os.makedirs("/root/.openclaw/workspace-ui/minimax-output", exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUTPUT, export_format='GLB')
print(f"导出完成: {OUTPUT}")
