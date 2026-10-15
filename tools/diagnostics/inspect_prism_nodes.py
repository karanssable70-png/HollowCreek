import re

with open('scenes/town.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

pattern = r'\[node name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]+)")?[^\]]*\](.*?)(?=\n\[node|\Z)'
matches = re.findall(pattern, text, re.DOTALL)

for name, ntype, parent, body in matches:
    if 'PrismMesh' in body:
        tf_match = re.search(r'transform = Transform3D\(([^)]+)\)', body)
        mesh_match = re.search(r'mesh = ([^\n]+)', body)
        tf = tf_match.group(1) if tf_match else "identity"
        mesh = mesh_match.group(1) if mesh_match else "none"
        print(f"{parent}/{name} | MESH: {mesh} | TF: {tf}")
