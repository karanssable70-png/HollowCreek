with open('scenes/town.tscn', 'r', encoding='utf-8') as f:
    for i, line in enumerate(f):
        if 'TownWorld' in line and '[node' in line:
            print(f'{i+1}: {line}')
            break
