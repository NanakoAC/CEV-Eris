/obj/item
	name = "item"
	icon = 'icons/obj/items.dmi'
	w_class = ITEM_SIZE_NORMAL

	var/image/blood_overlay = null //this saves our blood splatter overlay, which will be processed not to go over the edges of the sprite
	var/abstract = 0
	var/r_speed = 1.0
	var/health = null
	var/burn_point = null
	var/burning = null
	var/hitsound = null
	var/worksound = null
	var/storage_cost = null
	var/no_attack_log = 0			//If it's an item we don't want to log attack_logs with, set this to 1
	pass_flags = PASSTABLE
//	causeerrorheresoifixthis
	var/obj/item/master = null
	var/list/origin_tech = null	//Used by R&D to determine what research bonuses it grants.
	var/list/attack_verb = list() //Used in attackby() to say how something was attacked "[x] has been [z.attack_verb] by [y] with [z]"
	var/force = 0

	var/heat_protection = 0 //flags which determine which body parts are protected from heat. Use the HEAD, UPPER_TORSO, LOWER_TORSO, etc. flags. See setup.dm
	var/cold_protection = 0 //flags which determine which body parts are protected from cold. Use the HEAD, UPPER_TORSO, LOWER_TORSO, etc. flags. See setup.dm
	var/max_heat_protection_temperature //Set this variable to determine up to which temperature (IN KELVIN) the item protects against heat damage. Keep at null to disable protection. Only protects areas set by heat_protection flags
	var/min_cold_protection_temperature //Set this variable to determine down to which temperature (IN KELVIN) the item protects against cold damage. 0 is NOT an acceptable number due to if(varname) tests!! Keep at null to disable protection. Only protects areas set by cold_protection flags

	var/datum/action/item_action/action = null
	var/action_button_name //It is also the text which gets displayed on the action button. If not set it defaults to 'Use [name]'. If it's not set, there'll be no button.
	var/action_button_is_hands_free = 0 //If 1, bypass the restrained, lying, and stunned checks action buttons normally test for

	//This flag is used to determine when items in someone's inventory cover others. IE helmets making it so you can't see glasses, etc.
	//It should be used purely for appearance. For gameplay effects caused by items covering body parts, use body_parts_covered.
	var/flags_inv = 0
	var/body_parts_covered = 0 //see setup.dm for appropriate bit flags

	var/list/tool_qualities = null// List of item qualities for tools system. See qualities.dm.

	//var/heat_transfer_coefficient = 1 //0 prevents all transfers, 1 is invisible
	var/gas_transfer_coefficient = 1 // for leaking gas from turf to mask and vice-versa (for masks right now, but at some point, i'd like to include space helmets)
	var/permeability_coefficient = 1 // for chemicals/diseases
	var/siemens_coefficient = 1 // for electrical admittance/conductance (electrocution checks and shit)
	var/slowdown = 0 // How much clothing is slowing you down. Negative values speeds you up
	var/list/armor = list(melee = 0, bullet = 0, laser = 0,energy = 0, bomb = 0, bio = 0, rad = 0)
	var/list/allowed = null //suit storage stuff.
	var/obj/item/device/uplink/hidden/hidden_uplink = null // All items can have an uplink hidden inside, just remember to add the triggers.
	var/zoomdevicename = null //name used for message when binoculars/scope is used
	var/zoom = 0 //1 if item is actively being used to zoom. For scoped guns and binoculars.

	var/icon_override = null  //Used to override hardcoded clothing dmis in human clothing proc.

	//** These specify item/icon overrides for _slots_

	var/list/item_state_slots = list() //overrides the default item_state for particular slots.

	// Used to specify the icon file to be used when the item is worn. If not set the default icon for that slot will be used.
	// If icon_override or sprite_sheets are set they will take precendence over this, assuming they apply to the slot in question.
	// Only slot_l_hand/slot_r_hand are implemented at the moment. Others to be implemented as needed.
	var/list/item_icons = list()

/obj/item/Destroy()
	if(ismob(loc))
		var/mob/m = loc
		m.drop_from_inventory(src)
		src.loc = null
	return ..()

/obj/item/get_fall_damage()
	return w_class * 2

/obj/item/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				qdel(src)
				return
		if(3.0)
			if (prob(5))
				qdel(src)
				return

/obj/item/verb/move_to_top()
	set name = "Move To Top"
	set category = "Object"
	set src in oview(1)

	if(!istype(src.loc, /turf) || usr.stat || usr.restrained() )
		return

	var/turf/T = src.loc

	src.loc = null

	src.loc = T

/obj/item/examine(mob/user, var/distance = -1)
	var/message
	for(var/Q in tool_qualities)
		message += "\n<blue>This item posses [tool_qualities[Q]] tier of [Q] quality.<blue>"

	var/size
	switch(src.w_class)
		if(1.0)
			size = "tiny"
		if(2.0)
			size = "small"
		if(3.0)
			size = "normal-sized"
		if(4.0)
			size = "bulky"
		if(5.0)
			size = "huge"
	message += "\nIt is a [size] item."
	return ..(user, distance, "", message)

/obj/item/attack_hand(mob/user as mob)
	if (!user || !user.can_pickup(src))
		return

	var/atom/old_loc = src.loc

	src.pickup(user)
	if (istype(src.loc, /obj/item/weapon/storage))
		var/obj/item/weapon/storage/S = src.loc
		S.remove_from_storage(src)

	src.throwing = 0
	if (src.loc == user)
		if(!user.prepare_for_slotmove(src))
			return
	else
		if(isliving(src.loc))
			return

	if(user.put_in_active_hand(src) && old_loc )
		if (user != old_loc.get_holding_mob())
			do_pickup_animation(user,old_loc)

/obj/item/attack_ai(mob/user as mob)
	if (istype(src.loc, /obj/item/weapon/robot_module))
		//If the item is part of a cyborg module, equip it
		if(!isrobot(user))
			return
		var/mob/living/silicon/robot/R = user
		R.activate_module(src)
//		R.hud_used.update_robot_modules_display()

/obj/item/proc/talk_into(mob/M, text)
	return

/obj/item/proc/moved(mob/user as mob, old_loc as turf)
	return

// Called whenever an object is moved out of a mob's equip slot. Possibly into another slot, possibly to elsewhere
// Linker proc: mob/proc/prepare_for_slotmove, which is referenced in proc/handle_item_insertion and obj/item/attack_hand.
// This exists so that dropped() could exclusively be called when an item is dropped.
/obj/item/proc/on_slotmove(var/mob/user)
	if (zoom)
		zoom(user)


// called just as an item is picked up (loc is not yet changed)
/obj/item/proc/pickup(mob/user)
	return

// called when this item is removed from a storage item, which is passed on as S. The loc variable is already set to the new destination before this is called.
/obj/item/proc/on_exit_storage(obj/item/weapon/storage/S as obj)
	return

// called when this item is added into a storage item, which is passed on as S. The loc variable is already set to the storage item.
/obj/item/proc/on_enter_storage(obj/item/weapon/storage/S as obj)
	return

// called when "found" in pockets and storage items. Returns 1 if the search should end.
/obj/item/proc/on_found(mob/finder as mob)
	return
/obj/item/verb/verb_pickup()
	set src in oview(1)
	set category = "Object"
	set name = "Pick up"

	if(!usr) //BS12 EDIT
		return
	if(!usr.canmove || usr.stat || usr.restrained() || !Adjacent(usr))
		return
	if(!iscarbon(usr) || isbrain(usr))//Is humanoid, and is not a brain
		usr << SPAN_WARNING("You can't pick things up!")
		return
	if( usr.stat || usr.restrained() )//Is not asleep/dead and is not restrained
		usr << SPAN_WARNING("You can't pick things up!")
		return
	if(src.anchored) //Object isn't anchored
		usr << SPAN_WARNING("You can't pick that up!")
		return
	if(!usr.hand && usr.r_hand) //Right hand is not full
		usr << SPAN_WARNING("Your right hand is full.")
		return
	if(usr.hand && usr.l_hand) //Left hand is not full
		usr << SPAN_WARNING("Your left hand is full.")
		return
	if(!istype(src.loc, /turf)) //Object is on a turf
		usr << SPAN_WARNING("You can't pick that up!")
		return
	//All checks are done, time to pick it up!
	usr.UnarmedAttack(src)


//This proc is executed when someone clicks the on-screen UI button. To make the UI button show, set the 'icon_action_button' to the icon_state of the image of the button in screen1_action.dmi
//The default action is attack_self().
//Checks before we get to here are: mob is alive, mob is not restrained, paralyzed, asleep, resting, laying, item is on the mob.
/obj/item/proc/ui_action_click()
	attack_self(usr)

//RETURN VALUES
//handle_shield should return a positive value to indicate that the attack is blocked and should be prevented.
//If a negative value is returned, it should be treated as a special return value for bullet_act() and handled appropriately.
//For non-projectile attacks this usually means the attack is blocked.
//Otherwise should return 0 to indicate that the attack is not affected in any way.
/obj/item/proc/handle_shield(mob/user, var/damage, atom/damage_source = null, mob/attacker = null, var/def_zone = null, var/attack_text = "the attack")
	return 0

/obj/item/proc/get_loc_turf()
	var/atom/L = loc
	while(L && !istype(L, /turf/))
		L = L.loc
	return loc

/obj/item/proc/eyestab(mob/living/carbon/M as mob, mob/living/carbon/user as mob)

	var/mob/living/carbon/human/H = M
	if(istype(H))
		for(var/obj/item/protection in list(H.head, H.wear_mask, H.glasses))
			if(protection && (protection.body_parts_covered & EYES))
				// you can't stab someone in the eyes wearing a mask!
				user << SPAN_WARNING("You're going to need to remove the eye covering first.")
				return

	if(!M.has_eyes())
		user << SPAN_WARNING("You cannot locate any eyes on [M]!")
		return

	user.attack_log += "\[[time_stamp()]\]<font color='red'> Attacked [M.name] ([M.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>"
	M.attack_log += "\[[time_stamp()]\]<font color='orange'> Attacked by [user.name] ([user.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>"
	msg_admin_attack("[user.name] ([user.ckey]) attacked [M.name] ([M.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)") //BS12 EDIT ALG

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	user.do_attack_animation(M)

	src.add_fingerprint(user)
	//if((CLUMSY in user.mutations) && prob(50))
	//	M = user
		/*
		M << SPAN_WARNING("You stab yourself in the eye.")
		M.sdisabilities |= BLIND
		M.weakened += 4
		M.adjustBruteLoss(10)
		*/

	if(istype(H))

		var/obj/item/organ/internal/eyes/eyes = H.internal_organs_by_name[O_EYES]

		if(!eyes)
			return

		if(H != user)
			for(var/mob/O in (viewers(M) - user - M))
				O.show_message(SPAN_DANGER("[M] has been stabbed in the eye with [src] by [user]."), 1)
			M << SPAN_DANGER("[user] stabs you in the eye with [src]!")
			user << SPAN_DANGER("You stab [M] in the eye with [src]!")
		else
			user.visible_message( \
				SPAN_DANGER("[user] has stabbed themself with [src]!"), \
				SPAN_DANGER("You stab yourself in the eyes with [src]!") \
			)

		eyes.damage += rand(3,4)
		if(eyes.damage >= eyes.min_bruised_damage)
			if(M.stat != DEAD)
				if(eyes.robotic <= ORGAN_ASSISTED) //robot eyes bleeding might be a bit silly
					M << SPAN_DANGER("Your eyes start to bleed profusely!")
			if(prob(50))
				if(M.stat != DEAD)
					M << SPAN_WARNING("You drop what you're holding and clutch at your eyes!")
					M.drop_item()
				M.eye_blurry += 10
				M.Paralyse(1)
				M.Weaken(4)
			if (eyes.damage >= eyes.min_broken_damage)
				if(M.stat != 2)
					M << SPAN_WARNING("You go blind!")
		var/obj/item/organ/external/affecting = H.get_organ(BP_HEAD)
		if(affecting.take_damage(7))
			M:UpdateDamageIcon()
	else
		M.take_organ_damage(7)
	M.eye_blurry += rand(3,4)

/obj/item/clean_blood()
	. = ..()
	if(blood_overlay)
		overlays.Remove(blood_overlay)
	if(istype(src, /obj/item/clothing/gloves))
		var/obj/item/clothing/gloves/G = src
		G.transfer_blood = 0

/obj/item/reveal_blood()
	if(was_bloodied && !fluorescent)
		fluorescent = 1
		blood_color = COLOR_LUMINOL
		blood_overlay.color = COLOR_LUMINOL
		update_icon()

/obj/item/add_blood(mob/living/carbon/human/M as mob)
	if (!..())
		return 0

	if(istype(src, /obj/item/weapon/melee/energy))
		return

	//if we haven't made our blood_overlay already
	if( !blood_overlay )
		generate_blood_overlay()

	//apply the blood-splatter overlay if it isn't already in there
	if(!blood_DNA.len)
		blood_overlay.color = blood_color
		overlays += blood_overlay

	//if this blood isn't already in the list, add it
	if(istype(M))
		if(blood_DNA[M.dna.unique_enzymes])
			return 0 //already bloodied with this blood. Cannot add more.
		blood_DNA[M.dna.unique_enzymes] = M.dna.b_type
	return 1 //we applied blood to the item

var/global/list/items_blood_overlay_by_type = list()
/obj/item/proc/generate_blood_overlay()
	if(blood_overlay)
		return

	var/image/IMG = items_blood_overlay_by_type[type]
	if(IMG)
		blood_overlay = IMG
	else
		var/icon/ICO = new /icon(icon, icon_state)
		ICO.Blend(new /icon('icons/effects/blood.dmi', rgb(255, 255, 255)), ICON_ADD) // fills the icon_state with white (except where it's transparent)
		ICO.Blend(new /icon('icons/effects/blood.dmi', "itemblood"), ICON_MULTIPLY)   // adds blood and the remaining white areas become transparant
		IMG = image("icon" = ICO)
		items_blood_overlay_by_type[type] = IMG
		blood_overlay = IMG

/obj/item/proc/showoff(mob/user)
	for (var/mob/M in view(user))
		M.show_message("[user] holds up [src]. <a HREF=?src=\ref[M];lookitem=\ref[src]>Take a closer look.</a>",1)

/mob/living/carbon/verb/showoff()
	set name = "Show Held Item"
	set category = "Object"

	var/obj/item/I = get_active_hand()
	if(I && !I.abstract)
		I.showoff(src)

/*
For zooming with scope or binoculars. This is called from
modules/mob/mob_movement.dm if you move you will be zoomed out
modules/mob/living/carbon/human/life.dm if you die, you will be zoomed out.
*/
//Looking through a scope or binoculars should /not/ improve your periphereal vision. Still, increase viewsize a tiny bit so that sniping isn't as restricted to NSEW
/obj/item/proc/zoom(var/tileoffset = 14,var/viewsize = 9) //tileoffset is client view offset in the direction the user is facing. viewsize is how far out this thing zooms. 7 is normal view

	var/devicename

	if(zoomdevicename)
		devicename = zoomdevicename
	else
		devicename = src.name

	var/cannotzoom

	if(usr.stat || !(ishuman(usr)))
		usr << "You are unable to focus through the [devicename]"
		cannotzoom = 1
	else if(!zoom && global_hud.darkMask[1] in usr.client.screen)
		usr << "Your visor gets in the way of looking through the [devicename]"
		cannotzoom = 1
	else if(!zoom && usr.get_active_hand() != src)
		usr << "You are too distracted to look through the [devicename], perhaps if it was in your active hand this might work better"
		cannotzoom = 1

	if(!zoom && !cannotzoom)
		//if(usr.hud_used.hud_shown)
			//usr.toggle_zoom_hud()	// If the user has already limited their HUD this avoids them having a HUD when they zoom in
		usr.client.view = viewsize
		zoom = 1

		var/tilesize = 32
		var/viewoffset = tilesize * tileoffset

		switch(usr.dir)
			if (NORTH)
				usr.client.pixel_x = 0
				usr.client.pixel_y = viewoffset
			if (SOUTH)
				usr.client.pixel_x = 0
				usr.client.pixel_y = -viewoffset
			if (EAST)
				usr.client.pixel_x = viewoffset
				usr.client.pixel_y = 0
			if (WEST)
				usr.client.pixel_x = -viewoffset
				usr.client.pixel_y = 0

		usr.visible_message("[usr] peers through the [zoomdevicename ? "[zoomdevicename] of the [src.name]" : "[src.name]"].")

	else
		usr.client.view = world.view
		//if(!usr.hud_used.hud_shown)
			//usr.toggle_zoom_hud()
		zoom = 0

		usr.client.pixel_x = 0
		usr.client.pixel_y = 0

		if(!cannotzoom)
			usr.visible_message("[zoomdevicename ? "[usr] looks up from the [src.name]" : "[usr] lowers the [src.name]"].")

	return

/obj/item/proc/pwr_drain()
	return 0 // Process Kill

/* QUALITY AND TOOL SYSTEM */

/obj/item/proc/has_quality(quality_id)
	return quality_id in tool_qualities

/obj/item/proc/get_tool_quality(quality_id)
	return tool_qualities[quality_id]

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

//Simple form ideal for basic use. That proc will return TRUE only when everything was done right, and FALSE if something went wrong, ot user was unlucky.
//Editionaly, handle_failure proc will be called for a critical failure roll.
/obj/item/proc/use_tool(var/mob/living/user, var/atom/target, base_time, required_quality, fail_chance, required_stat = null, instant_finish_tier = 110, forced_sound = null)
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
/obj/item/proc/use_tool_extended(var/mob/living/user, var/atom/target, base_time, required_quality, fail_chance, required_stat = null, instant_finish_tier = 110, forced_sound = null)
	if(target.used_now)
		user << SPAN_WARNING("[target.name] is used by someone. Wait for them to finish.")
		return TOOL_USE_CANCEL

	if(istype(src, /obj/item/weapon/tool))
		var/obj/item/weapon/tool/T = src
		if(!T.check_tool_effects(user))
			return TOOL_USE_CANCEL

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.shock_stage >= 30)
			user << SPAN_WARNING("Pain distracts you from your task.")
			fail_chance += round(H.shock_stage/120 * 40)
			base_time += round(H.shock_stage/120 * 40)

	if(forced_sound != NO_WORKSOUND)
		if(forced_sound)
			playsound(src.loc, forced_sound, 100, 1)
		else
			playsound(src.loc, src.worksound, 100, 1)

	if(base_time && (instant_finish_tier >= get_tool_quality(required_quality)))
		target.used_now = TRUE
		var/time_to_finish = base_time - get_tool_quality(required_quality) - user.stats.getStat(required_stat)
		if(!do_after(user, time_to_finish, user))
			user << SPAN_WARNING("You need to stand still to finish the task properly!")
			target.used_now = FALSE
			return TOOL_USE_CANCEL
		else
			target.used_now = FALSE

	var/stat_modifer = 0
	if(required_stat)
		stat_modifer = user.stats.getStat(required_stat)
	fail_chance = fail_chance - get_tool_quality(required_quality) - stat_modifer
	if(prob(fail_chance))
		user << SPAN_WARNING("You failed to finish your task with [src.name]! There was a [fail_chance]% chance to screw this up.")
		return TOOL_USE_FAIL

	return TOOL_USE_SUCCESS

//Critical failture rolls. If you use use_tool_extended, you might want to call that proc as well.
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

			if(85 to 93)
				if(ishuman(user))
					user << SPAN_DANGER("Your [src] broke beyond repair!")
					new /obj/item/weapon/material/shard/shrapnel(user.loc)
					qdel(src)
					return

			if(94 to 100)
				if(ishuman(user))
					if(istype(src, /obj/item/weapon/tool))
						var/obj/item/weapon/tool/T = src
						if(T.use_fuel_cost)
							user << SPAN_DANGER("You ignite the fuel of the [src]!")
							explosion(src.loc,-1,1,2)
							qdel(src)
							return
						if(T.use_power_cost)
							user << SPAN_DANGER("You overload the cell in the [src]!")
							explosion(src.loc,-1,1,2)
							qdel(src)
							return


/obj/item/device
	icon = 'icons/obj/device.dmi'
