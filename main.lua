local c = computer.getInstance()
local rRecipe = "Smart Plating"
local availRes = {10, 5, 2}
c.startComputer(c)
print("Computer started at", computer.magicTime())

--Lines marked with ! are static, as in non adaptable to new modules


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

--sorts an array so that no elements in it is unique
function sort(t1)
	nt1 = {}
	for i, v in pairs(t1) do
		if tableHasValue(nt1, v) then
			local index = find(nt1, v)
			if index == nil then computer.panic("Sorting error!") end
		else 
			nt1[#nt1+1] = v
		end
	end
	return nt1
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




local constructors = getComponentsByClass( { "Build_ConstructorMk1_C"  }, false ) --!
local assemblers = getComponentsByClass( { "Build_AssemblerMk1_C"  }, false ) --!
local manufacturer = getComponentsByClass( { "Build_ManufacturerMk1_C"  }, false ) --!
if #constructors > 0 then cRecipes = constructors[1]:getRecipes() else cRecipes = {} end --!
if #assemblers > 0 then aRecipes = assemblers[1]:getRecipes() else aRecipes = {} end --!
if #manufacturer > 0 then mRecipes = manufacturer[1]:getRecipes() else mRecipes = {} end --!

local zw = {}
zw[1] = rRecipe
if zw[1] == nil then computer.panic("Target Recipe not recognized: ", zw[1]) end

rRecipes = {}
--first gets all possible recipes to the string, then searches ingredients for the last recipe and adds it to the loop
for _, res in pairs(zw) do
	local recipes = {}
	local flag = 0
	for _, r in pairs(cRecipes) do
		local prods = r:getProducts()
		local ing = r:getIngredients()
		local bool = false
		for _, i in pairs(ing) do
			if stringContains(i.type.name, "Ore") then --!
				bool = true
				break
			end
		end
		if not bool then
			for _, p in pairs(prods) do
				if p.type.name == res then
					bool = true
				end
			end
			if bool then
				if rRecipes[1] == nil then rRecipes[1] = {} end
				recipes[#recipes+1] = r
				rRecipes[1][#rRecipes[1]+1] = r
				flag = 1
			end
		end	
	end	
	if  flag ~= 1 then
		for _, r in pairs(aRecipes) do
			local prods = r:getProducts()
			local ing = r:getIngredients()
			local bool = false
			for _, i in pairs(ing) do
				if stringContains(i.type.name, "Ore") then
					bool = true
					break
				end
			end
			if not bool then
				for _, p in pairs(prods) do
					if p.type.name == res then
						bool = true
					end
				end
				if bool then
					if rRecipes[2] == nil then rRecipes[2] = {} end
					recipes[#recipes+1] = r
					rRecipes[2][#rRecipes[2]+1] = r
					flag = 2
				end
			end		
		end
	elseif flag ~= 2 then
		for _, r in pairs(mRecipes) do
			local prods = r:getProducts()
			local ing = r:getIngredients()
			local bool = false
			for _, i in pairs(ing) do
				if stringContains(i.type.name, "Ore") then
					bool = true
					break
				end
			end
			if not bool then
				for _, p in pairs(prods) do
					if p.type.name == res then
						bool = true
					end
				end
				if bool then
					if rRecipes[3] == nil then rRecipes[3] = {} end
					recipes[#recipes+1] = r
					rRecipes[3][#rRecipes[3]+1] = r
					flag = 3
				end
			end
		end
	end
	
	
	for _, r in pairs(recipes) do 
		next = r:getIngredients()
		for _, i in pairs(next) do
			local item = i.type.name
			if not stringContains(item, "Ore") then
				zw[#zw+1] = item --loop next item
			end
		end
	end
end

--here all possible recipes once (but not sorted aka in which order they go)
for r in pairs(rRecipes) do rRecipes[r] = sort(rRecipes[r]) end
--for r in pairs(rRecipes) do print(r) for t in pairs(rRecipes[r]) do print(rRecipes[r][t].name) end end

local aimRecipe = {}
if #rRecipes > 0 then
	for _, r in pairs(rRecipes[#rRecipes]) do
		if r.name == rRecipe then aimRecipe[#aimRecipe+1] = r end
	end
end

cPath = {}
cPath[1] = {}
for i, r in pairs(aimRecipe) do cPath[1][i] = {0, r} end

for c in pairs(cPath) do
	for d in pairs(cPath[c]) do
		for e = 2, #cPath[c][d], 1 do --first value is the previous path to this point
			zw = {}
			local ing = cPath[c][d][e]:getIngredients()
			local bool = false
			for _, i in pairs(ing) do
				local zw1 = {}
				for t in pairs(rRecipes) do --optimizable
					for s in pairs(rRecipes[t]) do
						if rRecipes[t][s]:getProducts()[1].type.name == i.type.name then
							zw1[#zw1+1] = rRecipes[t][s]
						end
					end
				end
				bool = #zw1 > 0
				zw[#zw+1] = {}
				for _, t in pairs(zw1) do zw[#zw][#zw[#zw]+1] = t end
			end
			local zw1 = {}
			local zw2 = {}
			for t in pairs(zw) do  --Permutations
				for u in pairs(zw[t]) do
					if #zw1 == 0 then zw2[#zw2+1] = {} zw2[#zw2][#zw2[#zw2]+1] = zw[t][u] end
					for s in pairs(zw1) do
						zw2[#zw2+1] = {}
						for q in pairs(zw1[s]) do
							zw2[#zw2][#zw2[#zw2]+1] = zw1[s][q]
						end
						zw2[#zw2][#zw2[#zw2]+1] = zw[t][u]
					end
				end
				zw1 = {}
				for s in pairs(zw2) do
					zw1[#zw1+1] = {}
					for q in pairs(zw2[s]) do
						zw1[#zw1][#zw1[#zw1]+1] = zw2[s][q]
					end
				end
				zw2 = {}
			end --end of permutations
			if bool then
				if #cPath ~= c+1 then cPath[c+1] = {} end
				for t in pairs(zw1) do
					cPath[c+1][#cPath[c+1]+1] = {}
					cPath[c+1][#cPath[c+1]][#cPath[c+1][#cPath[c+1]]+1] = d
					for s in pairs(zw1[t]) do
						cPath[c+1][#cPath[c+1]][#cPath[c+1][#cPath[c+1]]+1] = zw1[t][s]
					end
				end
			end
		end
	end
end
--[[ --all possible Recipes now linked in order
for c in pairs(cPath) do 
		for d in pairs(cPath[c]) do 
		print("c", c, "d", d, "d-ref:", cPath[c][d][1]) 
			for e = 2, #cPath[c][d], 1 do 
			print(cPath[c][d][e].name) end
end end --]]

zw = {}
rRecipes = {}
--deciphering the links
for i in pairs(cPath[#cPath]) do
	local zw1 = i
	local level = #cPath
	while zw1 ~= 0 and level > 0 do
		for e = 2, #cPath[level][zw1], 1 do
			zw[#zw+1] = cPath[level][zw1][e]
		end
		zw1 = cPath[level][zw1][1] --d-ref
		level = level - 1
	end
	if #zw > 0 then 
		rRecipes[#rRecipes+1] = {}
		for _, e in pairs(zw) do
			rRecipes[#rRecipes][#rRecipes[#rRecipes]+1] = e
		end
	end
	zw = {}
end

--for r in pairs(rRecipes) do for t in pairs(rRecipes[r]) do print(rRecipes[r][t].name) end end

--Recipe List finally done, now start of calc

local a = {}
local b = {}
for x in pairs(rRecipes) do
	a[#a+1] = {0, 0, 0} --!
	b[#b+1] = {}
	local res = rRecipes[x][#rRecipes[x]].name
	local map = {{res, 1.0}}
	local flag = 0
	for _, r in pairs(cRecipes) do --solely to add to result
		local prods = r:getProducts()
		for _, p in pairs(prods) do
			if p.type.name == res then
				a[#a][1] = a[#a][1] + 1
			end
		end
	end
	if flag ~= 1 then
		for _, r in pairs(aRecipes) do
			local prods = r:getProducts()
			for _, p in pairs(prods) do
				if p.type.name == res then
					a[#a][2] = a[#a][2] + 1
				end
			end
		end
	elseif flag ~= 2 then
		for _, r in pairs(mRecipes) do
			local prods = r:getProducts()
			for _, p in pairs(prods) do
				if p.type.name == res then
					a[#a][3] = a[#a][3] + 1
				end
			end
		end
	end
	for y = #rRecipes[x], 1, -1 do --_, item in pairs(rRecipes[x]) do 
		local item = rRecipes[x][y]
		local ing = item:getIngredients()
	for _, m in pairs(ing) do
		for _, n in pairs(rRecipes[x]) do
			if n:getProducts()[1].type.name == m.type.name then --.potential
				local flag = 0
				b[#b][#b[#b]+1] = {}
				for _, r in pairs(cRecipes) do
					if n == r then	--!
						local mul = 1.0
						for _, mn in pairs(map) do
							if item.name == mn[1] then
								mul = mn[2]
								break
							end
						end
						local num = ((m.amount*(60.0/item.duration))*mul) / (n:getProducts()[1].amount*(60.0/n.duration)) --verhältnis von davor
						a[#a][1] = a[#a][1] + math.ceil(num)
						b[#b][#b[#b]] = {m.type.name, num, "c"}
						map[#map+1] = {m.type.name, num}
						flag = 1
						break
					end
				end
				if  flag ~= 1 then
					for _, r in pairs(aRecipes) do
						if n == r then
							local mul = 1.0
							for _, mn in pairs(map) do
								if item.name == mn[1] then
									mul = mn[2]
									break
								end
							end
							local num = ((m.amount*(60.0/item.duration))*mul) / (n:getProducts()[1].amount*(60.0/n.duration))
							a[#a][2] = a[#a][2] + math.ceil(num)
							b[#b][#b[#b]] = {m.type.name, num, "a"}
							map[#map+1] = {m.type.name, num}
							flag = 2
							break
						end
					end
				elseif flag ~= 2 then
					for _, r in pairs(mRecipes) do
						if n == r then
							local mul = 1.0
							for _, mn in pairs(map) do
								if item.name == mn[1] then
									mul = mn[2]
									break
								end
							end
							local num = ((m.amount*(60.0/item.duration))*mul) / (n:getProducts()[1].amount*(60.0/n.duration))
							a[#a][3] = a[#a][3] + math.ceil(num)
							b[#b][#b[#b]] = {m.type.name, num, "m"}
							map[#map+1] = {m.type.name, num}
							flag = 3
							break
						end
					end
				end
				break
			end
		end
	end	
end end
--[[
for i in pairs(a) do
	for e in pairs(b[i]) do print(b[i][e][1],  b[i][e][2], b[i][e][3]) end
	print("c:", a[i][1], "a:", a[i][2], "m:", a[i][3]) --not really needed?
end--]]

--calculates the best amount of elements used per module for each recipe
local neededRes = {}
for i in pairs(a) do
	neededRes[#neededRes+1] = {}
	local difRec = {}
	local total = {}
	for e in pairs(a[i]) do difRec[#difRec+1] = {} total[#total+1] = 0 end
	for e in pairs(b[i]) do
		local num = b[i][e][2]
		if b[i][e][3] == "c" then
			difRec[1][#difRec[1]+1] = {math.ceil(num), b[i][e][1], b[i][e][2], b[i][e][3]}
			total[1] = total[1] + num
		elseif b[i][e][3] == "a" then
			difRec[2][#difRec[2]+1] = {math.ceil(num), b[i][e][1], b[i][e][2], b[i][e][3]}
			total[2] = total[2] + num
		elseif b[i][e][3] == "m" then
			difRec[3][#difRec[3]+1] = {math.ceil(num), b[i][e][1], b[i][e][2], b[i][e][3]}
			total[3] = total[3] + num
		end
	end

	neededRes[#neededRes][#neededRes[#neededRes]+1] = {}
	for i in pairs(difRec) do
		neededRes[#neededRes][#neededRes[#neededRes]][#neededRes[#neededRes][#neededRes[#neededRes]]+1] = {}
		for e in pairs(difRec[i]) do
			if difRec[i][e][4] == "c" then -- all constr - unique rec * ratio
				neededRes[#neededRes][#neededRes[#neededRes]][#neededRes[#neededRes][#neededRes[#neededRes]]]
				[#neededRes[#neededRes][#neededRes[#neededRes]][#neededRes[#neededRes][#neededRes[#neededRes]]]+1]
				= {(availRes[i] - #difRec[i])*(difRec[i][e][3]/total[i]), difRec[i][e][2], difRec[i][e][4]}
			elseif difRec[i][e][4] == "a" then
				neededRes[#neededRes][#neededRes[#neededRes]][#neededRes[#neededRes][#neededRes[#neededRes]]]
				[#neededRes[#neededRes][#neededRes[#neededRes]][#neededRes[#neededRes][#neededRes[#neededRes]]]+1]
				= {(availRes[i] - #difRec[i])*(difRec[i][e][3]/total[i]), difRec[i][e][2], difRec[i][e][4]}
			elseif difRec[i][e][4] == "m" then
				neededRes[#neededRes][#neededRes[#neededRes]][#neededRes[#neededRes][#neededRes[#neededRes]]]
				[#neededRes[#neededRes][#neededRes[#neededRes]][#neededRes[#neededRes][#neededRes[#neededRes]]]+1]
				= {(availRes[i] - #difRec[i])*(difRec[i][e][3]/total[i]), difRec[i][e][2], difRec[i][e][4]}
			end
		end
	end
end

--determines the best recipe
for i in pairs(neededRes) do
	for e in pairs(neededRes[i]) do
		print(" ")
		for f in pairs(neededRes[i][e]) do
			for g in pairs(neededRes[i][e][f]) do
				print(neededRes[i][e][f][g][1], neededRes[i][e][f][g][2], neededRes[i][e][f][g][3])
			end
		end
	end
end

print("Computer finished at", computer.magicTime())
c.stopComputer(c)
