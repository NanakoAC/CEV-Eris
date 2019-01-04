var/global/list/all_objectives = list()
var/global/list/all_objectives_types = null

/hook/startup/proc/init_objectives()
	all_objectives_types = list()
	var/indent = length("[/datum/objective]/")
	for(var/path in subtypesof(/datum/objective))
		var/id = copytext("[path]", indent+1)
		all_objectives_types[id] = path
	return TRUE

/datum/objective
	var/datum/antagonist/antag = null
	var/datum/mind/owner = null			//Who owns the objective.
	var/datum/faction/owner_faction = null
	var/explanation_text = "Nothing"	//What that person is supposed to do.
	var/datum/mind/target = null		//If they are focused on a particular person.
	var/target_amount = 0				//If they are focused on a particular number. Steal objectives have their own counter.
	var/completed = FALSE				//currently only used for custom objectives.

/datum/objective/New(var/datum/antagonist/new_owner, var/datum/mind/target)
	if (istype(new_owner))
		antag = new_owner
		antag.objectives += src
		if(antag.owner)
			owner = antag.owner
	else if (istype(new_owner, /datum/faction))
		owner_faction = new_owner
	if(!target)
		find_target()
	update_explanation()
	all_objectives.Add(src)
	..()

/datum/objective/Destroy()
	if(antag)
		antag.objectives -= src
		antag = null
	if(owner)
		owner = null
	if(target)
		target = null
	all_objectives.Remove(src)
	. = ..()

/datum/objective/proc/update_completion()	//This is for objectives requiring mid-round check, like harm or baptize
	return

/datum/objective/proc/check_completion()
	return completed

/datum/objective/proc/get_targets_list()
	var/list/possible_targets = list()
	for(var/datum/mind/possible_target in SSticker.minds)
		if(possible_target != owner && ishuman(possible_target.current) && (possible_target.current.stat != 2))
			possible_targets.Add(possible_target)
	return possible_targets


/datum/objective/proc/find_target()
	var/list/possible_targets = get_targets_list()
	if(possible_targets.len > 0)
		set_target(pick(possible_targets))

/datum/objective/proc/set_target(var/datum/mind/new_target)
	if(new_target)
		target = new_target
		update_explanation()

/datum/objective/proc/select_human_target(var/mob/user)
	var/list/possible_targets = get_targets_list()
	if(!possible_targets || !possible_targets.len)
		user << SPAN_WARNING("Sorry! No possible targets found!")
		return
	var/datum/mind/M = input(user, "New target") as null|anything in possible_targets
	if(M)
		target = M
		update_explanation()


/datum/objective/proc/update_explanation()

/datum/objective/proc/get_panel_entry()
	return explanation_text

/datum/objective/proc/get_info()	//Text returned by this proc will be displayed at the end of the round
	return ""

/datum/objective/Topic(href, href_list)
	if(!check_rights(R_DEBUG))
		return TRUE

	if(href_list["switch_target"])
		select_human_target(usr)
		antag.antagonist_panel()


//Used for steal objectives. Returns a list of the owner's contents, if the owner is a single player
//If the owner is a faction, then asks that faction to return its inventory
/datum/objective/proc/get_owner_inventory()
	var/list/contents = list()
	if (owner && owner.current)
		contents.Add(owner.current.get_contents())

	if (owner_faction)
		contents.Add(owner_faction.get_inventory())

	return contents