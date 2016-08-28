local gui_bg = default and default.gui_bg or ""
local gui_bg_img = default and default.gui_bg_img or ""
local contexts = {}

editor.editor = {}
function editor.editor:new(ref)
	if type(ref) == "string" then
		ref = {
			formname = ref,
			_buttons = {},
			_button_map = {},
			_context = {}
		}
	end

	ref = ref or {
		_buttons = {},
		_button_map = {},
		_context = {}
	}
	setmetatable(ref, self)
	self.__index = self

	if not ref.formname then
		error("!!!!")
	end

	local filesys = editor.filesystem:new()
	filesys:write("init.lua", "-- this is a test\nprint(\"test\")")
	filesys:write("depends.txt", "default")
	ref.default_filesystem = filesys

	ref:register_button("New", function(self, name, context)
		print("New button pressed!")
	end, function(self, name, context)
		return true
	end)

	ref:register_button("Save", function(self, name, context)
		local text = context.buffer[context.open]
			or error("[editor] This should never happen!")

		context.filesystem:write(context.open, text)
		minetest.chat_send_player(name, "Saved file to " .. context.open)
	end)

	ref:register_button("Close", function(self, name, context)
		for i = 1, #context.tabs do
			if context.tabs[i] == context.open then
				table.remove(context.tabs, i)
				context.buffer[context.open] = nil
				if i <= #context.tabs then
					context.open = context.tabs[i]
				elseif #context.tabs > 0 then
					context.open = context.tabs[#context.tabs]
				else
					context.open = nil
				end
				self:show(name)
				return
			end
		end
	end)

	return ref
end

function editor.editor:register_button(name, callback, should_show)
	self._buttons[#self._buttons + 1] = name
	self._button_map[name] = {
		callback = callback,
		should_show = should_show or function(self, name, context)
			return context.open ~= nil
		end
	}
end

function editor.editor:create_player(name)
	self._context[name] = self._context[name] or  {
		filesystem = self.default_filesystem:clone_filesystem(),
		open = "init.lua",
		tabs = {
			"init.lua",
			"depends.txt"
		},
		buffer = {}
	}
end

function editor.editor:delete_player(name)
	self._context[name] = nil
end

function editor.editor:get_formspec(name, context)
	local fs = "size[12,6.75]" .. gui_bg .. gui_bg_img

	if context.tabs and #context.tabs > 0 then
		fs = fs .. "tabheader[0.1,0;buffer_tabs;"
		local idx = 1
		for i = 1, #context.tabs do
			if i ~= 1 then
				fs = fs .. ","
			end
			fs = fs .. minetest.formspec_escape(context.tabs[i])
			if context.tabs[i] == context.open then
				idx = i
			end
		end
		fs = fs .. ";" .. idx .."]"
	end

	local x = 0
	for i = 1, #self._buttons do
		local btn = self._buttons[i]
		if self._button_map[btn].should_show(self, name, context) then
			x = x + 1
			fs = fs .. "button[" .. (2 + 1.05 * x) .. ",-0.15;1.2,1;btn_" ..
				btn:lower() .. ";" .. btn .. "]"
		end
	end

	if context.open then
		local text = context.buffer[context.open] or context.filesystem:read(context.open)
		fs = fs .. "textarea[3.25,0.8;9,7.2;text;;" .. text .. "]"
	end

	return fs
end

function editor.editor:show(name)
	self._context[name] = self._context[name] or {
		filesystem = self.default_filesystem:clone_filesystem(),
		open = "init.lua",
		tabs = {
			"init.lua",
			"depends.txt"
		},
		buffer = {}
	}
	minetest.show_formspec(name, self.formname, self:get_formspec(name, self._context[name]))
end

function editor.editor:on_event(name, fields)
	local context = self._context[name] or {}

	if context.open then
		context.buffer[context.open] = fields.text
	end

	for i = 1, #self._buttons do
		local btn = self._buttons[i]
		if fields["btn_" .. btn:lower()] then
			self._button_map[btn].callback(self, name, context)
		end
	end

	if fields.buffer_tabs then
		local idx = tonumber(fields.buffer_tabs)
		context.open = context.tabs[idx]
		self:show(name)
	end
end
