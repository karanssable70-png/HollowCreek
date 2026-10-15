class_name MedievalRoofBuilder
extends RefCounted

## MedievalRoofBuilder
## Procedural generator and material provider for authentic medieval European fantasy roofs.
## Features:
## - Steeply pitched gables (50° - 58°) with irregular building heights
## - Layered 3D tile steps on roof slopes with visible overhangs and eaves
## - Prominent segmented ridge caps and gable verge trims
## - Procedural PBR textures: individual overlapping curved clay tiles
## - Palette: Burgundy-red, muted crimson, dusty plum, reddish-purple, dark aubergine
## - High-quality normal maps, matte roughness, and crevice moss weathering

static var _cached_materials: Dictionary = {}

## Palette definitions
const COL_BURGUNDY_BASE    := Color(0.38, 0.11, 0.15) # Deep burgundy red
const COL_CRIMSON_MUTED    := Color(0.46, 0.15, 0.16) # Muted crimson
const COL_DUSTY_PLUM       := Color(0.30, 0.13, 0.24) # Dusty plum-purple
const COL_WINE_DARK        := Color(0.26, 0.08, 0.12) # Dark wine red
const COL_AUBERGINE_SHADOW := Color(0.16, 0.06, 0.10) # Dark aubergine / mortar shadow
const COL_TERRACOTTA_WARM  := Color(0.50, 0.20, 0.16) # Weathered clay red highlight
const COL_MOSS_ACCENT      := Color(0.24, 0.28, 0.15) # Crevice moss

## Generates or retrieves a shared PBR roof material
static func get_roof_material(palette_variant: String = "burgundy") -> StandardMaterial3D:
	if _cached_materials.has(palette_variant):
		return _cached_materials[palette_variant]

	var mat := StandardMaterial3D.new()
	mat.resource_name = "Mat_MedievalRoof_" + palette_variant

	# Generate procedural tile texture set
	var textures := _generate_tile_textures(palette_variant)
	mat.albedo_texture = textures["albedo"]
	mat.normal_enabled = true
	mat.normal_scale = 1.35
	mat.normal_texture = textures["normal"]
	mat.roughness = 0.90
	mat.roughness_texture = textures["roughness"]
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
	mat.uv1_scale = Vector3(1.0, 1.0, 1.0)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Two-sided rendering so roofs are solid and visible from every angle
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_cached_materials[palette_variant] = mat
	return mat

## Procedural 1024x1024 tile texture generator with individual overlapping tiles
static func _generate_tile_textures(variant: String) -> Dictionary:
	var width := 1024
	var height := 1024
	var rows := 10
	var cols := 14

	var img_albedo := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var img_height := Image.create(width, height, false, Image.FORMAT_R8)
	var img_roughness := Image.create(width, height, false, Image.FORMAT_R8)

	var tile_h := float(height) / float(rows)
	var tile_w := float(width) / float(cols)

	# Pseudo-random determinism based on variant name
	var seed_val := variant.hash()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Precompute color variations for individual tiles
	var tile_colors: Array[Color] = []
	var total_tiles := (rows + 1) * (cols + 2)
	for i in range(total_tiles):
		var r_pick := rng.randf()
		var col: Color
		if variant == "plum":
			if r_pick < 0.45:
				col = COL_DUSTY_PLUM.lerp(COL_BURGUNDY_BASE, rng.randf_range(0.0, 0.4))
			elif r_pick < 0.75:
				col = COL_BURGUNDY_BASE.lerp(COL_WINE_DARK, rng.randf_range(0.1, 0.5))
			elif r_pick < 0.90:
				col = COL_CRIMSON_MUTED.lerp(COL_DUSTY_PLUM, 0.5)
			else:
				col = COL_TERRACOTTA_WARM.lerp(COL_DUSTY_PLUM, 0.3)
		elif variant == "wine":
			if r_pick < 0.50:
				col = COL_WINE_DARK.lerp(COL_BURGUNDY_BASE, rng.randf_range(0.1, 0.5))
			elif r_pick < 0.80:
				col = COL_BURGUNDY_BASE.lerp(COL_AUBERGINE_SHADOW, rng.randf_range(0.1, 0.4))
			else:
				col = COL_DUSTY_PLUM.lerp(COL_WINE_DARK, 0.6)
		else: # "burgundy" (default)
			if r_pick < 0.45:
				col = COL_BURGUNDY_BASE.lerp(COL_CRIMSON_MUTED, rng.randf_range(0.0, 0.5))
			elif r_pick < 0.75:
				col = COL_WINE_DARK.lerp(COL_BURGUNDY_BASE, rng.randf_range(0.2, 0.6))
			elif r_pick < 0.90:
				col = COL_DUSTY_PLUM.lerp(COL_BURGUNDY_BASE, rng.randf_range(0.1, 0.4))
			else:
				col = COL_TERRACOTTA_WARM.lerp(COL_BURGUNDY_BASE, 0.4)

		# Subtle per-tile lightness variation
		var light_adjust := rng.randf_range(-0.04, 0.04)
		col.r = clampf(col.r + light_adjust, 0.05, 0.95)
		col.g = clampf(col.g + light_adjust * 0.6, 0.05, 0.95)
		col.b = clampf(col.b + light_adjust * 0.8, 0.05, 0.95)
		tile_colors.append(col)

	# Generate height and albedo pixel by pixel
	for y in range(height):
		var row := int(float(y) / tile_h)
		var y_in_tile := fmod(float(y), tile_h) / tile_h # 0.0 at top of row to 1.0 at bottom

		# Stagger every other row by 0.5 tile width
		var x_offset := (tile_w * 0.5) if (row % 2 == 1) else 0.0

		for x in range(width):
			var eff_x := fmod(float(x) + x_offset, float(width))
			var col_idx := int(eff_x / tile_w)
			var x_in_tile := fmod(eff_x, tile_w) / tile_w # 0.0 to 1.0 across tile

			var tile_index := (row * (cols + 1) + col_idx) % tile_colors.size()
			var base_tile_col: Color = tile_colors[tile_index]

			# 1. Height profile for overlapping curved barrel clay tiles:
			# - Slope from top to bottom (overlap ledge):
			#   Upper section (0.0 to 0.85) slopes gently outward, then drops down at bottom overlap edge (0.85 to 1.0)
			var slope_h: float
			if y_in_tile < 0.82:
				slope_h = 0.35 + (y_in_tile / 0.82) * 0.65
			else:
				# Overhang step shadow drop
				slope_h = 0.35 + (1.0 - (y_in_tile - 0.82) / 0.18) * 0.20

			# - Convex barrel profile across tile width (sinusoidal):
			var barrel_curve := sin(x_in_tile * PI)
			# Chamfer side edges
			var edge_fade := clampf(minf(x_in_tile, 1.0 - x_in_tile) * 8.0, 0.0, 1.0)
			var h := slope_h * (0.65 + barrel_curve * 0.35) * edge_fade

			# Add subtle rough grain
			var grain := sin(float(x) * 0.5) * cos(float(y) * 0.5) * 0.02
			h = clampf(h + grain, 0.0, 1.0)
			img_height.set_pixel(x, y, Color(h, h, h, 1.0))

			# 2. Albedo Color calculation:
			var final_col := base_tile_col

			# Overlap shadow: horizontal bottom edge of tile casts shadow on tile below
			if y_in_tile > 0.85:
				var shadow_f := (y_in_tile - 0.85) / 0.15
				final_col = final_col.lerp(COL_AUBERGINE_SHADOW, shadow_f * 0.65)
			elif y_in_tile < 0.15:
				# Contact shadow from tile above
				var shadow_top := (0.15 - y_in_tile) / 0.15
				final_col = final_col.lerp(COL_AUBERGINE_SHADOW, shadow_top * 0.40)

			# Side groove shadow between adjacent tiles
			if x_in_tile < 0.08 or x_in_tile > 0.92:
				var side_dist := minf(x_in_tile, 1.0 - x_in_tile) / 0.08
				final_col = final_col.lerp(COL_AUBERGINE_SHADOW, (1.0 - side_dist) * 0.55)

			# Weathered bottom edge highlights
			if y_in_tile >= 0.78 and y_in_tile <= 0.84:
				final_col = final_col.lerp(COL_TERRACOTTA_WARM, 0.35)

			# Crevice moss in select bottom-left corners
			if y_in_tile > 0.75 and x_in_tile < 0.22:
				var moss_f := (y_in_tile - 0.75) * (0.22 - x_in_tile) * 20.0
				if sin(float(x * 7 + y * 13)) > 0.2:
					final_col = final_col.lerp(COL_MOSS_ACCENT, clampf(moss_f * 0.45, 0.0, 0.60))

			img_albedo.set_pixel(x, y, final_col)

			# 3. Roughness: Matte clay with slight variation
			var rough := 0.88 + (1.0 - h) * 0.08
			if y_in_tile > 0.85:
				rough = 0.95 # Extra rough in shadows/mortar
			img_roughness.set_pixel(x, y, Color(rough, rough, rough, 1.0))

	# Compute tangent-space normal map from height map using Sobel filter
	var img_normal := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var normal_strength := 2.8
	for y in range(height):
		var y_prev := (y - 1 + height) % height
		var y_next := (y + 1) % height
		for x in range(width):
			var x_prev := (x - 1 + width) % width
			var x_next := (x + 1) % width

			var tl := img_height.get_pixel(x_prev, y_prev).r
			var l  := img_height.get_pixel(x_prev, y).r
			var bl := img_height.get_pixel(x_prev, y_next).r
			var tr := img_height.get_pixel(x_next, y_prev).r
			var r  := img_height.get_pixel(x_next, y).r
			var br := img_height.get_pixel(x_next, y_next).r
			var t  := img_height.get_pixel(x, y_prev).r
			var b  := img_height.get_pixel(x, y_next).r

			var dx := (tr + 2.0 * r + br) - (tl + 2.0 * l + bl)
			var dy := (bl + 2.0 * b + br) - (tl + 2.0 * t + tr)
			var dz := 1.0 / normal_strength

			var norm := Vector3(-dx, -dy, dz).normalized()
			# Map -1..1 to 0..1 for standard normal texture
			var norm_col := Color(norm.x * 0.5 + 0.5, norm.y * 0.5 + 0.5, norm.z * 0.5 + 0.5, 1.0)
			img_normal.set_pixel(x, y, norm_col)

	img_albedo.generate_mipmaps()
	img_normal.generate_mipmaps()
	img_roughness.generate_mipmaps()

	var tex_albedo := ImageTexture.create_from_image(img_albedo)
	var tex_normal := ImageTexture.create_from_image(img_normal)
	var tex_rough := ImageTexture.create_from_image(img_roughness)

	return {
		"albedo": tex_albedo,
		"normal": tex_normal,
		"roughness": tex_rough
	}

## Builds an authentic medieval steep gabled roof mesh with stepped tile rows,
## extended eaves overhang, prominent segmented ridge cap, and gable verge trims.
## [length]: Dimension along ridge (local X)
## [height]: Vertical peak height from eaves line to apex
## [span]: Wall-to-wall building width across gable (local Z)
## [overhang_eaves]: Eaves projection past wall line (default 0.32m)
## [overhang_gable]: Gable projection past front/back walls (default 0.28m)
static func build_steep_medieval_roof_mesh(
	length: float,
	height: float,
	span: float,
	overhang_eaves: float = 0.32,
	overhang_gable: float = 0.28,
	stepped_courses: int = 7
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var total_len := length + overhang_gable * 2.0
	var total_span := span + overhang_eaves * 2.0
	var half_len := total_len * 0.5
	var half_span := total_span * 0.5
	var apex_y := height * 0.5
	var eave_y := -height * 0.5

	# Slope vector along one side: from apex (y = apex_y, z = 0) to eave (y = eave_y, z = half_span)
	var slope_length := sqrt(height * height + half_span * half_span)
	var uv_scale_len := total_len / 2.2 # ~2.2m per UV repeat along length
	var uv_scale_slope := slope_length / 1.6 # ~1.6m per UV repeat along slope

	# -------------------------------------------------------------
	# 1. LAYERED STEPPED ROOF SLOPES (Left: +Z, Right: -Z)
	# -------------------------------------------------------------
	for side_sign: float in [1.0, -1.0]:
		var side_normal: Vector3 = Vector3(0.0, half_span, height * side_sign).normalized()
		var step_count: int = stepped_courses

		for s in range(step_count):
			var t0: float = float(s) / float(step_count)
			var t1: float = float(s + 1) / float(step_count)

			# Vertical & Z positions along slope
			var y0: float = lerpf(apex_y, eave_y, t0)
			var y1: float = lerpf(apex_y, eave_y, t1)
			var z0: float = lerpf(0.0, half_span * side_sign, t0)
			var z1: float = lerpf(0.0, half_span * side_sign, t1)

			# Subtle physical overhang step: upper courses sit slightly higher (0.025m) than lower courses
			var step_relief: float = (1.0 - t0) * 0.035
			var norm_offset: Vector3 = side_normal * step_relief

			# 4 vertices for the main slope band
			var v_top_l: Vector3 = Vector3(-half_len, y0, z0) + norm_offset
			var v_top_r: Vector3 = Vector3(half_len, y0, z0) + norm_offset
			var v_bot_l: Vector3 = Vector3(-half_len, y1, z1) + norm_offset
			var v_bot_r: Vector3 = Vector3(half_len, y1, z1) + norm_offset

			var u0: float = 0.0
			var u1: float = uv_scale_len
			var v0: float = t0 * uv_scale_slope
			var v1: float = t1 * uv_scale_slope

			# Quad 1 (main slope face)
			if side_sign > 0.0:
				_add_quad(st, v_top_l, v_top_r, v_bot_r, v_bot_l,
					Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1), side_normal)
			else:
				_add_quad(st, v_top_r, v_top_l, v_bot_l, v_bot_r,
					Vector2(u1, v0), Vector2(u0, v0), Vector2(u0, v1), Vector2(u1, v1), side_normal)

			# Lip / vertical step face creating physical cast shadow
			if s < step_count - 1:
				var next_relief: float = (1.0 - t1) * 0.035
				var next_offset: Vector3 = side_normal * next_relief
				var v_step_bot_l: Vector3 = Vector3(-half_len, y1, z1) + next_offset
				var v_step_bot_r: Vector3 = Vector3(half_len, y1, z1) + next_offset

				var lip_norm: Vector3 = Vector3(0.0, -height, half_span * side_sign).normalized()
				if side_sign > 0.0:
					_add_quad(st, v_bot_l, v_bot_r, v_step_bot_r, v_step_bot_l,
						Vector2(u0, v1), Vector2(u1, v1), Vector2(u1, v1 + 0.08), Vector2(u0, v1 + 0.08), lip_norm)
				else:
					_add_quad(st, v_bot_r, v_bot_l, v_step_bot_l, v_step_bot_r,
						Vector2(u1, v1), Vector2(u0, v1), Vector2(u0, v1 + 0.08), Vector2(u1, v1 + 0.08), lip_norm)

	# -------------------------------------------------------------
	# 2. SOLID GABLE ENDS (Front: +X, Back: -X, double-sided)
	# -------------------------------------------------------------
	for end_sign: float in [1.0, -1.0]:
		var norm_end: Vector3 = Vector3(end_sign, 0.0, 0.0)
		var x_pos: float = half_len * end_sign
		var v_apex: Vector3 = Vector3(x_pos, apex_y, 0.0)
		var v_eave_l: Vector3 = Vector3(x_pos, eave_y, half_span)
		var v_eave_r: Vector3 = Vector3(x_pos, eave_y, -half_span)

		# Face 1 (Outward)
		st.set_normal(norm_end)
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(v_apex)
		if end_sign > 0.0:
			st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(v_eave_r)
			st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(v_eave_l)
		else:
			st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(v_eave_l)
			st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(v_eave_r)

		# Face 2 (Inward reverse)
		st.set_normal(-norm_end)
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(v_apex)
		if end_sign > 0.0:
			st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(v_eave_l)
			st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(v_eave_r)
		else:
			st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(v_eave_r)
			st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(v_eave_l)

	# -------------------------------------------------------------
	# 3. GABLE VERGE TRIMS (Bargeboards on triangular edges)
	# -------------------------------------------------------------
	var verge_w: float = 0.16
	var verge_thick: float = 0.08
	for end_sign: float in [1.0, -1.0]:
		var x_base: float = half_len * end_sign
		var x_outer: float = (half_len + verge_thick) * end_sign
		for side_sign: float in [1.0, -1.0]:
			var norm_slope: Vector3 = Vector3(0.0, half_span, height * side_sign).normalized()
			var offset_inner: Vector3 = norm_slope * 0.05
			var offset_outer: Vector3 = norm_slope * (0.05 + verge_w)
			var v0_inner: Vector3 = Vector3(x_base, apex_y, 0.0) + offset_inner
			var v1_inner: Vector3 = Vector3(x_base, eave_y, half_span * side_sign) + offset_inner
			var v0_outer: Vector3 = Vector3(x_outer, apex_y, 0.0) + offset_outer
			var v1_outer: Vector3 = Vector3(x_outer, eave_y, half_span * side_sign) + offset_outer

			if end_sign * side_sign > 0.0:
				_add_quad(st, v0_inner, v0_outer, v1_outer, v1_inner,
					Vector2(0, 0), Vector2(0.2, 0), Vector2(0.2, 1.0), Vector2(0, 1.0), norm_slope, true)
			else:
				_add_quad(st, v0_outer, v0_inner, v1_inner, v1_outer,
					Vector2(0.2, 0), Vector2(0, 0), Vector2(0, 1.0), Vector2(0.2, 1.0), norm_slope, true)

	# -------------------------------------------------------------
	# 4. THICK OVERLAPPING RIDGE CAP ALONG PEAK
	# -------------------------------------------------------------
	var ridge_r := 0.22
	var ridge_segments := int(ceilf(total_len / 0.55)) # Overlapping cap segments every 0.55m
	var seg_len := total_len / float(ridge_segments)

	for r in range(ridge_segments):
		var x0 := -half_len + float(r) * seg_len - 0.04
		var x1 := -half_len + float(r + 1) * seg_len + 0.04
		var cap_r := ridge_r * (1.02 if (r % 2 == 0) else 0.98) # Slight alternating thickness

		# 3-segment arch over the apex
		var p_left_0  := Vector3(x0, apex_y - 0.08,  cap_r * 0.85)
		var p_left_1  := Vector3(x1, apex_y - 0.08,  cap_r * 0.85)
		var p_mid_0   := Vector3(x0, apex_y + cap_r * 0.55, 0)
		var p_mid_1   := Vector3(x1, apex_y + cap_r * 0.55, 0)
		var p_right_0 := Vector3(x0, apex_y - 0.08, -cap_r * 0.85)
		var p_right_1 := Vector3(x1, apex_y - 0.08, -cap_r * 0.85)

		var norm_l := Vector3(0, 0.707, 0.707)
		var norm_r := Vector3(0, 0.707, -0.707)

		_add_quad(st, p_left_0, p_left_1, p_mid_1, p_mid_0,
			Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.5), Vector2(0, 0.5), norm_l, true)
		_add_quad(st, p_mid_0, p_mid_1, p_right_1, p_right_0,
			Vector2(0, 0.5), Vector2(1, 0.5), Vector2(1, 1.0), Vector2(0, 1.0), norm_r, true)

	# -------------------------------------------------------------
	# 5. SOLID SOFFIT BASE (Seals bottom of roof at eaves line)
	# -------------------------------------------------------------
	var v_b0 := Vector3(-half_len, eave_y, -half_span)
	var v_b1 := Vector3(half_len, eave_y, -half_span)
	var v_b2 := Vector3(half_len, eave_y, half_span)
	var v_b3 := Vector3(-half_len, eave_y, half_span)
	_add_quad(st, v_b0, v_b1, v_b2, v_b3, Vector2(0, 0), Vector2(uv_scale_len, 0), Vector2(uv_scale_len, 1), Vector2(0, 1), Vector3.DOWN, true)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()

## Builds a pointed dormer roof with steep triangular gable and eaves
static func build_dormer_roof_mesh(length: float, height: float, span: float) -> ArrayMesh:
	return build_steep_medieval_roof_mesh(length, height, span, 0.18, 0.14, 4)

## Builds a tall, steep pyramidal spire for clock towers and town halls
static func build_spire_roof_mesh(base_w: float, height: float, base_d: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w: float = base_w * 0.5
	var half_d: float = base_d * 0.5
	var apex_y: float = height * 0.5
	var base_y: float = -height * 0.5

	var p_apex := Vector3(0.0, apex_y, 0.0)
	var corners: Array[Vector3] = [
		Vector3(-half_w, base_y, half_d),
		Vector3(half_w, base_y, half_d),
		Vector3(half_w, base_y, -half_d),
		Vector3(-half_w, base_y, -half_d)
	]

	# 4 triangular faces (both front and back for solid two-sided rendering)
	for i in range(4):
		var c0: Vector3 = corners[i]
		var c1: Vector3 = corners[(i + 1) % 4]
		var edge1 := c0 - p_apex
		var edge2 := c1 - p_apex
		var norm := edge1.cross(edge2).normalized()

		# Outward face
		st.set_normal(norm)
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(p_apex)
		st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(c0)
		st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(c1)

		# Inward face
		st.set_normal(-norm)
		st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(p_apex)
		st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(c1)
		st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(c0)

	# Solid bottom cap
	_add_quad(st, corners[3], corners[2], corners[1], corners[0], Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector3.DOWN, true)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()

## Builds a lean-to / shed roof with stepped horizontal tile courses
static func build_shed_roof_mesh(length: float, height: float, depth: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_len: float = length * 0.5
	var half_d: float = depth * 0.5
	var top_y: float = height * 0.5
	var bot_y: float = -height * 0.5

	var slope_norm: Vector3 = Vector3(0.0, depth, height).normalized()
	var steps: int = 5

	for s in range(steps):
		var t0: float = float(s) / float(steps)
		var t1: float = float(s + 1) / float(steps)

		var y0: float = lerpf(top_y, bot_y, t0)
		var y1: float = lerpf(top_y, bot_y, t1)
		var z0: float = lerpf(-half_d, half_d, t0)
		var z1: float = lerpf(-half_d, half_d, t1)

		var v0 := Vector3(-half_len, y0, z0)
		var v1 := Vector3(half_len, y0, z0)
		var v2 := Vector3(half_len, y1, z1)
		var v3 := Vector3(-half_len, y1, z1)

		_add_quad(st, v0, v1, v2, v3,
			Vector2(0, t0 * 3.0), Vector2(length / 2.0, t0 * 3.0),
			Vector2(length / 2.0, t1 * 3.0), Vector2(0, t1 * 3.0), slope_norm, true)

	# Solid bottom cap
	var v_b0 := Vector3(-half_len, bot_y, -half_d)
	var v_b1 := Vector3(half_len, bot_y, -half_d)
	var v_b2 := Vector3(half_len, bot_y, half_d)
	var v_b3 := Vector3(-half_len, bot_y, half_d)
	_add_quad(st, v_b0, v_b1, v_b2, v_b3, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector3.DOWN, true)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()

## Helper to add a textured quad (front face and reverse face for solid two-sided rendering)
static func _add_quad(
	st: SurfaceTool,
	v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3,
	uv0: Vector2, uv1: Vector2, uv2: Vector2, uv3: Vector2,
	normal: Vector3,
	two_sided: bool = true
) -> void:
	st.set_normal(normal)

	# Front face
	st.set_uv(uv0); st.add_vertex(v0)
	st.set_uv(uv1); st.add_vertex(v1)
	st.set_uv(uv2); st.add_vertex(v2)

	st.set_uv(uv0); st.add_vertex(v0)
	st.set_uv(uv2); st.add_vertex(v2)
	st.set_uv(uv3); st.add_vertex(v3)

	# Reverse face
	if two_sided:
		st.set_normal(-normal)
		st.set_uv(uv0); st.add_vertex(v0)
		st.set_uv(uv2); st.add_vertex(v2)
		st.set_uv(uv1); st.add_vertex(v1)

		st.set_uv(uv0); st.add_vertex(v0)
		st.set_uv(uv3); st.add_vertex(v3)
		st.set_uv(uv2); st.add_vertex(v2)

## Village-wide roof config dictionary
static func get_roof_configs() -> Dictionary:
	return {
		"TheLanternInn": {
			"palette": "burgundy",
			"main_len": 11.4, "main_h": 8.5, "main_span": 14.2,
			"main_pos_y": 10.95,
			"dormer_h": 1.35, "dormer_pos": Vector3(2.5, 9.6, 4.4),
			"has_porch": true, "porch_len": 8.0, "porch_h": 0.45, "porch_d": 4.4,
			"has_bay": true, "bay_len": 1.45, "bay_h": 0.85, "bay_span": 0.95
		},
		"TownHall": {
			"palette": "plum",
			"main_len": 13.8, "main_h": 11.2, "main_span": 17.4,
			"main_pos_y": 13.4,
			"dormer_h": 1.45, "dormer_pos": Vector3(3.2, 11.8, 5.2),
			"spire_w": 4.4, "spire_h": 7.8, "spire_d": 4.4, "spire_pos_y": 20.0
		},
		"GarricksForge": {
			"palette": "wine",
			"main_len": 10.0, "main_h": 7.6, "main_span": 12.5,
			"main_pos_y": 10.4,
			"dormer_h": 1.25, "dormer_pos": Vector3(2.2, 9.2, 3.8),
			"has_shed": true, "shed_len": 7.4, "shed_h": 0.45, "shed_d": 5.8
		},
		"PhysiciansClinic": {
			"palette": "burgundy",
			"main_len": 8.2, "main_h": 6.4, "main_span": 10.0,
			"main_pos_y": 8.3,
			"dormer_h": 1.25, "dormer_pos": Vector3(1.8, 7.5, 3.2)
		},
		"ElarasHerbalistCottage": {
			"palette": "plum",
			"main_len": 7.6, "main_h": 6.0, "main_span": 9.6,
			"main_pos_y": 7.8,
			"dormer_h": 1.25, "dormer_pos": Vector3(1.6, 7.1, 3.0)
		},
		"OldStorehouse": {
			"palette": "wine",
			"main_len": 9.8, "main_h": 7.8, "main_span": 13.0,
			"main_pos_y": 8.9,
			"dormer_h": 1.25, "dormer_pos": Vector3(2.0, 7.8, 4.0)
		},
		"WeaversCottage": {
			"palette": "burgundy",
			"main_len": 9.2, "main_h": 5.2, "main_span": 7.3,
			"main_pos_y": 7.86,
			"dormer_h": 1.20, "dormer_pos": Vector3(1.5, 7.0, 2.5),
			"has_bay": true, "bay_len": 1.45, "bay_h": 0.85, "bay_span": 0.95
		},
		"FishermansCottage": {
			"palette": "plum",
			"main_len": 8.5, "main_h": 5.0, "main_span": 7.0,
			"main_pos_y": 7.56,
			"dormer_h": 1.20, "dormer_pos": Vector3(1.5, 6.8, 2.4)
		},
		"MillersShed": {
			"palette": "wine",
			"main_len": 7.9, "main_h": 4.8, "main_span": 6.6,
			"main_pos_y": 7.26,
			"dormer_h": 1.20, "dormer_pos": Vector3(1.4, 6.6, 2.3),
			"has_bay": true, "bay_len": 1.45, "bay_h": 0.85, "bay_span": 0.95
		},
		"CentralSquareAndWell": {
			"palette": "burgundy",
			"well_len": 2.9, "well_h": 1.7, "well_span": 2.4,
			"well_pos_y": 3.55
		},
		"MountainEntranceGate": {
			"palette": "burgundy"
		}
	}

## Upgrades all roofs in the village scene tree to authentic steep medieval European tiled roofs
static func upgrade_all_building_roofs(town_world_node: Node) -> void:
	if town_world_node == null:
		return

	var configs: Dictionary = get_roof_configs()

	# Search in both Landmarks and duplicate container if present
	var search_containers: Array[Node] = []
	var landmarks := town_world_node.get_node_or_null("Landmarks")
	if landmarks:
		search_containers.append(landmarks)

	for c in town_world_node.get_children():
		if "@Node3D@" in c.name and c != landmarks:
			# Check if this container holds duplicate landmark nodes
			for b_name in configs.keys():
				if c.has_node(NodePath(b_name)):
					search_containers.append(c)
					break

	for container in search_containers:
		for b_name in configs.keys():
			var building := container.get_node_or_null(NodePath(b_name))
			if building:
				upgrade_single_building(building, configs[b_name])

## Upgrades a single building's roofs
static func upgrade_single_building(building: Node, cfg: Dictionary) -> void:
	var palette: String = cfg.get("palette", "burgundy")
	var mat_main := get_roof_material(palette)

	# 1. Main Roof
	if cfg.has("main_len"):
		var roof_node: MeshInstance3D = null
		for r_name in ["RoofMain", "MainRoof", "Roof"]:
			var node := building.get_node_or_null(NodePath(r_name))
			if node is MeshInstance3D:
				roof_node = node
				break

		if roof_node:
			var m_len: float = cfg["main_len"]
			var m_h: float = cfg["main_h"]
			var m_span: float = cfg["main_span"]
			var new_mesh := build_steep_medieval_roof_mesh(m_len, m_h, m_span)
			roof_node.mesh = new_mesh
			roof_node.material_override = mat_main
			roof_node.position.y = cfg["main_pos_y"]
			roof_node.extra_cull_margin = 16.0

			# Clean up old box eaves so they don't clip through layered steps
			for e_name in ["EaveL", "EaveR", "RidgeCap"]:
				var e_node := roof_node.get_node_or_null(NodePath(e_name))
				if e_node is MeshInstance3D:
					e_node.visible = false

			# Update collision shape height
			var col_shape := _find_collision_shape(roof_node)
			if col_shape and col_shape.shape is BoxShape3D:
				var bs := col_shape.shape as BoxShape3D
				bs.size = Vector3(m_len, m_h * 0.75, m_span)

	# 2. Dormer Roofs
	if cfg.has("dormer_h"):
		var dormer_h: float = cfg["dormer_h"]
		var d_mesh := build_dormer_roof_mesh(1.65, dormer_h, 1.65)
		var dormer_nodes := _find_nodes_recursive(building, "RoofDormer")

		for d_node in dormer_nodes:
			if cfg.has("dormer_pos"):
				d_node.position = cfg["dormer_pos"]

			var d_roof := d_node.get_node_or_null("DRoof")
			if d_roof is MeshInstance3D:
				d_roof.mesh = d_mesh
				d_roof.material_override = mat_main
				d_roof.extra_cull_margin = 12.0
				for e_name in ["EaveL", "EaveR", "RidgeCap"]:
					var e_node := d_roof.get_node_or_null(NodePath(e_name))
					if e_node is MeshInstance3D:
						e_node.visible = false

	# 3. Spire Roof (Town Hall)
	if cfg.has("spire_h"):
		var spire := building.get_node_or_null("SpireRoof")
		if spire is MeshInstance3D:
			spire.mesh = build_spire_roof_mesh(cfg["spire_w"], cfg["spire_h"], cfg["spire_d"])
			spire.material_override = mat_main
			spire.position.y = cfg["spire_pos_y"]
			spire.extra_cull_margin = 16.0

	# 4. Porch Roof (The Lantern Inn)
	if cfg.get("has_porch", false):
		var porch := building.get_node_or_null("PorchRoof")
		if porch is MeshInstance3D:
			porch.mesh = build_shed_roof_mesh(cfg["porch_len"], cfg["porch_h"], cfg["porch_d"])
			porch.material_override = mat_main
			porch.extra_cull_margin = 12.0
			for e_name in ["EaveL", "EaveR", "RidgeCap"]:
				var e_node := porch.get_node_or_null(NodePath(e_name))
				if e_node is MeshInstance3D:
					e_node.visible = false

	# 5. Shed Roof (Garrick's Forge)
	if cfg.get("has_shed", false):
		var shed := building.get_node_or_null("ShedRoof")
		if shed is MeshInstance3D:
			shed.mesh = build_shed_roof_mesh(cfg["shed_len"], cfg["shed_h"], cfg["shed_d"])
			shed.material_override = mat_main
			shed.extra_cull_margin = 12.0
			for e_name in ["EaveL", "EaveR", "RidgeCap"]:
				var e_node := shed.get_node_or_null(NodePath(e_name))
				if e_node is MeshInstance3D:
					e_node.visible = false

	# 6. Side Bay Window Roofs
	if cfg.get("has_bay", false):
		var bay_roof := building.get_node_or_null("SideBay/BayRoof")
		if bay_roof is MeshInstance3D:
			bay_roof.mesh = build_dormer_roof_mesh(cfg["bay_len"], cfg["bay_h"], cfg["bay_span"])
			bay_roof.material_override = mat_main
			bay_roof.extra_cull_margin = 12.0
			for e_name in ["EaveL", "EaveR", "RidgeCap"]:
				var e_node := bay_roof.get_node_or_null(NodePath(e_name))
				if e_node is MeshInstance3D:
					e_node.visible = false

	# 7. Village Well Roof
	if cfg.has("well_h"):
		var well_roof := building.get_node_or_null("VillageWell/WellRoof")
		if well_roof is MeshInstance3D:
			well_roof.mesh = build_steep_medieval_roof_mesh(cfg["well_len"], cfg["well_h"], cfg["well_span"], 0.20, 0.15, 5)
			well_roof.material_override = mat_main
			well_roof.position.y = cfg["well_pos_y"]
			well_roof.extra_cull_margin = 12.0

		var nb_roof := building.get_node_or_null("Noticeboard/Roof")
		if nb_roof is MeshInstance3D:
			nb_roof.material_override = get_roof_material("wine")
			nb_roof.extra_cull_margin = 12.0

	# 8. Sentry Post Roof (Mountain Entrance)
	var sentry_roof := building.get_node_or_null("GuardWatchpost/SentryRoof")
	if sentry_roof is MeshInstance3D:
		sentry_roof.material_override = mat_main
		sentry_roof.extra_cull_margin = 12.0

## Helper to find a CollisionShape3D in children
static func _find_collision_shape(parent: Node) -> CollisionShape3D:
	for c in parent.get_children():
		if c is CollisionShape3D:
			return c
		for gc in c.get_children():
			if gc is CollisionShape3D:
				return gc
	return null

## Recursive node search helper
static func _find_nodes_recursive(node: Node, target_name: String) -> Array[Node]:
	var result: Array[Node] = []
	for c in node.get_children():
		if c.name == target_name:
			result.append(c)
		result.append_array(_find_nodes_recursive(c, target_name))
	return result


