/atom/movable
	layer = OBJ_LAYER
	var/last_move = null
	var/anchored = 0
	// var/elevation = 2    - not used anywhere
	var/move_speed = 10
	var/l_move_time = 1
	var/m_flag = 1
	var/throwing = 0
	var/thrower
	var/turf/throw_source = null
	var/throw_speed = 2
	var/throw_range = 7
	var/moved_recently = 0
	var/mob/pulledby = null
	var/item_state = null // Used to specify the item state for the on-mob overlays.

/atom/movable/Del()
	if(isnull(gc_destroyed) && loc)
		testing("GC: -- [type] was deleted via del() rather than qdel() --")
		crash_with("GC: -- [type] was deleted via del() rather than qdel() --") // stick a stack trace in the runtime logs
//	else if(isnull(gcDestroyed))
//		testing("GC: [type] was deleted via GC without qdel()") //Not really a huge issue but from now on, please qdel()
//	else
//		testing("GC: [type] was deleted via GC with qdel()")
	..()

/atom/movable/Destroy()
	. = ..()
	for(var/atom/movable/AM in contents)
		qdel(AM)
	forceMove(null)
	if (pulledby)
		if (pulledby.pulling == src)
			pulledby.pulling = null
		pulledby = null

/atom/movable/Bump(var/atom/A, yes)
	if(src.throwing)
		src.throw_impact(A)
		src.throwing = 0

	spawn(0)
		if (A && yes)
			A.last_bumped = world.time
			A.Bumped(src)
		return
	..()
	return

/atom/movable/proc/forceMove(atom/destination, var/special_event)
	if(loc == destination)
		return 0

	var/is_origin_turf = isturf(loc)
	var/is_destination_turf = isturf(destination)
	// It is a new area if:
	//  Both the origin and destination are turfs with different areas.
	//  When either origin or destination is a turf and the other is not.
	var/is_new_area = (is_origin_turf ^ is_destination_turf) || (is_origin_turf && is_destination_turf && loc.loc != destination.loc)

	var/atom/origin = loc
	loc = destination

	if(origin)
		origin.Exited(src, destination)
		if(is_origin_turf)
			for(var/atom/movable/AM in origin)
				AM.Uncrossed(src)
			if(is_new_area && is_origin_turf)
				origin.loc.Exited(src, destination)

	if(destination)
		destination.Entered(src, origin, special_event)
		if(is_destination_turf) // If we're entering a turf, cross all movable atoms
			for(var/atom/movable/AM in loc)
				if(AM != src)
					AM.Crossed(src)
			if(is_new_area && is_destination_turf)
				destination.loc.Entered(src, origin)
	return 1

/atom/movable/proc/forceMoveOld(atom/destination)
	if(destination)
		if(loc)
			loc.Exited(src)
		loc = destination
		loc.Entered(src)
		return 1
	return 0

//called when src is thrown into hit_atom
/atom/movable/proc/throw_impact(atom/hit_atom, var/speed)
	if(isliving(hit_atom))
		var/mob/living/M = hit_atom
		M.hitby(src,speed)

	else if(isobj(hit_atom))
		var/obj/O = hit_atom
		if(!O.anchored)
			step(O, src.last_move)
		O.hitby(src,speed)

	else if(isturf(hit_atom))
		src.throwing = 0
		var/turf/T = hit_atom
		if(T.density)
			spawn(2)
				step(src, turn(src.last_move, 180))
			if(isliving(src))
				var/mob/living/M = src
				M.turf_collision(T, speed)

//decided whether a movable atom being thrown can pass through the turf it is in.
/atom/movable/proc/hit_check(var/speed)
	if(src.throwing)
		for(var/atom/A in get_turf(src))
			if(A == src) continue
			if(isliving(A))
				if(A:lying) continue
				src.throw_impact(A,speed)
			if(isobj(A))
				if(A.density && !A.throwpass)	// **TODO: Better behaviour for windows which are dense, but shouldn't always stop movement
					src.throw_impact(A,speed)

/atom/movable/proc/throw_at(atom/target, range, speed, thrower)
	if(!target || !src)	return 0

	spawn()//Spawn off this whole function so you can throw things without blocking the stack
	//Because it contains sleeps
		//use a modified version of Bresenham's algorithm to get from the atom's current position to that of the target

		src.throwing = 1
		if(target.allow_spin && src.allow_spin)
			SpinAnimation(5,1)
		src.thrower = thrower
		src.throw_source = get_turf(src)	//store the origin turf

		if(usr)
			if(HULK in usr.mutations)
				src.throwing = 2 // really strong throw!

		var/dist_x = abs(target.x - src.x)
		var/dist_y = abs(target.y - src.y)

		var/dx
		if (target.x > src.x)
			dx = EAST
		else
			dx = WEST

		var/dy
		if (target.y > src.y)
			dy = NORTH
		else
			dy = SOUTH
		var/dist_travelled = 0
		var/dist_since_sleep = 0
		var/area/a = get_area(src.loc)
		if(dist_x > dist_y)
			var/error = dist_x/2 - dist_y

			while(src && target &&((((src.x < target.x && dx == EAST) || (src.x > target.x && dx == WEST)) && dist_travelled < range) || (a && a.has_gravity == 0)  || istype(src.loc, /turf/space)) && src.throwing && istype(src.loc, /turf))
				// only stop when we've gone the whole distance (or max throw range) and are on a non-space tile, or hit something, or hit the end of the map, or someone picks it up
				if(error < 0)
					var/atom/step = get_step(src, dy)
					if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
						break
					src.Move(step)
					hit_check(speed)
					error += dist_x
					dist_travelled++
					dist_since_sleep++
					if(dist_since_sleep >= speed)
						dist_since_sleep = 0
						sleep(1)
				else
					var/atom/step = get_step(src, dx)
					if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
						break
					src.Move(step)
					hit_check(speed)
					error -= dist_y
					dist_travelled++
					dist_since_sleep++
					if(dist_since_sleep >= speed)
						dist_since_sleep = 0
						sleep(1)
				a = get_area(src.loc)
		else
			var/error = dist_y/2 - dist_x
			while(src && target &&((((src.y < target.y && dy == NORTH) || (src.y > target.y && dy == SOUTH)) && dist_travelled < range) || (a && a.has_gravity == 0)  || istype(src.loc, /turf/space)) && src.throwing && istype(src.loc, /turf))
				// only stop when we've gone the whole distance (or max throw range) and are on a non-space tile, or hit something, or hit the end of the map, or someone picks it up
				if(error < 0)
					var/atom/step = get_step(src, dx)
					if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
						break
					src.Move(step)
					hit_check(speed)
					error += dist_y
					dist_travelled++
					dist_since_sleep++
					if(dist_since_sleep >= speed)
						dist_since_sleep = 0
						sleep(1)
				else
					var/atom/step = get_step(src, dy)
					if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
						break
					src.Move(step)
					hit_check(speed)
					error -= dist_x
					dist_travelled++
					dist_since_sleep++
					if(dist_since_sleep >= speed)
						dist_since_sleep = 0
						sleep(1)

				a = get_area(src.loc)

		//done throwing, either because it hit something or it finished moving
		var/turf/new_loc = get_turf(src)
		if(new_loc)
			if(isobj(src))
				src.throw_impact(new_loc,speed)
			new_loc.Entered(src)
		src.throwing = 0
		src.thrower = null
		src.throw_source = null


//Overlays
/atom/movable/overlay
	var/atom/master = null
	anchored = 1

/atom/movable/overlay/New()
	for(var/x in src.verbs)
		src.verbs -= x
	..()

/atom/movable/overlay/attackby(a, b)
	if (src.master)
		return src.master.attackby(a, b)
	return

/atom/movable/overlay/attack_hand(a, b, c)
	if (src.master)
		return src.master.attack_hand(a, b, c)
	return

/atom/movable/proc/touch_map_edge()
/*
	if(z in config.sealed_levels)
		return
*/

	if(config.use_overmap)
		overmap_spacetravel(get_turf(src), src)
		return

	var/move_to_z = src.get_transit_zlevel()
	var/move_to_x = x
	var/move_to_y = y
	if(move_to_z)
		if(x <= TRANSITIONEDGE)
			move_to_x = world.maxx - TRANSITIONEDGE - 2
			move_to_y = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

		else if (x >= (world.maxx - TRANSITIONEDGE + 1))
			move_to_x = TRANSITIONEDGE + 1
			move_to_y = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

		else if (y <= TRANSITIONEDGE)
			move_to_y = world.maxy - TRANSITIONEDGE -2
			move_to_x = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

		else if (y >= (world.maxy - TRANSITIONEDGE + 1))
			move_to_y = TRANSITIONEDGE + 1
			move_to_x = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

		forceMove(locate(move_to_x, move_to_y, move_to_z))

//by default, transition randomly to another zlevel
/atom/movable/proc/get_transit_zlevel()
	var/list/candidates = maps_data.accessable_levels.Copy()
	candidates.Remove("[src.z]")

	if(!candidates.len)
		return null
	return text2num(pickweight(candidates))

