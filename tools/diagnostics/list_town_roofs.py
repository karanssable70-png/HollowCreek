import re

with open('scenes/town.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

# Find all nodes
pattern = r'\[node name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]+)")?[^\]]*\](.*?)(?=\n\[node|\Z)'
matches = re.findall(pattern, text, re.DOTALL)

print(f"Total nodes: {len(matches)}")
roof_nodes = []
for name, ntype, parent, body in matches:
    full_path = f"{parent}/{name}" if parent else name
    lower = full_path.lower()
    if any(k in lower for k in ['roof', 'shed', 'dormer', 'spire', 'porchroof', 'bayroof']):
        tf_match = re.search(r'transform = Transform3D\(([^)]+)\)', body)
        mesh_match = re.search(r'mesh = ([^\n]+)', body)
        vis_match = re.search(r'visible = ([^\n]+)', body)
        tf = tf_match.group(1) if tf_match else "identity"
        mesh = mesh_match.group(1) if mesh_match else "none"
        vis = vis_match.group(1) if vis_match else "true"
        roof_nodes.append((full_path, ntype, tf, mesh, vis))

print(f"Total roof nodes: {len(roof_nodes)}")
for r in roof_nodes:
    print(f"NAME: {r[0]} | TYPE: {r[1]} | VIS: {r[4]} | MESH: {r[3]} | TF: {r[2]}")
