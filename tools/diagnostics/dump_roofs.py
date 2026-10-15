import re

with open('scenes/town.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

pattern = r'\[node name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]+)")?[^\]]*\](.*?)(?=\n\[node|\Z)'
matches = re.findall(pattern, text, re.DOTALL)

with open('all_roofs_utf8.txt', 'w', encoding='utf-8') as out:
    out.write(f"=== ALL ROOF NODES IN TOWN.TSCN (Total matches: {len(matches)}) ===\n")
    for name, ntype, parent, body in matches:
        if not parent: continue
        full = f"{parent}/{name}"
        if any(k in name.lower() for k in ['roof', 'spire', 'shed', 'bay']) or 'mesh_roof' in body:
            tf = re.search(r'transform = Transform3D\(([^)]+)\)', body)
            mesh = re.search(r'mesh = ([^\n]+)', body)
            vis = re.search(r'visible = ([^\n]+)', body)
            if vis and vis.group(1) == 'false':
                continue
            out.write(f"NODE: {full}\n")
            if tf: out.write(f"  TF: {tf.group(1)}\n")
            if mesh: out.write(f"  MESH: {mesh.group(1)}\n")

print("Saved all_roofs_utf8.txt")
