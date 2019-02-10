/obj/random/structures
	name = "random structure"
	icon_state = "machine-black"

/obj/random/structures/item_to_spawn()
	return pickweight(list(/obj/structure/salvageable/machine = 10,\
				/obj/structure/salvageable/autolathe = 10,\
				/obj/structure/salvageable/implant_container = 1,\
				/obj/structure/salvageable/data = 5,\
				/obj/structure/salvageable/server = 5,\
				/obj/structure/computerframe = 5,\
				/obj/machinery/constructable_frame/machine_frame = 4,\
				/obj/structure/reagent_dispensers/fueltank = 6,\
				/obj/structure/reagent_dispensers/fueltank/huge = 2,\
				/obj/structure/reagent_dispensers/watertank = 6,\
				/obj/structure/largecrate = 2,\
				/obj/structure/ore_box = 2,\
				/obj/structure/dispenser/oxygen = 1,
				/obj/random/mecha = 0.01,
				/obj/random/mecha/damaged = 0.4,
				/obj/random/scrap/moderate_weighted = 8))

/obj/random/structures/rare/item_to_spawn()
	return pickweight(list(/obj/random/mecha = 0.01,
				/obj/random/mecha/damaged = 0.5,
				/obj/random/closet/rare = 1))

/obj/random/structures/low_chance
	name = "low chance random structures"
	icon_state = "machine-black-low"
	spawn_nothing_percentage = 60

/obj/random/structure_pack
	name = "truly random structure"
	icon_state = "machine-blank"

/obj/random/structure_pack/item_to_spawn()
	return pick(/obj/random/structures,
				/obj/random/closet)
