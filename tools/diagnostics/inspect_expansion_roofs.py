import re

with open('scenes/village_expansion.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

pattern = r'\[node name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]+)")?[^\]]*\](.*?)(?=\n\[node|\Z)'
for name, ntype, parent, body in re.findall(pattern, text, re.DOTALL):
    full = f"{parent}/{name}" if parent else name
    if any(k in full.lower() for k in ['awning', 'roof', 'slope', 'gable', 'ridge']):
        tf = re.search(r'transform = Transform3D\(([^)]+)\)', body)
        mesh = re.search(r'mesh = ([^\n]+)', body)
        print(f"NODE: {full}")
        if tf: print(f"  TF: {tf.group(1)}")
        if mesh: print(f"  MESH: {mesh.group(1)}")
