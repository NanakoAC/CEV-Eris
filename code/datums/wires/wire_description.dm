/datum/wire_description
	var/index
	var/description
	var/skill_level = 0 //SKILL_PROF //TODO: Hook eris skills here

/datum/wire_description/New(index, description, skill_level)
	src.index = index
	if(description)
		src.description = description
	if(skill_level)
		src.skill_level = skill_level
	..()