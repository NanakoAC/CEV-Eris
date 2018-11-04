#define NEIGHBOR_REFRESH_TIME 100

/obj/effect/plant/proc/get_cardinal_neighbors()
	var/list/cardinal_neighbors = list()
	for(var/check_dir in cardinal)
		var/turf/simulated/T = get_step(get_turf(src), check_dir)
		if(istype(T))
			cardinal_neighbors |= T
	return cardinal_neighbors

/obj/effect/plant/proc/update_neighbors(var/debug = FALSE)
	// Update our list of valid neighboring turfs.
	neighbors = list()
	var/list/tocheck = get_cardinal_neighbors()
	for(var/turf/simulated/floor in tocheck)
		var/turf/zdest = get_connecting_turf(floor, loc)//Handling zlevels
		if(get_dist(parent, floor) > spread_distance)
			continue

		//We check zdest, not floor, for existing plants
		if((locate(/obj/effect/plant) in zdest.contents) || (locate(/obj/effect/dead_plant) in zdest.contents) )

			continue
		if(floor.density)
			if(!isnull(seed.chems["pacid"]))
				spawn(rand(5,25)) floor.ex_act(3)
			continue
		if(!Adjacent(floor))
			continue

		//Space vines can grow through airlocks by forcing their way into tiny gaps
		if (!floor.Enter(src))

			//If these two are not the same then we're attempting to enter a portal or stairs
			//We will allow it
			if (zdest == floor)
				var/obj/machinery/door/found_door = null
				for (var/obj/machinery/door/D in floor)
					if (!D || !istype(D) || !D.density)
						continue

					found_door = D

				if (!found_door)
					continue


				//We have to make sure that nothing ELSE aside from the door is blocking us
				var/blocked = FALSE
				for (var/obj/O in floor)
					if (O == found_door)
						continue

					if (!O.CanPass(src, floor))
						blocked = TRUE
						break

				if (blocked)
					continue

		neighbors |= floor
	// Update all of our friends.
	var/turf/T = get_turf(src)
	for(var/obj/effect/plant/neighbor in range(1,src))
		neighbor.neighbors -= T


//This silly special case override is needed to make vines work with portals.
//Code is copied from /atoms_movable.dm, but a spawn call is removed, making it completely synchronous
/obj/effect/plant/Bump(var/atom/A, yes)
	if (A && yes)
		A.last_bumped = world.time
		A.Bumped(src)

/obj/effect/plant/Process()

	// Something is very wrong, kill ourselves.
	if(!seed || !loc)
		die_off()
		return 0

	for(var/obj/effect/effect/smoke/chem/smoke in view(1, src))
		if(smoke.reagents.has_reagent("plantbgone"))
			die_off()
			return

	// Handle life.
	var/turf/simulated/T = get_turf(src)
	if(istype(T))
		health -= seed.handle_environment(T,T.return_air(),null,1)
	if(health < max_health)
		//Plants can grow through closed airlocks, but more slowly, since they have to force metal to make space
		var/obj/machinery/door/D = (locate(/obj/machinery/door) in loc)
		if (D)
			health += rand(0,2)
		else
			health += rand(3,5)
		refresh_icon()
		if(health > max_health)
			health = max_health
	else if(health == max_health && !plant && (seed.type != /datum/seed/mushroom/maintshroom))
		plant = new(T,seed)
		plant.dir = src.dir
		plant.transform = src.transform
		plant.age = seed.get_trait(TRAIT_MATURATION)-1
		plant.update_icon()
		if(growth_type==0) //Vines do not become invisible.
			invisibility = INVISIBILITY_MAXIMUM
		else
			plant.layer = layer + 0.1

	if(buckled_mob)
		seed.do_sting(buckled_mob,src)
		if(seed.get_trait(TRAIT_CARNIVOROUS))
			seed.do_thorns(buckled_mob,src)

	if(world.time >= last_tick+NEIGHBOR_REFRESH_TIME)
		last_tick = world.time
		update_neighbors()

	if(sampled)
		//Should be between 2-7 for given the default range of values for TRAIT_PRODUCTION
		var/chance = max(1, round(30/seed.get_trait(TRAIT_PRODUCTION)))
		if(prob(chance))
			sampled = 0

	if(is_mature() && neighbors.len && prob(spread_chance))
		//spread to 1-3 adjacent turfs depending on yield trait.
		var/max_spread = between(1, round(seed.get_trait(TRAIT_YIELD)*3/14), 3)

		for(var/i in 1 to max_spread)
			if(prob(spread_chance))
				sleep(rand(3,5))
				if(!neighbors.len)
					break
				var/turf/target_turf = pick(neighbors)
				var/obj/effect/plant/child = new(get_turf(src),seed,parent)
				spawn(1) // This should do a little bit of animation.
					child.handle_move(loc, target_turf)
				// Update neighboring squares.
				for(var/obj/effect/plant/neighbor in range(1,target_turf))
					neighbor.neighbors -= target_turf

	// We shouldn't have spawned if the controller doesn't exist.
	check_health(FALSE)//Dont want to update the icon every process
	if(neighbors.len || health != max_health)
		plant_controller.add_plant(src)

	if (seed.get_trait(TRAIT_CHEM_SPRAYER) && !spray_cooldown)
		var/turf/mainloc = get_turf(src)
		for(var/mob/living/A in range(1,mainloc))
			if(A.move_speed < 12)
				HasProximity(A)
				A.visible_message(SPAN_WARNING("[src] sprays something on [A.name]!"), SPAN_WARNING("[src] sprays something on you!"))
				spray_cooldown = TRUE
				spawn(10)
					spray_cooldown = FALSE

	if(seed.get_trait(TRAIT_CHEMS) && reagents.get_free_space() && !chem_regen_cooldown)
		for (var/reagent in seed.chems)
			src.reagents.add_reagent(reagent, 1)
		chem_regen_cooldown = TRUE
		spawn(600)
			chem_regen_cooldown = FALSE


//Once created, the new vine moves to destination turf
/obj/effect/plant/proc/handle_move(var/turf/origin, var/turf/destination)
	//First of all lets ensure we still exist.
	//We may have been deleted by another vine doing postmove cleanup
	if (QDELETED(src))
		return

	//And lets make sure we haven't already moved
	if (loc != origin)
		return

	//We un-anchor ourselves, so that we're exposed to effects like gravity and teleporting
	anchored = FALSE

	//Now we will attempt a normal movement, obeying all the normal rules
	//This allows us to bump into portals and get teleported
	Move(destination)

	/*Now we check if we went anywhere. We don't care about the return value of move, we do our own check
	In the case of a portal, or falling through an openspace, or moving along stairs, Move may return false
	but we've still gone somewhere. We will only consider it a failure if we're still where we started
	*/
	if (loc == origin)
		//That failed, okay this time we're not asking
		forceMove(destination)
		//forceMove won't work properly with portals, so we only do it as a backup option


	//Ok now we should definitely be somewhere
	if (loc == origin)
		//Welp, we give up.
		//This shouldn't be possible, but if it somehow happens then this vine is toast
		qdel(src)
		return

	//Ok we got somewhere, hooray
	//Now we settle down
	anchored = TRUE

	//And do this
	handle_postmove()

//Now we clean up our arrival tile
/obj/effect/plant/proc/handle_postmove()
	for (var/obj/effect/plant/Bl in loc)
		if (Bl != src)
			qdel(Bl) //Lets make sure we don't get doubleblobs


/obj/effect/plant/proc/die_off()
	// Kill off our plant.
	if(plant) plant.die()
	// This turf is clear now, let our buddies know.
	for(var/turf/simulated/check_turf in get_cardinal_neighbors())
		if(!istype(check_turf))
			continue
		for(var/obj/effect/plant/neighbor in check_turf.contents)
			neighbor.neighbors |= check_turf
			plant_controller.add_plant(neighbor)
	spawn(1) if(src) qdel(src)

#undef NEIGHBOR_REFRESH_TIME