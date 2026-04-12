"""导出 GLB """
import bpy
import os

output_dir = "/root/.openclaw/workspace-ui/minimax-output"
os.makedirs(output_dir, exist_ok=True)

filepath = os.path.join(output_dir, "沈墨渊_baseMesh.glb")
bpy.ops.export_scene.gltf(filepath=filepath, export_format='GLB')
print(f"导出完成: {filepath}")
