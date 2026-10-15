import re
import os

COLOR_MAP = {
    # Inspector
    "Dark brown hair.002": {"albedo": (0.28, 0.18, 0.12), "roughness": 0.85},
    "Brass badge and buckles.001": {"albedo": (0.85, 0.70, 0.28), "roughness": 0.35, "metallic": 0.85},
    "Hat band.001": {"albedo": (0.45, 0.12, 0.16), "roughness": 0.85},
    "Navy coat edge details": {"albedo": (0.18, 0.24, 0.38), "roughness": 0.85},
    "Deep navy coat": {"albedo": (0.10, 0.14, 0.24), "roughness": 0.85},
    "Muted burgundy cravat.001": {"albedo": (0.46, 0.14, 0.18), "roughness": 0.85},
    "Eyes.004": {"albedo": (0.10, 0.10, 0.12), "roughness": 0.2},
    "Inspector skin.001": {"albedo": (0.86, 0.70, 0.58), "roughness": 0.85},
    "Cream shirt.001": {"albedo": (0.88, 0.86, 0.78), "roughness": 0.85},
    "Hair highlights.004": {"albedo": (0.38, 0.25, 0.16), "roughness": 0.85},
    "Gloves.001": {"albedo": (0.18, 0.16, 0.14), "roughness": 0.75},
    "Studio ground.002": {"albedo": (0.20, 0.20, 0.20), "roughness": 0.9},
    "Dark navy wide-brim hat": {"albedo": (0.08, 0.12, 0.20), "roughness": 0.85},
    "Navy trousers": {"albedo": (0.12, 0.16, 0.26), "roughness": 0.85},
    "Notebook cover.001": {"albedo": (0.36, 0.18, 0.12), "roughness": 0.7},
    "Notebook pages.001": {"albedo": (0.92, 0.90, 0.82), "roughness": 0.9},
    "Leather boots.003": {"albedo": (0.20, 0.14, 0.10), "roughness": 0.7},

    # Herbalist (Elora)
    "Natural linen apron": {"albedo": (0.84, 0.80, 0.70), "roughness": 0.85},
    "Leather brown": {"albedo": (0.38, 0.24, 0.15), "roughness": 0.7},
    "Deep chestnut hair": {"albedo": (0.32, 0.18, 0.12), "roughness": 0.85},
    "Herbal bottles": {"albedo": (0.58, 0.22, 0.68), "roughness": 0.15}, # Rich purple herbal elixir
    "Pale bottle": {"albedo": (0.35, 0.65, 0.60), "roughness": 0.2},
    "Warm skin": {"albedo": (0.88, 0.72, 0.60), "roughness": 0.85},
    "Flower centers": {"albedo": (0.92, 0.75, 0.22), "roughness": 0.8},
    "Warm studio floor": {"albedo": (0.20, 0.20, 0.20), "roughness": 0.9},
    "Hair highlights": {"albedo": (0.42, 0.26, 0.16), "roughness": 0.85},
    "Herb leaves": {"albedo": (0.22, 0.52, 0.26), "roughness": 0.8},
    "Dark boots": {"albedo": (0.18, 0.14, 0.10), "roughness": 0.7},
    "Eyes": {"albedo": (0.10, 0.10, 0.12), "roughness": 0.2},
    "Linen sleeves": {"albedo": (0.88, 0.85, 0.78), "roughness": 0.85},
    "Forest green tunic": {"albedo": (0.18, 0.36, 0.22), "roughness": 0.85},
    "Small ivory flowers": {"albedo": (0.94, 0.94, 0.88), "roughness": 0.85},

    # Bazaar Guy (Corin)
    "Dark brown hair": {"albedo": (0.24, 0.15, 0.10), "roughness": 0.85},
    "Leather boots.001": {"albedo": (0.24, 0.16, 0.11), "roughness": 0.7},
    "Cream linen shirt": {"albedo": (0.86, 0.82, 0.74), "roughness": 0.85},
    "Eyes.002": {"albedo": (0.10, 0.10, 0.12), "roughness": 0.2},
    "Skin": {"albedo": (0.85, 0.68, 0.55), "roughness": 0.85},
    "Hair highlights.002": {"albedo": (0.32, 0.22, 0.14), "roughness": 0.85},
    "Dark gloves": {"albedo": (0.18, 0.16, 0.14), "roughness": 0.75},
    "Ground": {"albedo": (0.20, 0.20, 0.20), "roughness": 0.9},
    "Dark trousers": {"albedo": (0.20, 0.18, 0.22), "roughness": 0.85},
    "Trouser patches.001": {"albedo": (0.44, 0.32, 0.22), "roughness": 0.85},
    "Rust-red sash": {"albedo": (0.70, 0.22, 0.16), "roughness": 0.85},
    "Rust-red headscarf": {"albedo": (0.70, 0.22, 0.16), "roughness": 0.85},
    "Dark brown vest.001": {"albedo": (0.32, 0.20, 0.14), "roughness": 0.75}
}

TARGET_FILES = [
    "scenes/characters/inspector.tscn",
    "scenes/characters/elora.tscn",
    "scenes/characters/corin.tscn"
]

def update_materials_in_scene(file_path):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Pattern to match StandardMaterial3D sub_resource blocks:
    # [sub_resource type="StandardMaterial3D" id="..."]
    # ... lines ...
    # (up to next [sub_resource or [node or EOF)
    pattern = re.compile(
        r'(\[sub_resource type="StandardMaterial3D" id="[^"]+"\]\n(?:[^\n\[]+\n)+)',
        re.MULTILINE
    )

    modified_count = 0

    def replace_block(match):
        nonlocal modified_count
        block = match.group(1)
        name_match = re.search(r'resource_name = "([^"]+)"', block)
        if not name_match:
            return block

        mat_name = name_match.group(1)
        if mat_name in COLOR_MAP:
            props = COLOR_MAP[mat_name]
            albedo = props["albedo"]
            roughness = props.get("roughness", 0.8)
            metallic = props.get("metallic", 0.0)

            # Replace or add albedo_color
            albedo_str = f"albedo_color = Color({albedo[0]}, {albedo[1]}, {albedo[2]}, 1)"
            if "albedo_color =" in block:
                block = re.sub(r'albedo_color = Color\([^\)]+\)', albedo_str, block)
            else:
                block += f"{albedo_str}\n"

            # Set vertex_color_use_as_albedo to false so pure albedo is used
            if "vertex_color_use_as_albedo =" in block:
                block = re.sub(r'vertex_color_use_as_albedo = (?:true|false)', 'vertex_color_use_as_albedo = false', block)
            else:
                block += "vertex_color_use_as_albedo = false\n"

            # Set roughness
            if "roughness =" in block:
                block = re.sub(r'roughness = [0-9.]+', f'roughness = {roughness}', block)
            else:
                block += f"roughness = {roughness}\n"

            # Set metallic if specified
            if metallic > 0:
                if "metallic =" in block:
                    block = re.sub(r'metallic = [0-9.]+', f'metallic = {metallic}', block)
                else:
                    block += f"metallic = {metallic}\n"

            modified_count += 1
            print(f"  [OK] Updated '{mat_name}' -> {albedo_str}")

        return block

    new_content = pattern.sub(replace_block, content)

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(new_content)

    print(f"Processed {file_path}: Updated {modified_count} materials.")

if __name__ == "__main__":
    for tf in TARGET_FILES:
        print(f"\nProcessing {tf}...")
        update_materials_in_scene(tf)
