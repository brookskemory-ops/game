class_name BurningCenser
extends Weapon
## Ansel's Burning Censer — niche: bodies orbiting the wielder, constant
## contact ticks (docs/ABILITIES.md weapon #4). Can't be aimed at all.

var _angle := 0.0
var _last_hit := {}  # enemy slot -> last hit time (seconds)

func _physics_process(delta: float) -> void:
	if wielder == null or wielder.dead:
		return
	_angle = fmod(_angle + float(def.get("orbit_speed", 2.6)) * delta, TAU)
	var orb_count := int(def.get("orbs", 2)) + extra_projectiles
	var orbit_radius := float(def.get("orbit_radius", 36)) * area_mul()
	var orb_radius := float(def.get("orb_radius", 9)) * area_mul()
	var hit_interval := float(def.get("hit_interval", 0.5))
	var now := float(Time.get_ticks_msec()) / 1000.0
	for k in orb_count:
		var orb_pos: Vector2 = wielder.global_position \
			+ Vector2.from_angle(_angle + TAU * float(k) / float(orb_count)) * orbit_radius
		for slot in enemies.query_circle(orb_pos, orb_radius):
			if now - float(_last_hit.get(slot, -9.9)) < hit_interval:
				continue
			_last_hit[slot] = now
			enemies.damage_slot(slot, damage())
	# Halo of Cinders: a second, counter-rotating ring.
	if bool(def.get("second_ring", false)):
		var halo_radius := orbit_radius + 15.0
		for k in orb_count:
			var orb_pos: Vector2 = wielder.global_position \
				+ Vector2.from_angle(-_angle * 1.2 + TAU * float(k) / float(orb_count)) * halo_radius
			for slot in enemies.query_circle(orb_pos, orb_radius):
				if now - float(_last_hit.get(slot, -9.9)) < hit_interval:
					continue
				_last_hit[slot] = now
				enemies.damage_slot(slot, damage())
	queue_redraw()

func _draw() -> void:
	var orb_count := int(def.get("orbs", 2)) + extra_projectiles
	var orbit_radius := float(def.get("orbit_radius", 36)) * area_mul()
	# The burning glow spans the orb's actual hit radius (which grows with area
	# upgrades), so the fire you see is the fire that burns.
	var orb_radius := float(def.get("orb_radius", 9)) * area_mul()
	# Faint orbit ring.
	draw_arc(Vector2.ZERO, orbit_radius, 0.0, TAU, 28,
		Color(Palette.EMBER.r, Palette.EMBER.g, Palette.EMBER.b, 0.10), 1.0)
	for k in orb_count:
		var local := Vector2.from_angle(_angle + TAU * float(k) / float(orb_count)) * orbit_radius
		# Chain from the wielder, then the burning orb with a glow.
		draw_line(Vector2.ZERO, local, Color(Palette.IRON.r, Palette.IRON.g, Palette.IRON.b, 0.35), 1.0)
		_draw_orb(local, orb_radius)
	if bool(def.get("second_ring", false)):
		var halo_radius := orbit_radius + 15.0
		for k in orb_count:
			var halo_angle := -_angle * 1.2 + TAU * float(k) / float(orb_count)
			var local := Vector2.from_angle(halo_angle) * halo_radius
			# Ember trail behind each halo coal.
			draw_arc(Vector2.ZERO, halo_radius, halo_angle + 0.5, halo_angle + 0.06, 8,
				Color(Palette.EMBER.r, Palette.EMBER.g, Palette.EMBER.b, 0.28), 2.0)
			_draw_orb(local, orb_radius)

func _draw_orb(local: Vector2, hit_radius: float) -> void:
	# Outer glow = the damage radius; the coal and hot core sit at its heart.
	draw_circle(local, hit_radius, Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, 0.16))
	draw_circle(local, hit_radius * 0.6, Color(Palette.TORCH.r, Palette.TORCH.g, Palette.TORCH.b, 0.45))
	draw_circle(local, maxf(2.5, hit_radius * 0.4), Palette.TORCH)
	draw_circle(local, maxf(1.0, hit_radius * 0.18), Color(1.0, 0.95, 0.8))

func _on_upgrade(new_level: int) -> String:
	if new_level % 2 == 0:
		extra_projectiles += 1
		return "Burning Censer: another coal (+1 orb)"
	damage_mul *= 1.15
	return "Burning Censer: hotter embers (+15% damage)"
