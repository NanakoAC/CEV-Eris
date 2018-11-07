/obj/item/weapon/tool
	name = "tool"
	icon = 'icons/obj/tools.dmi'
	slot_flags = SLOT_BELT
	force = WEAPON_FORCE_NORMAL
	throwforce = WEAPON_FORCE_NORMAL
	w_class = ITEM_SIZE_SMALL

	var/sparks_on_use = FALSE	//Set to TRUE if you want to have sparks on each use of a tool
	var/eye_hazard = FALSE	//Set to TRUE should damage users eyes if they without eye protection

	var/use_power_cost = 0	//For tool system, determinze how much power tool will drain from cells, 0 means no cell needed
	var/obj/item/weapon/cell/cell = null
	var/suitable_cell = null	//Dont forget to edit this for a tool, if you want in to consume cells

	var/use_fuel_cost = 0	//Same, only for fuel. And for the sake of God, DONT USE CELLS AND FUEL SIMULTANEOUSLY.
	var/passive_fuel_cost = 0.03 //Fuel consumed per process tick while active
	var/max_fuel = 0

	//Third type of resource, stock. A tool that uses physical objects (or itself) in order to work
	//Currently used for tape roll
	var/use_stock_cost = 0
	var/stock = 0
	var/max_stock = 0
	var/allow_decimal_stock = TRUE
	var/delete_when_empty = TRUE

	var/toggleable = FALSE	//Determinze if it can be switched ON or OFF, for example, if you need a tool that will consume power/fuel upon turning it ON only. Such as welder.
	var/switched_on = FALSE	//Curent status of tool. Dont edit this in subtypes vars, its for procs only.
	var/switched_on_qualities = null	//This var will REPLACE tool_qualities when tool will be toggled on.
	var/switched_off_qualities = null	//This var will REPLACE tool_qualities when tool will be toggled off. So its possible for tool to have diferent qualities both for ON and OFF state.
	var/create_hot_spot = FALSE	//Set this TRUE to ignite plasma on turf with tool upon activation
	var/glow_color = null	//Set color of glow upon activation, or leave it null if you dont want any light


/******************************
	/* Core Procs */
*******************************/
//Fuel and cell spawn
/obj/item/weapon/tool/New()
	..()
	if(!cell && suitable_cell)
		cell = new suitable_cell(src)

	if(use_fuel_cost)
		var/datum/reagents/R = new/datum/reagents(max_fuel)
		reagents = R
		R.my_atom = src
		R.add_reagent("fuel", max_fuel)

	if (use_stock_cost)
		stock = max_stock

	update_icon()
	return

//For killing processes like hot spots
/obj/item/weapon/tool/Destroy()
	if (src in SSobj.processing)
		STOP_PROCESSING(SSobj, src)
	return ..()

//Ignite plasma around, if we need it
/obj/item/weapon/tool/Process()
	if(switched_on)
		if(create_hot_spot)
			var/turf/location = src.loc
			if(istype(location, /mob/))
				var/mob/M = location
				if(M.l_hand == src || M.r_hand == src)
					location = get_turf(M)
			if (istype(location, /turf))
				location.hotspot_expose(700, 5)

		if (passive_fuel_cost)
			if(!consume_fuel(passive_fuel_cost))
				turn_off()


//Cell reload
/obj/item/weapon/tool/MouseDrop(over_object)
	if((src.loc == usr) && istype(over_object, /obj/screen/inventory/hand) && eject_item(cell, usr))
		cell = null
		update_icon()
	else
		..()

/obj/item/weapon/tool/attackby(obj/item/C, mob/living/user)
	if(istype(C, suitable_cell) && !cell && insert_item(C, user))
		src.cell = C
		update_icon()

//Turning it on/off
/obj/item/weapon/tool/attack_self(mob/user)
	if(toggleable)
		if (switched_on)
			turn_off(user)
		else
			turn_on(user)
	..()
	return




/******************************
	/* Tool Usage */
*******************************/

//Simple form ideal for basic use. That proc will return TRUE only when everything was done right, and FALSE if something went wrong, ot user was unlucky.
//Editionaly, handle_failure proc will be called for a critical failure roll.
/obj/item/proc/use_tool(var/mob/living/user, var/atom/target, base_time, required_quality, fail_chance, required_stat = null, instant_finish_tier = 110, forced_sound = null, var/sound_repeat = 2.5)
	var/result = use_tool_extended(user, target, base_time, required_quality, fail_chance, required_stat, instant_finish_tier, forced_sound)
	switch(result)
		if(TOOL_USE_CANCEL)
			return FALSE
		if(TOOL_USE_FAIL)
			handle_failure(user, target, required_stat = required_stat, required_quality = required_quality)	//We call it here because extended proc mean to be used only when you need to handle tool fail by yourself
			return FALSE
		if(TOOL_USE_SUCCESS)
			return TRUE

//Use this proc if you want to handle all types of failure yourself. It used in surgery, for example, to deal damage to patient.
/obj/item/proc/use_tool_extended(var/mob/living/user, var/atom/target, base_time, required_quality, fail_chance, required_stat = null, instant_finish_tier = 110, forced_sound = null, var/sound_repeat = 2.5 SECONDS)
	if (is_hot() >= HEAT_MOBIGNITE_THRESHOLD)
		if (isliving(target))
			var/mob/living/L = target
			L.IgniteMob()

	if(target.used_now)
		user << SPAN_WARNING("[target.name] is used by someone. Wait for them to finish.")
		return TOOL_USE_CANCEL



	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.shock_stage >= 30)
			user << SPAN_WARNING("Pain distracts you from your task.")
			fail_chance += round(H.shock_stage/120 * 40)
			base_time += round(H.shock_stage/120 * 40)


	//Start time and time spent are used to calculate resource use
	var/start_time = world.time
	var/time_spent = 0

	//Precalculate worktime here
	var/time_to_finish = 0
	if (base_time)
		time_to_finish = base_time - get_tool_quality(required_quality) - user.stats.getStat(required_stat)

	if((instant_finish_tier < get_tool_quality(required_quality)) || time_to_finish < 0)
		time_to_finish = 0

	var/obj/item/weapon/tool/T
	if(istype(src, /obj/item/weapon/tool))
		T = src
		if(!T.check_tool_effects(user, time_to_finish))
			return TOOL_USE_CANCEL

	//Repeating sound code!
	//A datum/repeating_sound is a little object we can use to make a sound repeat a few times
	var/datum/repeating_sound/toolsound = null
	if(forced_sound != NO_WORKSOUND)

		var/soundfile
		if(forced_sound)
			soundfile = forced_sound
		else
			soundfile = worksound

		if (sound_repeat && time_to_finish)
			//It will repeat roughly every 2.5 seconds until our tool finishes
			toolsound = new/datum/repeating_sound(sound_repeat,time_to_finish,0.15, src, soundfile, 70, 1)
		else
			playsound(src.loc, soundfile, 70, 1)

	//The we handle the doafter for the tool usage
	if(time_to_finish)
		target.used_now = TRUE

		if(!do_after(user, time_to_finish, user))
			//If the doafter fails
			user << SPAN_WARNING("You need to stand still to finish the task properly!")
			target.used_now = FALSE
			time_spent = world.time - start_time //We failed, spent only part of the time working
			if (T)
				T.consume_resources(time_spent, user)
			if (toolsound)
				//We abort the repeating sound.
				//Stop function will delete itself too
				toolsound.stop()
				toolsound = null
			return TOOL_USE_CANCEL
		else
			target.used_now = FALSE

	//If we get here the operation finished correctly, we spent the full time working
	time_spent = time_to_finish
	if (T)
		T.consume_resources(time_spent, user)

	//Safe cleanup
	if (toolsound)
		toolsound.stop()
		toolsound = null

	var/stat_modifer = 0
	if(required_stat)
		stat_modifer = user.stats.getStat(required_stat)
	fail_chance = fail_chance - get_tool_quality(required_quality) - stat_modifer
	if(prob(fail_chance))
		user << SPAN_WARNING("You failed to finish your task with [src.name]! There was a [fail_chance]% chance to screw this up.")
		return TOOL_USE_FAIL

	return TOOL_USE_SUCCESS




/******************************
	/* Tool Failure */
*******************************/

//Critical failure rolls. If you use use_tool_extended, you might want to call that proc as well.
/obj/item/proc/handle_failure(var/mob/living/user, var/atom/target, required_stat = null, required_quality)

	var/crit_fail_chance = 25
	if(required_stat)
		crit_fail_chance = crit_fail_chance - user.stats.getStat(required_stat)
	else
		crit_fail_chance = 10

	if(prob(crit_fail_chance))
		var/fail_type = rand(0, 100)

		switch(fail_type)

			if(0 to 29)
				if(ishuman(user))
					user << SPAN_DANGER("You drop [src] on the floor.")
					user.drop_from_inventory(src)
					return

			if(30 to 49)
				if(ishuman(user))
					var/mob/living/carbon/human/H = user
					user << SPAN_DANGER("Your hand slips while working with [src]!")
					attack(H, H, H.get_holding_hand(src))
					return

			if(50 to 79)
				if(ishuman(user))
					var/mob/living/carbon/human/H = user
					var/throw_target = pick(trange(6, user))
					user << SPAN_DANGER("Your [src] flies away!")
					H.unEquip(src)
					src.throw_at(throw_target, src.throw_range, src.throw_speed, H)
					return

			if(70 to 84)
				if(ishuman(user))
					var/mob/living/carbon/human/H = user
					user << SPAN_DANGER("You accidentally stuck [src] in your hand!")
					H.get_organ(H.get_holding_hand(src)).embed(src)
					return

			if(85 to 94)
				if(ishuman(user))
					user << SPAN_DANGER("Your [src] broke beyond repair!")
					new /obj/item/weapon/material/shard/shrapnel(user.loc)
					qdel(src)
					return

			if(95 to 100)
				if(ishuman(user))
					if(istype(src, /obj/item/weapon/tool))
						var/obj/item/weapon/tool/T = src
						if(T.use_fuel_cost)
							user << SPAN_DANGER("You ignite the fuel of the [src]!")
							var/fuel = T.get_fuel()
							T.consume_fuel(fuel)
							user.adjust_fire_stacks(fuel/10)
							user.IgniteMob()
							T.update_icon()
							return
						if(T.use_power_cost && T.cell)
							user << SPAN_DANGER("You overload the cell in the [src]!")
							if (T.cell.charge >= 400)
								explosion(src.loc,-1,0,2)
							else
								explosion(src.loc,-1,0,1)
							qdel(T.cell)
							T.cell = null
							T.update_icon()
							return





/******************************
	/* Data and Checking */
*******************************/
/obj/item/proc/has_quality(quality_id)
	return quality_id in tool_qualities

/obj/item/proc/get_tool_quality(quality_id)
	if (tool_qualities && tool_qualities.len)
		return tool_qualities[quality_id]
	return null

//We are cheking if our item got required qualities. If we require several qualities, and item posses more than one of those, we ask user to choose how that item should be used
/obj/item/proc/get_tool_type(var/mob/living/user, var/list/required_qualities)
	var/start_loc = user.loc
	var/list/L = required_qualities & tool_qualities

	if(!L.len)
		return FALSE

	var/return_quality = L[1]
	if(L.len > 1)
		return_quality = input(user,"What quality you using?", "Tool options", ABORT_CHECK) in L
	if(user.loc != start_loc)
		user << SPAN_WARNING("You need to stand still!")
		return ABORT_CHECK
	else
		return return_quality








/obj/item/weapon/tool/proc/turn_on(mob/user)
	switched_on = TRUE
	tool_qualities = switched_on_qualities
	if(glow_color)
		set_light(l_range = 1.7, l_power = 1.3, l_color = glow_color)
	update_icon()
	update_wear_icon()

/obj/item/weapon/tool/proc/turn_off(mob/user)
	switched_on = FALSE
	STOP_PROCESSING(SSobj, src)
	tool_qualities = switched_off_qualities
	if(glow_color)
		set_light(l_range = 0, l_power = 0, l_color = glow_color)
	update_icon()
	update_wear_icon()








/*********************
	Resource Consumption
**********************/
/obj/item/weapon/tool/proc/consume_resources(var/timespent, var/user)
	//We will always use a minimum of 0.5 second worth of resources
	if (timespent < 5)
		timespent = 5

	if(use_power_cost)
		if (!cell.checked_use(use_power_cost*timespent))
			user << SPAN_WARNING("[src] battery is dead or missing.")
			return FALSE

	if(use_fuel_cost)
		if(!consume_fuel(use_fuel_cost*timespent))
			user << SPAN_NOTICE("You need more welding fuel to complete this task.")
			return FALSE

	if(use_stock_cost)
		var/scost = use_stock_cost * timespent
		if (!allow_decimal_stock)
			scost = round(scost, 1)
		consume_stock(scost)

//Power and fuel drain, sparks spawn
/obj/item/weapon/tool/proc/check_tool_effects(mob/living/user, var/time)

	if(use_power_cost)
		if(!cell || !cell.check_charge(use_power_cost*time))
			user << SPAN_WARNING("[src] battery is dead or missing.")
			return FALSE

	if(use_fuel_cost)
		if(get_fuel() < (use_fuel_cost*time))
			user << SPAN_NOTICE("You need more welding fuel to complete this task.")
			return FALSE

	if (use_stock_cost)
		if(stock < (use_stock_cost*time))
			user << SPAN_NOTICE("There is not enough left in [src] to complete this task.")
			return FALSE

	if(eye_hazard)
		eyecheck(user)

	if(sparks_on_use)
		var/datum/effect/effect/system/spark_spread/sparks = new /datum/effect/effect/system/spark_spread()
		sparks.set_up(3, 0, get_turf(src))
		sparks.start()

	update_icon()
	return TRUE

//Returns the amount of fuel in tool
/obj/item/weapon/tool/proc/get_fuel()
	return reagents.get_reagent_amount("fuel")

/obj/item/weapon/tool/proc/consume_fuel(var/volume)
	if (get_fuel() >= volume)
		reagents.remove_reagent("fuel", volume)
		return TRUE
	return FALSE


/obj/item/weapon/tool/proc/consume_stock(var/number)
	if (stock >= number)
		stock -= number
	else
		stock = 0

	if (delete_when_empty && stock <= 0)
		qdel(src)


/obj/item/weapon/tool/examine(mob/user)
	if(!..(user,2))
		return

	if(use_power_cost)
		if(!cell)
			user << SPAN_WARNING("There is no cell inside to power the tool")
		else
			user << "The charge meter reads [round(cell.percent() )]%."

	if(use_fuel_cost)
		user << text("\icon[] [] contains []/[] units of fuel!", src, src.name, get_fuel(),src.max_fuel )

	if (use_stock_cost)
		user << SPAN_NOTICE("it has [stock] / [max_stock] units remaining.")


//Recharge the fuel at fueltank, also explode if switched on
/obj/item/weapon/tool/afterattack(obj/O, mob/user, proximity)
	if(use_fuel_cost)
		if(!proximity) return
		if ((istype(O, /obj/structure/reagent_dispensers/fueltank) || istype(O, /obj/item/weapon/weldpack)) && get_dist(src,O) <= 1 && !switched_on)
			O.reagents.trans_to_obj(src, max_fuel)
			user << SPAN_NOTICE("[src] refueled")
			playsound(src.loc, 'sound/effects/refill.ogg', 50, 1, -6)
			return
		else if ((istype(O, /obj/structure/reagent_dispensers/fueltank) || istype(O, /obj/item/weapon/weldpack)) && get_dist(src,O) <= 1 && switched_on)
			message_admins("[key_name_admin(user)] triggered a fueltank explosion with a welding tool.")
			log_game("[key_name(user)] triggered a fueltank explosion with a welding tool.")
			user << SPAN_DANGER("You begin welding on the [O] and with a moment of lucidity you realize, this might not have been the smartest thing you've ever done.")
			var/obj/structure/reagent_dispensers/fueltank/tank = O
			tank.explode()
			return
		if (switched_on)
			var/turf/location = get_turf(user)
			if(isliving(O))
				var/mob/living/L = O
				L.IgniteMob()
			if (istype(location, /turf))
				location.hotspot_expose(700, 50, 1)
	return

//Decides whether or not to damage a player's eyes based on what they're wearing as protection
//Note: This should probably be moved to mob
/obj/item/weapon/tool/proc/eyecheck(mob/user as mob)
	if(!iscarbon(user))
		return TRUE
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/internal/eyes/E = H.internal_organs_by_name[O_EYES]
		if(!E)
			return
		var/safety = H.eyecheck()
		switch(safety)
			if(FLASH_PROTECTION_MODERATE)
				H << SPAN_WARNING("Your eyes sting a little.")
				E.damage += rand(1, 2)
				if(E.damage > 12)
					H.eye_blurry += rand(3,6)
			if(FLASH_PROTECTION_NONE)
				H << SPAN_WARNING("Your eyes burn.")
				E.damage += rand(2, 4)
				if(E.damage > 10)
					E.damage += rand(4,10)
			if(FLASH_PROTECTION_REDUCED)
				H << SPAN_DANGER("Your equipment intensify the welder's glow. Your eyes itch and burn severely.")
				H.eye_blurry += rand(12,20)
				E.damage += rand(12, 16)
		if(safety<FLASH_PROTECTION_MAJOR)
			if(E.damage > 10)
				user << SPAN_WARNING("Your eyes are really starting to hurt. This can't be good for you!")

			if (E.damage >= E.min_broken_damage)
				H << SPAN_DANGER("You go blind!")
				H.sdisabilities |= BLIND
			else if (E.damage >= E.min_bruised_damage)
				H << SPAN_DANGER("You go blind!")
				H.eye_blind = 5
				H.eye_blurry = 5
				H.disabilities |= NEARSIGHTED
				spawn(100)
					H.disabilities &= ~NEARSIGHTED


/obj/item/weapon/tool/attack(mob/living/M, mob/living/user, var/target_zone)
	if ((user.a_intent == I_HELP) && ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/organ/external/S = H.organs_by_name[user.targeted_organ]

		if (!istype(S) || S.robotic < ORGAN_ROBOT)
			return ..()

		if (get_tool_type(user, list(QUALITY_WELDING))) //Prosthetic repair
			if (S.brute_dam)
				if (S.brute_dam < ROBOLIMB_SELF_REPAIR_CAP)
					if (use_tool(user, H, WORKTIME_FAST, QUALITY_WELDING, FAILCHANCE_NORMAL, required_stat = STAT_MEC))
						S.heal_damage(15,0,0,1)
						user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
						user.visible_message(SPAN_NOTICE("\The [user] patches some dents on \the [H]'s [S.name] with \the [src]."))
						return 1
				else if (S.open != 2)
					user << SPAN_DANGER("The damage is far too severe to patch over externally.")
					return 1
			else if (S.open != 2) // For surgery.
				user << SPAN_NOTICE("Nothing to fix!")
				return 1

	return ..()

/obj/item/weapon/tool/update_icon()
	overlays.Cut()

	if(switched_on && toggleable)
		overlays += "[icon_state]_on"

	if(use_power_cost)
		var/ratio = 0
		//make sure that rounding down will not give us the empty state even if we have charge for a shot left.
		if(cell && cell.charge >= use_power_cost)
			ratio = cell.charge / cell.maxcharge
			ratio = max(round(ratio, 0.25) * 100, 25)
			overlays += "[icon_state]-[ratio]"

	if(use_fuel_cost)
		var/ratio = 0
		//make sure that rounding down will not give us the empty state even if we have charge for a shot left.
		if(get_fuel() >= use_fuel_cost)
			ratio = get_fuel() / max_fuel
			ratio = max(round(ratio, 0.25) * 100, 25)
			overlays += "[icon_state]-[ratio]"


/obj/item/weapon/tool/admin_debug
	name = "Electric Boogaloo 3000"
	icon_state = "omnitool"
	item_state = "omnitool"
	tool_qualities = list(QUALITY_BOLT_TURNING = 100,
							QUALITY_PRYING = 100,
							QUALITY_WELDING = 100,
							QUALITY_SCREW_DRIVING = 100,
							QUALITY_CLAMPING = 100,
							QUALITY_CAUTERIZING = 100,
							QUALITY_WIRE_CUTTING = 100,
							QUALITY_RETRACTING = 100,
							QUALITY_DRILLING = 100,
							QUALITY_SAWING = 100,
							QUALITY_VEIN_FIXING = 100,
							QUALITY_BONE_SETTING = 100,
							QUALITY_BONE_FIXING = 100,
							QUALITY_SHOVELING = 100,
							QUALITY_DIGGING = 100,
							QUALITY_EXCAVATION = 100,
							QUALITY_CUTTING = 100)
