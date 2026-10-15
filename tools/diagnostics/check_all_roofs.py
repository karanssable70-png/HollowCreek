import re

with open('scenes/town.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

pattern = r'\[node name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]+)")?[^\]]*\](.*?)(?=\n\[node|\Z)'
matches = re.findall(pattern, text, re.DOTALL)

print("=== ALL ROOF NODES IN TOWN.TSCN ===")
for name, ntype, parent, body in matches:
    if not parent: continue
    full = f"{parent}/{name}"
    # check if node name or mesh or parent relates to roof
    if any(k in name.lower() for k in ['roof', 'spire']) or 'mesh_roof' in body:
        tf = re.search(r'transform = Transform3D\(([^)]+)\)', body)
        mesh = re.search(r'mesh = ([^\n]+)', body)
        vis = re.search(r'visible = ([^\n]+)', body)
        if vis and vis.group(1) == 'false':
            continue
        print(f"NODE: {full}")
        if tf: print(f"  TF: {tf.group(1)}")
        if mesh: print(f"  MESH: {mesh.group(1)}")
