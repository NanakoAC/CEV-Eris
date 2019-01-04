/datum/antagonist/revolutionary/excelsior
	id = ROLE_EXCELSIOR_REV
	role_text = "Excelsior Infiltrator"
	role_text_plural = "Infiltrators"
	bantype = ROLE_BANTYPE_EXCELSIOR
	welcome_text = "Viva la revolution!"

	faction_id = FACTION_EXCELSIOR
	allow_neotheology = FALSE //Implant causes head asplode

/datum/antagonist/revolutionary/excelsior/equip()
	.=..()
	var/obj/item/weapon/implant/revolution/excelsior/implant = new(owner.current)
	implant.install(owner.current)

/datum/faction/revolutionary/excelsior
	id = FACTION_EXCELSIOR
	name = "Excelsior"
	antag = "infiltrator"
	antag_plural = "infiltrators"
	welcome_text = ""

	hud_indicator = "hudexcelsior"

	possible_antags = list(ROLE_EXCELSIOR_REV)
	verbs = list(/datum/faction/revolutioanry/excelsior/proc/communicate_verb)

/datum/faction/revolutioanry/excelsior/proc/communicate_verb()

	set name = "Excelsior comms"
	set category = "Cybernetics"

	if(!ishuman(usr))
		return

	var/datum/faction/F = get_faction_by_id(FACTION_EXCELSIOR)

	if(!F)
		return

	F.communicate(usr)
