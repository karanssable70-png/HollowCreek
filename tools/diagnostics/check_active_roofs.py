with open('town_roofs_list.txt', 'r', encoding='utf-16', errors='ignore') as f:
    for line in f:
        if 'VIS: true' in line and ('MeshInstance3D' in line or 'Node3D' in line):
            print(line.strip())
