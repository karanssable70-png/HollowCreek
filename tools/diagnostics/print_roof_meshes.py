with open('town_roofs_list.txt', 'r', encoding='utf-16', errors='ignore') as f:
    for line in f:
        line = line.strip()
        if 'mesh_roof_' in line:
            print(line)
