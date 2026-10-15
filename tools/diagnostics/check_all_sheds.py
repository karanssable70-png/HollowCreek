import re

with open('scenes/town.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

pattern = r'\[node name="([^"]+)" parent="([^"]+)"[^\]]*\](.*?)(?=\n\[node|\Z)'
for m in re.finditer(pattern, text, re.DOTALL):
    name = m.group(1)
    parent = m.group(2)
    body = m.group(3)
    if any(k in name.lower() for k in ['shedroof', 'porchroof', 'bayroof', 'sentryroof', 'roof']):
        tf = re.search(r'transform = Transform3D\(([^)]+)\)', body)
        mesh = re.search(r'mesh = ([^\n]+)', body)
        vis = re.search(r'visible = ([^\n]+)', body)
        if vis and vis.group(1) == 'false':
            continue
        print(f"PATH: {parent}/{name}")
        if tf: print(f"  TF: {tf.group(1)}")
        if mesh: print(f"  MESH: {mesh.group(1)}")
