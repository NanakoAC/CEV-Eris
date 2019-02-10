/obj
	var/oldified = FALSE  // Whether the item has underwent make_old()
	// var/crit_fail = FALSE // In theory should make the item fail horifically, currently only used in vending.dm

/obj/proc/make_old()
	if (oldified)
		return
	color = pick("#AA7744", "#774411", "#777777")
	light_color = color
	name = "[pick("old", "worn", "rusted", "weathered", "expired", "dirty", "frayed", "beaten", "ancient", "tarnished")] [initial(name)]"
	desc += pick("\nWarranty has expired.", "\nThe inscriptions on this thing were erased by time.", "\nLooks completely wasted.")

	germ_level = pick(80,110,160)

	for(var/obj/item/sub_item in contents)
		sub_item.make_old()

	oldified = TRUE


	update_icon()

/obj/item/make_old()
	..()
	if(prob(75))
		origin_tech = null
	siemens_coefficient += 0.3

/obj/item/weapon/tool/make_old()
	..()
	unreliability += rand(40, 100) * degradation

/obj/item/weapon/storage/make_old()
	var/del_count = rand(0, contents.len)
	for(var/i = 1 to del_count)
		var/removed_item = pick(contents)
		contents -= removed_item
		qdel(removed_item)

	if(storage_slots && prob(75))
		storage_slots = max(contents.len, max(0, storage_slots - pick(2, 2, 2, 3, 3, 4)))
	if(max_storage_space && prob(75))
		max_storage_space = max_storage_space / 2

	..()

/obj/item/weapon/reagent_containers/make_old()
	var/actual_volume = reagents.total_volume
	for(var/datum/reagent/R in reagents.reagent_list)
		R.volume = rand(0, R.volume)
	reagents.add_reagent("toxin", rand(0, actual_volume - reagents.total_volume))
	..()

//Sealed survival food, always edible
/obj/item/weapon/reagent_containers/food/snacks/liquidfood/make_old()
	return

/obj/item/ammo_magazine/make_old()
	var/del_count = rand(0,contents.len)
	for(var/i = 1 to del_count)
		var/removed_item = pick(stored_ammo)
		stored_ammo -= removed_item
		qdel(removed_item)
	..()

/obj/item/weapon/cell/make_old()
	charge = min(charge, rand_between(0, maxcharge))
	if(prob(10))
		rigged = TRUE
		if(prob(80))
			charge = maxcharge  //make it BOOM hard
	..()

/obj/item/weapon/stock_parts/make_old()
	var/degrade = pick(0,1,1,1,2)
	rating = max(rating - degrade, 1)
	..()

/obj/item/stack/material/make_old()
	return

/obj/item/stack/rods/make_old()
	return

/obj/item/weapon/grenade/make_old()
	..()
	det_time = rand_between(0, det_time)

/obj/item/weapon/tank/make_old()
	air_contents.remove(pick(0.2, 0.4 ,0.6, 0.8))
	..()

/obj/item/weapon/circuitboard/make_old()
	if(prob(75))
		name = T_BOARD("unknown")
		build_path = pick(/obj/machinery/washing_machine, /obj/machinery/broken, /obj/machinery/shower, /obj/machinery/holoposter, /obj/machinery/holosign)
	..()

/obj/item/weapon/aiModule/make_old()
	if(prob(75) && !istype(src, /obj/item/weapon/aiModule/broken))
		var/obj/item/weapon/aiModule/brokenmodule = new /obj/item/weapon/aiModule/broken
		brokenmodule.name = src.name
		brokenmodule.desc = src.desc
		brokenmodule.make_old()
		qdel(src)
	..()

/obj/item/clothing/suit/space/make_old()
	if(prob(50))
		create_breaches(pick(BRUTE, BURN), rand(10, 50))
	..()

/obj/item/clothing/make_old()
	if(prob(30))
		slowdown += pick(0.5, 0.5, 1, 1.5)
	if(prob(50))
		armor["melee"] = rand(0, armor["melee"])
		armor["bullet"] = rand(0, armor["bullet"])
		armor["laser"] = rand(0, armor["laser"])
		armor["energy"] = rand(0, armor["energy"])
		armor["bomb"] = rand(0, armor["bomb"])
		armor["bio"] = rand(0, armor["bio"])
		armor["rad"] = rand(0, armor["rad"])
	if(prob(50))
		heat_protection = rand(0, round(heat_protection * 0.5))
	if(prob(50))
		cold_protection = rand(0, round(cold_protection * 0.5))
	if(prob(50))
		contaminate()
	if(prob(60))
		add_blood()
	if(prob(60)) // I mean, the thing is ew gross.
		equip_delay += rand(0, 6 SECONDS)
	..()

/obj/item/weapon/aiModule/broken
	name = "\improper broken core AI module"
	desc = "broken Core AI Module: 'Reconfigures the AI's core laws.'"

/obj/machinery/broken/Initialize()
	..()
	explosion(loc, 1, 2, 3, 3)
	return INITIALIZE_HINT_QDEL

/obj/machinery/broken/Destroy()
	contents.Cut()
	return ..()

/obj/item/weapon/aiModule/broken/transmitInstructions(mob/living/silicon/ai/target, mob/sender)
	..()
	IonStorm(0)
	explosion(sender.loc, 1, 1, 1, 3)
	sender.drop_from_inventory(src)
	qdel(src)

/obj/item/weapon/dnainjector/make_old()
	if(prob(75))
		name = "DNA-Injector (unknown)"
		desc = pick("1mm0r74l17y 53rum", "1ncr3d1bl3 73l3p47y hNlk", "5up3rhum4n m16h7")
		value = 0xFFF
	if(prob(75))
		block = pick(MONKEYBLOCK, HALLUCINATIONBLOCK, DEAFBLOCK, BLINDBLOCK, NERVOUSBLOCK, TWITCHBLOCK, CLUMSYBLOCK, COUGHBLOCK, HEADACHEBLOCK, GLASSESBLOCK)
	..()

/obj/item/clothing/glasses/hud/make_old()
	if(prob(75) && !istype(src, /obj/item/clothing/glasses/hud/broken))
		var/obj/item/clothing/glasses/hud/broken/brokenhud = new /obj/item/clothing/glasses/hud/broken
		brokenhud.name = src.name
		brokenhud.desc = src.desc
		brokenhud.icon = src.icon
		brokenhud.icon_state = src.icon_state
		brokenhud.item_state = src.item_state
		brokenhud.make_old()
		qdel(src)
	..()

/obj/item/clothing/glasses/make_old()
	..()
	if(prob(75))
		vision_flags = 0
	if(prob(75))
		darkness_view = -1

/obj/item/device/lighting/glowstick/make_old()
	..()
	if(prob(75))
		fuel = rand(0, fuel)

/obj/item/device/lighting/toggleable/make_old()
	..()
	if(prob(75))
		brightness_on = brightness_on / 2

/obj/machinery/floodlight/make_old()
	..()
	if(prob(75))
		brightness_on = brightness_on / 2

/obj/machinery/make_old()
	..()
	if(prob(60))
		stat |= BROKEN
	if(prob(60))
		emagged = TRUE

/obj/machinery/vending/make_old()
	..()
	if(prob(60))
		seconds_electrified = -1
	if(prob(60))
		shut_up = 0
	if(prob(60))
		shoot_inventory = 1
	if(prob(75))
		var/del_count = rand(0,product_records.len)
		for(var/i = 1 to del_count)
			var/removed_item = pick(contents)
			contents -= removed_item

/obj/machinery/vending/make_old()
	..()
	if(prob(60))
		vend_power_usage *= pick(1, 1.3, 1.5, 1.7, 2.0)
	if(prob(60))
		seconds_electrified = -1
	if(prob(60))
		shut_up = FALSE
		slogan_delay = rand(round(slogan_delay * 0.5), slogan_delay)
	if(prob(60))
		shoot_inventory = TRUE

	var/del_count = rand(0, product_records.len)
	for(var/i in 1 to del_count)
		product_records.Remove(pick(product_records))

/obj/item/clothing/glasses/sunglasses/sechud/make_old()
	..()
	if(hud && prob(75))
		hud = new /obj/item/clothing/glasses/hud/broken

/obj/effect/decal/mecha_wreckage/make_old()
	salvage_num = max(1, salvage_num - pick(1, 2, 3))


/obj/mecha/make_old()
	//Now we determine the exosuit's condition
	switch (rand(0,100))
		if (0 to 3)
		//Perfect condition, it was well cared for and put into storage in a pristine state
		//Nothing is done to it.
		if (4 to 10)
		//Poorly maintained.
		//The internal airtank and power cell will be somewhat depleted, otherwise intact
			var/P = rand(0,50)
			P /= 100
			if (cell)//Set the cell to a random charge below 50%
				cell.charge =  cell.maxcharge * P

			P = rand(50,100)
			P /= 100
			if(internal_tank)//remove 50-100% of airtank contents
				internal_tank.air_contents.remove(internal_tank.air_contents.total_moles * P)


		if (11 to 20)
		//Wear and tear
		//Hull has light to moderate damage, tank and cell are depleted
		//Any equipment will have a 25% chance to be lost
			var/P = rand(0,30)
			P /= 100
			if (cell)//Set the cell to a random charge below 50%
				cell.charge =  cell.maxcharge * P

			P = rand(70,100)
			P /= 100
			if(internal_tank)//remove 50-100% of airtank contents
				internal_tank.air_contents.remove(internal_tank.air_contents.total_moles * P)

			lose_equipment(25)//Lose modules

			P = rand(10,100)//Set hull integrity
			P /= 100
			health = initial(health)*P


		if (21 to 40)
		//Severe damage
		//Power cell has 50% chance to be missing or is otherwise low
		//Significant chance for internal damage
		//Hull integrity less than half
		//Each module has a 50% loss chance
		//Systems may be misconfigured
			var/P

			if (prob(50))//Remove cell
				cell = null
			else
				P = rand(0,20)//or deplete it
				P /= 100
				if (cell)//Set the cell to a random charge below 50%
					cell.charge = cell.maxcharge * P

			P = rand(80,100)
			P /= 100//Deplete tank
			if(internal_tank)//remove 50-100% of airtank contents
				internal_tank.air_contents.remove(internal_tank.air_contents.total_moles * P)

			lose_equipment(50)//Lose modules
			random_internal_damage(15)//Internal damage

			P = rand(5,50)//Set hull integrity
			P /= 100
			health = initial(health)*P
			misconfigure_systems(15)


		if (41 to 80)
		//Decomissioned
		//The exosuit is a writeoff, it was tossed into storage for later scrapping.
		//Wasnt considered worth repairing, but you still can
		//Power cell missing, internal tank completely drained or ruptured/
		//65% chance for each type of internal damage
		//90% chance to lose each equipment
		//System settings will be randomly configured
			var/P
			if (prob(15))
				cell.rigged = 1//Powercell will explode if you use it
			else if (prob(50))//Remove cell
				cell = null

			if (cell)
				P = rand(0,20)//or deplete it
				P /= 100
				if (cell)//Set the cell to a random charge below 50%
					cell.charge =  cell.maxcharge * P

			lose_equipment(90)//Lose modules
			random_internal_damage(50)//Internal damage

			if (!hasInternalDamage(MECHA_INT_TANK_BREACH))//If the tank isn't breaches
				qdel(internal_tank)//Then delete it
				internal_tank = null

			P = rand(5,50)//Set hull integrity
			P /= 100
			health = initial(health)*P
			misconfigure_systems(45)


		if (81 to 100)
		//Salvage
		//The exosuit is wrecked. Spawns a wreckage object instead of a suit
			//Set the noexplode var so it doesn't explode, then just qdel it
			//The destroy proc handles wreckage generation
			noexplode = 1
			qdel(src)

	//Finally, so that the exosuit seems like it's been in storage for a while
	//We will take any malfunctions to their logical conclusion, and set the error states high

	//If the tank has a breach, then there will be no air left
	if (hasInternalDamage(MECHA_INT_TANK_BREACH) && internal_tank)
		internal_tank.air_contents.remove(internal_tank.air_contents.total_moles)

	//If there's an electrical fault, the cell will be complerely drained
	if (hasInternalDamage(MECHA_INT_SHORT_CIRCUIT) && cell)
		cell.charge = 0


	//Code for interacting with damage+power warnings, an unported aurora feature
	/*
	process_warnings()//Trigger them first, if they'll happen

	if (power_alert_status)
		last_power_warning = -99999999
		//Make it go into infrequent warning state instantly
		power_warning_delay = 99999999
		//and set the delay between warnings to a functionally infinite value
		//so that it will shut up

	if (damage_alert_status)
		last_damage_warning = -99999999
		damage_warning_delay = 99999999

	process_warnings()
	*/