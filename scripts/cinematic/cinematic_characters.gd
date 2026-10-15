class_name CinematicCharacters
extends RefCounted

## CinematicCharacters
## Procedural 3D model and prop builder for Whispers of Hollow Creek cinematic opening.
## Builds:
## - The Mercenary (travelling clothes, hooded cloak, boots, articulated limbs)
## - The Mysterious Contractor (clad in obsidian black, hooded veil, parchment letter)
## - Lord Aris (motionless victim in aristocratic burgundy doublet)
## - Sealed Letter Prop (aged parchment with crimson wax raven seal)
## - Stiletto Dagger (steel blade with stylized blood droplet)
## - Mountain Cliff Ledge (stepped rocks with boulder for exact Shot 3 hand & foot contact)

static func create_material(color: Color, roughness: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

## Builds the Mercenary character with articulated limb pivots for cinematic poses
static func build_mercenary(is_pose_ledge: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "Mercenary"
	
	var mat_clothes := create_material(Color(0.20, 0.22, 0.24)) # Charcoal travelling tunic
	var mat_cloak := create_material(Color(0.14, 0.15, 0.18))   # Deep slate hooded cloak
	var mat_leather := create_material(Color(0.25, 0.16, 0.10)) # Worn brown leather
	var mat_skin := create_material(Color(0.85, 0.72, 0.60))    # Weathered skin tone
	var mat_boots := create_material(Color(0.16, 0.11, 0.08))   # Sturdy dark boots
	var mat_gloves := create_material(Color(0.18, 0.14, 0.11))  # Dark leather gloves
	
	# Torso
	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	var bm_t := BoxMesh.new(); bm_t.size = Vector3(0.56, 0.76, 0.36)
	torso.mesh = bm_t
	torso.material_override = mat_clothes
	torso.position = Vector3(0, 1.05, 0)
	root.add_child(torso)
	
	# Leather Belt with iron buckle
	var belt := MeshInstance3D.new()
	belt.name = "Belt"
	var bm_b := BoxMesh.new(); bm_b.size = Vector3(0.58, 0.12, 0.38)
	belt.mesh = bm_b
	belt.material_override = mat_leather
	belt.position = Vector3(0, 0.72, 0)
	root.add_child(belt)
	
	# Cloak Mantle over shoulders
	var mantle := MeshInstance3D.new()
	mantle.name = "Mantle"
	var bm_m := BoxMesh.new(); bm_m.size = Vector3(0.68, 0.40, 0.46)
	mantle.mesh = bm_m
	mantle.material_override = mat_cloak
	mantle.position = Vector3(0, 1.25, -0.02)
	root.add_child(mantle)
	
	# Cloak Back drape
	var drape := MeshInstance3D.new()
	drape.name = "CloakDrape"
	var bm_d := BoxMesh.new(); bm_d.size = Vector3(0.60, 0.95, 0.10)
	drape.mesh = bm_d
	drape.material_override = mat_cloak
	drape.position = Vector3(0, 0.65, -0.22)
	drape.rotation_degrees.x = 8.0 # Slight wind flare
	root.add_child(drape)
	
	# Head
	var head := MeshInstance3D.new()
	head.name = "Head"
	var bm_h := BoxMesh.new(); bm_h.size = Vector3(0.34, 0.36, 0.34)
	head.mesh = bm_h
	head.material_override = mat_skin
	head.position = Vector3(0, 1.62, 0)
	root.add_child(head)
	
	# Deep Hood over head (casting shadow on face)
	var hood := MeshInstance3D.new()
	hood.name = "Hood"
	var bm_hd := BoxMesh.new(); bm_hd.size = Vector3(0.44, 0.46, 0.44)
	hood.mesh = bm_hd
	hood.material_override = mat_cloak
	hood.position = Vector3(0, 1.66, -0.04)
	root.add_child(hood)
	
	# Hood Brow overhang
	var brow := MeshInstance3D.new()
	brow.name = "HoodBrow"
	var bm_br := BoxMesh.new(); bm_br.size = Vector3(0.40, 0.12, 0.22)
	brow.mesh = bm_br
	brow.material_override = mat_cloak
	brow.position = Vector3(0, 1.82, 0.15)
	brow.rotation_degrees.x = 22.0
	root.add_child(brow)
	
	# --- LEFT LEG ---
	var leg_pivot_l := Node3D.new()
	leg_pivot_l.name = "LegPivotL"
	leg_pivot_l.position = Vector3(-0.16, 0.70, 0)
	root.add_child(leg_pivot_l)
	
	var leg_l := MeshInstance3D.new()
	leg_l.name = "LegL"
	var bm_leg := BoxMesh.new(); bm_leg.size = Vector3(0.20, 0.55, 0.22)
	leg_l.mesh = bm_leg
	leg_l.material_override = mat_clothes
	leg_l.position = Vector3(0, -0.275, 0)
	leg_pivot_l.add_child(leg_l)
	
	var boot_l := MeshInstance3D.new()
	boot_l.name = "BootL"
	var bm_boot := BoxMesh.new(); bm_boot.size = Vector3(0.22, 0.18, 0.32)
	boot_l.mesh = bm_boot
	boot_l.material_override = mat_boots
	boot_l.position = Vector3(0, -0.60, 0.04)
	leg_pivot_l.add_child(boot_l)
	
	# --- RIGHT LEG ---
	var leg_pivot_r := Node3D.new()
	leg_pivot_r.name = "LegPivotR"
	leg_pivot_r.position = Vector3(0.16, 0.70, 0)
	root.add_child(leg_pivot_r)
	
	var leg_r := MeshInstance3D.new()
	leg_r.name = "LegR"
	leg_r.mesh = bm_leg
	leg_r.material_override = mat_clothes
	leg_r.position = Vector3(0, -0.275, 0)
	leg_pivot_r.add_child(leg_r)
	
	var boot_r := MeshInstance3D.new()
	boot_r.name = "BootR"
	boot_r.mesh = bm_boot
	boot_r.material_override = mat_boots
	boot_r.position = Vector3(0, -0.60, 0.04)
	leg_pivot_r.add_child(boot_r)
	
	# --- LEFT ARM ---
	var arm_pivot_l := Node3D.new()
	arm_pivot_l.name = "ArmPivotL"
	arm_pivot_l.position = Vector3(-0.36, 1.35, 0)
	root.add_child(arm_pivot_l)
	
	var arm_l := MeshInstance3D.new()
	arm_l.name = "ArmL"
	var bm_arm := BoxMesh.new(); bm_arm.size = Vector3(0.16, 0.60, 0.18)
	arm_l.mesh = bm_arm
	arm_l.material_override = mat_clothes
	arm_l.position = Vector3(0, -0.30, 0)
	arm_pivot_l.add_child(arm_l)
	
	var glove_l := MeshInstance3D.new()
	glove_l.name = "HandL"
	var bm_glv := BoxMesh.new(); bm_glv.size = Vector3(0.15, 0.18, 0.18)
	glove_l.mesh = bm_glv
	glove_l.material_override = mat_gloves
	glove_l.position = Vector3(0, -0.62, 0)
	arm_pivot_l.add_child(glove_l)
	
	# --- RIGHT ARM ---
	var arm_pivot_r := Node3D.new()
	arm_pivot_r.name = "ArmPivotR"
	arm_pivot_r.position = Vector3(0.36, 1.35, 0)
	root.add_child(arm_pivot_r)
	
	var arm_r := MeshInstance3D.new()
	arm_r.name = "ArmR"
	arm_r.mesh = bm_arm
	arm_r.material_override = mat_clothes
	arm_r.position = Vector3(0, -0.30, 0)
	arm_pivot_r.add_child(arm_r)
	
	var glove_r := MeshInstance3D.new()
	glove_r.name = "HandR"
	glove_r.mesh = bm_glv
	glove_r.material_override = mat_gloves
	glove_r.position = Vector3(0, -0.62, 0)
	arm_pivot_r.add_child(glove_r)
	
	# If requested, configure the EXACT Shot 3 Ledge Pose:
	# - Left foot planted on higher rock step (+0.40m)
	# - Right foot planted on lower ground level (0.0m)
	# - Right hand resting firmly against nearby boulder for support (touching rock)
	# - Torso leaning slightly towards the rock
	# - Head turned towards the village below
	if is_pose_ledge:
		apply_shot3_ledge_pose(root)
		
	return root

## Applies the precise, required Shot 3 pose to the Mercenary node hierarchy
static func apply_shot3_ledge_pose(mercenary: Node3D) -> void:
	var leg_l: Node3D = mercenary.get_node_or_null("LegPivotL")
	var leg_r: Node3D = mercenary.get_node_or_null("LegPivotR")
	var arm_r: Node3D = mercenary.get_node_or_null("ArmPivotR")
	var arm_l: Node3D = mercenary.get_node_or_null("ArmPivotL")
	var head: Node3D = mercenary.get_node_or_null("Head")
	var hood: Node3D = mercenary.get_node_or_null("Hood")
	var brow: Node3D = mercenary.get_node_or_null("HoodBrow")
	var torso: Node3D = mercenary.get_node_or_null("Torso")
	
	# Left Leg: Raised on higher rock step (+0.40m elevation)
	# Hip flexed forward and knee bent so left boot rests at Y = +0.40m
	if leg_l:
		leg_l.rotation_degrees = Vector3(-38.0, 12.0, -8.0)
		leg_l.position = Vector3(-0.16, 0.85, 0.15)
		var boot_l = leg_l.get_node_or_null("BootL")
		if boot_l:
			boot_l.rotation_degrees.x = 24.0 # Ankle flexion resting flat on higher rock
			
	# Right Leg: Planted firmly on lower step at ground level (Y = 0.0m)
	if leg_r:
		leg_r.rotation_degrees = Vector3(10.0, -5.0, 4.0)
		leg_r.position = Vector3(0.16, 0.70, -0.05)
		
	# Right Arm: Raised outward to rest hand firmly against the boulder at (X=0.82, Y=0.94)
	if arm_r:
		# Shoulder rotated up and outward to the right (+Z rotation) so hand palm touches boulder
		arm_r.rotation_degrees = Vector3(-10.0, 8.0, 48.0)
		var hand_r = arm_r.get_node_or_null("HandR")
		if hand_r:
			hand_r.rotation_degrees = Vector3(10.0, 0.0, -35.0) # Palm pressed flat to stone
			
	# Left Arm: Relaxed at side / clutching cloak
	if arm_l:
		arm_l.rotation_degrees = Vector3(12.0, 4.0, 8.0)
		
	# Torso: Slight lean towards the right rock for support without looking unnatural
	if torso:
		torso.rotation_degrees = Vector3(4.0, 6.0, -6.5)
		
	# Head & Hood: Turned down towards Hollow Creek village below (cautious, calculating gaze)
	if head:
		head.rotation_degrees = Vector3(-14.0, -32.0, -4.0)
	if hood:
		hood.rotation_degrees = Vector3(-14.0, -32.0, -4.0)
	if brow:
		brow.rotation_degrees = Vector3(8.0, -32.0, -4.0)

## Builds the Mysterious Contractor clad in black holding the letter
static func build_contractor() -> Node3D:
	var root := Node3D.new()
	root.name = "Contractor"
	
	var mat_obsidian := create_material(Color(0.06, 0.06, 0.08), 0.90) # Total black
	var mat_cloak := create_material(Color(0.04, 0.04, 0.05), 0.95)
	var mat_shadow := create_material(Color(0.02, 0.02, 0.02), 1.0)
	
	# Torso in black robes
	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	var bm_t := BoxMesh.new(); bm_t.size = Vector3(0.58, 0.85, 0.38)
	torso.mesh = bm_t
	torso.material_override = mat_obsidian
	torso.position = Vector3(0, 1.10, 0)
	root.add_child(torso)
	
	# Long black robe lower
	var robe := MeshInstance3D.new()
	robe.name = "RobeLower"
	var bm_r := BoxMesh.new(); bm_r.size = Vector3(0.62, 0.80, 0.44)
	robe.mesh = bm_r
	robe.material_override = mat_cloak
	robe.position = Vector3(0, 0.40, 0)
	root.add_child(robe)
	
	# Head shrouded in deep shadow
	var head := MeshInstance3D.new()
	head.name = "Head"
	var bm_h := BoxMesh.new(); bm_h.size = Vector3(0.32, 0.35, 0.32)
	head.mesh = bm_h
	head.material_override = mat_shadow
	head.position = Vector3(0, 1.62, 0)
	root.add_child(head)
	
	# Deep cowl hood obscuring face
	var hood := MeshInstance3D.new()
	hood.name = "Hood"
	var bm_hd := BoxMesh.new(); bm_hd.size = Vector3(0.48, 0.50, 0.48)
	hood.mesh = bm_hd
	hood.material_override = mat_cloak
	hood.position = Vector3(0, 1.68, -0.02)
	root.add_child(hood)
	
	# Face veil (total black darkness under cowl)
	var veil := MeshInstance3D.new()
	veil.name = "Veil"
	var bm_v := BoxMesh.new(); bm_v.size = Vector3(0.30, 0.32, 0.06)
	veil.mesh = bm_v
	veil.material_override = mat_shadow
	veil.position = Vector3(0, 1.60, 0.16)
	root.add_child(veil)
	
	# Arms
	var arm_l := MeshInstance3D.new()
	arm_l.name = "ArmL"
	var bm_a := BoxMesh.new(); bm_a.size = Vector3(0.18, 0.65, 0.20)
	arm_l.mesh = bm_a
	arm_l.material_override = mat_obsidian
	arm_l.position = Vector3(-0.38, 1.05, 0.05)
	root.add_child(arm_l)
	
	# Right arm extending forward to hand over the contract
	var arm_pivot_r := Node3D.new()
	arm_pivot_r.name = "ArmPivotR"
	arm_pivot_r.position = Vector3(0.38, 1.35, 0)
	arm_pivot_r.rotation_degrees = Vector3(-55.0, -15.0, 0) # Extended forward towards mercenary
	root.add_child(arm_pivot_r)
	
	var arm_r := MeshInstance3D.new()
	arm_r.name = "ArmR"
	arm_r.mesh = bm_a
	arm_r.material_override = mat_obsidian
	arm_r.position = Vector3(0, -0.32, 0)
	arm_pivot_r.add_child(arm_r)
	
	# Black leather gloved hand holding the contract
	var hand_r := MeshInstance3D.new()
	hand_r.name = "HandR"
	var bm_g := BoxMesh.new(); bm_g.size = Vector3(0.15, 0.16, 0.18)
	hand_r.mesh = bm_g
	hand_r.material_override = mat_obsidian
	hand_r.position = Vector3(0, -0.66, 0.05)
	arm_pivot_r.add_child(hand_r)
	
	return root

## Builds the Sealed Parchment Letter with crimson wax seal and black raven emblem
static func build_letter_prop() -> Node3D:
	var root := Node3D.new()
	root.name = "ContractLetter"
	
	var mat_parchment := create_material(Color(0.88, 0.82, 0.68), 0.95) # Aged yellowed parchment
	var mat_wax := create_material(Color(0.72, 0.12, 0.14), 0.40)       # Crimson sealing wax
	var mat_raven := create_material(Color(0.10, 0.08, 0.08), 0.30)     # Black raven seal stamp
	
	# Folded parchment envelope / document
	var paper := MeshInstance3D.new()
	paper.name = "Parchment"
	var bm_p := BoxMesh.new(); bm_p.size = Vector3(0.24, 0.02, 0.32)
	paper.mesh = bm_p
	paper.material_override = mat_parchment
	root.add_child(paper)
	
	# Wax seal disc
	var seal := MeshInstance3D.new()
	seal.name = "WaxSeal"
	var cm_s := CylinderMesh.new()
	cm_s.top_radius = 0.045
	cm_s.bottom_radius = 0.048
	cm_s.height = 0.012
	seal.mesh = cm_s
	seal.material_override = mat_wax
	seal.position = Vector3(0, 0.015, 0)
	root.add_child(seal)
	
	# Embossed Raven stamp emblem on wax
	var raven := MeshInstance3D.new()
	raven.name = "RavenEmblem"
	var bm_rv := BoxMesh.new(); bm_rv.size = Vector3(0.04, 0.008, 0.04)
	raven.mesh = bm_rv
	raven.material_override = mat_raven
	raven.position = Vector3(0, 0.022, 0)
	root.add_child(raven)
	
	return root

## Builds the Stiletto Dagger prop with blood drop node
static func build_dagger_prop() -> Node3D:
	var root := Node3D.new()
	root.name = "StilettoDagger"
	
	var mat_steel := create_material(Color(0.75, 0.78, 0.82), 0.25, 0.85) # Polished steel
	var mat_brass := create_material(Color(0.82, 0.68, 0.32), 0.35, 0.80) # Brass guard
	var mat_grip := create_material(Color(0.15, 0.12, 0.10), 0.90)        # Dark leather wrapped grip
	var mat_blood := create_material(Color(0.65, 0.05, 0.06), 0.15)       # Glossy crimson blood
	
	# Blade (pointed downward)
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var pm_b := PrismMesh.new(); pm_b.size = Vector3(0.05, 0.32, 0.015)
	blade.mesh = pm_b
	blade.material_override = mat_steel
	blade.position = Vector3(0, -0.16, 0)
	blade.rotation_degrees.z = 180.0 # Pointing downwards
	root.add_child(blade)
	
	# Crossguard
	var guard := MeshInstance3D.new()
	guard.name = "Crossguard"
	var bm_g := BoxMesh.new(); bm_g.size = Vector3(0.12, 0.02, 0.03)
	guard.mesh = bm_g
	guard.material_override = mat_brass
	guard.position = Vector3(0, 0, 0)
	root.add_child(guard)
	
	# Handle grip
	var grip := MeshInstance3D.new()
	grip.name = "Grip"
	var cm_g := CylinderMesh.new()
	cm_g.top_radius = 0.018
	cm_g.bottom_radius = 0.018
	cm_g.height = 0.12
	grip.mesh = cm_g
	grip.material_override = mat_grip
	grip.position = Vector3(0, 0.07, 0)
	root.add_child(grip)
	
	# Pommel
	var pommel := MeshInstance3D.new()
	pommel.name = "Pommel"
	var sm_p := SphereMesh.new()
	sm_p.radius = 0.022
	sm_p.height = 0.044
	pommel.mesh = sm_p
	pommel.material_override = mat_brass
	pommel.position = Vector3(0, 0.14, 0)
	root.add_child(pommel)
	
	# Stylized blood droplet on blade tip
	var blood_drop := MeshInstance3D.new()
	blood_drop.name = "BloodDrop"
	var sm_b := SphereMesh.new()
	sm_b.radius = 0.012
	sm_b.height = 0.025
	blood_drop.mesh = sm_b
	blood_drop.material_override = mat_blood
	blood_drop.position = Vector3(0, -0.32, 0)
	root.add_child(blood_drop)
	
	return root

## Builds the fallen target (Lord Aris) lying motionless on the floor
static func build_victim_aris() -> Node3D:
	var root := Node3D.new()
	root.name = "VictimLordAris"
	
	var mat_doublet := create_material(Color(0.48, 0.12, 0.16)) # Burgundy aristocratic doublet
	var mat_trim := create_material(Color(0.85, 0.75, 0.35), 0.4, 0.6) # Gold embroidery trim
	var mat_hose := create_material(Color(0.18, 0.18, 0.22))    # Dark grey hose
	var mat_skin := create_material(Color(0.88, 0.82, 0.78))    # Pale deceased skin
	var mat_hair := create_material(Color(0.65, 0.62, 0.60))    # Greying hair
	var mat_blood := create_material(Color(0.45, 0.04, 0.05), 0.2) # Dark pool of blood
	
	# Fallen body oriented horizontally on stone floor
	var body := Node3D.new()
	body.name = "FallenBody"
	body.rotation_degrees = Vector3(90.0, 25.0, 0.0) # Lying prone on floor
	body.position = Vector3(0, 0.15, 0)
	root.add_child(body)
	
	# Torso
	var torso := MeshInstance3D.new()
	var bm_t := BoxMesh.new(); bm_t.size = Vector3(0.55, 0.72, 0.32)
	torso.mesh = bm_t
	torso.material_override = mat_doublet
	body.add_child(torso)
	
	# Gold sash / trim
	var sash := MeshInstance3D.new()
	var bm_s := BoxMesh.new(); bm_s.size = Vector3(0.57, 0.10, 0.34)
	sash.mesh = bm_s
	sash.material_override = mat_trim
	sash.position = Vector3(0, 0.1, 0)
	body.add_child(sash)
	
	# Pale head tilted sideways
	var head := MeshInstance3D.new()
	var bm_h := BoxMesh.new(); bm_h.size = Vector3(0.32, 0.34, 0.32)
	head.mesh = bm_h
	head.material_override = mat_skin
	head.position = Vector3(0, 0.55, 0)
	head.rotation_degrees.z = 28.0 # Limp tilt
	body.add_child(head)
	
	var hair := MeshInstance3D.new()
	var bm_hr := BoxMesh.new(); bm_hr.size = Vector3(0.34, 0.18, 0.34)
	hair.mesh = bm_hr
	hair.material_override = mat_hair
	hair.position = Vector3(0, 0.68, 0)
	body.add_child(hair)
	
	# Legs splayed motionlessly
	var leg_l := MeshInstance3D.new()
	var bm_l := BoxMesh.new(); bm_l.size = Vector3(0.20, 0.65, 0.20)
	leg_l.mesh = bm_l
	leg_l.material_override = mat_hose
	leg_l.position = Vector3(-0.16, -0.65, 0)
	leg_l.rotation_degrees.z = -12.0
	body.add_child(leg_l)
	
	var leg_r := MeshInstance3D.new()
	leg_r.mesh = bm_l
	leg_r.material_override = mat_hose
	leg_r.position = Vector3(0.18, -0.65, 0.05)
	leg_r.rotation_degrees.z = 20.0
	body.add_child(leg_r)
	
	# Stylized pool of blood under the victim on the stone floor
	var blood_pool := MeshInstance3D.new()
	blood_pool.name = "BloodPool"
	var cm_bp := CylinderMesh.new()
	cm_bp.top_radius = 0.45
	cm_bp.bottom_radius = 0.50
	cm_bp.height = 0.015
	blood_pool.mesh = cm_bp
	blood_pool.material_override = mat_blood
	blood_pool.position = Vector3(0.1, 0.01, -0.15)
	root.add_child(blood_pool)
	
	return root

## Builds the exact mountain cliff ledge with stepped rock elevations and support boulder
static func build_cliff_ledge() -> Node3D:
	var root := Node3D.new()
	root.name = "MountainCliffLedge"
	
	var mat_granite := create_material(Color(0.45, 0.42, 0.40), 0.90) # Weathered granite
	var mat_dark_stone := create_material(Color(0.32, 0.30, 0.28), 0.92)
	
	# 1. Lower Step Rock (Ground level at Y = 0.0m for right foot)
	var lower_step := MeshInstance3D.new()
	lower_step.name = "LowerRockStep"
	var bm_ls := BoxMesh.new(); bm_ls.size = Vector3(1.4, 0.40, 1.6)
	lower_step.mesh = bm_ls
	lower_step.material_override = mat_dark_stone
	lower_step.position = Vector3(0.25, -0.20, 0.0) # Top surface at Y = 0.0m
	root.add_child(lower_step)
	
	# 2. Higher Rock Step (Elevated +0.40m for left foot contact)
	var higher_step := MeshInstance3D.new()
	higher_step.name = "HigherRockStep"
	var bm_hs := BoxMesh.new(); bm_hs.size = Vector3(1.1, 0.40, 1.2)
	higher_step.mesh = bm_hs
	higher_step.material_override = mat_granite
	higher_step.position = Vector3(-0.45, 0.20, 0.25) # Top surface at Y = +0.40m
	higher_step.rotation_degrees.y = 15.0
	root.add_child(higher_step)
	
	# 3. Support Boulder (Firmly touched by mercenary's right hand at X=0.82, Y=0.94)
	var boulder := MeshInstance3D.new()
	boulder.name = "SupportBoulder"
	var bm_b := BoxMesh.new(); bm_b.size = Vector3(0.85, 1.40, 0.85)
	boulder.mesh = bm_b
	boulder.material_override = mat_granite
	boulder.position = Vector3(0.85, 0.85, 0.08)
	boulder.rotation_degrees = Vector3(10.0, -15.0, 5.0)
	root.add_child(boulder)
	
	# Secondary crags framing the composition (set back to not clip camera)
	var crag_back := MeshInstance3D.new()
	crag_back.name = "BackgroundCrag"
	var pm_c := PrismMesh.new(); pm_c.size = Vector3(4.5, 6.0, 2.5)
	crag_back.mesh = pm_c
	crag_back.material_override = mat_dark_stone
	crag_back.position = Vector3(-5.0, 3.5, -4.5)
	crag_back.rotation_degrees = Vector3(5.0, 35.0, -8.0)
	root.add_child(crag_back)
	
	return root
