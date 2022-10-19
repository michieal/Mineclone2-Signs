---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Michieal (FaerRaven).
--- DateTime: 10/14/22 4:05 PM
---

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

local table = table
local m = -1 / 16 + 1 / 64

-- Signs API
dofile(modpath .. "/signs_api.lua")

-- LOCALIZATION
local S = minetest.get_translator(modname)

-- PLACE YAW VALUES INTO THE TABLE.
for rot = 0, 15 do
    local yaw = math.pi * 2 - (((math.pi * 2) / 16) * rot)
    local delta = vector.multiply(minetest.yaw_to_dir(yaw), m)
    -- Offset because sign is a bit above node boundaries
    delta.y = delta.y + 2 / 28
    table.insert(mcl_signs.signtext_info_standing, { delta = delta, yaw = yaw })
end

-- HANDLE THE FORMSPEC CALLBACK
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname:find("mcl_signs:set_text_") == 1 then
        local x, y, z = formname:match("mcl_signs:set_text_(.-)_(.-)_(.*)")
        local pos = { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
        if not pos or not pos.x or not pos.y or not pos.z then
            return
        end
        mcl_signs:update_sign(pos, fields, player)
    end
end)

mcl_signs.generate_signs() -- initialize the nodes for the signs.

-- FIXME: Prevent entity destruction by /clearobjects
minetest.register_entity("mcl_signs:text", {
    pointable = false,
    visual = "upright_sprite",
    textures = {},
    physical = false,
    collide_with_objects = false,

    _signnodename = nil, -- node name of sign node to which the text belongs

    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            local des = minetest.deserialize(staticdata)
            if des then
                self._signnodename = des._signnodename
            end
        end
        local meta = minetest.get_meta(self.object:get_pos())
        local text = meta:get_string("text")
--[[
        if DEBUG then
            minetest.log("text found:")
            minetest.log(dump(text))
        end
]]

        self.object:set_properties({
            textures = { mcl_signs.create_lettering(text, self._signnodename) },
        })
        self.object:set_armor_groups({ immortal = 1 })
    end,
    get_staticdata = function(self)
        local out = { _signnodename = self._signnodename }
        return minetest.serialize(out)
    end,
})

-- Make the wall signs burnable.
minetest.register_craft({
    type = "fuel",
    recipe = "mcl_signs:wall_sign",
    burntime = 10,
})

minetest.register_craft({
    type = "fuel",
    recipe = "mcl_signs:wall_sign_dark",
    burntime = 10,
})

-- register crafts (actual recipes)
if minetest.get_modpath("mcl_core") then

    -- debug step
    minetest.log("verbose", "Register Sign Crafts: \n" .. dump(mcl_signs.woods))

    for w = 1, #mcl_signs.woods do
        local itemstring = ""

        if mcl_signs.woods[w] == "mcl_core:sprucewood" or mcl_signs.woods[w] == "mcl_core:darkwood" then
            itemstring = "mcl_signs:wall_sign_dark"
        else
            itemstring = "mcl_signs:wall_sign 3"
        end

        local c = mcl_signs.woods[w]

        minetest.register_craft({
            output = itemstring,
            recipe = {
                { c, c, c },
                { c, c, c },
                { "", "mcl_core:stick", "" },
            },
        })
    end
end

if minetest.get_modpath("doc") then
    doc.add_entry_alias("nodes", "mcl_signs:wall_sign", "nodes", "mcl_signs:standing_sign")
    doc.add_entry_alias("nodes", "mcl_signs:wall_sign", "nodes", "mcl_signs:standing_sign22_5")
    doc.add_entry_alias("nodes", "mcl_signs:wall_sign", "nodes", "mcl_signs:standing_sign45")
    doc.add_entry_alias("nodes", "mcl_signs:wall_sign", "nodes", "mcl_signs:standing_sign67_5")
    doc.add_entry_alias("nodes", "mcl_signs:wall_sign", "nodes", "mcl_signs:wall_sign_dark")
    doc.add_entry_alias("nodes", "mcl_signs:wall_sign", "nodes", "mcl_signs:standing_sign_dark")
    doc.add_entry_alias("nodes", "mcl_signs:wall_sign", "nodes", "mcl_signs:standing_sign22_5_dark")
    doc.add_entry_alias("nodes", "mcl_signs:wall_sign", "nodes", "mcl_signs:standing_sign45_dark")
    doc.add_entry_alias("nodes", "mcl_signs:wall_sign", "nodes", "mcl_signs:standing_sign67_5_dark")
end

minetest.register_alias("signs:sign_wall", "mcl_signs:wall_sign")
minetest.register_alias("signs:sign_yard", "mcl_signs:standing_sign")
minetest.register_alias("mcl_signs:wall_sign 3", "mcl_signs:wall_sign")

minetest.register_lbm({
    name = "mcl_signs:respawn_entities",
    label = "Respawn sign text entities",
    run_at_every_load = true,
    nodenames = {
        "mcl_signs:wall_sign", "mcl_signs:wall_sign_dark",
        "mcl_signs:standing_sign", "mcl_signs:standing_sign_dark",
        "mcl_signs:standing_sign22_5", "mcl_signs:standing_sign22_5_dark",
        "mcl_signs:standing_sign45", "mcl_signs:standing_sign45_dark",
        "mcl_signs:standing_sign67_5", "mcl_signs:standing_sign67_5_dark"
    },
    action = function(pos, node)
        mcl_signs:update_sign(pos)
    end,
})