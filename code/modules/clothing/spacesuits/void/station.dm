// Station voidsuits
//Engineering rig
/obj/item/clothing/head/helmet/space/void/engineering
	name = "engineering voidsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low-pressure environment. Has radiation shielding."
	icon_state = "rig0-engineering"
	item_state = "eng_helm"
	item_state_slots = list(
		slot_l_hand_str = "eng_helm",
		slot_r_hand_str = "eng_helm",
		)
	armor = list(melee = 40, bullet = 35, laser = 35,energy = 5, bomb = 35, bio = 100, rad = 90)

/obj/item/clothing/suit/space/void/engineering
	name = "engineering voidsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has radiation shielding."
	icon_state = "rig-engineering"
	item_state = "eng_voidsuit"
	slowdown = 1
	armor = list(melee = 40, bullet = 35, laser = 35,energy = 5, bomb = 35, bio = 100, rad = 90)
	allowed = list(
		/obj/item/device/lighting/toggleable/flashlight,/obj/item/weapon/tank,/obj/item/device/suit_cooling_unit,
		/obj/item/weapon/storage/bag/ore,/obj/item/device/t_scanner,/obj/item/weapon/tool/pickaxe,
		/obj/item/weapon/rcd
	)

//Mining rig
/obj/item/clothing/head/helmet/space/void/mining
	name = "mining voidsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low pressure environment. Has reinforced plating."
	icon_state = "rig0-mining"
	item_state = "mining_helm"
	item_state_slots = list(
		slot_l_hand_str = "mining_helm",
		slot_r_hand_str = "mining_helm",
		)
	armor = list(melee = 40, bullet = 35, laser = 35,energy = 5, bomb = 35, bio = 100, rad = 60)
	light_overlay = "helmet_light_dual"

/obj/item/clothing/suit/space/void/mining
	icon_state = "rig-mining"
	name = "mining voidsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has reinforced plating."
	item_state = "mining_voidsuit"
	armor = list(melee = 40, bullet = 35, laser = 35,energy = 5, bomb = 35, bio = 100, rad = 60)

//Medical Rig
/obj/item/clothing/head/helmet/space/void/medical
	name = "medical voidsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low pressure environment. Has minor radiation shielding."
	icon_state = "rig0-medical"
	item_state = "medical_helm"
	item_state_slots = list(
		slot_l_hand_str = "medical_helm",
		slot_r_hand_str = "medical_helm",
		)
	armor = list(melee = 40, bullet = 35, laser = 35,energy = 5, bomb = 35, bio = 100, rad = 60)

/obj/item/clothing/suit/space/void/medical
	icon_state = "rig-medical"
	name = "medical voidsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has minor radiation shielding."
	item_state = "medical_voidsuit"
	allowed = list(
		/obj/item/device/lighting/toggleable/flashlight,/obj/item/weapon/tank,/obj/item/device/suit_cooling_unit,
		/obj/item/weapon/storage/firstaid,/obj/item/device/scanner/healthanalyzer,/obj/item/stack/medical
	)
	armor = list(melee = 40, bullet = 35, laser = 35,energy = 5, bomb = 35, bio = 100, rad = 60)

	//Security
/obj/item/clothing/head/helmet/space/void/security
	name = "security voidsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low pressure environment. Has an additional layer of armor."
	icon_state = "rig0-sec"
	item_state = "sec_helm"
	item_state_slots = list(
		slot_l_hand_str = "sec_helm",
		slot_r_hand_str = "sec_helm",
		)
	armor = list(melee = 50, bullet = 45, laser = 45,energy = 35, bomb = 35, bio = 100, rad = 60)
	siemens_coefficient = 0.7
	light_overlay = "helmet_light_dual"

/obj/item/clothing/suit/space/void/security
	icon_state = "rig-sec"
	name = "security voidsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has an additional layer of armor."
	item_state = "sec_voidsuit"
	armor = list(melee = 50, bullet = 45, laser = 45,energy = 35, bomb = 35, bio = 100, rad = 60)
	allowed = list(
		/obj/item/weapon/gun,/obj/item/device/lighting/toggleable/flashlight,/obj/item/weapon/tank,
		/obj/item/device/suit_cooling_unit,/obj/item/weapon/melee/baton
	)
	siemens_coefficient = 0.7

//Atmospherics Rig (BS12)
/obj/item/clothing/head/helmet/space/void/atmos
	desc = "A special helmet designed for work in a hazardous, low pressure environments. Has improved thermal protection and minor radiation shielding."
	name = "atmospherics voidsuit helmet"
	icon_state = "rig0-atmos"
	item_state = "atmos_helm"
	item_state_slots = list(
		slot_l_hand_str = "atmos_helm",
		slot_r_hand_str = "atmos_helm",
		)
	armor = list(melee = 40, bullet = 35, laser = 35,energy = 5, bomb = 35, bio = 100, rad = 90)
	max_heat_protection_temperature = FIRE_HELMET_MAX_HEAT_PROTECTION_TEMPERATURE
	light_overlay = "helmet_light_dual"

/obj/item/clothing/suit/space/void/atmos
	desc = "A special suit that protects against hazardous, low pressure environments. Has improved thermal protection and minor radiation shielding."
	icon_state = "rig-atmos"
	name = "atmos voidsuit"
	item_state = "atmos_voidsuit"
	armor = list(melee = 40, bullet = 35, laser = 35,energy = 5, bomb = 35, bio = 100, rad = 90)
	max_heat_protection_temperature = FIRESUIT_MAX_HEAT_PROTECTION_TEMPERATURE