editor = {
	_context = {}
}

local modpath = minetest.get_modpath("editor")
dofile(modpath .. "/filesystem.lua")
dofile(modpath .. "/editor.lua")

-- Example editor!

local test_editor = editor.editor:new("editor:editor")
test_editor:register_button("Run", function(self, name, context)
	local code = context.buffer[context.open]
	if code then
		-- WARNING! Insecure
		print("running: " .. code)
		local luacode = loadstring("return (" .. code .. ")")
		if luacode then
			minetest.chat_send_player(name, "Result: " .. dump(luacode()))
		else
			minetest.chat_send_player(name, "Could not execute, errors in lua code")
		end
	else
		minetest.chat_send_player(name, "Could not execute, unable to get code from buffer")
	end
end)

minetest.register_chatcommand("editor", {
	func = function(name, param)
		test_editor:show(name)
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "editor:editor" then
		local name = player:get_player_name()
		test_editor:on_event(name, fields)
	elseif formname == "editor:editor_new" then
		local name = player:get_player_name()
		test_editor:on_new_dialog_event(name, fields)
	end
end)

--
-- Save and load player filesystems from "editor_files" directory
--

local datapath = minetest.get_worldpath() .. "/editor_files/"
if not minetest.mkdir(datapath) then
	error("[editor] failed to create directory!")
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	test_editor:create_player(name)
	local file = io.open(datapath .. "/" .. name .. ".lua", "r")
	if file then
		print("[editor] loading " .. datapath .. "/" .. name .. ".lua")
		file:close()
		test_editor._context[name].filesystem:load(datapath .. "/" .. name .. ".lua")
	else
		error("could not load " .. datapath .. "/" .. name .. ".lua")
	end
end)

local function save_and_delete_player_editor(name)
	local context = test_editor._context[name]
	if context and context.filesystem then
		print("[editor] Saved to " .. datapath .. "/" .. name .. ".lua")
		context.filesystem:save(datapath .. "/" .. name .. ".lua")
		test_editor:delete_player(name)
	else
		error("Count not save!" .. datapath .. "/" .. name .. ".lua")
	end
end

minetest.register_on_leaveplayer(function(player)
	save_and_delete_player_editor(player:get_player_name())
end)

minetest.register_on_shutdown(function()
	for key, value in pairs(test_editor._context) do
		save_and_delete_player_editor(key)
	end
end)
