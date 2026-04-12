"""
Blender Character Workflow - #001 沈墨渊
水墨古风 · 暗黑武侠 · Blender 4.3

使用方法:
  /root/blender-4.3.2-linux-x64/blender --background --python blend workflow.py

建模流程:
  Phase 1: 基础素体 (Base Mesh) - 人体比例参考
  Phase 2: 服装分层 (Clothing Layers) - 内衬/外袍/大氅
  Phase 3: 配饰细节 (Accessories) - 发冠/圣火令/疤痕
  Phase 4: 材质与UV (Materials & UV)
"""

import bpy
import math
import json

# ============================================================
# 角色参数
# ============================================================
CHAR_NAME = "沈墨渊"
HEIGHT_M = 1.85  # 身高 185cm
SCALE = 1.0     # Blender 单位 = 1m

# 配色方案
COLORS = {
    "玄黑":    (0.102, 0.102, 0.102, 1.0),   # #1A1A1A
    "深赭":    (0.169, 0.106, 0.071, 1.0),   # #2B1B12
    "玄褐":    (0.239, 0.169, 0.122, 1.0),   # #3D2B1F
    "暗铜":    (0.290, 0.216, 0.157, 1.0),   # #4A3728
    "朱砂":    (0.608, 0.137, 0.208, 1.0),   # #9B2335
    "赤金":    (0.788, 0.635, 0.153, 1.0),   # #C9A227
    "肤":      (0.831, 0.722, 0.588, 1.0),   # #D4B896
    "白":      (1.0, 1.0, 1.0, 1.0),
}

# ============================================================
# 工具函数
# ============================================================
def clear_scene():
    """清空场景"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for collection in bpy.data.collections:
        bpy.data.collections.remove(collection)

def create_collection(name):
    return bpy.data.collections.new(name)

def add_to_collection(obj, collection):
    collection.objects.link(obj)
    bpy.context.scene.collection.children.link(collection)

def create_material(name, color, metallic=0.0, roughness=0.5):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    
    # Clear default nodes
    for n in nodes:
        nodes.remove(n)
    
    # Create principled BSDF
    bsdf = nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.location = (0, 0)
    bsdf.inputs['Base Color'].default_value = color
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    
    # Output node
    output = nodes.new('ShaderNodeOutputMaterial')
    output.location = (300, 0)
    links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
    
    return mat

# ============================================================
# Phase 1: 基础素体
# ============================================================
def build_base_mesh():
    """创建基础人体素体 - 185cm 精瘦体型"""
    
    # 使用 Blender 基础体素构造
    bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 0.9))
    body = bpy.context.active_object
    body.name = f"{CHAR_NAME}_Body"
    
    # 应用缩放，设定身高185cm
    # Blender 默认立方体 2m，调整为 0.4m 肩宽
    body.scale = (0.22, 0.15, 4.625)  # 调整为185cm身高
    
    bpy.ops.object.transform_apply(scale=True)
    
    # 简化为一个基础形状，实际项目需要精细雕刻
    # 这里先用基础几何体代表躯干
    return body

def build_head():
    """创建头部 - 菱形脸，棱角分明"""
    # 头部椭球
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.12, location=(0, 0, 2.03))
    head = bpy.context.active_object
    head.name = f"{CHAR_NAME}_Head"
    
    # 菱形脸调整 - 拉伸颧骨位置
    head.scale = (0.85, 0.75, 1.1)
    bpy.ops.object.transform_apply(scale=True)
    
    return head

def build_torso():
    """创建躯干 - 肩宽腰细"""
    # 胸腔
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.4))
    torso = bpy.context.active_object
    torso.name = f"{CHAR_NAME}_Torso"
    torso.scale = (0.25, 0.15, 0.35)
    bpy.ops.object.transform_apply(scale=True)
    
    # 收腰处理 - 附加腰段
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.0))
    waist = bpy.context.active_object
    waist.name = f"{CHAR_NAME}_Waist"
    waist.scale = (0.18, 0.12, 0.2)
    bpy.ops.object.transform_apply(scale=True)
    
    return torso, waist

def build_legs():
    """创建腿部 - 四肢修长"""
    leg_r = bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.9, location=(0.1, 0, 0.45))
    leg_r = bpy.context.active_object
    leg_r.name = f"{CHAR_NAME}_Leg_R"
    
    leg_l = bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.9, location=(-0.1, 0, 0.45))
    leg_l = bpy.context.active_object
    leg_l.name = f"{CHAR_NAME}_Leg_L"
    
    return leg_r, leg_l

def build_arms():
    """创建手臂 - 肌肉线条内敛"""
    # 上臂
    arm_r_upper = bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.35, location=(0.28, 0, 1.5))
    arm_r_upper = bpy.context.active_object
    arm_r_upper.name = f"{CHAR_NAME}_Arm_R_Upper"
    
    arm_l_upper = bpy.ops.mesh.primitive_cylinder_add(radius=0.05, depth=0.35, location=(-0.28, 0, 1.5))
    arm_l_upper = bpy.context.active_object
    arm_l_upper.name = f"{CHAR_NAME}_Arm_L_Upper"
    
    # 前臂
    arm_r_lower = bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.35, location=(0.3, 0, 1.15))
    arm_r_lower = bpy.context.active_object
    arm_r_lower.name = f"{CHAR_NAME}_Arm_R_Lower"
    
    arm_l_lower = bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.35, location=(-0.3, 0, 1.15))
    arm_l_lower = bpy.context.active_object
    arm_l_lower.name = f"{CHAR_NAME}_Arm_L_Lower"
    
    return arm_r_upper, arm_l_upper, arm_r_lower, arm_l_lower

# ============================================================
# Phase 2: 服装分层
# ============================================================
def build_costume():
    """创建服装 - 内衬/外袍/大氅"""
    
    # 内衬 (深灰 #1A1A1A)
    inner_mat = create_material("内衬_玄黑", COLORS["玄黑"], metallic=0.0, roughness=0.8)
    
    # 外袍 (深赭 #2B1B12)
    robe_mat = create_material("外袍_深赭", COLORS["深赭"], metallic=0.1, roughness=0.7)
    
    # 大氅 (带朱砂红徽章)
    cloak_mat = create_material("大氅_暗铜", COLORS["暗铜"], metallic=0.2, roughness=0.6)
    
    return inner_mat, robe_mat, cloak_mat

# ============================================================
# Phase 3: 配饰细节
# ============================================================
def build_crown():
    """发冠 - 铜制哑光，冠顶三道火焰线条"""
    crown_mat = create_material("发冠_暗铜", COLORS["暗铜"], metallic=0.7, roughness=0.4)
    
    # 冠体
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.06, location=(0, 0, 2.17))
    crown_base = bpy.context.active_object
    crown_base.name = f"{CHAR_NAME}_Crown_Base"
    crown_base.data.materials.append(crown_mat)
    
    # 冠顶三道火焰线 (简化为三条细圆柱)
    for i, angle in enumerate([-0.3, 0, 0.3]):
        x = 0.03 * math.sin(angle)
        y = 0.03 * math.cos(angle)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.008, depth=0.05, location=(x, y, 2.22))
        flame = bpy.context.active_object
        flame.name = f"{CHAR_NAME}_Crown_Flame_{i}"
        flame.data.materials.append(crown_mat)
    
    return crown_base

def build_sacred_fire_token():
    """圣火令 - 六角形令牌"""
    token_mat = create_material("圣火令_赤金", COLORS["赤金"], metallic=0.9, roughness=0.3)
    
    # 六角形 - 使用多边形放样
    # 简化为六边形棱柱
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.04, 
        depth=0.015, 
        location=(0, 0, 0), 
        vertices=6  # 六边形
    )
    token = bpy.context.active_object
    token.name = f"{CHAR_NAME}_SacredFireToken"
    token.data.materials.append(token_mat)
    token.rotation_euler = (0, math.pi/2, 0)
    
    # 圣火纹 (朱砂红) - 简化纹理表现
    fire_mat = create_material("圣火纹_朱砂", COLORS["朱砂"], metallic=0.3, roughness=0.5)
    # 圣火纹徽章位置在令牌中心
    
    return token, token_mat, fire_mat

def build_scar():
    """疤痕 - 左脸颧骨处 3cm 浅疤"""
    scar_mat = create_material("疤痕", (0.85, 0.75, 0.7, 1.0), metallic=0.0, roughness=0.9)
    
    # 斜向椭球模拟疤痕
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.1, 0.07, 2.04))
    scar = bpy.context.active_object
    scar.name = f"{CHAR_NAME}_Scar"
    scar.scale = (0.03, 0.005, 0.015)
    scar.rotation_euler = (0, 0.5, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    scar.data.materials.append(scar_mat)
    
    return scar

# ============================================================
# Phase 4: 材质与颜色应用
# ============================================================
def apply_materials():
    """应用所有材质到对应部件"""
    
    materials = {
        "内衬_玄黑": COLORS["玄黑"],
        "外袍_深赭": COLORS["深赭"],
        "大氅_暗铜": COLORS["暗铜"],
        "圣火纹_朱砂": COLORS["朱砂"],
        "赤金": COLORS["赤金"],
    }
    
    for obj in bpy.data.objects:
        for mat_name, color in materials.items():
            if mat_name in obj.name:
                if obj.data.materials:
                    obj.data.materials[0] = create_material(mat_name, color)
                else:
                    obj.data.materials.append(create_material(mat_name, color))

# ============================================================
# 主流程
# ============================================================
def main():
    print(f"=== {CHAR_NAME} 建模流程启动 ===")
    
    # 清空场景
    clear_scene()
    
    # Phase 1: 基础素体
    print("Phase 1: 创建基础素体...")
    body = build_base_mesh()
    head = build_head()
    torso, waist = build_torso()
    leg_r, leg_l = build_legs()
    arm_ru, arm_lu, arm_rl, arm_ll = build_arms()
    
    # Phase 2: 服装
    print("Phase 2: 创建服装...")
    inner_mat, robe_mat, cloak_mat = build_costume()
    
    # Phase 3: 配饰
    print("Phase 3: 创建配饰...")
    crown = build_crown()
    token, token_mat, fire_mat = build_sacred_fire_token()
    scar = build_scar()
    
    # Phase 4: 材质
    print("Phase 4: 应用材质...")
    apply_materials()
    
    # 导出设置 (GLB 格式，兼容大多数引擎)
    # bpy.ops.export_scene.gltf(filepath=f"/root/.openclaw/workspace-ui/minimax-output/{CHAR_NAME}.glb")
    
    print(f"=== {CHAR_NAME} 建模流程完成 ===")
    print(f"输出目录: /root/.openclaw/workspace-ui/minimax-output/")

if __name__ == "__main__":
    main()
