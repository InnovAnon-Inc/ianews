local MODNAME = minetest.get_current_modname()
local S = minetest.get_translator(MODNAME)
local F = minetest.formspec_escape
local lpp = 14 -- Lines per book's page

ianews              = {}
ianews.publications = {}

minetest.register_craftitem("ianews:newspaper_blank", {
        description = S("Blank Newspaper"),
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

ianews.register_special_newspaper = function(name, desc, image, file)
	file = 'news/'..file
	newspaper.register_newspaper(name, desc, 
		"[combine:64x64:0,0=ianews_newspaper_single.png\\^\\[resize\\:64x64]:7,27="..image.."\\^\\[resize\\:23x23", file)

	ianews.publications[name] = file
end

ianews.register_newspaper = function(name, desc, image, file, craftitem)
	file = 'news/'..file
	newspaper.register_newspaper(name, desc, 
		"[combine:64x64:0,0=ianews_newspaper_single.png\\^\\[resize\\:64x64]:7,27="..image.."\\^\\[resize\\:23x23", file)


	minetest.register_craft({
   		type   = "shapeless",
    		output = name,
    		recipe = {"ianews:newspaper_blank", craftitem,},
	})

	ianews.publications[name] = file
end

ianews.register_special_newspaper("ianews:newspaper_newplayer", S("Expositional Newspaper"), "kabuto.png", "newplayer.txt")
--ianews.register_newspaper("ianews:newspaper_newplayer", S("Expositional Newspaper"), "default_obsidian_shard.png", "newplayer.txt", "default:obsidian_shard")


local function formspec_display(meta, player_name, pos)
	-- Courtesy of minetest_game/mods/default/craftitems.lua
	local title, text = "", "", player_name
	local page, page_max, lines, string = 1, 1, {}, ""

	--if meta:to_table().fields.owner then
		title = meta:get_string("title")
		text = meta:get_string("text")

		for str in (text .. "\n"):gmatch("([^\n]*)[\n]") do
			lines[#lines+1] = str
		end

		if meta:to_table().fields.page then
			page = meta:to_table().fields.page
			page_max = meta:to_table().fields.page_max

			for i = ((lpp * page) - lpp) + 1, lpp * page do
				if not lines[i] then break end
				string = string .. lines[i] .. "\n"
			end
		end
	--end
	
	--if ianews.publications[title] ~= true then return end -- don't write to weird files

	local formspec
	if --owner == player_name or
		true or -- TODO
	(minetest.check_player_privs(player_name, {editor = true})
	and minetest.get_player_by_name(player_name):get_wielded_item():get_name() == "books:admin_pencil" ) then
		formspec = "size[8,8]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			--"field[-4,-4;0,0;owner;"..F(S("Owner:"))..";" .. owner .. "]" ..

			"field[0.5,1;7.5,0;title;"..F(S("Title:"))..";" ..
				F(title) .. "]" ..
			"textarea[0.5,1.5;7.5,7;text;"..F(S("Contents:"))..";" ..
				F(text) .. "]" ..
			"button_exit[2.5,7.5;3,1;save;"..F(S("Save")).."]"
			-- TODO FIXME WE NEED TO SET A HIDDEN "owner" FIELD !!
	minetest.show_formspec(player_name,
			'ianews:newspaper_stack_' .. minetest.pos_to_string(pos), formspec)
	else
		--formspec = "size[8,8]" ..
		--	default.gui_bg ..
		--	default.gui_bg_img ..
		--	--"label[0.5,0.5;by " .. owner .. "]" ..
		--	"tablecolumns[color;text]" ..
		--	"tableoptions[background=#00000000;highlight=#00000000;border=false]" ..
		--	"table[0.4,0;7,0.5;title;#FFFF00," .. F(title) .. "]" ..
		--	"textarea[0.5,1.5;7.5,7;;" ..
		--		F(string ~= "" and string or text) .. ";]" ..
		--	"button[2.4,7.6;0.8,0.8;book_prev;<]" ..
		--	"label[3.2,7.7;"..F(S("Page @1 of @2", page, page_max)) .. "]" ..
		--	"button[4.9,7.6;0.8,0.8;book_next;>]"
	end
end
minetest.register_on_player_receive_fields(function(player, formname, fields)
	print('formname: '..formname)
	if formname:sub(1, 23) ~= "ianews:newspaper_stack_" then return end
	print('sub: '..formname:sub(24))

	if fields.save and fields.title ~= "" and fields.text ~= "" then
		local pos = minetest.string_to_pos(formname:sub(24))
		local node = minetest.get_node(pos)
		local meta = minetest.get_meta(pos)
		local text = fields.text:gsub("\r\n", "\n"):gsub("\r", "\n"):sub(1, 10000)
		local title = fields.title:sub(1, 80)

		meta:set_string("title", title)
		meta:set_string("text", text)
		--meta:set_string("owner", fields.owner or player:get_player_name() )
		meta:set_string("infotext", text)

		local txt = ianews.publications[title]
		if txt == nil then return end -- don't write to weird files

    		--local txt = title or "nil_newspaper.txt"
		local news_file = io.open(minetest.get_worldpath().."/"..tostring(txt), "w")
		print('news_file: '..minetest.get_worldpath().."/"..tostring(txt))
		if news_file then
			news_file:write(text)
			news_file:close()
		else
			-- ?
		end
	end
end)
minetest.register_node("ianews:newspaper_stack", {
       description = "Stack of Newspapers",
       tiles = {"ianews_newspaper_stack.png",},
	--tiles      = ianews.chest_add.tiles,
        paramtype2 = "facedir",
        --groups     = ianews.chest_add.groups,
	--tube       = ianews.chest_add.tube,
        legacy_facedir_simple = true,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local player_name = clicker:get_player_name()
		local meta = minetest.get_meta(pos)
		formspec_display(meta, player_name, pos)
	end,
})
