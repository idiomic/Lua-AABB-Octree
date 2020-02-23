--Tyler R. Hoyer
--February 22, 2020
--Volumetric AABB Octree with Intersection Test and Commenting
--TylerRichardHoyer@gmail.com

local Octree = {}
local Octree_metatable = {__index = Octree}

--The smallest size of a cell
local MINIMUM_SIZE = 1

local function NIL()
	return
end

local pow2 = {
	2^0;
	2^1;
	2^2;
}

local toCoord = {
	'X';
	'Y';
	'Z';
}

function Octree.new(origin, size)
	assert(size >= MINIMUM_SIZE, 'Requested size is too small')

	local new
	if size == MINIMUM_SIZE then
		new = {
			origin = origin;
			size = size;
			values = {};
			child = NIL;
			num_children = 0;
		}
	else
		new = {
			origin = origin;
			size = size;
			values = {};
			num_children = 0;
			nil, nil, nil, nil; --(1, 2, 3, 4)
			nil, nil, nil, nil; --(5, 6, 7, 8)
		}
	end
	return setmetatable(new, Octree_metatable)
end

function Octree:index(min, max)
	local o = self.origin
	local i = 1
	for axis, coord in ipairs(toCoord) do
		if min[coord] > o[coord] then
			i = i + pow2[axis]
		elseif max[coord] > o[coord] then
			if min[coord] < o[coord] then
				return
			end
			i = i + pow2[axis]
		end
	end
	return i
end

function Octree:remove(min, max, value)
	local n = self.num_children
	local i = self:index(min, max)

	if not i or self.size <= MINIMUM_SIZE then
		self.values[value] = nil
	else
		if self[i] and self[i]:remove(min, max, value) then
			n = n - 1
			self[i] = nil
			self.num_children = n
		end
	end

	return n == 0 and next(self.values) == nil
end

function Octree:insert(min, max, value)
	if self.size <= MINIMUM_SIZE then
		self.values[value] = true
		return
	end

	local i = self:index(min, max)
	if not i then
		self.values[value] = true
		return
	end

	local child = self[i]
	if not child then
		local origin = self.origin
		local offset = self.size * 0.5
		child = Octree.new(
			Vector3.new(
				origin.X + (min.X <= origin.X and -offset or offset),
				origin.Y + (min.Y <= origin.Y and -offset or offset),
				origin.Z + (min.Z <= origin.Z and -offset or offset)
			),
			offset
		)
		self.num_children = self.num_children + 1
		self[i] = child
	end

	return child:insert(min, max, value)
end

function Octree:_check(min, max, result, i, axis)
	if axis == 0 then
		if self[i] then
			return self[i]:intersection(min, max, result)
		end
		return
	end
	
	local coord = toCoord[axis]
	if max[coord] <= self.origin[coord] then
		return self:_check(min, max, result, i, axis - 1)
	elseif min[coord] >= self.origin[coord] then
		return self:_check(min, max, result, i + pow2[axis], axis - 1)
	else
		self:_check(min, max, result, i, axis - 1)
		return self:_check(min, max, result, i + pow2[axis], axis - 1)
	end
end

function Octree:intersection(min, max, result)
	for value in pairs(self.values) do
		result[value] = true
	end
	return self:_check(min, max, result, 1, 3)
end

return Octree
