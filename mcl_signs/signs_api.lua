---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Michieal (FaerRaven).
--- DateTime: 10/14/22 4:05 PM
---

-- INITIALIZE THE GLOBAL API FOR SIGNS.
mcl_signs = {}

-- LOCALIZATION
local S = minetest.get_translator("mcl_signs")
-- Signs form
local F = minetest.formspec_escape

-- PATHs
local modpath = minetest.get_modpath("mcl_signs")

-- CONSTANTS
local SIGN_WIDTH = 115

local LINE_LENGTH = 15
local NUMBER_OF_LINES = 4

local LINE_HEIGHT = 14
local CHAR_WIDTH = 5

-- SET UP THE CHARACTER MAPPING
-- Load the characters map (characters.txt)
--[[ File format of characters.txt:
It's an UTF-8 encoded text file that contains metadata for all supported characters. It contains a sequence of info
    blocks, one for each character. Each info block is made out of 3 lines:
Line 1: The literal UTF-8 encoded character
Line 2: Name of the texture file for this character minus the “.png” suffix; found in the “textures/” sub-directory
Line 3: Currently ignored. Previously this was for the character width in pixels

After line 3, another info block may follow. This repeats until the end of the file.

All character files must be 5 or 6 pixels wide (5 pixels are preferred)
]]

local chars_file = io.open(modpath .. "/characters.txt", "r")
-- FIXME: Support more characters (many characters are missing). Currently ASCII and Latin-1 Supplement are supported.
local charmap = {}
if not chars_file then
    minetest.log("error", "[mcl_signs] : character map file not found")
else
    while true do
        local char = chars_file:read("*l")
        if char == nil then
            break
        end
        local img = chars_file:read("*l")
        chars_file:read("*l")
        charmap[char] = img
    end
end

-- for testing purposes
-- local test_color = "#BC0000"

local pi = math.pi
local n = 23 / 56 - 1 / 128

-- GLOBALS
--- colors used for wools.
mcl_signs.mcl_wool_colors = {
    unicolor_white = "#FFFFFF",
    unicolor_dark_orange = "#502A00",
    unicolor_grey = "#5B5B5B",
    unicolor_darkgrey = "#303030",
    unicolor_blue = "#0000CC",
    unicolor_dark_green = "#005000",
    unicolor_green_or_lime = "#50CC00",
    unicolor_violet_purple = "#5000CC",
    unicolor_light_red_pink = "#FF5050",
    unicolor_yellow = "#CCCC00",
    unicolor_orange = "#CC5000",
    unicolor_red = "#CC0000",
    unicolor_cyan = "#00CCCC",
    unicolor_red_violet_magenta = "#CC0050",
    unicolor_black = "#000000",
    unicolor_light_blue = "#5050FF",
}
mcl_colors_official = {
    BLACK = "#000000",
    DARK_BLUE = "#0000AA",
    DARK_GREEN = "#00AA00",
    DARK_AQUA = "#00AAAA",
    DARK_RED = "#AA0000",
    DARK_PURPLE = "#AA00AA",
    GOLD = "#FFAA00",
    GRAY = "#AAAAAA",
    DARK_GRAY = "#555555",
    BLUE = "#5555FF",
    GREEN = "#55FF55",
    AQUA = "#55FFFF",
    RED = "#FF5555",
    LIGHT_PURPLE = "#FF55FF",
    YELLOW = "#FFFF55",
    WHITE = "#FFFFFF"
}
mcl_signs.woods = { "mcl_core:sprucewood", "mcl_core:darkwood", "mcl_core:wood", "mcl_core:birchwood", "mcl_core:junglewood", "mcl_core:acaciawood", "mcl_mangrove:mangrove_wood" }

mcl_signs.signtext_info_wall = {
    { delta = { x = 0, y = 0, z = n }, yaw = 0 },
    { delta = { x = n, y = 0, z = 0 }, yaw = pi / -2 },
    { delta = { x = 0, y = 0, z = -n }, yaw = pi },
    { delta = { x = -n, y = 0, z = 0 }, yaw = pi / 2 },
}
mcl_signs.signtext_info_standing = {}
mcl_signs.sign_groups = { handy = 1, axey = 1, deco_block = 1, material_wood = 1, attached_node = 1, dig_by_piston = 1, flammable = -1 }

-- HELPER FUNCTIONS' VARIABLES
local sign_glow = 6
local Dyes_table = {
    { "mcl_dye:aqua", mcl_colors_official.AQUA },
    { "mcl_dye:black", mcl_colors_official.BLACK },
    { "mcl_dye:blue", mcl_colors_official.BLUE },
    { "mcl_dye:brown", mcl_colors_official.brown },
    { "mcl_dye:cyan", mcl_signs.mcl_wool_colors.unicolor_cyan },
    { "mcl_dye:cyan 2", mcl_signs.mcl_wool_colors.unicolor_cyan },
    { "mcl_dye:green", mcl_colors_official.GREEN },
    { "mcl_dye:green 2", mcl_colors_official.GREEN },
    { "mcl_dye:dark_green", mcl_colors_official.DARK_GREEN },
    { "mcl_dye:grey", mcl_colors_official.GRAY },
    { "mcl_dye:grey 2", mcl_signs.mcl_wool_colors.unicolor_grey },
    { "mcl_dye:grey 3", mcl_colors_official.GRAY },
    { "mcl_dye:dark_grey", mcl_colors_official.DARK_GRAY },
    { "mcl_dye:dark_grey 2", mcl_signs.mcl_wool_colors.unicolor_darkgrey },
    { "mcl_dye:lightblue", mcl_signs.mcl_wool_colors.unicolor_light_blue },
    { "mcl_dye:lightblue 2", mcl_signs.mcl_wool_colors.unicolor_light_blue },
    { "mcl_dye:lime", mcl_signs.unicolor_green_or_lime },
    { "mcl_dye:magenta", mcl_signs.mcl_wool_colors.unicolor_red_violet_magenta },
    { "mcl_dye:magenta 2", mcl_signs.mcl_wool_colors.unicolor_red_violet_magenta },
    { "mcl_dye:magenta 3", mcl_signs.mcl_wool_colors.unicolor_red_violet_magenta },
    { "mcl_dye:orange", mcl_signs.mcl_wool_colors.unicolor_orange },
    { "mcl_dye:orange 2", mcl_signs.mcl_wool_colors.unicolor_dark_orange },
    { "mcl_dye:pink", mcl_signs.mcl_wool_colors.unicolor_light_red_pink },
    { "mcl_dye:pink 2", mcl_signs.mcl_wool_colors.unicolor_light_red_pink },
    { "mcl_dye:purple", mcl_colors_official.LIGHT_PURPLE },
    { "mcl_dye:red", mcl_signs.mcl_wool_colors.unicolor_red },
    { "mcl_dye:red 2", mcl_colors_official.RED },
    { "mcl_dye:silver", mcl_signs.mcl_wool_colors.unicolor_grey },
    { "mcl_dye:violet", mcl_colors_official.DARK_PURPLE },
    { "mcl_dye:violet 2", mcl_colors_official.DARK_PURPLE },
    { "mcl_dye:white", mcl_colors_official.WHITE },
    { "mcl_dye:white 3", mcl_colors_official.WHITE },
    { "mcl_dye:yellow", mcl_colors_official.YELLOW },
    { "mcl_dye:yellow 2", mcl_signs.mcl_wool_colors.unicolor_yellow },
}

-- Helper functions
local function string_to_array(str)
    local tab = {}
    for i = 1, string.len(str) do
        table.insert(tab, string.sub(str, i, i))
    end
    return tab
end

local function string_to_line_array(str)
    local tab = {}
    local current = 1
    local linechar = 1
    tab[1] = ""
    for _, char in ipairs(string_to_array(str)) do
        -- New line
        if char == "\n" then
            current = current + 1
            tab[current] = ""
            linechar = 1
        else
            tab[current] = tab[current] .. char
            linechar = linechar + 1
        end
    end
    return tab
end

local function get_rotation_level(facedir, nodename)
    local rl = facedir * 4
    if nodename == "mcl_signs:standing_sign22_5" or  nodename == "mcl_signs:standing_sign22_5_dark" then
        rl = rl + 1
    elseif nodename == "mcl_signs:standing_sign45" or  nodename == "mcl_signs:standing_sign45_dark" then
        rl = rl + 2
    elseif nodename == "mcl_signs:standing_sign67_5" or  nodename == "mcl_signs:standing_sign67_5_dark" then
        rl = rl + 3
    end
    return rl
end

function mcl_signs:round(num, idp)
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function mcl_signs:get_color_for_sign(item_name)

    for d = 1, #Dyes_table do
        if Dyes_table[d][1] == item_name then
            return Dyes_table[d][2]
        end
    end
    return "false"
end

function mcl_signs:color_sign (pos, text_color)
    local success = mcl_signs:update_sign(pos, nil, nil, true, text_color)

    -- debug step
    local meta = minetest.get_meta(pos)
    if not meta then
        minetest.log("verbose","Sign Color Fail - Metadata.")
        return false
    end
    minetest.log("verbose","Post-Sign Color: " .. meta:get_string("mcl_signs:text_color") .. " " .. meta:get_string("mcl_signs:glowing_sign") .. ".\n" .. dump(pos))

    return success

end

function mcl_signs:glow_sign (pos)
    local success = true
    -- Get Meta Data for the sign.
    local meta = minetest.get_meta(pos)

    if not meta then
        return false
    end
    local text = meta:get_string("text")
    if text == nil then
        text = ""
    end

    -- we can't make the text glow if there isn't any text
    if text == "" then
        return false
    end

    -- set up text glow
    local objects = minetest.get_objects_inside_radius(pos, 0.5)
    local text_entity
    for _, v in ipairs(objects) do
        local ent = v:get_luaentity()
        if ent and ent.name == "mcl_signs:text" then
            text_entity = v
            break
        end
    end
    text_entity:set_properties({
        glow = sign_glow,
    })

    meta:set_string("mcl_signs:glowing_sign", "true")
    -- debug step
    minetest.log("verbose","Post-Sign Glow: " .. meta:get_string("mcl_signs:text_color") .. " " .. meta:get_string("mcl_signs:glowing_sign") .. ".\n" .. dump(pos))

    return success
end

function mcl_signs:create_lettering(text, signnodename, sign_color)
    if sign_color == nil then
        sign_color = mcl_colors.BLACK
    end
    local texture = mcl_signs:generate_texture(mcl_signs:create_lines(text), signnodename, sign_color)

    return texture
end

function mcl_signs:create_lines(text)
    local line_num = 1
    local tab = {}
    for _, line in ipairs(string_to_line_array(text)) do
        if line_num > NUMBER_OF_LINES then
            break
        end
        table.insert(tab, line)
        line_num = line_num + 1
    end
    return tab
end

function mcl_signs:generate_line(s, ypos)
    local i = 1
    local parsed = {}
    local width = 0
    local chars = 0
    local printed_char_width = CHAR_WIDTH + 1
    while chars < LINE_LENGTH and i <= #s do
        local file
        -- Get and render character
        if charmap[s:sub(i, i)] then
            file = charmap[s:sub(i, i)]
            i = i + 1
        elseif i < #s and charmap[s:sub(i, i + 1)] then
            file = charmap[s:sub(i, i + 1)]
            i = i + 2
        else
            -- No character image found.
            -- Use replacement character:
            file = "_rc"
            i = i + 1
            minetest.log("verbose", "[mcl_signs] Unknown symbol in '" .. s .. "' at " .. i)
        end
        if file then
            width = width + printed_char_width
            table.insert(parsed, file)
            chars = chars + 1
        end
    end
    width = width - 1

    local texture = ""
    local xpos = math.floor((SIGN_WIDTH - width) / 2)
    for i = 1, #parsed do
        texture = texture .. ":" .. xpos .. "," .. ypos .. "=" .. parsed[i] .. ".png"
        xpos = xpos + printed_char_width
    end
    return texture
end

function mcl_signs:generate_texture(lines, signnodename, letter_color)
    local texture = "[combine:" .. SIGN_WIDTH .. "x" .. SIGN_WIDTH
    local ypos
    if signnodename == "mcl_signs:wall_sign" or signnodename == "mcl_signs:wall_sign_dark" then
        ypos = 30
    else
        ypos = 0
    end
    for i = 1, #lines do
        texture = texture .. mcl_signs:generate_line(lines[i], ypos)
        ypos = ypos + LINE_HEIGHT
    end

    texture = "(" .. texture .. "^[multiply:" .. letter_color .. ")"
    return texture
end

function mcl_signs:get_wall_signtext_info(param2, nodename)
    local dir = minetest.wallmounted_to_dir(param2)
    if dir.x > 0 then
        return 2
    elseif dir.z > 0 then
        return 1
    elseif dir.x < 0 then
        return 4
    else
        return 3
    end
end

function mcl_signs:destruct_sign(pos)
    local objects = minetest.get_objects_inside_radius(pos, 0.5)
    for _, v in ipairs(objects) do
        local ent = v:get_luaentity()
        if ent and ent.name == "mcl_signs:text" then
            v:remove()
        end
    end
    local players = minetest.get_connected_players()
    for p = 1, #players do
        if vector.distance(players[p]:get_pos(), pos) <= 30 then
            minetest.close_formspec(players[p]:get_player_name(), "mcl_signs:set_text_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z)
        end
    end
end

function mcl_signs:update_sign(pos, fields, sender, force_remove, text_color)
    -- Get Meta Data for the sign.
    local meta = minetest.get_meta(pos)

    if not meta then
        return false
    end
    local text = meta:get_string("text")
    if fields and (text == "" and fields.text) then
        meta:set_string("text", fields.text)
        text = fields.text
    end
    if text == nil then
        text = ""
    end

    -- find text color.
    local sign_color

    if meta:get_string("mcl_signs:text_color") == "" then
        -- if no sign text color has been assigned, make it black.
        sign_color = mcl_colors.BLACK
        meta:set_string("mcl_signs:text_color", sign_color)
    else
        sign_color = meta:get_string("mcl_signs:text_color")
    end

    if text_color == nil then
        text_color = "false"
    end

    if text_color == "false" then
        text_color = sign_color --if a new color hasn't been chosen, then keep the existing color.
    end

    -- find the sign's glow value
    local has_glow = false

    if meta:get_string("mcl_signs:glowing_sign") == "" or meta:get_string("mcl_signs:glowing_sign") == "false" then
        has_glow = false
        meta:set_string("mcl_signs:glowing_sign", "false")
    else
        has_glow = true
    end

    -- debug step
    -- minetest.log("Pre-Sign Update: " .. sign_color .. " " .. meta:get_string("mcl_signs:glowing_sign") .. ".\n" .. dump(pos))

    local sign_info
    local n = minetest.get_node(pos)
    local nn = n.name

    if nn == "mcl_signs:standing_sign" or nn == "mcl_signs:standing_sign22_5" or nn == "mcl_signs:standing_sign45" or nn == "mcl_signs:standing_sign67_5" then
        sign_info = mcl_signs.signtext_info_standing[get_rotation_level(n.param2, nn) + 1]
    elseif nn == "mcl_signs:standing_sign_dark" or nn == "mcl_signs:standing_sign22_5_dark" or nn == "mcl_signs:standing_sign45_dark" or nn == "mcl_signs:standing_sign67_5_dark" then
        sign_info = mcl_signs.signtext_info_standing[get_rotation_level(n.param2, nn) + 1]
    elseif nn == "mcl_signs:wall_sign" or nn == "mcl_signs:wall_sign_dark" then
        sign_info = mcl_signs.signtext_info_wall[mcl_signs:get_wall_signtext_info(n.param2)]
    end
    if sign_info == nil then
        minetest.log("error", "[mcl_signs::update] Missing sign_info!")
        return
    end

    local objects = minetest.get_objects_inside_radius(pos, 0.5)
    local text_entity
    for _, v in ipairs(objects) do
        local ent = v:get_luaentity()
        if ent and ent.name == "mcl_signs:text" then
            if force_remove then
                v:remove()
            else
                text_entity = v
                break
            end
        end
    end

    if not text_entity then
        text_entity = minetest.add_entity({
            x = pos.x + sign_info.delta.x,
            y = pos.y + sign_info.delta.y,
            z = pos.z + sign_info.delta.z }, "mcl_signs:text")
    end
    text_entity:get_luaentity()._signnodename = nn

    -- Set the actual properties for the sign
    text_entity:set_properties({
        textures = { mcl_signs:create_lettering(text, nn, text_color) },
    })

    if has_glow then
        text_entity:set_properties({
            glow = sign_glow,
        })
    end

    text_entity:set_yaw(sign_info.yaw)

    -- save sign metadata.
    meta:set_string("mcl_signs:text_color", text_color)
    -- debug step
    -- minetest.log("Post-Sign Update: " .. meta:get_string("mcl_signs:text_color") .. " " .. meta:get_string("mcl_signs:glowing_sign") .. ".\n" .. dump(pos))

    return true

end

function mcl_signs:show_formspec(player, pos)
    minetest.show_formspec(
            player:get_player_name(),
            "mcl_signs:set_text_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z,
            "size[6,3]textarea[0.25,0.25;6,1.5;text;" .. F(S("Enter sign text:")) .. ";]label[0,1.5;" .. F(S("Maximum line length: 15")) .. "\n" .. F(S("Maximum lines: 4")) .. "]button_exit[0,2.5;6,1;submit;" .. F(S("Done")) .. "]"
    )
end

