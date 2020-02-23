Lua-Octree
==========

Lua implimentation of an Octree with an intersection test. The intersection test does not capture "touching" AABBs. If this behavior is desired, enlarge the search AABB by a value smaller than the minimum grid size. "min" and "max" are tables or userdatas representing a coordinate position with "X", "Y", and "Z" properties. The code currently, uses a Roblox envirionment global, "Vector3" to create these vector userdatas but this can be replaced to function outside the Roblox environment.
