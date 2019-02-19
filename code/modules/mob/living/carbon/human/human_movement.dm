/mob/living/carbon/human/movement_delay()
	var/tally = ..()

	if(species.slowdown)
		tally += species.slowdown

	if (istype(loc, /turf/space)) // It's hard to be slowed down in space by... anything
		return -1

	if(embedded_flag)
		handle_embedded_objects() //Moving with objects stuck in you can cause bad times.

	if(CE_SPEEDBOOST in chem_effects)
		tally -= chem_effects[CE_SPEEDBOOST]

	if(CE_SLOWDOWN in chem_effects)
		tally += chem_effects[CE_SLOWDOWN]

	var/health_deficiency = (maxHealth - health)
	if(health_deficiency >= 40) tally += (health_deficiency / 25)

	if (!(species && (species.flags & NO_PAIN)))
		if(halloss >= 10) tally += (halloss / 10) //halloss shouldn't slow you down if you can't even feel it

	if(istype(buckled, /obj/structure/bed/chair/wheelchair))
		//Not porting bay's silly organ checking code here
	else
		if(wear_suit)
			tally += wear_suit.slowdown
		if(shoes)
			tally += shoes.slowdown

	if(shock_stage >= 10) tally += 3

	if(is_asystole()) tally += 10  //heart attacks are kinda distracting

	if(aiming && aiming.aiming_at) tally += 5 // Iron sights make you slower, it's a well-known fact.

	if(MUTATION_FAT in src.mutations)
		tally += 1.5
	if (bodytemperature < 283.222)
		tally += (283.222 - bodytemperature) / 10 * 1.75

	tally += max(2 * stance_damage, 0) //damaged/missing feet or legs is slow

	if(mRun in mutations)
		tally = 0

	return (tally+config.human_delay)

/mob/living/carbon/human/movement_delay_OLD()
	if (istype(loc, /turf/space)) return MOVE_DELAY_BASE // It's hard to be slowed down in space by... anything

	// Humans specifically are 1 delay unit SLOWER because shoes make them 1 delay unit FASTER.
	var/tally = MOVE_DELAY_BASE+1






	if(CE_SPEEDBOOST in chem_effects)
		return 0

	var/health_deficiency = (maxHealth - health)
	if(health_deficiency >= 40) tally += (health_deficiency / 25)



	var/hungry = (500 - nutrition)/5 // So overeat would be 100 and default level would be 80
	if (hungry >= 70) tally += hungry/50

	if(wear_suit)
		tally += wear_suit.slowdown

	if(istype(buckled, /obj/structure/bed/chair/wheelchair))
		for(var/organ_name in list(BP_L_ARM, BP_R_ARM))
			var/obj/item/organ/external/E = get_organ(organ_name)
			if(!E)
				tally += 4
			else
				tally += E.get_tally()
	else
		if(shoes)
			tally += shoes.slowdown

		for(var/organ_name in BP_LEGS)
			var/obj/item/organ/external/E = get_organ(organ_name)
			if(!E)
				tally += 4
			else
				tally += E.get_tally()


	if(shock_stage >= 10) tally += 3

	if(aiming && aiming.aiming_at) tally += 5 // Iron sights make you slower, it's a well-known fact.

	if(FAT in src.mutations)
		tally += 1.5
	if (bodytemperature < 283.222)
		tally += (283.222 - bodytemperature) / 10 * 1.75

	tally += max(2 * stance_damage, 0) //damaged/missing feet or legs is slow

	if(mRun in mutations)
		tally = 0

	return tally

/mob/living/carbon/human/allow_spacemove(var/check_drift = 0)
	//Can we act?
	if(restrained())	return 0

	//Do we have a working jetpack?
	var/obj/item/weapon/tank/jetpack/thrust = get_jetpack()

	if(thrust)
		//The cost for stabilization is paid later
		if (check_drift)
			if (thrust.stabilization_on)
				inertia_dir = 0
				return TRUE
			return FALSE
		else if(thrust.allow_thrust(JETPACK_MOVE_COST, src))
			inertia_dir = 0
			return TRUE

	//If no working jetpack then use the other checks
	. = ..()



/mob/living/carbon/human/slip_chance(var/prob_slip = 5)
	if(!..())
		return 0

	//Check hands and mod slip
	if(!l_hand)
		prob_slip -= 2
	else if(l_hand.w_class <= ITEM_SIZE_SMALL)
		prob_slip -= 1
	if (!r_hand)
		prob_slip -= 2
	else if(r_hand.w_class <= ITEM_SIZE_SMALL)
		prob_slip -= 1

	return prob_slip

/mob/living/carbon/human/check_shoegrip()
	if(species.flags & NO_SLIP)
		return 1
	if(shoes && (shoes.item_flags & NOSLIP) && istype(shoes, /obj/item/clothing/shoes/magboots))  //magboots + dense_object = no floating
		return 1
	return 0

/*
/mob/living/carbon/human/handle_footstep(atom/T)
	if(..())

		if(MOVING_QUICKLY(src))
			if(!(step_count % 2)) //every other turf makes a sound
				return

		if(istype(shoes, /obj/item/clothing/shoes))
			var/obj/item/clothing/shoes/footwear = shoes
			if(footwear.silence_steps)
				return //silent

		if(!has_organ(BP_L_LEG) && !has_organ(BP_R_LEG))
			return //no feet no footsteps

		if(buckled || lying || throwing)
			return //people flying, lying down or sitting do not step

		if(!has_gravity(src))
			if(step_count % 3) //this basically says, every three moves make a noise
				return //1st - none, 1%3==1, 2nd - none, 2%3==2, 3rd - noise, 3%3==0

		if(species.silent_steps)
			return //species is silent


		var/S = T.get_footstep_sound("human")
		if(S)
			var/range = -(world.view - 2)
			var/volume = 90

			if(MOVING_DELIBERATELY(src))
				volume -= 55
				range -= 0.333
			if(!shoes)
				volume -= 70
				range -= 0.333

			playsound(T, S, volume, 1, range)
			return
*/