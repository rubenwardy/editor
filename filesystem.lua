function editor.parse_path(path)
	local arr = path:split("/")
	local res = {}
	for i = 1, #arr do
		if arr ~= "" then
			res[#res + 1] = arr[i]

			if not arr[i]:find('^[%-%.%w_-% ]+$') then
				return nil
			end
		end
	end
	return arr
end

editor.filesystem = {}

function editor.filesystem:new(ref)
	ref = ref or {}
	setmetatable(ref, self)
	self.__index = self
	ref.files = {}
	return ref
end

function editor.filesystem:clone_filesystem()
	local ref = editor.filesystem:new()
	for path, data in pairs(self.files) do
		ref.files[path] = data
	end
	return ref
end

function editor.filesystem:exists(filepath)
	return self:read(filepath)
end

function editor.filesystem:read(filepath)
	return self.files[filepath]
end

function editor.filesystem:write(filepath, value)
	self.files[filepath] = value
end

function editor.filesystem:get_first_filepath()
	for path, _ in pairs(self.files) do
		return path
	end
end

function editor.filesystem:append(filepath, value)
	local txt = self.files[filepath] or ""
	txt = txt .. value
	self.files[filepath] = txt
end

function editor.filesystem:load(realfilepath)
	local file = io.open(realfilepath, "r")
	if file then
		local table = minetest.deserialize(file:read("*all"))
		file:close()
		if type(table) == "table" then
			self.files = table.files
			return true
		end
	end
	error("Unable to read filesystem")
end

function editor.filesystem:save(realfilepath)
	local file = io.open(realfilepath, "w")
	if file then
		file:write(minetest.serialize({
			version = 1,
			files = self.files
		}))
		file:close()
		return true
	end
	error("Unable to save filesystem")
end
