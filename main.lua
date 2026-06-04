local c = computer.getInstance()
local rRecipe = "Smart Plating"
local availRes = {50, 10, 2}
c.startComputer(c)
print("Loading ...")
local _, _, time = computer.magicTime()
local _, _, _, _, mi, s, ms = time:match("(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)%.(%d+)Z")
local starttime = mi * 60 * 1000 + s * 1000 + ms


---Start of Helpfunctions


-- string.find returns the starting and ending positions of the substring if found, or nil if not found.
function stringContains(mainString, substring)
  	local startPos, endPos = string.find(mainString, substring)
  	if startPos then
    	return true
  	else
   	 	return false
 	end
end


-- Adds the contents of t2 to t1
function tableConcat( t1, t2 )
    for i=1, #t2 do
       t1[#t1+1] = t2[i]
    end
    return t1
end

-- Finds the first value of t1
function find(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

---Can the given value be found in a table of { key, values } ?
function tableHasValue( t, value )
    if t == nil or value == nil then
    print("table or value is nil")
        return false
    end

    for _,v in pairs( t ) do
        if v == value then --value exists
            return true
        end
    end

    return false
end



---Find and return a table of all the NetworkComponent proxies that are of the given class[es]
---@param class any Class name or table (of tables) of class names
---@param boolean Return only one
---@return table | nil | proxy: indexed table of all NetworkComponents found
function getComponentsByClass( class, getOne )
    local results = {}

    if ( getOne == nil ) then
        getOne = false
    end

    if type( class ) == "table" then

        for _, c in pairs( class ) do
            local proxies = getComponentsByClass( c, getOne )
            if not getOne then
                tableConcat( results, proxies )
            else
                if( proxies ~= nil ) then
                    return proxies
                end
            end
        end

    elseif type( class ) == "string" then

        local ctype = classes[ class ]
        if ctype ~= nil then
            local comps = component.findComponent( ctype )
            for _, c in pairs( comps ) do
                local proxy = component.proxy( c )
                if getOne and proxy ~= nil then
                    return proxy
                elseif not tableHasValue( results, proxy ) then
                	--print("") print(proxy.ID)
                    table.insert( results, proxy )
                end
            end
        end
    end

    if ( getOne ) then
        return {}
    end

    return results
end

---Find and return a table of all the NetworkComponent proxies that are of the given class[es] and contain the given nick parts
---@param class any Class name or table (of tables) of class names
---@param class nickParts Nick or parts of a nick that we want to see
---@return table: indexed table of all NetworkComponents found
function getComponentsByClassAndNick( class, nickParts )
    if type( nickParts ) == 'string' then
        nickParts = { nickParts }
    end

    local classComponents = getComponentsByClass( class )
    local results = {}

    for _, component in pairs( classComponents ) do
        for _, nickPart in pairs( nickParts ) do
            if component.nick:find( nickPart, 1, true ) == nil then
                goto nextComponent
            end
        end

        table.insert( results, component )

        ::nextComponent::
    end

    return results
end



--- End of Helpfunctions

print("Allocating all possible recipes ...")

--find all recipes in the network sorted by class

local bool = true
local zw = getComponentsByClass("Manufacturer")
local zw1 = {zw[1]:getType()}
local modules = {{zw[1]}}
local modRec = {}

for _, res in pairs(zw) do
	bool = true
	for i, tp in pairs(zw1) do
		if bool and res:getType() == tp then
			modules[i][#modules[i]+1] = res
			bool = false
		end
	end
	if bool then
		modules[#modules+1] = {res}
		zw1[#zw1+1] = res:getType()
	end
end

local modRecopy = {}
for _, mod in pairs(modules) do 
	modRec[#modRec+1] = mod[1]:getRecipes()
	modRecopy[#modRecopy+1] = mod[1]:getRecipes()
end

--initialize arrays since i cant loop over an empty array

local currentPath = {} -- Top to bottom order in 2nd array!

rRlength = 0
rRecipes = {} -- endresult
zw = {} -- stack of established recipes
zw1 = {} -- corresponding module layer
for i, _ in pairs(modRec) do
	rRecipes[i] = {}
	for _, re in pairs(modRec[i]) do
		local pro = re:getProducts()
		for _, r in pairs(pro) do
			if r.type.name == rRecipe then
				rRecipes[i][#rRecipes[i]+1] = re
				currentPath[#currentPath+1] = re
				zw[#zw+1] = re
				zw1[#zw1+1] = i
			end
		end
	end
end
rRlength = #zw

-- then filter out all not needed recipes so we can do another bfs over it later on

local j = 1
while j <= #zw do
	for i, _ in pairs(modRecopy) do
		for h, re in pairs(modRecopy[i]) do
			if type(re) ~= "string" then
			bool = true
			local pro = re:getProducts()
			local ing = zw[j]:getIngredients()
			for _, r in pairs(pro) do
				if bool then
				for _, k in pairs(ing) do
					-- replace recipe so we dont get duplicates
					if bool and r.type.name == k.type.name then
						zw[#zw+1] = re
						rRecipes[i][#rRecipes[i]+1] = re
						modRecopy[i][h] = "some bullshit value"
						bool = false --better break
						break
					end

				end
				else break end 
			end
			end
		end
	end
	j = j+1
end

--for r in pairs(rRecipes) do print(r) for t in pairs(rRecipes[r]) do print(rRecipes[r][t].name) end end print(" ")

print("Establishing all permutations ...") -- #Have to take it for granted that the first recipes are the source recipes!

local visitedNodes = {}
local pathArray = {}
local origins = {}

while #currentPath ~= 0 do
	-- find next recipes based on the required ingredients
	local additionals = 1
	local ingredient
	while additionals > 0 do
		additionals = 0
		local ing = currentPath[#currentPath]:getIngredients()
		bool = true
		for i, _ in pairs(rRecipes) do
			if bool then
			for _, l in pairs(rRecipes[i]) do
				if bool then
				local pro = l:getProducts()
				for ii, j in pairs(ing) do
					if bool then
					for _, k in pairs(pro) do

						if k.type.name == j.type.name then
							for _, r in pairs(visitedNodes) do
								if l == r then
									additionals = -1
								end
							end
							if additionals == 0 then
								bool = false --couldnt i just do additionals > 0?
								additionals = 1
								currentPath[#currentPath+1] = l
								pathArray[#pathArray+1] = {{l}} -- structure is {current_recipes/path{ingredient.name{next_recipe}}}
								ingredient = ii
								if #currentPath == 2 then
									origins[#origins+1] = #pathArray
								end
								break
							else additionals = 0 end
						end
						
					end
					else break end 
				end
				else break end 
			end
			else break end 
		end
	end
	additionals = 0
	visitedNodes[#visitedNodes+1] = table.remove(currentPath, #currentPath) --deleting last one since itself doesnt have any permutations
	if #pathArray[#currentPath] < ingredient+1 then pathArray[#currentPath][ingredient+1] = {} end
	pathArray[#currentPath][ingredient+1][#pathArray[#currentPath][ingredient+1]+1] = visitedNodes[#visitedNodes] --save its relation to actually fully develop a tree for the final permutation calculation
end

print("Almost Done...") -- final permutation

local nextRecipes = {}

for ii, i in pairs(origins) do -- establish all the possible permutations for each layer -> so we need to search next arrays for the wished for ingredient
	
	local ending
	if ii == #origins then ending = #pathArray[i] else ending = origins[ii+1] end
	local currentPermutations
	local newCurrentPerms
	local additions = {}
	
	while #additions ~= 0 do
		local ingredients = additions[1]:getIngredients()
		for _, ing in pairs(ingredients) do

			for j in range(origin, ending) do -- j is the ingredients index
				if pathArray[j][1][1].name == ing then
					additions[#additions+1] = pathArray[j][1][1]
				if #currentPermutations == 0 then newCurrentPerms[#newCurrentPerms+1] = k 
				else
					for _, k in pairs(currentPermutations) do -- idee ist das zuerst alle permutation des ersten ingredients berechnet werden und danach das zweite damit weiterpermutiert
						newCurrentPerms[#newCurrentPerms+1] = k + pathArray[j][1][1]
					end 
				end
				end
			end
		end
		currentPermutations = {}
		for _, j in pairs(newCurrentPerms) do -- backtracing?
			currentPermutations[#currentPermutations+1] = j
		end
		table.remove(additions, 1)
	end

	--search next recipe in the array
end

print("Done")
--for r in pairs(rRecipes) do for t in pairs(rRecipes[r]) do print(rRecipes[r][t].name) end end


print("Calculating ratio of recipe to modules ...")
--Recipe List finally done, now start of calc
local a = {}
local b = {}
for x in pairs(rRecipes) do
	a[#a+1] = {}
	for z, _ in pairs(modules) do
		a[#a][#a[#a]+1] = 0
	end
	b[#b+1] = {}
	local res = rRecipes[x][#rRecipes[x]].name
	local map = {{res, 1.0}}
	for y = #rRecipes[x], 1, -1 do --_, item in pairs(rRecipes[x]) do 
		local item = rRecipes[x][y]
		local ing = item:getIngredients()
		for _, m in pairs(ing) do
			for _, n in pairs(rRecipes[x]) do
				local o = n:getProducts()
				for _, p in pairs(o) do
					if p.type.name == m.type.name then --.potential
						bool = true
						b[#b][#b[#b]+1] = {}
						for q, _ in pairs(modRec) do
							if bool then
							for _, r in pairs(modRec[q]) do
								if bool and n == r then
									local mul = 1.0
									for _, mn in pairs(map) do
										if item.name == mn[1] then
											mul = mn[2]
											break
										end
									end
									local num = ((m.amount*(60.0/item.duration))*mul) / (p.amount*(60.0/n.duration))
									a[#a][2] = a[#a][q] + math.ceil(num)
									b[#b][#b[#b]] = {m, num, q} --"a"
									map[#map+1] = {m.type.name, num}
									bool = false
									break
								end
							end
							end
						end
					end
				end
			end
		end 
	end
	for q, _ in pairs(modRec) do --solely to add to result
		for _, r in pairs(modRec[q]) do
			local prods = r:getProducts()
			for _, p in pairs(prods) do
				if p.type.name == res then
					a[#a][q] = a[#a][q] + 1
					b[#b][#b[#b]] = {p, 1.0, q}
				end
			end
		end
	end
end
print("Done")
--[[
for i in pairs(a) do
	for e in pairs(b[i]) do print(b[i][e][1],  b[i][e][2], b[i][e][3]) end
	print("c:", a[i][1], "a:", a[i][2], "m:", a[i][3]) --not really needed?
end--]]

print("Determine which recipe has the best ratio ...")
--calculates the best amount of elements used per module for each recipe, first better ordering tho
local neededRes = {}
for i in pairs(a) do
	neededRes[#neededRes+1] = {}
	local difRec = {}
	local total = {}
	for e in pairs(a[i]) do difRec[#difRec+1] = {} total[#total+1] = 0 end
	for e in pairs(b[i]) do
		local num = b[i][e][2]
		difRec[1][#difRec[1]+1] = {math.ceil(num), b[i][e][1], b[i][e][2], b[i][e][3]}
		total[b[i][e][3]] = total[b[i][e][3]] + num
	end

	neededRes[#neededRes][#neededRes[#neededRes]+1] = {}
	for i in pairs(difRec) do
		neededRes[#neededRes][#neededRes[#neededRes]][#neededRes[#neededRes][#neededRes[#neededRes]]+1] = {}
		for e in pairs(difRec[i]) do-- all constr - unique rec * ratio
			neededRes[#neededRes][#neededRes[#neededRes]][#neededRes[#neededRes][#neededRes[#neededRes]]]
			[#neededRes[#neededRes][#neededRes[#neededRes]][#neededRes[#neededRes][#neededRes[#neededRes]]]+1]
			= {(availRes[i] - #difRec[i])*(difRec[i][e][3]/total[i]), difRec[i][e][2], difRec[i][e][4]}
		end
	end
end
print("Almost done")
--[[
for i in pairs(neededRes) do
	for e in pairs(neededRes[i]) do print(" ")
		for f in pairs(neededRes[i][e]) do
			for g in pairs(neededRes[i][e][f]) do
				print(neededRes[i][e][f][g][1], neededRes[i][e][f][g][2], neededRes[i][e][f][g][3])
			end
		end
	end
end--]]

--determines the best recipe

local brsf = 0
local bri = {-1, -1}
for i in pairs(neededRes) do
	for e in pairs(neededRes[i]) do
		for f in pairs(neededRes[i][e]) do
			for g in pairs(neededRes[i][e][f]) do
				if neededRes[i][e][f][g][2].type.name == rRecipe then
					if neededRes[i][e][f][g][1] > brsf then
						brsf = neededRes[i][e][f][g][1]
						bri[1] = i
						bri[2] = e
					end
				end
			end
		end
	end
end
print("Done, the winner is:")
print(" ")
for f in pairs(neededRes[bri[1]][bri[2]]) do
	for g in pairs(neededRes[bri[1]][bri[2]][f]) do
		print(neededRes[bri[1]][bri[2]][f][g][1], neededRes[bri[1]][bri[2]][f][g][2].type.name, neededRes[bri[1]][bri[2]][f][g][3])
	end
end
print(" ")

local _, _, time = computer.magicTime()
_, _, _, _, mi, s, ms = time:match("(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)%.(%d+)Z")
local endtime = mi * 60 * 1000 + s * 1000 + ms
print("... Finished! It took:", endtime - starttime, "ms")
c.stopComputer(c)
