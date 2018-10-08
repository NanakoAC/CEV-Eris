/datum/craft_recipe/floor
	category = "Tiles"
	steps = list(
		list(/obj/item/stack/material/steel, 1),
	)

/datum/craft_recipe/floor/regular
	name = "regular floor tile"
	result = /obj/item/stack/tile/floor

/datum/craft_recipe/floor/gray
	name = "grey techfloor tile"
	result = /obj/item/stack/tile/floor/techgrey

/datum/craft_recipe/floor/grid
	name = "grid techfloor tile"
	result = /obj/item/stack/tile/floor/techgrid

/datum/craft_recipe/floor/white
	name = "white floor tile"
	result = /obj/item/stack/tile/floor/white
	steps = list(
		list(/obj/item/stack/material/plastic, 1)
	)

/datum/craft_recipe/floor/white/freezer
	name = "freezer floor tile"
	result = /obj/item/stack/tile/floor/freezer

/datum/craft_recipe/floor/dark
	name = "dark floor tile"
	result = /obj/item/stack/tile/floor/dark

/datum/craft_recipe/floor/wood
	name = "wood floor tile"
	result = /obj/item/stack/tile/wood
	steps = list(
		list(/obj/item/stack/material/wood, 1)
	)


