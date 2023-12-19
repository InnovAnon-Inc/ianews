local MODNAME = minetest.get_current_modname()
minetest.register_craftitem("ianews:newspaper_blank", {
	description = "Blank Newspaper",
	inventory_image = "ianews_newspaper_single.png"
})
minetest.register_craft({
    type   = "shaped",
    output = "ianews:newspaper_blank",
    recipe = {
        {"",              "dye:black",     ""},
        {"default:paper", "default:paper", "default:paper"},
        {"default:paper", "default:paper", "default:paper"}
    }
})

newspaper.register_newspaper("ianews:newspaper_official", "Mine Times Newspaper", "ianews_newspaper_mese_crystal.png",   "news/official.txt")
minetest.register_craft({
    type   = "shapeless",
    output = "ianews:newspaper_official",
    recipe = {"ianews:newspaper_blank", "default:mese_crystal"}
})

newspaper.register_newspaper("ianews:newspaper_default",  "Default Newspaper",    "ianews_newspaper_obsidian_shard.png", "news/default.txt")
minetest.register_craft({
    type   = "shapeless",
    output = "ianews:newspaper_default",
    recipe = {"ianews:newspaper_blank", "default:obsidian_shard"}
})

newspaper.register_newspaper("ianews:newspaper_example",  "Example Newspaper",    "ianews_newspaper_diamond.png",        "news/example.txt")
minetest.register_craft({
    type   = "shapeless",
    output = "ianews:newspaper_example",
    recipe = {"ianews:newspaper_blank", "default:diamond"}
})

if false then
--local S = minetest.get_translator("homedecor_books")

--local bookcolors = {
--	{ "red",    0xffd26466 },
--	{ "green",  0xff62aa66 },
--	{ "blue",   0xff8686d7 },
--	{ "violet", 0xff9c65a7 },
--	{ "grey",   0xff757579 },
--	{ "brown",  0xff896958 }
--}

--local color_locale = {
--	red = S("red") ,
--	green = S("green"),
--	blue = S("blue"),
--	violet = S("violet"),
--	grey = S("grey"),
--	brown = S("brown"),
--}


local BOOK_FORMNAME = "homedecor:book_form"

local player_current_book = { }

for _, c in ipairs(bookcolors) do
	local color, hue = unpack(c)

	local function book_dig(pos, node, digger)
		if not digger or minetest.is_protected(pos, digger:get_player_name()) then return end
		local meta = minetest.get_meta(pos)
		local data = minetest.serialize({
			title = meta:get_string("title") or "",
			text = meta:get_string("text") or "",
			owner = meta:get_string("owner") or "",
			_recover = meta:get_string("_recover") or "",
		})
		local stack = ItemStack({
			name = "homedecor:book_"..color,
			metadata = data,
		})
		stack = digger:get_inventory():add_item("main", stack)
		if not stack:is_empty() then
			minetest.item_drop(stack, digger, pos)
		end
		minetest.remove_node(pos)
	end

	homedecor.register("book_"..color, {
		description = S("Writable Book (@1)", color_locale[color]),
		mesh = "homedecor_book.obj",
		tiles = {
			{ name = "homedecor_book_cover.png", color = hue },
			{ name = "homedecor_book_edges.png", color = "white" }
		},
		overlay_tiles = {
			{ name = "homedecor_book_cover_trim.png", color = "white" },
			""
		},
		groups = { snappy=3, oddly_breakable_by_hand=3, book=1 },
		walkable = false,
		stack_max = 1,
		on_punch = function(pos, node, puncher, pointed_thing)
			local fdir = node.param2
			minetest.swap_node(pos, { name = "homedecor:book_open_"..color, param2 = fdir })
		end,
		on_place = function(itemstack, placer, pointed_thing)
			local plname = placer:get_player_name()
			local pos = pointed_thing.under
			local node = minetest.get_node_or_nil(pos)
			local def = node and minetest.registered_nodes[node.name]
			if not def or not def.buildable_to then
				pos = pointed_thing.above
				node = minetest.get_node_or_nil(pos)
				def = node and minetest.registered_nodes[node.name]
				if not def or not def.buildable_to then return itemstack end
			end
			if minetest.is_protected(pos, plname) then return itemstack end
			local fdir = minetest.dir_to_facedir(placer:get_look_dir())
			minetest.set_node(pos, {
				name = "homedecor:book_"..color,
				param2 = fdir,
			})
			local text = itemstack:get_metadata() or ""
			local meta = minetest.get_meta(pos)
			local data = minetest.deserialize(text) or {}
			if type(data) ~= "table" then
				data = {}
				-- Store raw metadata in case some data is lost by the
				-- transition to the new meta format, so it is not lost
				-- and can be recovered if needed.
				meta:set_string("_recover", text)
			end
			meta:set_string("title", data.title or "")
			meta:set_string("text", data.text or "")
			meta:set_string("owner", data.owner or "")
			if data.title and data.title ~= "" then
				meta:set_string("infotext", data.title)
			end
			if not creative.is_enabled_for(plname) then
				itemstack:take_item()
			end
			return itemstack
		end,
		on_dig = book_dig,
		selection_box = {
		        type = "fixed",
				fixed = {-0.2, -0.5, -0.25, 0.2, -0.35, 0.25}
		}
	})

	homedecor.register("book_open_"..color, {
		mesh = "homedecor_book_open.obj",
		tiles = {
			{ name = "homedecor_book_cover.png", color = hue },
			{ name = "homedecor_book_edges.png", color = "white" },
			{ name = "homedecor_book_pages.png", color = "white" }
		},
		groups = { snappy=3, oddly_breakable_by_hand=3, not_in_creative_inventory=1 },
		drop = "homedecor:book_"..color,
		walkable = false,
		on_dig = book_dig,
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			local meta = minetest.get_meta(pos)
			local player_name = clicker:get_player_name()
			local title = meta:get_string("title") or ""
			local text = meta:get_string("text") or ""
			local owner = meta:get_string("owner") or ""
			local formspec
			if owner == "" or owner == player_name then
				formspec = "size[8,8]"..default.gui_bg..default.gui_bg_img..
					"field[0.5,1;7.5,0;title;Book title :;"..
						minetest.formspec_escape(title).."]"..
					"textarea[0.5,1.5;7.5,7;text;Book content :;"..
						minetest.formspec_escape(text).."]"..
					"button_exit[2.5,7.5;3,1;save;Save]"
			else
				formspec = "size[8,8]"..default.gui_bg..
				"button_exit[7,0.25;1,0.5;close;X]"..
				default.gui_bg_img..
					"label[0.5,0.5;by "..owner.."]"..
					"label[0.5,0;"..minetest.formspec_escape(title).."]"..
					"textarea[0.5,1.5;7.5,7;;"..minetest.formspec_escape(text)..";]"
			end
			player_current_book[player_name] = pos
			minetest.show_formspec(player_name, BOOK_FORMNAME, formspec)
			return itemstack
		end,
		on_punch = function(pos, node, puncher, pointed_thing)
			local fdir = node.param2
			minetest.swap_node(pos, { name = "homedecor:book_"..color, param2 = fdir })
			minetest.sound_play("homedecor_book_close", {
				pos=pos,
				max_hear_distance = 3,
				gain = 2,
				})
		end,
		selection_box = {
		        type = "fixed",
				fixed = {-0.35, -0.5, -0.25, 0.35, -0.4, 0.25}
		}
	})

end

minetest.register_on_player_receive_fields(function(player, form_name, fields)
	if form_name ~= BOOK_FORMNAME then
		return false
	end
	local player_name = player:get_player_name()
	local pos = player_current_book[player_name]
	if not pos then
		return true
	end
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	if owner ~= "" and player_name ~= owner or not fields.save then
		player_current_book[player_name] = nil
		return true
	end
	meta:set_string("title", fields.title or "")
	meta:set_string("text", fields.text or "")
	meta:set_string("owner", player_name)
	if (fields.title or "") ~= "" then
		meta:set_string("infotext", fields.title)
	end
	minetest.log("action", S("@1 has written in a book (title: \"@2\"): \"@3\" at location @4",
			player:get_player_name(), fields.title, fields.text, minetest.pos_to_string(player:getpos())))

	player_current_book[player_name] = nil
	return true
end)



-- aliases

minetest.register_alias("homedecor:book", "homedecor:book_grey")
minetest.register_alias("homedecor:book_open", "homedecor:book_open_grey")









-- TODO register book/writable
-- TODO placeable newspaper nodes
-- TODO newspaper group (for stack of newspapers inventory)

-- TODO stack of newspapers
--
if false then









ianews.chest_add = {};
ianews.chest_add.tiles  = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
                "default_chest_side.png", "default_chest_side.png", "default_chest_front.png^locks_lock16.png"};
ianews.chest_add.groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2};
ianews.chest_add.tube   = {};

-- additional/changed definitions for pipeworks;
-- taken from pipeworks/compat.lua
if( ianews.pipeworks_enabled ) then
   ianews.chest_add.tiles = {
	"default_chest_top.png^pipeworks_tube_connection_wooden.png",
	"default_chest_top.png^pipeworks_tube_connection_wooden.png",
	"default_chest_side.png^pipeworks_tube_connection_wooden.png",
	"default_chest_side.png^pipeworks_tube_connection_wooden.png",
	"default_chest_side.png^pipeworks_tube_connection_wooden.png",
	"default_chest_front.png^locks_lock16.png"};
   ianews.chest_add.groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,
	tubedevice = 1, tubedevice_receiver = 1 };
   ianews.chest_add.tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("main", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("main", stack)
		end,
		input_inventory = "main",
		connect_sides = {left=1, right=1, back=1, front=1, bottom=1, top=1}
	};
end


minetest.register_node("ianews:newspaper_stack", {
       description = "Stack of Newspapers",
	tiles      = ianews.chest_add.tiles,
        paramtype2 = "facedir",
        groups     = ianews.chest_add.groups,
	tube       = ianews.chest_add.tube,
        legacy_facedir_simple = true,

        on_construct = function(pos)
                local meta = minetest.get_meta(pos)
                -- prepare the lock of the chest
                ianews:lock_init( pos, 
                                "size[8,10]"..
----                                "field[0.5,0.2;8,1.0;locks_sent_lock_command;Locked chest. Type password, command or /help for help:;]"..
----                                "button_exit[3,0.8;2,1.0;locks_sent_input;Proceed]"..
--                                "list[current_name;main;0,0;8,4;]"..
--                                "list[current_player;main;0,5;8,4;]"..
--                                "field[0.3,9.6;6,0.7;locks_sent_lock_command;Locked chest. Type /help for help:;]"..
--								"background[-0.5,-0.65;9,11.2;bg_shared_locked_chest.jpg]"..
--                                "button_exit[6.3,9.2;1.7,0.7;locks_sent_input;Proceed]" );
----                                "size[8,9]"..
----                                "list[current_name;main;0,0;8,4;]"..
----                                "list[current_player;main;0,5;8,4;]");
				ianews.uniform_background ..
				"list[current_name;main;0,1;8,4;]"..
				"list[current_player;main;0,5.85;8,1;]" ..
				"list[current_player;main;0,7.08;8,3;8]" ..
				"listring[current_name;main]" ..
				"listring[current_player;main]" ..
				default.get_hotbar_bg(0,5.85) );

                local inv = meta:get_inventory()
                inv:set_size("main", 8*4)
        end,

        after_place_node = function(pos, placer)

                if( ianews.pipeworks_enabled ) then
		   pipeworks.scan_for_tube_objects( pos );
                end

                ianews:lock_set_owner( pos, placer, "Shared locked chest" );
        end,


        can_dig = function(pos,player)
               
                if( not(ianews:lock_allow_dig( pos, player ))) then
                   return false;
                end
                local meta = minetest.get_meta(pos);
                local inv = meta:get_inventory()
                return inv:is_empty("main")
        end,

        on_receive_fields = function(pos, formname, fields, sender)
                ianews:lock_handle_input( pos, formname, fields, sender );
        end,
 
 

        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
                if( not( ianews:lock_allow_use( pos, player ))) then
                   return 0;
                end
                return count;
        end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
                if( not( ianews:lock_allow_use( pos, player ))) then
                   return 0;
                end
                return stack:get_count()
        end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
                if( not( ianews:lock_allow_use( pos, player ))) then
                   return 0;
                end
                return stack:get_count()
        end,
        on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
                minetest.log("action", player:get_player_name()..
                                " moves stuff in locked shared chest at "..minetest.pos_to_string(pos))
        end,
        on_metadata_inventory_put = function(pos, listname, index, stack, player)
                minetest.log("action", player:get_player_name()..
                                " moves stuff to locked shared chest at "..minetest.pos_to_string(pos))
        end,
        on_metadata_inventory_take = function(pos, listname, index, stack, player)
                minetest.log("action", player:get_player_name()..
                                " takes stuff from locked shared chest at "..minetest.pos_to_string(pos))
        end,


	after_dig_node = function( pos )
                if( ianews.pipeworks_enabled ) then              
		   pipeworks.scan_for_tube_objects(pos)
                end
	end
})

minetest.register_craft({
   output = 'ianews:shared_locked_chest',
   recipe = {
      { 'default:chest', 'ianews:lock', '' },
   },
})

print( "[Mod] ianews: loading ianews:shared_locked_chest");
local pipeworks_installed = minetest.get_modpath("pipeworks")

local function find_water_supply(pos)
	if not pipeworks_installed then return true end
	local minp = vector.add(pos,vector.new(-1,-1,-1))
	local maxp = vector.add(pos,vector.new(1,1,1))
	local nodes = minetest.find_nodes_in_area(minp,maxp,"group:pipe")
	for _,pos in pairs(nodes) do
		local node = minetest.get_node(pos)
		if string.match(node.name,"^pipeworks:.*_loaded$") then
			return true
		end
	end
	return false
end

local function set_formspec(meta,enabled,full,water)
	local status
	if enabled then
		if water then
			if full then
				status = "Full Bin"
			else
				status = "Making Ice"
			end
		else
			status = "Water Error"
		end
	else
		status = "Off"
	end
	local fs = "size[3,2]"..
	           "box[-0.15,0;3,1.5;#0000FF]"..
	           "label[0.2,0.3;"..status.."]"..
	           "button[0.5,1.5;2,1;power;Power]"
	meta:set_string("formspec",fs)
end

local function update_status(pos,meta,ice)
	local timer = minetest.get_node_timer(pos)
	local enabled = meta:get_int("enabled")==1
	if not enabled then
		timer:stop()
		set_formspec(meta,false)
	else
		local water = find_water_supply(pos)
		local binpos = vector.add(pos,vector.new(0,-1,0))
		local binnode = minetest.get_node(binpos)
		local binmeta = minetest.get_meta(binpos)
		local bininv = binmeta:get_inventory()
		if binnode.name ~= "icemachine:bin" or not bininv:room_for_item("ice","icemachine:cube") then
			timer:stop()
			set_formspec(meta,true,true,true)
		else
			if water then
				if not timer:is_started() then timer:start(30) end
				if ice then bininv:add_item("ice","icemachine:cube 9") end
				set_formspec(meta,true,false,true)
			else
				timer:stop()
				set_formspec(meta,true,false,false)
			end
		end
	end
end

minetest.register_node("icemachine:machine",{
	description = "Ice Machine",
	paramtype2 = "facedir",
	groups = {cracky=3},
	tiles = {
		"default_steel_block.png",
		"default_steel_block.png",
		"default_steel_block.png^icemachine_machine_sides.png",
		"default_steel_block.png^icemachine_machine_sides.png",
		"default_steel_block.png",
		"default_steel_block.png^icemachine_machine_front.png",
	},
	pipe_connections = {left=1,right=1,front=1,back=1,left_param2=3,right_param2=1,front_param2=2,back_param2=0,},
	after_place_node = (pipeworks_installed and pipeworks.scan_for_pipe_objects),
	after_dig_node = (pipeworks_installed and pipeworks.scan_for_pipe_objects),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		update_status(pos,meta)
	end,
	on_receive_fields = function(pos,_,fields)
		local meta = minetest.get_meta(pos)
		if fields.power then
			meta:set_int("enabled",math.abs(meta:get_int("enabled")-1))
			update_status(pos,meta)
		end
	end,
	on_timer = function(pos)
		local meta = minetest.get_meta(pos)
		update_status(pos,meta,true)
	end,
})

minetest.register_node("icemachine:bin",{
	description = "Ice Bin",
	paramtype2 = "facedir",
	groups = {cracky=3},
	tiles = {
		"default_steel_block.png",
		"default_steel_block.png",
		"default_steel_block.png",
		"default_steel_block.png",
		"default_steel_block.png",
		"default_steel_block.png^icemachine_bin_front.png",
	},
	tube = {input_inventory="ice"},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("ice",8*3)
		meta:set_string("formspec",
			"size[8,9]"..
			"list[context;ice;0,0;8,4;]"..
			"list[current_player;main;0,5;8,4;]"..
			"listring[]")
	end,
	allow_metadata_inventory_put = function(_,_,_,stack)
		if stack:get_name() == "icemachine:cube" then
			return(stack:get_count())
		else
			return(0)
		end
	end,
	on_metadata_inventory_take = function(pos)
		local machinepos = vector.add(pos,vector.new(0,1,0))
		local machinemeta = minetest.get_meta(machinepos)
		update_status(machinepos,machinemeta)
	end,
	can_dig = function(pos)
		return(minetest.get_meta(pos):get_inventory():is_empty("ice"))
	end,
})

minetest.register_craftitem("icemachine:cube",{
	description = "Ice Cube",
	inventory_image = "icemachine_cube.png",
})

minetest.register_craft({
	output = "icemachine:machine",
	recipe = {
		{"default:steel_ingot",  "bucket:bucket_water",        "default:steel_ingot"},
		{"default:steel_ingot",  "homedecor:fence_chainlink",  "homedecor:motor"},
		{"default:steel_ingot",  "bucket:bucket_empty",        "homedecor:ic"},
	},
})

minetest.register_craft({
	output = "icemachine:bin",
	recipe = {
		{"homedecor:plastic_sheeting",  "",                     "homedecor:plastic_sheeting"},
		{"homedecor:plastic_sheeting",  "",                     "homedecor:plastic_sheeting"},
		{"default:steel_ingot",         "default:steel_ingot",  "default:steel_ingot"},
	},
})

minetest.register_craft({
	output = "default:ice",
	recipe = {
		{"icemachine:cube",  "icemachine:cube",  "icemachine:cube"},
		{"icemachine:cube",  "icemachine:cube",  "icemachine:cube"},
		{"icemachine:cube",  "icemachine:cube",  "icemachine:cube"},
	},
})

minetest.register_craft({
	type = "shapeless",
	output = "icemachine:cube 9",
	recipe = {"default:ice"},
})

if minetest.get_modpath("technic") then
	technic.register_grinder_recipe({input={"default:ice 1"},output="default:snowblock 1"})
end

end
end
