class_name TownWorldEnvironment
extends Node

## Day/Night Cycle and World Environment Controller
## Controls dynamic procedural lighting, sky transitions, atmospheric fog,
## directional sun/moon light, and tone-mapping exposure across 4 distinct phases:
## Morning, Afternoon, Evening, and Night.

# ------------------------------------------------------------------------------
# SIGNALS
# ------------------------------------------------------------------------------
signal time_updated(time_of_day: float, phase: String)

# ------------------------------------------------------------------------------
# CONFIGURABLE PARAMETERS
# ------------------------------------------------------------------------------
@export var cycle_duration: float = 60.0 # Total cycle duration in seconds
@export var morning_fraction: float = 0.25 # 15s of 60s
@export var afternoon_fraction: float = 0.25 # 15s of 60s
@export var evening_fraction: float = 0.167 # 10s of 60s
@export var night_fraction: float = 0.333 # 20s of 60s

# ------------------------------------------------------------------------------
# TIME TRACKING
# ------------------------------------------------------------------------------
var time_of_day: float = 0.0 # 0.0 to 1.0 normalized cycle progress
var _elapsed_time: float = 0.0

# ------------------------------------------------------------------------------
# NODE & RESOURCE REFERENCES
# ------------------------------------------------------------------------------
var world_env: WorldEnvironment
var environment: Environment
var sky_material: ProceduralSkyMaterial
var sun_light: DirectionalLight3D

# ------------------------------------------------------------------------------
# CONSTANTS - KEY PALETTES
# ------------------------------------------------------------------------------
const COLOR_EVENING_AMBER_SKY: Color = Color(0.82, 0.55, 0.35)
const COLOR_EVENING_AMBER_HORIZON: Color = Color(0.92, 0.62, 0.35)
const COLOR_EVENING_PURPLE_SKY: Color = Color(0.25, 0.15, 0.35)
const COLOR_EVENING_PURPLE_HORIZON: Color = Color(0.35, 0.18, 0.32)

const COLOR_NIGHT_SKY_TOP: Color = Color(0.04, 0.05, 0.10)
const COLOR_NIGHT_HORIZON: Color = Color(0.06, 0.07, 0.12)
const COLOR_NIGHT_GROUND_BOTTOM: Color = Color(0.02, 0.02, 0.04)
const COLOR_NIGHT_GROUND_HORIZON: Color = Color(0.04, 0.05, 0.08)

# ------------------------------------------------------------------------------
# LIFECYCLE
# ------------------------------------------------------------------------------
func _ready() -> void:
	_setup_environment()
	_setup_sunlight()
	# Apply initial morning lighting state immediately
	_update_lighting(0.0)

func _process(delta: float) -> void:
	if cycle_duration > 0.0:
		_elapsed_time += delta
		_elapsed_time = fmod(_elapsed_time, cycle_duration)
		time_of_day = _elapsed_time / cycle_duration
	else:
		time_of_day = 0.0

	_update_lighting(time_of_day)

# ------------------------------------------------------------------------------
# INITIAL SETUP
# ------------------------------------------------------------------------------
func _setup_environment() -> void:
	world_env = get_node_or_null("WorldEnvironment") as WorldEnvironment
	if not world_env:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)

	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sun_angle_max = 30.0
	sky.sky_material = sky_material
	environment.sky = sky

	# Tonemapping & Glow
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.95
	environment.glow_enabled = true
	environment.glow_normalized = true
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.1

	# Atmospheric Fog
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.52, 0.55, 0.60)
	environment.fog_density = 0.006
	environment.fog_aerial_perspective = 0.4
	environment.fog_sky_affect = 0.35

	# Ambient Lighting initial setup
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.4
	environment.ambient_light_color = Color(0.55, 0.58, 0.65)
	environment.ambient_light_energy = 0.35

	world_env.environment = environment

func _setup_sunlight() -> void:
	sun_light = get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if not sun_light:
		sun_light = DirectionalLight3D.new()
		sun_light.name = "DirectionalLight3D"
		add_child(sun_light)

	sun_light.shadow_enabled = true
	sun_light.shadow_bias = 0.04
	sun_light.light_energy = 0.45
	sun_light.light_color = Color(0.72, 0.75, 0.82)
	sun_light.rotation_degrees = Vector3(-15.0, 45.0, 0.0)

# ------------------------------------------------------------------------------
# CORE UPDATE LOGIC
# ------------------------------------------------------------------------------
func _update_lighting(current_time: float) -> void:
	var phase_info: Dictionary = _get_phase_progress()
	var phase: String = phase_info["phase"]
	var t: float = phase_info["t"]
	var st: float = _smooth_step(t)

	var sun_pitch: float = 0.0
	var sun_yaw: float = 45.0
	var sun_energy: float = 0.0
	var sun_color: Color = Color.WHITE

	var sky_top: Color = Color.WHITE
	var sky_horizon: Color = Color.WHITE
	var ground_bottom: Color = Color.BLACK
	var ground_horizon: Color = Color.DARK_GRAY

	var ambient_src: Environment.AmbientSource = Environment.AMBIENT_SOURCE_SKY
	var ambient_col: Color = Color.WHITE
	var ambient_energy: float = 0.35
	var ambient_sky_contrib: float = 0.4

	var fog_col: Color = Color(0.52, 0.55, 0.60)
	var fog_dens: float = 0.006

	var exposure: float = 0.95

	match phase:
		"morning":
			# Sun rotation: pitch -15 to -35, yaw ~45
			sun_pitch = lerpf(-15.0, -35.0, st)
			sun_yaw = lerpf(30.0, 60.0, st)

			# Sun light_energy: 0.45 to 0.65 (gloomy, muted)
			sun_energy = lerpf(0.45, 0.65, st)

			# Sun color: cool blue-grey desaturated -> transitions toward afternoon
			sun_color = _lerp_color(Color(0.72, 0.75, 0.82), Color(0.85, 0.82, 0.78), st)

			# Sky colors
			sky_top = _lerp_color(Color(0.35, 0.42, 0.55), Color(0.42, 0.52, 0.68), st)
			sky_horizon = _lerp_color(Color(0.55, 0.58, 0.62), Color(0.62, 0.65, 0.70), st)
			ground_bottom = _lerp_color(Color(0.12, 0.14, 0.18), Color(0.18, 0.22, 0.25), st)
			ground_horizon = _lerp_color(Color(0.42, 0.45, 0.50), Color(0.50, 0.54, 0.58), st)

			# Ambient light: source=SKY, sky_contribution=0.4, color=Color(0.55, 0.58, 0.65), energy=0.35
			ambient_src = Environment.AMBIENT_SOURCE_SKY
			ambient_sky_contrib = lerpf(0.38, 0.48, st)
			ambient_col = _lerp_color(Color(0.50, 0.53, 0.60), Color(0.58, 0.60, 0.66), st)
			ambient_energy = lerpf(0.32, 0.40, st)

			# Fog: color=Color(0.52, 0.55, 0.60), density=0.006
			fog_col = _lerp_color(Color(0.48, 0.50, 0.55), Color(0.55, 0.58, 0.62), st)
			fog_dens = lerpf(0.0065, 0.0045, st)

			# Tonemap exposure: morning 0.95
			exposure = lerpf(0.88, 0.98, st)

		"afternoon":
			# Sun rotation: pitch -35 to -55 (high overhead), yaw ~90
			sun_pitch = lerpf(-35.0, -55.0, st)
			sun_yaw = lerpf(60.0, 115.0, st)

			# Sun light_energy: 0.65 to 0.85 (brightest but still muted)
			sun_energy = lerpf(0.65, 0.85, st)

			# Sun color: warm but muted -> transitions toward amber sunset
			sun_color = _lerp_color(Color(0.85, 0.82, 0.78), Color(0.95, 0.65, 0.35), st)

			# Sky colors
			sky_top = _lerp_color(Color(0.42, 0.52, 0.68), COLOR_EVENING_AMBER_SKY, st)
			sky_horizon = _lerp_color(Color(0.62, 0.65, 0.70), COLOR_EVENING_AMBER_HORIZON, st)
			ground_bottom = _lerp_color(Color(0.18, 0.22, 0.25), Color(0.15, 0.18, 0.20), st)
			ground_horizon = _lerp_color(Color(0.50, 0.54, 0.58), Color(0.58, 0.45, 0.35), st)

			# Ambient light: sky_contribution=0.5, energy=0.45
			ambient_src = Environment.AMBIENT_SOURCE_SKY
			ambient_sky_contrib = lerpf(0.48, 0.52, st)
			ambient_col = _lerp_color(Color(0.58, 0.60, 0.66), Color(0.68, 0.65, 0.62), st)
			ambient_energy = lerpf(0.40, 0.45, st)

			# Fog: density=0.004
			fog_col = _lerp_color(Color(0.55, 0.58, 0.62), Color(0.58, 0.52, 0.50), st)
			fog_dens = lerpf(0.0045, 0.0040, st)

			# Tonemap exposure: afternoon 1.0
			exposure = lerpf(0.98, 1.00, st)

		"evening":
			# Sun rotation: pitch -55 to -12 (setting), yaw ~135
			sun_pitch = lerpf(-55.0, -12.0, st)
			sun_yaw = lerpf(115.0, 160.0, st)

			# Sun light_energy: 0.85 to 0.15 (fading)
			sun_energy = lerpf(0.85, 0.15, st)

			# Sun color: amber sunset -> purple dusk
			sun_color = _lerp_color(Color(0.95, 0.65, 0.35), Color(0.45, 0.25, 0.55), st)

			# Sky colors: amber sunset -> purple dusk
			sky_top = _lerp_color(COLOR_EVENING_AMBER_SKY, COLOR_EVENING_PURPLE_SKY, st)
			sky_horizon = _lerp_color(COLOR_EVENING_AMBER_HORIZON, COLOR_EVENING_PURPLE_HORIZON, st)
			ground_bottom = _lerp_color(Color(0.15, 0.18, 0.20), Color(0.05, 0.05, 0.09), st)
			ground_horizon = _lerp_color(Color(0.58, 0.45, 0.35), Color(0.20, 0.12, 0.22), st)

			# Ambient light: reduce energy to 0.15
			ambient_src = Environment.AMBIENT_SOURCE_SKY
			ambient_sky_contrib = lerpf(0.50, 0.20, st)
			ambient_col = _lerp_color(Color(0.68, 0.65, 0.62), Color(0.35, 0.25, 0.38), st)
			ambient_energy = lerpf(0.45, 0.15, st)

			# Fog: color shifts to dark purple-blue, density=0.008
			fog_col = _lerp_color(Color(0.58, 0.52, 0.50), Color(0.18, 0.12, 0.26), st)
			fog_dens = lerpf(0.0045, 0.0080, st)

			# Tonemap exposure: evening 0.85
			exposure = lerpf(1.00, 0.85, st)

		"night":
			# Sun rotation: pitch -12 to 170 (below horizon), yaw 180
			sun_pitch = lerpf(-12.0, 170.0, st)
			sun_yaw = lerpf(160.0, 200.0, st)

			# Sun light_energy: 0.0 (no sun; smoothly extinguishing twilight at start)
			if st < 0.15:
				sun_energy = lerpf(0.15, 0.0, st / 0.15)
			elif st > 0.90:
				sun_energy = lerpf(0.0, 0.45, (st - 0.90) / 0.10)
			else:
				sun_energy = 0.0

			# Sun color: very faint navy
			sun_color = _lerp_color(Color(0.45, 0.25, 0.55), Color(0.15, 0.18, 0.35), clampf(st * 3.0, 0.0, 1.0))
			if st > 0.85:
				sun_color = _lerp_color(sun_color, Color(0.72, 0.75, 0.82), (st - 0.85) / 0.15)

			# Sky colors: very dark navy-black
			if st < 0.3:
				sky_top = _lerp_color(COLOR_EVENING_PURPLE_SKY, COLOR_NIGHT_SKY_TOP, st / 0.3)
				sky_horizon = _lerp_color(COLOR_EVENING_PURPLE_HORIZON, COLOR_NIGHT_HORIZON, st / 0.3)
			elif st > 0.85:
				var dawn_t: float = (st - 0.85) / 0.15
				sky_top = _lerp_color(COLOR_NIGHT_SKY_TOP, Color(0.35, 0.42, 0.55), dawn_t)
				sky_horizon = _lerp_color(COLOR_NIGHT_HORIZON, Color(0.55, 0.58, 0.62), dawn_t)
			else:
				sky_top = COLOR_NIGHT_SKY_TOP
				sky_horizon = COLOR_NIGHT_HORIZON

			ground_bottom = COLOR_NIGHT_GROUND_BOTTOM
			ground_horizon = COLOR_NIGHT_GROUND_HORIZON

			# Ambient light: source=COLOR (not sky), color=Color(0.06, 0.07, 0.12), energy=0.06 (VERY LOW)
			ambient_src = Environment.AMBIENT_SOURCE_COLOR
			ambient_sky_contrib = 0.0
			ambient_col = Color(0.06, 0.07, 0.12)
			if st < 0.25:
				ambient_energy = lerpf(0.15, 0.06, st / 0.25)
			elif st > 0.85:
				ambient_energy = lerpf(0.06, 0.32, (st - 0.85) / 0.15)
			else:
				ambient_energy = 0.06

			# Fog: color=Color(0.03, 0.04, 0.06), density=0.012 (thicker, darker)
			if st < 0.25:
				fog_col = _lerp_color(Color(0.18, 0.12, 0.26), Color(0.03, 0.04, 0.06), st / 0.25)
				fog_dens = lerpf(0.0080, 0.0120, st / 0.25)
			elif st > 0.85:
				var dawn_f: float = (st - 0.85) / 0.15
				fog_col = _lerp_color(Color(0.03, 0.04, 0.06), Color(0.48, 0.50, 0.55), dawn_f)
				fog_dens = lerpf(0.0120, 0.0065, dawn_f)
			else:
				fog_col = Color(0.03, 0.04, 0.06)
				fog_dens = 0.0120

			# Tonemap exposure: night 0.65 (reduced to make darkness darker)
			if st < 0.25:
				exposure = lerpf(0.85, 0.65, st / 0.25)
			elif st > 0.85:
				exposure = lerpf(0.65, 0.88, (st - 0.85) / 0.15)
			else:
				exposure = 0.65

	# Apply to DirectionalLight3D
	if sun_light:
		sun_light.rotation_degrees = Vector3(sun_pitch, sun_yaw, 0.0)
		sun_light.light_energy = sun_energy
		sun_light.light_color = sun_color
		# Disable shadows at night for optimization
		sun_light.shadow_enabled = (phase != "night" and sun_energy > 0.02)

	# Apply to Sky Material
	if sky_material:
		sky_material.sky_top_color = sky_top
		sky_material.sky_horizon_color = sky_horizon
		sky_material.ground_bottom_color = ground_bottom
		sky_material.ground_horizon_color = ground_horizon

	# Apply to Environment
	if environment:
		environment.ambient_light_source = ambient_src
		environment.ambient_light_sky_contribution = ambient_sky_contrib
		environment.ambient_light_color = ambient_col
		environment.ambient_light_energy = ambient_energy

		environment.fog_enabled = true
		environment.fog_light_color = fog_col
		environment.fog_density = fog_dens

		environment.tonemap_exposure = exposure

	# Emit signal every frame for external subscribers (e.g., lantern brightness, window emissives)
	time_updated.emit(current_time, phase)

# ------------------------------------------------------------------------------
# HELPER FUNCTIONS
# ------------------------------------------------------------------------------
func _lerp_color(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, clampf(t, 0.0, 1.0))

func _smooth_step(t: float) -> float:
	var c: float = clampf(t, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)

func _get_phase_progress() -> Dictionary:
	var total_fraction: float = morning_fraction + afternoon_fraction + evening_fraction + night_fraction
	if total_fraction <= 0.0:
		total_fraction = 1.0

	var m_end: float = morning_fraction / total_fraction
	var a_end: float = (morning_fraction + afternoon_fraction) / total_fraction
	var e_end: float = (morning_fraction + afternoon_fraction + evening_fraction) / total_fraction

	var norm_time: float = clampf(time_of_day, 0.0, 1.0)

	if norm_time < m_end:
		var dur: float = maxf(m_end, 0.0001)
		return {"phase": "morning", "t": clampf(norm_time / dur, 0.0, 1.0)}
	elif norm_time < a_end:
		var dur: float = maxf(a_end - m_end, 0.0001)
		return {"phase": "afternoon", "t": clampf((norm_time - m_end) / dur, 0.0, 1.0)}
	elif norm_time < e_end:
		var dur: float = maxf(e_end - a_end, 0.0001)
		return {"phase": "evening", "t": clampf((norm_time - a_end) / dur, 0.0, 1.0)}
	else:
		var dur: float = maxf(1.0 - e_end, 0.0001)
		return {"phase": "night", "t": clampf((norm_time - e_end) / dur, 0.0, 1.0)}

## Public helper to manually set the time of day (0.0 - 1.0)
func set_time_of_day(new_time: float) -> void:
	time_of_day = clampf(new_time, 0.0, 1.0)
	_elapsed_time = time_of_day * cycle_duration
	_update_lighting(time_of_day)
