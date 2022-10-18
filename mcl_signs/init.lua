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

local node_sounds
if minetest.get_modpath("mcl_sounds") then
    node_sounds = mcl_sounds.node_sound_wood_defaults()
end

-- wall signs & hanging signs. (including darker signs)
local whsigns = {
    description = S("Sign"),
    _tt_help = S("Can be written"),
    _doc_items_longdesc = S("Signs can be written and come in two variants: Wall sign and sign on a sign post. Signs can be placed on the top and the sides of other blocks, but not below them."),
    _doc_items_usagehelp = S("After placing the sign, you can write something on it. You have 4 lines of text with up to 15 characters for each line; anything beyond these limits is lost. Not all characters are supported. The text can not be changed once it has been written; you have to break and place the sign again. Can be colored and made to glow."),
    inventory_image = "default_sign.png",
    walkable = false,
    is_ground_content = false,
    wield_image = "default_sign.png",
    node_placement_prediction = "",
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "wallmounted",
    drawtype = "mesh",
    mesh = "mcl_signs_signonwallmount.obj",
    selection_box = { type = "wallmounted", wall_side = { -0.5, -7 / 28, -0.5, -23 / 56, 7 / 28, 0.5 } },
    tiles = { "mcl_signs_sign.png" },
    use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "opaque" or false,
    groups = mcl_signs.sign_groups,
    stack_max = 16,
    sounds = node_sounds,

    on_place = function(itemstack, placer, pointed_thing)
        local above = pointed_thing.above
        local under = pointed_thing.under

        -- Use pointed node's on_rightclick function first, if present
        local node_under = minetest.get_node(under)
        if placer and not placer:get_player_control().sneak then
            if minetest.registered_nodes[node_under.name] and minetest.registered_nodes[node_under.name].on_rightclick then
                return minetest.registered_nodes[node_under.name].on_rightclick(under, node_under, placer, itemstack) or itemstack
            end
        end

        local dir = vector.subtract(under, above)

        -- Only build when it's legal
        local abovenodedef = minetest.registered_nodes[minetest.get_node(above).name]
        if not abovenodedef or abovenodedef.buildable_to == false then
            return itemstack
        end

        local wdir = minetest.dir_to_wallmounted(dir)

        --local placer_pos = placer:get_pos()

        local fdir = minetest.dir_to_facedir(dir)

        local sign_info
        local nodeitem = ItemStack(itemstack)
        -- Ceiling
        if wdir == 0 then
            --how would you add sign to ceiling?
            return itemstack
            -- Floor
        elseif wdir == 1 then
            -- Standing sign

            -- Determine the sign rotation based on player's yaw
            local yaw = math.pi * 2 - placer:get_look_horizontal()

            -- Select one of 16 possible rotations (0-15)
            local rotation_level = round((yaw / (math.pi * 2)) * 16)

            if rotation_level > 15 then
                rotation_level = 0
            elseif rotation_level < 0 then
                rotation_level = 15
            end

            -- The actual rotation is a combination of predefined mesh and facedir (see node definition)
            if rotation_level % 4 == 0 then
                nodeitem:set_name("mcl_signs:standing_sign")
            elseif rotation_level % 4 == 1 then
                nodeitem:set_name("mcl_signs:standing_sign22_5")
            elseif rotation_level % 4 == 2 then
                nodeitem:set_name("mcl_signs:standing_sign45")
            elseif rotation_level % 4 == 3 then
                nodeitem:set_name("mcl_signs:standing_sign67_5")
            end
            fdir = math.floor(rotation_level / 4)

            -- Place the node!
            local _, success = minetest.item_place_node(nodeitem, placer, pointed_thing, fdir)
            if not success then
                return itemstack
            end
            if not minetest.is_creative_enabled(placer:get_player_name()) then
                itemstack:take_item()
            end
            sign_info = mcl_signs.signtext_info_standing[rotation_level + 1]
            -- Side
        else
            -- Wall sign
            local _, success = minetest.item_place_node(itemstack, placer, pointed_thing, wdir)
            if not success then
                return itemstack
            end
            sign_info = mcl_signs.signtext_info_wall[fdir + 1]
        end

        -- Determine spawn position of entity
        local place_pos
        if minetest.registered_nodes[node_under.name].buildable_to then
            place_pos = under
        else
            place_pos = above
        end

        local text_entity = minetest.add_entity({
            x = place_pos.x + sign_info.delta.x,
            y = place_pos.y + sign_info.delta.y,
            z = place_pos.z + sign_info.delta.z }, "mcl_signs:text")
        text_entity:set_yaw(sign_info.yaw)
        text_entity:get_luaentity()._signnodename = nodeitem:get_name()

        minetest.sound_play({ name = "default_place_node_hard", gain = 1.0 }, { pos = place_pos }, true)

        mcl_signs:show_formspec(placer, place_pos)
        return itemstack
    end,
    on_destruct = function(pos)
        mcl_signs:destruct_sign(pos)
    end,
    --[[   on_punch = function(pos, node, puncher)
           mcl_signs:update_sign(pos)
       end,  ]] -- commented out, as it's pretty useless code. "punch to update the sign"
    on_rotate = function(pos, node, user, mode)
        if mode == screwdriver.ROTATE_FACE then
            local r = screwdriver.rotate.wallmounted(pos, node, mode)
            node.param2 = r
            minetest.swap_node(pos, node)
            mcl_signs:update_sign(pos, nil, nil, true)
            return true
        else
            return false
        end
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        -- local pt_pos = pointed_thing:get_pos()
        minetest.log("verbose","MCL_SIGNS::Wall_Sign Right Click event.")

        -- make sure player is clicking
        if not clicker or not clicker:is_player() then
            return
        end

        local item = clicker:get_wielded_item()
        local iname = item:get_name()

        if node then
            minetest.log("verbose","MCL_SIGNS::Wall_Sign Right Click event on valid node.")

            -- handle glow from glow_ink_sac *first*
            if (iname == "mcl_mobitems:glow_ink_sac") then
                clicker:set_wielded_item(item)
                local success = mcl_signs:glow_sign(pos)
                if success then
                    minetest.log("verbose","Sign Glow Success.")
                    itemstack:take_item()
                end
                return
            end

            -- check the wielded item to make sure that it is a dye.
            local txt_color = mcl_signs:get_color_for_sign(iname)
            if txt_color ~= "false" then
                clicker:set_wielded_item(item)
                local success = mcl_signs:color_sign(pos, txt_color)
                if success then
                    minetest.log("verbose","Sign Color Success.")
                    itemstack:take_item()
                end
            end
        end
    end,

    _mcl_hardness = 1,
    _mcl_blast_resistance = 1,
}

-- standard wall_sign:
minetest.register_node("mcl_signs:wall_sign", whsigns)

-- dark standard wall sign
local whsigns_dark = table.copy(whsigns)
whsigns_dark.wield_image = "default_sign_dark.png"
whsigns_dark.tiles = { "mcl_signs_sign_dark.png" }
whsigns_dark.inventory_image = "default_sign_dark.png"

minetest.register_node("mcl_signs:wall_sign_dark", whsigns_dark)

-- Standing sign nodes.
-- 4 rotations at 0°, 22.5°, 45° and 67.5°.
-- These are 4 out of 16 possible rotations.
-- With facedir the remaining 12 rotations are constructed.

-- 0°
local ssign = {
    paramtype = "light",
    use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "opaque" or false,
    sunlight_propagates = true,
    walkable = false,
    is_ground_content = false,
    paramtype2 = "facedir",
    drawtype = "mesh",
    mesh = "mcl_signs_sign.obj",
    selection_box = { type = "fixed", fixed = { -0.2, -0.5, -0.2, 0.2, 0.5, 0.2 } },
    tiles = { "mcl_signs_sign.png" },
    groups = mcl_signs.sign_groups,
    drop = "mcl_signs:wall_sign",
    stack_max = 16,
    sounds = node_sounds,

    on_destruct = function(pos)
        mcl_signs:destruct_sign(pos)
    end,
    --[[    on_punch = function(pos, node, puncher)
            mcl_signs:update_sign(pos)
        end, ]] -- commented out, as it's pretty useless code. "punch to update the sign"
    on_rotate = function(pos, node, user, mode)
        if mode == screwdriver.ROTATE_FACE then
            node.name = "mcl_signs:standing_sign22_5"
            minetest.swap_node(pos, node)
        elseif mode == screwdriver.ROTATE_AXIS then
            return false
        end
        mcl_signs:update_sign(pos, nil, nil, true)
        return true
    end,

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        -- local pt_pos = pointed_thing:get_pos()
        minetest.log("verbose","MCL_SIGNS::Standing_Sign Right Click event.")

        -- make sure player is clicking
        if not clicker or not clicker:is_player() then
            return
        end

        local item = clicker:get_wielded_item()
        local iname = item:get_name()

        if node then
            -- handle glow from glow_ink_sac *first*
            minetest.log("verbose","MCL_SIGNS::Standing_Sign Right Click event on valid node.")

            if (iname == "mcl_mobitems:glow_ink_sac") then
                clicker:set_wielded_item(item)
                local success = mcl_signs:glow_sign(pos)
                if success then
                    minetest.log("verbose","Sign Glow Success.")
                    itemstack:take_item()
                end
                return
            end

            -- check the wielded item to make sure that it is a dye.
            local txt_color = mcl_signs:get_color_for_sign(iname)
            if txt_color ~= "false" then
                clicker:set_wielded_item(item)
                local success = mcl_signs:color_sign(pos, txt_color)
                if success then
                    minetest.log("verbose","Sign Color Success.")
                    itemstack:take_item()
                end
            end
        end
    end,

    _mcl_hardness = 1,
    _mcl_blast_resistance = 1,
}

minetest.register_node("mcl_signs:standing_sign", ssign)

-- And, it's dark copy...
local ssignd = table.copy(ssign)
ssignd.wield_image = "default_sign_dark.png"
ssignd.tiles = { "mcl_signs_sign_dark.png" }
ssignd.inventory_image = "default_sign_dark.png"
ssignd.drop = "mcl_signs:wall_sign_dark"
minetest.register_node("mcl_signs:standing_sign_dark", ssignd)

-- 22.5°
local ssign22_5 = table.copy(ssign)
ssign22_5.mesh = "mcl_signs_sign22.5.obj"
ssign22_5.on_rotate = function(pos, node, user, mode)
    if mode == screwdriver.ROTATE_FACE then
        node.name = "mcl_signs:standing_sign45"
        minetest.swap_node(pos, node)
    elseif mode == screwdriver.ROTATE_AXIS then
        return false
    end
    mcl_signs:update_sign(pos, nil, nil, true)
    return true
end
minetest.register_node("mcl_signs:standing_sign22_5", ssign22_5)
-- register dark variant
ssign22_5.wield_image = "default_sign_dark.png"
ssign22_5.tiles = { "mcl_signs_sign_dark.png" }
ssign22_5.inventory_image = "default_sign_dark.png"
ssign22_5.drop = "mcl_signs:wall_sign_dark"
minetest.register_node("mcl_signs:standing_sign22_5_dark", ssign22_5)

-- 45°
local ssign45 = table.copy(ssign)
ssign45.mesh = "mcl_signs_sign45.obj"
ssign45.on_rotate = function(pos, node, user, mode)
    if mode == screwdriver.ROTATE_FACE then
        node.name = "mcl_signs:standing_sign67_5"
        minetest.swap_node(pos, node)
    elseif mode == screwdriver.ROTATE_AXIS then
        return false
    end
    mcl_signs:update_sign(pos, nil, nil, true)
    return true
end
minetest.register_node("mcl_signs:standing_sign45", ssign45)
-- register dark variant
ssign45.wield_image = "default_sign_dark.png"
ssign45.tiles = { "mcl_signs_sign_dark.png" }
ssign45.inventory_image = "default_sign_dark.png"
ssign45.drop = "mcl_signs:wall_sign_dark"
minetest.register_node("mcl_signs:standing_sign45_dark", ssign45)

-- 67.5°
local ssign67_5 = table.copy(ssign)
ssign67_5.mesh = "mcl_signs_sign67.5.obj"
ssign67_5.on_rotate = function(pos, node, user, mode)
    if mode == screwdriver.ROTATE_FACE then
        node.name = "mcl_signs:standing_sign"
        node.param2 = (node.param2 + 1) % 4
        minetest.swap_node(pos, node)
    elseif mode == screwdriver.ROTATE_AXIS then
        return false
    end
    mcl_signs:update_sign(pos, nil, nil, true)
    return true
end
minetest.register_node("mcl_signs:standing_sign67_5", ssign67_5)
-- register dark variant
ssign67_5.wield_image = "default_sign_dark.png"
ssign67_5.tiles = { "mcl_signs_sign_dark.png" }
ssign67_5.inventory_image = "default_sign_dark.png"
ssign67_5.drop = "mcl_signs:wall_sign_dark"
minetest.register_node("mcl_signs:standing_sign67_5_dark", ssign67_5)

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
        self.object:set_properties({
            textures = { mcl_signs:create_lettering(text, self._signnodename) },
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
    minetest.log("verbose","Register Sign Crafts: \n" .. dump(mcl_signs.woods))

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