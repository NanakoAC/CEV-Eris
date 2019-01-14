/datum/antagonist

	// Base vars
	var/list/objectives = list()

	var/objective_quantity = 1 //How many random objectives will we create.
	var/list/possible_objectives = list()
	var/survive_objective = /datum/objective/escape

	var/datum/mind/owner = null

	var/flags = 0                           // Various runtime options.

	var/list/restricted_jobs =     list()   // Jobs that technically cannot be this antagonist (like AI-changeling)
	var/list/protected_jobs =      list()   // As above, but this jobs are rewstricted ideologically (like Security Officer-traitor)

	// Strings.
	var/welcome_text = "Cry havoc and let slip the dogs of war!"

	// Role data.
	var/id = null                      		// Unique type identifier.
	var/role_text = "Traitor"               // special_role text.
	var/role_text_plural = "Traitors"       // As above but plural.
	var/selectable = TRUE

	// Faction data.
	var/datum/faction/faction = null
	var/faction_id = null

	//For station antags, access that gets added to their existing ID
	//For outer antags, access they spawn with on their newly created ID
	var/list/default_access = list(access_external_airlocks,access_maint_tunnels)

	// Misc.
	var/bantype               // Ban to check when spawning this antag.
	var/list/uplinks = list()
	var/only_human = TRUE
	var/allow_neotheology = TRUE //If false, followers of neotheology cannot become this antag

/datum/antagonist/New()
	..()
	if(!role_text_plural)
		role_text_plural = role_text
	if(config.protect_roles_from_antagonist)
		restricted_jobs |= protected_jobs

	/*if(antaghud_indicator)
		if(!hud_icon_reference)
			hud_icon_reference = list()
		if(role_text)
			hud_icon_reference[role_text] = antaghud_indicator
	*/
