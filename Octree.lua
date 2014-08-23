--Tyler R. Hoyer
--August 22, 2014
--Volumetric AABB Octree with Intersection Test and Commenting
--TylerRichardHoyer@gmail.com

local Octree = {}
local Octree_metatable = {__index = Octree}

--The smallest size of a cell
local MINIMUM_SIZE = 1

--Create a new Octree
--Returns a table
function Octree.Octree(x, y, z, size) 
	return setmetatable({
		x, y, z; --The center (1, 2, 3)
		
		size; --The size of the cell as power of 2 (4)
		
		{}; --The list of values inside of the cell (5)
		
		--The eight sub-cells (xyz sorted, lowest first)
		false, false, false, false; --(6, 7, 8, 9)
		false, false, false, false; --(10, 11, 12, 13)
	}, Octree_metatable)
end

--Get the index of a child
--Returns an integer or false
function Octree:child(min_x, min_y, min_z, max_x, max_y, max_z)

	--The size of the cell's children
	local children_size = 2^(self[4] - 1)
	
	--Check that the children are big enough
	if children_size < MINIMUM_SIZE then
		return false
	end

	--The cell's center point
	local x = self[1]
	local y = self[2]
	local z = self[3]

	--The min point's octant relative to the center point of the cell
	local lesser_x = min_x <= x
	local lesser_y = min_y <= y
	local lesser_z = min_z <= z
	
	--Check if the max and min points are in the same child
	if lesser_x == (max_x <= x) 
		and lesser_y == (max_y <= y) 
		and lesser_z == (max_z <= z) then
		
		--Return the child's index
		return 6 
			+ (lesser_x and 0 or 4) 
			+ (lesser_y and 0 or 2) 
			+ (lesser_z and 0 or 1)
	end

	--Return false, in multiple children
	return false
end

--Remove a value
--Returns a boolean
function Octree:remove(min_x, min_y, min_z, max_x, max_y, max_z, value)

	--If the value is in a child, get it's index
	local child_index = self:child(min_x, min_y, min_z, max_x, max_y, max_z)
	
	--Check if the value belongs in a child
	if child_index then
		local child = self[child_index]

		if not child then
			--Value's container does not exist, return cell not changed
			return false
		end

		--Remove the value from the child cell
		local child_updated = child:remove(min_x, min_y, min_z, max_x, max_y, max_z, value)

		--Check if the child can be deleted
		--Must have been updated, have no values, and have no children
		if child_updated and #child[5] == 0 and not (
			child[6] or child[7] or child[8] or child[9] 
			or child[10] or child[11] or child[12] or child[13]) then
			self[child_index] = false

			--Value removed, return cell changed
			return true
		end

		--Value removed, return cell not changed
		return false
	end

	--Search the cell's values
	local values = self[5]
	for i = 1, #values do

		--Check if the value is the value that needs to be deleted
		if values[i] == value then
			table.remove(values, i)

			--Value removed, return cell changed
			return true
		end
	end
	
	--Value not found, return cell not changed
	return false
end

--Add a value
--Returns nil
function Octree:add(min_x, min_y, min_z, max_x, max_y, max_z, value)

	--If the value is in a child, get it's index
	local child_index = self:child(min_x, min_y, min_z, max_x, max_y, max_z)
	
	--Check if the value belongs in a child
	if child_index then
		local child = self[child_index]

		--Create the child if it does not exist
		if not child then
			local offset = 2 ^ (self[4] - 2)
			local child_x = self[1] + (min_x <= self[1] and -offset or offset)
			local child_y = self[2] + (min_y <= self[2] and -offset or offset)
			local child_z = self[3] + (min_z <= self[3] and -offset or offset)
			child = Octree.Octree(child_x, child_y, child_z, self[4] - 1)
			self[child_index] = child
		end
		
		--Add the value to the child (tail call for speed, returns nil)
		return child:add(min_x, min_y, min_z, max_x, max_y, max_z, value)
	end
	
	--Add the value to this cell
	local values = self[5]
	values[#values + 1] = value
end

--Get values intersecting an AABB
--Returns nil, result argument contains resultant values
--Beware: this recursive function calls itself in a sub-recursive function
function Octree:intersection(min_x, min_y, min_z, max_x, max_y, max_z, result)

	--Append the values in the cell to the result
	local values = self[5]
	local numResult = #result
	for i = 1, #values do
		result[numResult + i] = values[i]
	end

	--The center point of the cell
	local x = self[1]
	local y = self[2]
	local z = self[3]

	--The min point's octant relative to the center of the cell
	local lesser = {
		min_z <= z,
		min_y <= y,
		min_x <= x}

	--The true if the min and max points are in different octants
	local split = {
		lesser[1] ~= (max_z <= z),
		lesser[2] ~= (max_y <= y),
		lesser[3] ~= (max_x <= x)}

	--This is very complex on multiple levels. The goal is to find out what octants contain
	--the AABB defined by the min and max points. It does this by checking each axis. For each
	--axis, the min and max points can be less than, greater than, or split around the center
	--offset. Once one axis is determined, then it checks the next axis. Once all three are
	--checked, it checks the current point defined by them. If an axis is split, it checks the
	--first side for the rest of the axises, then checks the other side. It is simplest, fastest,
	--and easiest to write in a recursive function.
	local function check(current, i)

		--If the checks are done
		if i == 0 then
			local child = self[current]
			--Check if the child exists

			if child then
				--Add values contained in the child
				return child:intersection(min_x, min_y, min_z, max_x, max_y, max_z, result)
			end

		--Check if split
		elseif split[i] then
			--Add lesser side
			check(current, i - 1)
			--Add greater side
			return check(current + 2^(i - 1), i - 1)

		--Check if on lesser side
		elseif lesser[i] then
			--Add lesser side
			return check(current, i - 1)

		else
			--Add greater side
			return check(current + 2^(i - 1), i - 1)
		end
	end

	--Start the checks. Returns nil
	return check(6, 3)
end

--Print structure
--Returns nil
function Octree:print(tabs)
	tabs = tabs or ""
	
	--Print center
	print(tabs .. "Center: <" .. self[1] .. ", " .. self[2] .. ", " .. self[3] .. ">")

	--Print values
	print(tabs .. "Values: {" .. table.concat(self[5], ", ") .. "}")

	--Print children
	tabs = tabs .. "\t"
	for i = 6, 13 do

		--Check if the child exists and print it
		if self[i] then
			self[i]:print(tabs)
		end
	end
end
