var/bomb_set

/obj/machinery/nuclearbomb
	name = "\improper Nuclear Fission Explosive"
	desc = "Uh oh. RUN!!!!"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "nuclearbomb0"
	density = 1
	var/deployable = 0
	var/extended = 0
	var/lighthack = 0
	var/timeleft = 120
	var/timing = 0
	var/r_code = "ADMIN"
	var/code = ""
	var/yes_code = 0
	var/safety = 1
	var/obj/item/weapon/disk/nuclear/auth = null
	var/removal_stage = 0 // 0 is no removal, 1 is covers removed, 2 is covers open, 3 is sealant open, 4 is unwrenched, 5 is removed from bolts.
	var/lastentered
	use_power = 0
	unacidable = 1
	var/previous_level = ""
	var/datum/wires/nuclearbomb/wires = null

/obj/machinery/nuclearbomb/New()
	..()
	r_code = "[rand(10000, 99999.0)]"//Creates a random code upon object spawn.
	wires = new/datum/wires/nuclearbomb(src)

/obj/machinery/nuclearbomb/Destroy()
	qdel(wires)
	wires = null
	return ..()

/obj/machinery/nuclearbomb/process()
	if (src.timing)
		src.timeleft = max(timeleft - 2, 0) // 2 seconds per process()
		if (timeleft <= 0)
			spawn
				explode()
		nanomanager.update_uis(src)
	return

/obj/machinery/nuclearbomb/attackby(obj/item/weapon/O as obj, mob/user as mob, params)
	if (istype(O, /obj/item/weapon/tool/screwdriver))
		src.add_fingerprint(user)
		if (src.auth)
			if (panel_open == 0)
				panel_open = 1
				overlays += image(icon, "npanel_open")
				user << "You unscrew the control panel of [src]."
				playsound(src, 'sound/items/Screwdriver.ogg', 50, 1)
			else
				panel_open = 0
				overlays -= image(icon, "npanel_open")
				user << "You screw the control panel of [src] back on."
				playsound(src, 'sound/items/Screwdriver.ogg', 50, 1)
		else
			if (panel_open == 0)
				user << "\The [src] emits a buzzing noise, the panel staying locked in."
			if (panel_open == 1)
				panel_open = 0
				overlays -= image(icon, "npanel_open")
				user << "You screw the control panel of \the [src] back on."
				playsound(src, 'sound/items/Screwdriver.ogg', 50, 1)
			flick("nuclearbombc", src)
		return

	if (panel_open && (istype(O, /obj/item/weapon/tool/multitool) || istype(O, /obj/item/weapon/tool/wirecutters)))
		return attack_hand(user)

	if (src.extended)
		if (istype(O, /obj/item/weapon/disk/nuclear))
			usr.drop_item()
			O.loc = src
			src.auth = O
			src.add_fingerprint(user)
			return attack_hand(user)

	if (src.anchored)
		switch(removal_stage)
			if(0)
				if(istype(O,/obj/item/weapon/tool/weldingtool))
					var/obj/item/weapon/tool/weldingtool/WT = O
					if(!WT.isOn()) return
					if (WT.get_fuel() < 5) // uses up 5 fuel.
						user << SPAN_WARNING("You need more fuel to complete this task.")
						return

					user.visible_message("[user] starts cutting loose the anchoring bolt covers on [src].", "You start cutting loose the anchoring bolt covers with [O]...")

					if(do_after(user,40, src))
						if(!src || !user || !WT.remove_fuel(5, user)) return
						user.visible_message("\The [user] cuts through the bolt covers on \the [src].", "You cut through the bolt cover.")
						removal_stage = 1
				return

			if(1)
				if(istype(O,/obj/item/weapon/tool/crowbar))
					user.visible_message("[user] starts forcing open the bolt covers on [src].", "You start forcing open the anchoring bolt covers with [O]...")

					if(do_after(user, 15, src))
						if(!src || !user) return
						user.visible_message("\The [user] forces open the bolt covers on \the [src].", "You force open the bolt covers.")
						removal_stage = 2
				return

			if(2)
				if(istype(O,/obj/item/weapon/tool/weldingtool))

					var/obj/item/weapon/tool/weldingtool/WT = O
					if(!WT.isOn()) return
					if (WT.get_fuel() < 5) // uses up 5 fuel.
						user << SPAN_WARNING("You need more fuel to complete this task.")
						return

					user.visible_message("[user] starts cutting apart the anchoring system sealant on [src].", "You start cutting apart the anchoring system's sealant with [O]...")

					if(do_after(user, 40, src))
						if(!src || !user || !WT.remove_fuel(5, user)) return
						user.visible_message("\The [user] cuts apart the anchoring system sealant on \the [src].", "You cut apart the anchoring system's sealant.")
						removal_stage = 3
				return

			if(3)
				if(istype(O,/obj/item/weapon/tool/wrench))

					user.visible_message("[user] begins unwrenching the anchoring bolts on [src].", "You begin unwrenching the anchoring bolts...")

					if(do_after(user, 50, src))
						if(!src || !user) return
						user.visible_message("[user] unwrenches the anchoring bolts on [src].", "You unwrench the anchoring bolts.")
						removal_stage = 4
				return

			if(4)
				if(istype(O,/obj/item/weapon/tool/crowbar))

					user.visible_message("[user] begins lifting [src] off of the anchors.", "You begin lifting the device off the anchors...")

					if(do_after(user, 80, src))
						if(!src || !user) return
						user.visible_message("\The [user] crowbars \the [src] off of the anchors. It can now be moved.", "You jam the crowbar under the nuclear device and lift it off its anchors. You can now move it!")
						anchored = 0
						removal_stage = 5
				return
	..()

/obj/machinery/nuclearbomb/attack_ghost(mob/user as mob)
	attack_hand(user)

/obj/machinery/nuclearbomb/attack_hand(mob/user as mob)
	if (extended)
		if (panel_open)
			wires.Interact(user)
		else
			ui_interact(user)
	else if (deployable)
		if(removal_stage < 5)
			src.anchored = 1
			visible_message(SPAN_WARNING("With a steely snap, bolts slide out of [src] and anchor it to the flooring!"))
		else
			visible_message(SPAN_WARNING("\The [src] makes a highly unpleasant crunching noise. It looks like the anchoring bolts have been cut."))
		extended = 1
		if(!src.lighthack)
			flick("nuclearbombc", src)
			update_icon()
	return

/obj/machinery/nuclearbomb/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	var/data[0]
	data["hacking"] = 0
	data["auth"] = is_auth(user)
	if (is_auth(user))
		if (yes_code)
			data["authstatus"] = timing ? "Functional/Set" : "Functional"
		else
			data["authstatus"] = "Auth. S2"
	else
		if (timing)
			data["authstatus"] = "Set"
		else
			data["authstatus"] = "Auth. S1"
	data["safe"] = safety ? "Safe" : "Engaged"
	data["time"] = timeleft
	data["timer"] = timing
	data["safety"] = safety
	data["anchored"] = anchored
	data["yescode"] = yes_code
	data["message"] = "AUTH"
	if (is_auth(user))
		data["message"] = code
		if (yes_code)
			data["message"] = "*****"

	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "nuclear_bomb.tmpl", "Nuke Control Panel", 300, 510)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/nuclearbomb/verb/toggle_deployable()
	set category = "Object"
	set name = "Toggle Deployable"
	set src in oview(1)

	if(usr.incapacitated())
		return

	if (src.deployable)
		usr << SPAN_WARNING("You close several panels to make [src] undeployable.")
		src.deployable = 0
	else
		usr << SPAN_WARNING("You adjust some panels to make [src] deployable.")
		src.deployable = 1
	return

/obj/machinery/nuclearbomb/proc/is_auth(var/mob/user)
	if(auth)
		return 1
	if(user.can_admin_interact())
		return 1
	return 0

/obj/machinery/nuclearbomb/Topic(href, href_list)
	if(..())
		return 1

	if (href_list["auth"])
		if (auth)
			auth.loc = loc
			yes_code = 0
			auth = null
		else
			var/obj/item/I = usr.get_active_hand()
			if (istype(I, /obj/item/weapon/disk/nuclear))
				usr.drop_item()
				I.loc = src
				auth = I
	if (is_auth(usr))
		if (href_list["type"])
			if (href_list["type"] == "E")
				if (code == r_code)
					yes_code = 1
					code = null
				else
					code = "ERROR"
			else
				if (href_list["type"] == "R")
					yes_code = 0
					code = null
				else
					lastentered = text("[]", href_list["type"])
					if (text2num(lastentered) == null)
						var/turf/LOC = get_turf(usr)
						message_admins("[key_name_admin(usr)] tried to exploit a nuclear bomb by entering non-numerical codes: <a href='?_src_=vars;Vars=\ref[src]'>[lastentered]</a>! ([LOC ? "<a href='?_src_=holder;adminplayerobservecoodjump=1;X=[LOC.x];Y=[LOC.y];Z=[LOC.z]'>JMP</a>" : "null"])", 0)
						log_admin("EXPLOIT: [key_name(usr)] tried to exploit a nuclear bomb by entering non-numerical codes: [lastentered]!")
					else
						code += lastentered
						if (length(code) > 5)
							code = "ERROR"
		if (yes_code)
			if (href_list["time"])
				var/time = text2num(href_list["time"])
				timeleft += time
				timeleft = Clamp(timeleft, 120, 600)
			if (href_list["timer"])
				if (timing == -1)
					nanomanager.update_uis(src)
					return
				if (!anchored)
					usr << SPAN_WARNING("\The [src] needs to be anchored.")
					nanomanager.update_uis(src)
					return
				if (safety)
					usr << SPAN_WARNING("The safety is still on.")
					nanomanager.update_uis(src)
					return
				if (wires.IsIndexCut(NUCLEARBOMB_WIRE_TIMING))
					usr << SPAN_WARNING("Nothing happens, something might be wrong with the wiring.")
					nanomanager.update_uis(src)
					return

				if (!timing && !safety)
					timing = 1
					log_and_message_admins("engaged a nuclear bomb")
					bomb_set++ //There can still be issues with this resetting when there are multiple bombs. Not a big deal though for Nuke/N
					update_icon()
				else
					secure_device()
			if (href_list["safety"])
				if (wires.IsIndexCut(NUCLEARBOMB_WIRE_SAFETY))
					usr << SPAN_WARNING("Nothing happens, something might be wrong with the wiring.")
					nanomanager.update_uis(src)
					return
				safety = !safety
				if(safety)
					secure_device()
			if (href_list["anchor"])
				if(removal_stage == 5)
					anchored = 0
					visible_message(SPAN_WARNING("\The [src] makes a highly unpleasant crunching noise. It looks like the anchoring bolts have been cut."))
					nanomanager.update_uis(src)
					return

				if(!isinspace())
					anchored = !anchored
					if(anchored)
						visible_message(SPAN_WARNING("With a steely snap, bolts slide out of [src] and anchor it to the flooring."))
					else
						secure_device()
						visible_message(SPAN_WARNING("The anchoring bolts slide back into the depths of [src]."))
				else
					usr << SPAN_WARNING("There is nothing to anchor to!")

	nanomanager.update_uis(src)

/obj/machinery/nuclearbomb/proc/secure_device()
	if(timing <= 0)
		return

	bomb_set--
	timing = 0
	timeleft = Clamp(timeleft, 120, 600)
	update_icon()

/obj/machinery/nuclearbomb/ex_act(severity)
	return

#define NUKERANGE 80
/obj/machinery/nuclearbomb/proc/explode()
	if (src.safety)
		timing = 0
		return
	src.timing = -1
	src.yes_code = 0
	src.safety = 1
	update_icon()
	playsound(src,'sound/machines/Alarm.ogg',100,0,5)
	if (ticker)
		ticker.nuke_in_progress = TRUE
	sleep(100)

	var/off_station = 0
	var/turf/bomb_location = get_turf(src)
	if(bomb_location && isStationLevel(bomb_location.z))
		if( (bomb_location.x < (128-NUKERANGE)) || (bomb_location.x > (128+NUKERANGE)) || (bomb_location.y < (128-NUKERANGE)) || (bomb_location.y > (128+NUKERANGE)) )
			off_station = 1
	else
		off_station = 2

	if(ticker && ticker.storyteller)
		ticker.nuke_in_progress = FALSE
		if(off_station == 1)
			world << "<b>A nuclear device was set off, but the explosion was out of reach of the ship!</b>"
		else if(off_station == 2)
			world << "<b>A nuclear device was set off, but the device was not on the ship!</b>"
		else
			world << "<b>The ship was destoyed by the nuclear blast!</b>"

		ticker.ship_was_nuked = (off_station<2)	//offstation==1 is a draw. the station becomes irradiated and needs to be evacuated.
														//kinda shit but I couldn't  get permission to do what I wanted to do.

		ticker.station_explosion_cinematic(off_station)

	return

/obj/machinery/nuclearbomb/update_icon()
	if(lighthack)
		icon_state = "nuclearbomb0"
		return

	else if(timing == -1)
		icon_state = "nuclearbomb3"
	else if(timing)
		icon_state = "nuclearbomb2"
	else if(extended)
		icon_state = "nuclearbomb1"
	else
		icon_state = "nuclearbomb0"
/*
if(!N.lighthack)
	if (N.icon_state == "nuclearbomb2")
		N.icon_state = "nuclearbomb1"
		*/

//====The nuclear authentication disc====
/obj/item/weapon/disk/nuclear
	name = "nuclear authentication disk"
	desc = "Better keep this safe."
	icon = 'icons/obj/items.dmi'
	icon_state = "nucleardisk"
	item_state = "card-id"
	w_class = ITEM_SIZE_TINY

/obj/item/weapon/disk/nuclear/touch_map_edge()
	qdel(src)
