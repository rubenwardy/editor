editor = {
	_context = {}
}

local modpath = minetest.get_modpath("editor")
dofile(modpath .. "/filesystem.lua")
dofile(modpath .. "/editor.lua")

-- Example editor!

local test_editor = editor.editor:new()

test_editor:register_button("Run", function(name, context)
	local code = context.buffer[context.open]
	if code then
		-- WARNING! Insecure
		print("running: " .. code)
		local luacode = loadstring("return (" .. code .. ")")
		if luacode then
			local res = luacode()
			minetest.chat_send_player(name, "Result: " .. res)
		else
			minetest.chat_send_player(name, "Could not execute, errors in lua code")
		end
	else
		minetest.chat_send_player(name, "Could not execute, unable to get code from buffer")
	end
end)

minetest.register_chatcommand("editor", {
	func = function(name, param)
		test_editor:show(name, "editor:editor")
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "editor:editor" then
		local name = player:get_player_name()
		test_editor:on_event(name, fields)
	end
end)
