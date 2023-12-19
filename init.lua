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

--newspaper.register_newspaper("ianews:newspaper_official", "Mine Times Newspaper", "ianews_newspaper_mese_crystal.png",   "news/official.txt")
--minetest.register_craft({
--    type   = "shapeless",
--    output = "ianews:newspaper_official",
--    recipe = {"ianews:newspaper_blank", "default:mese_crystal"}
--})

-- TODO use a different image for expositional newspaper
-- TODO make it uncraftable
newspaper.register_newspaper("ianews:newspaper_newplayer",  "Expositional Newspaper",    "ianews_newspaper_obsidian_shard.png", "news/newplayer.txt")
minetest.register_craft({
    type   = "shapeless",
    output = "ianews:newspaper_default",
    recipe = {"ianews:newspaper_blank", "default:obsidian_shard"}
})

--newspaper.register_newspaper("ianews:newspaper_example",  "Example Newspaper",    "ianews_newspaper_diamond.png",        "news/example.txt")
--minetest.register_craft({
--    type   = "shapeless",
--    output = "ianews:newspaper_example",
--    recipe = {"ianews:newspaper_blank", "default:diamond"}
--})
