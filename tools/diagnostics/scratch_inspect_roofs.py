import re
import math

def check_file(filepath):
    print(f"\n=================== CHECKING {filepath} ===================")
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    current_node = None
    current_parent = None
    current_transform = None
    nodes = []
    
    for line in lines:
        m_node = re.match(r'\[node name="([^"]+)"(?:\s+type="([^"]+)")?(?:\s+parent="([^"]+)")?', line)
        if m_node:
            if current_node:
                nodes.append((current_node, current_parent, current_transform))
            current_node = m_node.group(1)
            current_parent = m_node.group(3)
            current_transform = None
        m_tf = re.match(r'transform = Transform3D\(([^)]+)\)', line)
        if m_tf:
            current_transform = [float(x.strip()) for x in m_tf.group(1).split(',')]
            
    if current_node:
        nodes.append((current_node, current_parent, current_transform))
        
    for name, parent, tf in nodes:
        full_name = f"{parent}/{name}" if parent else name
        lower = full_name.lower()
        if any(k in lower for k in ['roof', 'slope', 'dormer', 'spire', 'gable', 'eave', 'porch']):
            if tf:
                # Transform3D(xx, xy, xz, yx, yy, yz, zx, zy, zz, px, py, pz)
                # In Godot Transform3D format:
                # Basis X: (xx, yx, zx) = (tf[0], tf[3], tf[6])
                # Basis Y: (xy, yy, zy) = (tf[1], tf[4], tf[7])
                # Basis Z: (xz, yz, zz) = (tf[2], tf[5], tf[8])
                # Origin: (px, py, pz) = (tf[9], tf[10], tf[11])
                # Note: in Godot text format: Transform3D(x.x, x.y, x.z, y.x, y.y, y.z, z.x, z.y, z.z, o.x, o.y, o.z)
                # Let's check Godot 4 text representation:
                # Transform3D(basis.x.x, basis.x.y, basis.x.z, basis.y.x, basis.y.y, basis.y.z, basis.z.x, basis.z.y, basis.z.z, origin.x, origin.y, origin.z)
                bx = (tf[0], tf[1], tf[2])
                by = (tf[3], tf[4], tf[5])
                bz = (tf[6], tf[7], tf[8])
                origin = (tf[9], tf[10], tf[11])
                
                # Check for upside down:
                # If basis Y has negative Y component (pointing down)
                is_upside_down = by[1] < 0
                
                # For slope meshes:
                slope_info = ""
                if 'slope' in lower:
                    # Look at how X maps to Y
                    slope_info = f" | Slope dY/dX = {bx[1]/bx[0] if bx[0] != 0 else 'inf':.3f}"
                
                status = " [POTENTIAL UPSIDE DOWN]" if is_upside_down else ""
                print(f"{full_name}: Pos={origin}, BasisX={bx}, BasisY={by}{slope_info}{status}")

check_file('scenes/village_expansion.tscn')
check_file('scenes/town.tscn')
