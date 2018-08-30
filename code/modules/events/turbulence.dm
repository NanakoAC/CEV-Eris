/datum/event/turbulence
	var/slide_chance_mundane = 20//5
	var/slide_chance_moderate = 50//20
	var/slide_chance_major = 	100//40

	var/list/items_to_throw = list()

	var/started = FALSE

/datum/event/turbulence/announce()
	command_announcement.Announce("Turbulence!", "Turbulence")


/datum/event/turbulence/start()

	if (started)
		crash_with("Turbulence event started twice! activeFor [activeFor], startWhen [startWhen]")

	started = TRUE

	var/total = 0
	for (var/obj/item/i in world)
		if (!i.z in maps_data.station_levels)
			continue
		if (!istype(i.loc, /turf))
			continue
		if (i.anchored)
			continue
		var/turf/target = pick(trange(7, i.loc)-i.loc)
		items_to_throw["\ref[i]"] = "\ref[target]"

	world << "Listed [items_to_throw.len] items"
	for (var/a in items_to_throw)
		var/obj/item/i = locate(a)
		var/turf/target = locate(items_to_throw[a])
		if (!i || !target)
			continue
		i.throw_at(target, i.throw_range *(rand()*2), i.throw_speed *(rand()*2), null)
		total++

		//Occasionally sleep for a frame in order to not lockup the server
		if (world.tick_usage >= 70)
			world << "Sleeping, thrown [total] items"
			sleep()

	world << "Threw [total] items"