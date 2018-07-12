//
// Sheet Exports
//

/datum/export/stack
	unit_name = "sheet"

/datum/export/stack/get_amount(obj/O)
	var/obj/item/stack/S = O
	if(istype(S))
		return S.amount
	return 0


// Leather, skin and other farming by-products.
/*
/datum/export/stack/skin
	unit_name = ""

// Monkey hide. Cheap.
/datum/export/stack/skin/monkey
	cost = 150
	unit_name = "monkey hide"
	export_types = list(/obj/item/stack/sheet/animalhide/monkey)

// Human skin. Illegal
/datum/export/stack/skin/human
	cost = 2000
	contraband = 1
	unit_name = "piece"
	message = "of human skin"
	export_types = list(/obj/item/stack/sheet/animalhide/human)

// Goliath hide. Expensive.
/datum/export/stack/skin/goliath_hide
	cost = 2500
	unit_name = "goliath hide"
	export_types = list(/obj/item/asteroid/goliath_hide)

// Cat hide. Just in case Runtime is catsploding again.
/datum/export/stack/skin/cat
	cost = 2000
	contraband = 1
	unit_name = "cat hide"
	export_types = list(/obj/item/stack/sheet/animalhide/cat)

// Corgi hide. You monster.
/datum/export/stack/skin/corgi
	cost = 2500
	contraband = 1
	unit_name = "corgi hide"
	export_types = list(/obj/item/stack/sheet/animalhide/corgi)

// Lizard hide. Very expensive.
/datum/export/stack/skin/lizard
	cost = 5000
	unit_name = "lizard hide"
	export_types = list(/obj/item/stack/sheet/animalhide/lizard)

// Alien hide. Extremely expensive.
/datum/export/stack/skin/xeno
	cost = 15000
	unit_name = "alien hide"
	export_types = list(/obj/item/stack/sheet/animalhide/xeno)
*/

// Common materials.

// Metal. Common building material.
/datum/export/stack/metal
	cost = 5
	message = "of metal"
	export_types = list(/obj/item/stack/material/steel)

// Glass. Common building material.
/datum/export/stack/glass
	cost = 5
	message = "of glass"
	export_types = list(/obj/item/stack/material/glass)

// Plasteel. Lightweight, strong and contains some plasma too.
/datum/export/stack/plasteel
	cost = 85
	message = "of plasteel"
	export_types = list(/obj/item/stack/material/plasteel)

// Wood. Quite expensive in the grim and dark 26 century.
/datum/export/stack/wood
	cost = 25
	unit_name = "wood plank"
	export_types = list(/obj/item/stack/material/wood)

// Cardboard. Cheap.
/datum/export/stack/cardboard
	cost = 2
	message = "of cardboard"
	export_types = list(/obj/item/stack/material/cardboard)

// Sandstone. Literally dirt cheap.
/datum/export/stack/sandstone
	cost = 1
	unit_name = "block"
	message = "of sandstone"
	export_types = list(/obj/item/stack/material/sandstone)

// Cable.
/datum/export/stack/cable
	cost = 0.2
	unit_name = "cable piece"
	export_types = list(/obj/item/stack/cable_coil)

/datum/export/stack/cable/get_cost(O)
	return round(..(O))

/datum/export/stack/cable/get_amount(obj/O)
	var/obj/item/stack/cable_coil/S = O
	if(istype(S))
		return S.amount
	return 0


// Diamonds. Rare and expensive.
/datum/export/stack/diamond
	cost = 2500
	export_types = list(/obj/item/stack/material/diamond)
	message = "of diamonds"

// Phoron. The oil of 26 century. The reason why you are here.
/datum/export/stack/phoron
	cost = 300
	export_types = list(/obj/item/stack/material/plasma)
	message = "of phoron"

/datum/export/stack/phoron/get_cost(obj/O, contr = 0, emag = 0)
	. = ..(O)
	if(emag) // Syndicate pays you more for the plasma.
		. = round(. * 1.5)

// Uranium. Still useful for both power generation and nuclear annihilation.
/datum/export/stack/uranium
	cost = 400
	export_types = list(/obj/item/stack/material/diamond)
	message = "of uranium"

// Gold. Used in electronics and corrosion-resistant plating.
/datum/export/stack/gold
	cost = 250
	export_types = list(/obj/item/stack/material/gold)
	message = "of gold"

// Silver.
/datum/export/stack/silver
	cost = 100
	export_types = list(/obj/item/stack/material/silver)
	message = "of silver"

// Plastic.
/datum/export/stack/plastic
	cost = 20
	export_types = list(/obj/item/stack/material/plastic)
	message = "of plastic"

// Platinum.
/datum/export/stack/platinum
	cost = 1000
	message = "of platinum"
	export_types = list(/obj/item/stack/material/platinum)

/datum/export/stack/nanopaste
	cost = 80
	message = "of nanopaste"
	export_types = list(/obj/item/stack/nanopaste)
