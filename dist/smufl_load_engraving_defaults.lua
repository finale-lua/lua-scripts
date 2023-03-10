__imports = __imports or {}
__import_results = __import_results or {}
__aaa_original_require_for_deployment__ = __aaa_original_require_for_deployment__ or require
function require(item)
    if not __imports[item] then
        return __aaa_original_require_for_deployment__(item)
    end
    if __import_results[item] == nil then
        __import_results[item] = __imports[item]()
        if __import_results[item] == nil then
            __import_results[item] = true
        end
    end
    return __import_results[item]
end
__imports["lunajson.decoder"] = __imports["lunajson.decoder"] or function()
    local setmetatable, tonumber, tostring =
          setmetatable, tonumber, tostring
    local floor, inf =
          math.floor, math.huge
    local mininteger, tointeger =
          math.mininteger or nil, math.tointeger or nil
    local byte, char, find, gsub, match, sub =
          string.byte, string.char, string.find, string.gsub, string.match, string.sub
    local function _decode_error(pos, errmsg)
    	error("parse error at " .. pos .. ": " .. errmsg, 2)
    end
    local f_str_ctrl_pat
    if _VERSION == "Lua 5.1" then
    	
    	f_str_ctrl_pat = '[^\32-\255]'
    else
    	f_str_ctrl_pat = '[\0-\31]'
    end
    local _ENV = nil
    local function newdecoder()
    	local json, pos, nullv, arraylen, rec_depth
    	
    	
    	local dispatcher, f
    	
    	local function decode_error(errmsg)
    		return _decode_error(pos, errmsg)
    	end
    	
    	local function f_err()
    		decode_error('invalid value')
    	end
    	
    	
    	local function f_nul()
    		if sub(json, pos, pos+2) == 'ull' then
    			pos = pos+3
    			return nullv
    		end
    		decode_error('invalid value')
    	end
    	
    	local function f_fls()
    		if sub(json, pos, pos+3) == 'alse' then
    			pos = pos+4
    			return false
    		end
    		decode_error('invalid value')
    	end
    	
    	local function f_tru()
    		if sub(json, pos, pos+2) == 'rue' then
    			pos = pos+3
    			return true
    		end
    		decode_error('invalid value')
    	end
    	
    	
    	local radixmark = match(tostring(0.5), '[^0-9]')
    	local fixedtonumber = tonumber
    	if radixmark ~= '.' then
    		if find(radixmark, '%W') then
    			radixmark = '%' .. radixmark
    		end
    		fixedtonumber = function(s)
    			return tonumber(gsub(s, '.', radixmark))
    		end
    	end
    	local function number_error()
    		return decode_error('invalid number')
    	end
    	
    	local function f_zro(mns)
    		local num, c = match(json, '^(%.?[0-9]*)([-+.A-Za-z]?)', pos)
    		if num == '' then
    			if c == '' then
    				if mns then
    					return -0.0
    				end
    				return 0
    			end
    			if c == 'e' or c == 'E' then
    				num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    				if c == '' then
    					pos = pos + #num
    					if mns then
    						return -0.0
    					end
    					return 0.0
    				end
    			end
    			number_error()
    		end
    		if byte(num) ~= 0x2E or byte(num, -1) == 0x2E then
    			number_error()
    		end
    		if c ~= '' then
    			if c == 'e' or c == 'E' then
    				num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    			end
    			if c ~= '' then
    				number_error()
    			end
    		end
    		pos = pos + #num
    		c = fixedtonumber(num)
    		if mns then
    			c = -c
    		end
    		return c
    	end
    	
    	local function f_num(mns)
    		pos = pos-1
    		local num, c = match(json, '^([0-9]+%.?[0-9]*)([-+.A-Za-z]?)', pos)
    		if byte(num, -1) == 0x2E then
    			number_error()
    		end
    		if c ~= '' then
    			if c ~= 'e' and c ~= 'E' then
    				number_error()
    			end
    			num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    			if not num or c ~= '' then
    				number_error()
    			end
    		end
    		pos = pos + #num
    		c = fixedtonumber(num)
    		if mns then
    			c = -c
    			if c == mininteger and not find(num, '[^0-9]') then
    				c = mininteger
    			end
    		end
    		return c
    	end
    	
    	local function f_mns()
    		local c = byte(json, pos)
    		if c then
    			pos = pos+1
    			if c > 0x30 then
    				if c < 0x3A then
    					return f_num(true)
    				end
    			else
    				if c > 0x2F then
    					return f_zro(true)
    				end
    			end
    		end
    		decode_error('invalid number')
    	end
    	
    	local f_str_hextbl = {
    		0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7,
    		0x8, 0x9, inf, inf, inf, inf, inf, inf,
    		inf, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF,
    		__index = function()
    			return inf
    		end
    	}
    	setmetatable(f_str_hextbl, f_str_hextbl)
    	local f_str_escapetbl = {
    		['"']  = '"',
    		['\\'] = '\\',
    		['/']  = '/',
    		['b']  = '\b',
    		['f']  = '\f',
    		['n']  = '\n',
    		['r']  = '\r',
    		['t']  = '\t',
    		__index = function()
    			decode_error("invalid escape sequence")
    		end
    	}
    	setmetatable(f_str_escapetbl, f_str_escapetbl)
    	local function surrogate_first_error()
    		return decode_error("1st surrogate pair byte not continued by 2nd")
    	end
    	local f_str_surrogate_prev = 0
    	local function f_str_subst(ch, ucode)
    		if ch == 'u' then
    			local c1, c2, c3, c4, rest = byte(ucode, 1, 5)
    			ucode = f_str_hextbl[c1-47] * 0x1000 +
    			        f_str_hextbl[c2-47] * 0x100 +
    			        f_str_hextbl[c3-47] * 0x10 +
    			        f_str_hextbl[c4-47]
    			if ucode ~= inf then
    				if ucode < 0x80 then
    					if rest then
    						return char(ucode, rest)
    					end
    					return char(ucode)
    				elseif ucode < 0x800 then
    					c1 = floor(ucode / 0x40)
    					c2 = ucode - c1 * 0x40
    					c1 = c1 + 0xC0
    					c2 = c2 + 0x80
    					if rest then
    						return char(c1, c2, rest)
    					end
    					return char(c1, c2)
    				elseif ucode < 0xD800 or 0xE000 <= ucode then
    					c1 = floor(ucode / 0x1000)
    					ucode = ucode - c1 * 0x1000
    					c2 = floor(ucode / 0x40)
    					c3 = ucode - c2 * 0x40
    					c1 = c1 + 0xE0
    					c2 = c2 + 0x80
    					c3 = c3 + 0x80
    					if rest then
    						return char(c1, c2, c3, rest)
    					end
    					return char(c1, c2, c3)
    				elseif 0xD800 <= ucode and ucode < 0xDC00 then
    					if f_str_surrogate_prev == 0 then
    						f_str_surrogate_prev = ucode
    						if not rest then
    							return ''
    						end
    						surrogate_first_error()
    					end
    					f_str_surrogate_prev = 0
    					surrogate_first_error()
    				else
    					if f_str_surrogate_prev ~= 0 then
    						ucode = 0x10000 +
    						        (f_str_surrogate_prev - 0xD800) * 0x400 +
    						        (ucode - 0xDC00)
    						f_str_surrogate_prev = 0
    						c1 = floor(ucode / 0x40000)
    						ucode = ucode - c1 * 0x40000
    						c2 = floor(ucode / 0x1000)
    						ucode = ucode - c2 * 0x1000
    						c3 = floor(ucode / 0x40)
    						c4 = ucode - c3 * 0x40
    						c1 = c1 + 0xF0
    						c2 = c2 + 0x80
    						c3 = c3 + 0x80
    						c4 = c4 + 0x80
    						if rest then
    							return char(c1, c2, c3, c4, rest)
    						end
    						return char(c1, c2, c3, c4)
    					end
    					decode_error("2nd surrogate pair byte appeared without 1st")
    				end
    			end
    			decode_error("invalid unicode codepoint literal")
    		end
    		if f_str_surrogate_prev ~= 0 then
    			f_str_surrogate_prev = 0
    			surrogate_first_error()
    		end
    		return f_str_escapetbl[ch] .. ucode
    	end
    	
    	local f_str_keycache = setmetatable({}, {__mode="v"})
    	local function f_str(iskey)
    		local newpos = pos
    		local tmppos, c1, c2
    		repeat
    			newpos = find(json, '"', newpos, true)
    			if not newpos then
    				decode_error("unterminated string")
    			end
    			tmppos = newpos-1
    			newpos = newpos+1
    			c1, c2 = byte(json, tmppos-1, tmppos)
    			if c2 == 0x5C and c1 == 0x5C then
    				repeat
    					tmppos = tmppos-2
    					c1, c2 = byte(json, tmppos-1, tmppos)
    				until c2 ~= 0x5C or c1 ~= 0x5C
    				tmppos = newpos-2
    			end
    		until c2 ~= 0x5C
    		local str = sub(json, pos, tmppos)
    		pos = newpos
    		if iskey then
    			tmppos = f_str_keycache[str]
    			if tmppos then
    				return tmppos
    			end
    			tmppos = str
    		end
    		if find(str, f_str_ctrl_pat) then
    			decode_error("unescaped control string")
    		end
    		if find(str, '\\', 1, true) then
    			
    			
    			
    			
    			
    			str = gsub(str, '\\(.)([^\\]?[^\\]?[^\\]?[^\\]?[^\\]?)', f_str_subst)
    			if f_str_surrogate_prev ~= 0 then
    				f_str_surrogate_prev = 0
    				decode_error("1st surrogate pair byte not continued by 2nd")
    			end
    		end
    		if iskey then
    			f_str_keycache[tmppos] = str
    		end
    		return str
    	end
    	
    	
    	local function f_ary()
    		rec_depth = rec_depth + 1
    		if rec_depth > 1000 then
    			decode_error('too deeply nested json (> 1000)')
    		end
    		local ary = {}
    		pos = match(json, '^[ \n\r\t]*()', pos)
    		local i = 0
    		if byte(json, pos) == 0x5D then
    			pos = pos+1
    		else
    			local newpos = pos
    			repeat
    				i = i+1
    				f = dispatcher[byte(json,newpos)]
    				pos = newpos+1
    				ary[i] = f()
    				newpos = match(json, '^[ \n\r\t]*,[ \n\r\t]*()', pos)
    			until not newpos
    			newpos = match(json, '^[ \n\r\t]*%]()', pos)
    			if not newpos then
    				decode_error("no closing bracket of an array")
    			end
    			pos = newpos
    		end
    		if arraylen then
    			ary[0] = i
    		end
    		rec_depth = rec_depth - 1
    		return ary
    	end
    	
    	local function f_obj()
    		rec_depth = rec_depth + 1
    		if rec_depth > 1000 then
    			decode_error('too deeply nested json (> 1000)')
    		end
    		local obj = {}
    		pos = match(json, '^[ \n\r\t]*()', pos)
    		if byte(json, pos) == 0x7D then
    			pos = pos+1
    		else
    			local newpos = pos
    			repeat
    				if byte(json, newpos) ~= 0x22 then
    					decode_error("not key")
    				end
    				pos = newpos+1
    				local key = f_str(true)
    				
    				
    				
    				f = f_err
    				local c1, c2, c3 = byte(json, pos, pos+3)
    				if c1 == 0x3A then
    					if c2 ~= 0x20 then
    						f = dispatcher[c2]
    						newpos = pos+2
    					else
    						f = dispatcher[c3]
    						newpos = pos+3
    					end
    				end
    				if f == f_err then
    					newpos = match(json, '^[ \n\r\t]*:[ \n\r\t]*()', pos)
    					if not newpos then
    						decode_error("no colon after a key")
    					end
    					f = dispatcher[byte(json, newpos)]
    					newpos = newpos+1
    				end
    				pos = newpos
    				obj[key] = f()
    				newpos = match(json, '^[ \n\r\t]*,[ \n\r\t]*()', pos)
    			until not newpos
    			newpos = match(json, '^[ \n\r\t]*}()', pos)
    			if not newpos then
    				decode_error("no closing bracket of an object")
    			end
    			pos = newpos
    		end
    		rec_depth = rec_depth - 1
    		return obj
    	end
    	
    	dispatcher = { [0] =
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_str, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_mns, f_err, f_err,
    		f_zro, f_num, f_num, f_num, f_num, f_num, f_num, f_num,
    		f_num, f_num, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_ary, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_fls, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_nul, f_err,
    		f_err, f_err, f_err, f_err, f_tru, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_obj, f_err, f_err, f_err, f_err,
    		__index = function()
    			decode_error("unexpected termination")
    		end
    	}
    	setmetatable(dispatcher, dispatcher)
    	
    	local function decode(json_, pos_, nullv_, arraylen_)
    		json, pos, nullv, arraylen = json_, pos_, nullv_, arraylen_
    		rec_depth = 0
    		pos = match(json, '^[ \n\r\t]*()', pos)
    		f = dispatcher[byte(json, pos)]
    		pos = pos+1
    		local v = f()
    		if pos_ then
    			return v, pos
    		else
    			f, pos = find(json, '^[ \n\r\t]*', pos)
    			if pos ~= #json then
    				decode_error('json ended')
    			end
    			return v
    		end
    	end
    	return decode
    end
    return newdecoder
end
__imports["lunajson.encoder"] = __imports["lunajson.encoder"] or function()
    local error = error
    local byte, find, format, gsub, match = string.byte, string.find, string.format,  string.gsub, string.match
    local concat = table.concat
    local tostring = tostring
    local pairs, type = pairs, type
    local setmetatable = setmetatable
    local huge, tiny = 1/0, -1/0
    local f_string_esc_pat
    if _VERSION == "Lua 5.1" then
    	
    	f_string_esc_pat = '[^ -!#-[%]^-\255]'
    else
    	f_string_esc_pat = '[\0-\31"\\]'
    end
    local _ENV = nil
    local function newencoder()
    	local v, nullv
    	local i, builder, visited
    	local function f_tostring(v)
    		builder[i] = tostring(v)
    		i = i+1
    	end
    	local radixmark = match(tostring(0.5), '[^0-9]')
    	local delimmark = match(tostring(12345.12345), '[^0-9' .. radixmark .. ']')
    	if radixmark == '.' then
    		radixmark = nil
    	end
    	local radixordelim
    	if radixmark or delimmark then
    		radixordelim = true
    		if radixmark and find(radixmark, '%W') then
    			radixmark = '%' .. radixmark
    		end
    		if delimmark and find(delimmark, '%W') then
    			delimmark = '%' .. delimmark
    		end
    	end
    	local f_number = function(n)
    		if tiny < n and n < huge then
    			local s = format("%.17g", n)
    			if radixordelim then
    				if delimmark then
    					s = gsub(s, delimmark, '')
    				end
    				if radixmark then
    					s = gsub(s, radixmark, '.')
    				end
    			end
    			builder[i] = s
    			i = i+1
    			return
    		end
    		error('invalid number')
    	end
    	local doencode
    	local f_string_subst = {
    		['"'] = '\\"',
    		['\\'] = '\\\\',
    		['\b'] = '\\b',
    		['\f'] = '\\f',
    		['\n'] = '\\n',
    		['\r'] = '\\r',
    		['\t'] = '\\t',
    		__index = function(_, c)
    			return format('\\u00%02X', byte(c))
    		end
    	}
    	setmetatable(f_string_subst, f_string_subst)
    	local function f_string(s)
    		builder[i] = '"'
    		if find(s, f_string_esc_pat) then
    			s = gsub(s, f_string_esc_pat, f_string_subst)
    		end
    		builder[i+1] = s
    		builder[i+2] = '"'
    		i = i+3
    	end
    	local function f_table(o)
    		if visited[o] then
    			error("loop detected")
    		end
    		visited[o] = true
    		local tmp = o[0]
    		if type(tmp) == 'number' then
    			builder[i] = '['
    			i = i+1
    			for j = 1, tmp do
    				doencode(o[j])
    				builder[i] = ','
    				i = i+1
    			end
    			if tmp > 0 then
    				i = i-1
    			end
    			builder[i] = ']'
    		else
    			tmp = o[1]
    			if tmp ~= nil then
    				builder[i] = '['
    				i = i+1
    				local j = 2
    				repeat
    					doencode(tmp)
    					tmp = o[j]
    					if tmp == nil then
    						break
    					end
    					j = j+1
    					builder[i] = ','
    					i = i+1
    				until false
    				builder[i] = ']'
    			else
    				builder[i] = '{'
    				i = i+1
    				local tmp = i
    				for k, v in pairs(o) do
    					if type(k) ~= 'string' then
    						error("non-string key")
    					end
    					f_string(k)
    					builder[i] = ':'
    					i = i+1
    					doencode(v)
    					builder[i] = ','
    					i = i+1
    				end
    				if i > tmp then
    					i = i-1
    				end
    				builder[i] = '}'
    			end
    		end
    		i = i+1
    		visited[o] = nil
    	end
    	local dispatcher = {
    		boolean = f_tostring,
    		number = f_number,
    		string = f_string,
    		table = f_table,
    		__index = function()
    			error("invalid type value")
    		end
    	}
    	setmetatable(dispatcher, dispatcher)
    	function doencode(v)
    		if v == nullv then
    			builder[i] = 'null'
    			i = i+1
    			return
    		end
    		return dispatcher[type(v)](v)
    	end
    	local function encode(v_, nullv_)
    		v, nullv = v_, nullv_
    		i, builder, visited = 1, {}, {}
    		doencode(v)
    		return concat(builder)
    	end
    	return encode
    end
    return newencoder
end
__imports["lunajson.sax"] = __imports["lunajson.sax"] or function()
    local setmetatable, tonumber, tostring =
          setmetatable, tonumber, tostring
    local floor, inf =
          math.floor, math.huge
    local mininteger, tointeger =
          math.mininteger or nil, math.tointeger or nil
    local byte, char, find, gsub, match, sub =
          string.byte, string.char, string.find, string.gsub, string.match, string.sub
    local function _parse_error(pos, errmsg)
    	error("parse error at " .. pos .. ": " .. errmsg, 2)
    end
    local f_str_ctrl_pat
    if _VERSION == "Lua 5.1" then
    	
    	f_str_ctrl_pat = '[^\32-\255]'
    else
    	f_str_ctrl_pat = '[\0-\31]'
    end
    local type, unpack = type, table.unpack or unpack
    local open = io.open
    local _ENV = nil
    local function nop() end
    local function newparser(src, saxtbl)
    	local json, jsonnxt, rec_depth
    	local jsonlen, pos, acc = 0, 1, 0
    	
    	
    	local dispatcher, f
    	
    	if type(src) == 'string' then
    		json = src
    		jsonlen = #json
    		jsonnxt = function()
    			json = ''
    			jsonlen = 0
    			jsonnxt = nop
    		end
    	else
    		jsonnxt = function()
    			acc = acc + jsonlen
    			pos = 1
    			repeat
    				json = src()
    				if not json then
    					json = ''
    					jsonlen = 0
    					jsonnxt = nop
    					return
    				end
    				jsonlen = #json
    			until jsonlen > 0
    		end
    		jsonnxt()
    	end
    	local sax_startobject = saxtbl.startobject or nop
    	local sax_key = saxtbl.key or nop
    	local sax_endobject = saxtbl.endobject or nop
    	local sax_startarray = saxtbl.startarray or nop
    	local sax_endarray = saxtbl.endarray or nop
    	local sax_string = saxtbl.string or nop
    	local sax_number = saxtbl.number or nop
    	local sax_boolean = saxtbl.boolean or nop
    	local sax_null = saxtbl.null or nop
    	
    	local function tryc()
    		local c = byte(json, pos)
    		if not c then
    			jsonnxt()
    			c = byte(json, pos)
    		end
    		return c
    	end
    	local function parse_error(errmsg)
    		return _parse_error(acc + pos, errmsg)
    	end
    	local function tellc()
    		return tryc() or parse_error("unexpected termination")
    	end
    	local function spaces()
    		while true do
    			pos = match(json, '^[ \n\r\t]*()', pos)
    			if pos <= jsonlen then
    				return
    			end
    			if jsonlen == 0 then
    				parse_error("unexpected termination")
    			end
    			jsonnxt()
    		end
    	end
    	
    	local function f_err()
    		parse_error('invalid value')
    	end
    	
    	
    	local function generic_constant(target, targetlen, ret, sax_f)
    		for i = 1, targetlen do
    			local c = tellc()
    			if byte(target, i) ~= c then
    				parse_error("invalid char")
    			end
    			pos = pos+1
    		end
    		return sax_f(ret)
    	end
    	
    	local function f_nul()
    		if sub(json, pos, pos+2) == 'ull' then
    			pos = pos+3
    			return sax_null(nil)
    		end
    		return generic_constant('ull', 3, nil, sax_null)
    	end
    	
    	local function f_fls()
    		if sub(json, pos, pos+3) == 'alse' then
    			pos = pos+4
    			return sax_boolean(false)
    		end
    		return generic_constant('alse', 4, false, sax_boolean)
    	end
    	
    	local function f_tru()
    		if sub(json, pos, pos+2) == 'rue' then
    			pos = pos+3
    			return sax_boolean(true)
    		end
    		return generic_constant('rue', 3, true, sax_boolean)
    	end
    	
    	
    	local radixmark = match(tostring(0.5), '[^0-9]')
    	local fixedtonumber = tonumber
    	if radixmark ~= '.' then
    		if find(radixmark, '%W') then
    			radixmark = '%' .. radixmark
    		end
    		fixedtonumber = function(s)
    			return tonumber(gsub(s, '.', radixmark))
    		end
    	end
    	local function number_error()
    		return parse_error('invalid number')
    	end
    	
    	local function generic_number(mns)
    		local buf = {}
    		local i = 1
    		local is_int = true
    		local c = byte(json, pos)
    		pos = pos+1
    		local function nxt()
    			buf[i] = c
    			i = i+1
    			c = tryc()
    			pos = pos+1
    		end
    		if c == 0x30 then
    			nxt()
    			if c and 0x30 <= c and c < 0x3A then
    				number_error()
    			end
    		else
    			repeat nxt() until not (c and 0x30 <= c and c < 0x3A)
    		end
    		if c == 0x2E then
    			is_int = false
    			nxt()
    			if not (c and 0x30 <= c and c < 0x3A) then
    				number_error()
    			end
    			repeat nxt() until not (c and 0x30 <= c and c < 0x3A)
    		end
    		if c == 0x45 or c == 0x65 then
    			is_int = false
    			nxt()
    			if c == 0x2B or c == 0x2D then
    				nxt()
    			end
    			if not (c and 0x30 <= c and c < 0x3A) then
    				number_error()
    			end
    			repeat nxt() until not (c and 0x30 <= c and c < 0x3A)
    		end
    		if c and (0x41 <= c and c <= 0x5B or
    		          0x61 <= c and c <= 0x7B or
    		          c == 0x2B or c == 0x2D or c == 0x2E) then
    			number_error()
    		end
    		pos = pos-1
    		local num = char(unpack(buf))
    		num = fixedtonumber(num)
    		if mns then
    			num = -num
    			if num == mininteger and is_int then
    				num = mininteger
    			end
    		end
    		return sax_number(num)
    	end
    	
    	local function f_zro(mns)
    		local num, c = match(json, '^(%.?[0-9]*)([-+.A-Za-z]?)', pos)
    		if num == '' then
    			if pos > jsonlen then
    				pos = pos - 1
    				return generic_number(mns)
    			end
    			if c == '' then
    				if mns then
    					return sax_number(-0.0)
    				end
    				return sax_number(0)
    			end
    			if c == 'e' or c == 'E' then
    				num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    				if c == '' then
    					pos = pos + #num
    					if pos > jsonlen then
    						pos = pos - #num - 1
    						return generic_number(mns)
    					end
    					if mns then
    						return sax_number(-0.0)
    					end
    					return sax_number(0.0)
    				end
    			end
    			pos = pos-1
    			return generic_number(mns)
    		end
    		if byte(num) ~= 0x2E or byte(num, -1) == 0x2E then
    			pos = pos-1
    			return generic_number(mns)
    		end
    		if c ~= '' then
    			if c == 'e' or c == 'E' then
    				num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    			end
    			if c ~= '' then
    				pos = pos-1
    				return generic_number(mns)
    			end
    		end
    		pos = pos + #num
    		if pos > jsonlen then
    			pos = pos - #num - 1
    			return generic_number(mns)
    		end
    		c = fixedtonumber(num)
    		if mns then
    			c = -c
    		end
    		return sax_number(c)
    	end
    	
    	local function f_num(mns)
    		pos = pos-1
    		local num, c = match(json, '^([0-9]+%.?[0-9]*)([-+.A-Za-z]?)', pos)
    		if byte(num, -1) == 0x2E then
    			return generic_number(mns)
    		end
    		if c ~= '' then
    			if c ~= 'e' and c ~= 'E' then
    				return generic_number(mns)
    			end
    			num, c = match(json, '^([^eE]*[eE][-+]?[0-9]+)([-+.A-Za-z]?)', pos)
    			if not num or c ~= '' then
    				return generic_number(mns)
    			end
    		end
    		pos = pos + #num
    		if pos > jsonlen then
    			pos = pos - #num
    			return generic_number(mns)
    		end
    		c = fixedtonumber(num)
    		if mns then
    			c = -c
    			if c == mininteger and not find(num, '[^0-9]') then
    				c = mininteger
    			end
    		end
    		return sax_number(c)
    	end
    	
    	local function f_mns()
    		local c = byte(json, pos) or tellc()
    		if c then
    			pos = pos+1
    			if c > 0x30 then
    				if c < 0x3A then
    					return f_num(true)
    				end
    			else
    				if c > 0x2F then
    					return f_zro(true)
    				end
    			end
    		end
    		parse_error("invalid number")
    	end
    	
    	local f_str_hextbl = {
    		0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7,
    		0x8, 0x9, inf, inf, inf, inf, inf, inf,
    		inf, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, inf, inf, inf, inf, inf, inf, inf,
    		inf, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF,
    		__index = function()
    			return inf
    		end
    	}
    	setmetatable(f_str_hextbl, f_str_hextbl)
    	local f_str_escapetbl = {
    		['"']  = '"',
    		['\\'] = '\\',
    		['/']  = '/',
    		['b']  = '\b',
    		['f']  = '\f',
    		['n']  = '\n',
    		['r']  = '\r',
    		['t']  = '\t',
    		__index = function()
    			parse_error("invalid escape sequence")
    		end
    	}
    	setmetatable(f_str_escapetbl, f_str_escapetbl)
    	local function surrogate_first_error()
    		return parse_error("1st surrogate pair byte not continued by 2nd")
    	end
    	local f_str_surrogate_prev = 0
    	local function f_str_subst(ch, ucode)
    		if ch == 'u' then
    			local c1, c2, c3, c4, rest = byte(ucode, 1, 5)
    			ucode = f_str_hextbl[c1-47] * 0x1000 +
    			        f_str_hextbl[c2-47] * 0x100 +
    			        f_str_hextbl[c3-47] * 0x10 +
    			        f_str_hextbl[c4-47]
    			if ucode ~= inf then
    				if ucode < 0x80 then
    					if rest then
    						return char(ucode, rest)
    					end
    					return char(ucode)
    				elseif ucode < 0x800 then
    					c1 = floor(ucode / 0x40)
    					c2 = ucode - c1 * 0x40
    					c1 = c1 + 0xC0
    					c2 = c2 + 0x80
    					if rest then
    						return char(c1, c2, rest)
    					end
    					return char(c1, c2)
    				elseif ucode < 0xD800 or 0xE000 <= ucode then
    					c1 = floor(ucode / 0x1000)
    					ucode = ucode - c1 * 0x1000
    					c2 = floor(ucode / 0x40)
    					c3 = ucode - c2 * 0x40
    					c1 = c1 + 0xE0
    					c2 = c2 + 0x80
    					c3 = c3 + 0x80
    					if rest then
    						return char(c1, c2, c3, rest)
    					end
    					return char(c1, c2, c3)
    				elseif 0xD800 <= ucode and ucode < 0xDC00 then
    					if f_str_surrogate_prev == 0 then
    						f_str_surrogate_prev = ucode
    						if not rest then
    							return ''
    						end
    						surrogate_first_error()
    					end
    					f_str_surrogate_prev = 0
    					surrogate_first_error()
    				else
    					if f_str_surrogate_prev ~= 0 then
    						ucode = 0x10000 +
    						        (f_str_surrogate_prev - 0xD800) * 0x400 +
    						        (ucode - 0xDC00)
    						f_str_surrogate_prev = 0
    						c1 = floor(ucode / 0x40000)
    						ucode = ucode - c1 * 0x40000
    						c2 = floor(ucode / 0x1000)
    						ucode = ucode - c2 * 0x1000
    						c3 = floor(ucode / 0x40)
    						c4 = ucode - c3 * 0x40
    						c1 = c1 + 0xF0
    						c2 = c2 + 0x80
    						c3 = c3 + 0x80
    						c4 = c4 + 0x80
    						if rest then
    							return char(c1, c2, c3, c4, rest)
    						end
    						return char(c1, c2, c3, c4)
    					end
    					parse_error("2nd surrogate pair byte appeared without 1st")
    				end
    			end
    			parse_error("invalid unicode codepoint literal")
    		end
    		if f_str_surrogate_prev ~= 0 then
    			f_str_surrogate_prev = 0
    			surrogate_first_error()
    		end
    		return f_str_escapetbl[ch] .. ucode
    	end
    	local function f_str(iskey)
    		local pos2 = pos
    		local newpos
    		local str = ''
    		local bs
    		while true do
    			while true do
    				newpos = find(json, '[\\"]', pos2)
    				if newpos then
    					break
    				end
    				str = str .. sub(json, pos, jsonlen)
    				if pos2 == jsonlen+2 then
    					pos2 = 2
    				else
    					pos2 = 1
    				end
    				jsonnxt()
    				if jsonlen == 0 then
    					parse_error("unterminated string")
    				end
    			end
    			if byte(json, newpos) == 0x22 then
    				break
    			end
    			pos2 = newpos+2
    			bs = true
    		end
    		str = str .. sub(json, pos, newpos-1)
    		pos = newpos+1
    		if find(str, f_str_ctrl_pat) then
    			parse_error("unescaped control string")
    		end
    		if bs then
    			
    			
    			
    			
    			
    			str = gsub(str, '\\(.)([^\\]?[^\\]?[^\\]?[^\\]?[^\\]?)', f_str_subst)
    			if f_str_surrogate_prev ~= 0 then
    				f_str_surrogate_prev = 0
    				parse_error("1st surrogate pair byte not continued by 2nd")
    			end
    		end
    		if iskey then
    			return sax_key(str)
    		end
    		return sax_string(str)
    	end
    	
    	
    	local function f_ary()
    		rec_depth = rec_depth + 1
    		if rec_depth > 1000 then
    			parse_error('too deeply nested json (> 1000)')
    		end
    		sax_startarray()
    		spaces()
    		if byte(json, pos) == 0x5D then
    			pos = pos+1
    		else
    			local newpos
    			while true do
    				f = dispatcher[byte(json, pos)]
    				pos = pos+1
    				f()
    				newpos = match(json, '^[ \n\r\t]*,[ \n\r\t]*()', pos)
    				if newpos then
    					pos = newpos
    				else
    					newpos = match(json, '^[ \n\r\t]*%]()', pos)
    					if newpos then
    						pos = newpos
    						break
    					end
    					spaces()
    					local c = byte(json, pos)
    					pos = pos+1
    					if c == 0x2C then
    						spaces()
    					elseif c == 0x5D then
    						break
    					else
    						parse_error("no closing bracket of an array")
    					end
    				end
    				if pos > jsonlen then
    					spaces()
    				end
    			end
    		end
    		rec_depth = rec_depth - 1
    		return sax_endarray()
    	end
    	
    	local function f_obj()
    		rec_depth = rec_depth + 1
    		if rec_depth > 1000 then
    			parse_error('too deeply nested json (> 1000)')
    		end
    		sax_startobject()
    		spaces()
    		if byte(json, pos) == 0x7D then
    			pos = pos+1
    		else
    			local newpos
    			while true do
    				if byte(json, pos) ~= 0x22 then
    					parse_error("not key")
    				end
    				pos = pos+1
    				f_str(true)
    				newpos = match(json, '^[ \n\r\t]*:[ \n\r\t]*()', pos)
    				if newpos then
    					pos = newpos
    				else
    					spaces()
    					if byte(json, pos) ~= 0x3A then
    						parse_error("no colon after a key")
    					end
    					pos = pos+1
    					spaces()
    				end
    				if pos > jsonlen then
    					spaces()
    				end
    				f = dispatcher[byte(json, pos)]
    				pos = pos+1
    				f()
    				newpos = match(json, '^[ \n\r\t]*,[ \n\r\t]*()', pos)
    				if newpos then
    					pos = newpos
    				else
    					newpos = match(json, '^[ \n\r\t]*}()', pos)
    					if newpos then
    						pos = newpos
    						break
    					end
    					spaces()
    					local c = byte(json, pos)
    					pos = pos+1
    					if c == 0x2C then
    						spaces()
    					elseif c == 0x7D then
    						break
    					else
    						parse_error("no closing bracket of an object")
    					end
    				end
    				if pos > jsonlen then
    					spaces()
    				end
    			end
    		end
    		rec_depth = rec_depth - 1
    		return sax_endobject()
    	end
    	
    	dispatcher = { [0] =
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_str, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_mns, f_err, f_err,
    		f_zro, f_num, f_num, f_num, f_num, f_num, f_num, f_num,
    		f_num, f_num, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_ary, f_err, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_fls, f_err,
    		f_err, f_err, f_err, f_err, f_err, f_err, f_nul, f_err,
    		f_err, f_err, f_err, f_err, f_tru, f_err, f_err, f_err,
    		f_err, f_err, f_err, f_obj, f_err, f_err, f_err, f_err,
    	}
    	
    	local function run()
    		rec_depth = 0
    		spaces()
    		f = dispatcher[byte(json, pos)]
    		pos = pos+1
    		f()
    	end
    	local function read(n)
    		if n < 0 then
    			error("the argument must be non-negative")
    		end
    		local pos2 = (pos-1) + n
    		local str = sub(json, pos, pos2)
    		while pos2 > jsonlen and jsonlen ~= 0 do
    			jsonnxt()
    			pos2 = pos2 - (jsonlen - (pos-1))
    			str = str .. sub(json, pos, pos2)
    		end
    		if jsonlen ~= 0 then
    			pos = pos2+1
    		end
    		return str
    	end
    	local function tellpos()
    		return acc + pos
    	end
    	return {
    		run = run,
    		tryc = tryc,
    		read = read,
    		tellpos = tellpos,
    	}
    end
    local function newfileparser(fn, saxtbl)
    	local fp = open(fn)
    	local function gen()
    		local s
    		if fp then
    			s = fp:read(8192)
    			if not s then
    				fp:close()
    				fp = nil
    			end
    		end
    		return s
    	end
    	return newparser(gen, saxtbl)
    end
    return {
    	newparser = newparser,
    	newfileparser = newfileparser
    }
end
__imports["lunajson.lunajson"] = __imports["lunajson.lunajson"] or function()
    local newdecoder = require('lunajson.decoder')
    local newencoder = require('lunajson.encoder')
    local sax = require('lunajson.sax')


    return {
    	decode = newdecoder(),
    	encode = newencoder(),
    	newparser = sax.newparser,
    	newfileparser = sax.newfileparser,
    }
end
__imports["library.client"] = __imports["library.client"] or function()

    local client = {}
    local function to_human_string(feature)
        return string.gsub(feature, "_", " ")
    end
    local function requires_later_plugin_version(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. "which is only available in a later version of RGP Lua. Please update RGP Lua instead to use this script."
        end
        return "This script requires a later version of RGP Lua. Please update RGP Lua instead to use this script."
    end
    local function requires_rgp_lua(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which is not available on JW Lua. Please use RGP Lua instead to use this script."
        end
        return "This script requires RGP Lua, the successor of JW Lua. Please use RGP Lua instead to use this script."
    end
    local function requires_plugin_version(version, feature)
        if tonumber(version) <= 0.54 then
            if feature then
                return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua or JW Lua version " .. version ..
                           " or later. Please update your plugin to use this script."
            end
            return "This script requires RGP Lua or JW Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        return "This script requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    local function requires_finale_version(version, feature)
        return "This script uses " .. to_human_string(feature) .. ", which is only available on Finale " .. version .. " or later"
    end

    function client.get_raw_finale_version(major, minor, build)
        local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
        if build then
            retval = bit32.bor(retval, math.floor(build))
        end
        return retval
    end

    function client.get_lua_plugin_version()
        local num_string = tostring(finenv.MajorVersion) .. "." .. tostring(finenv.MinorVersion)
        return tonumber(num_string)
    end
    local features = {
        clef_change = {
            test = client.get_lua_plugin_version() >= 0.60,
            error = requires_plugin_version("0.58", "a clef change"),
        },
        ["FCKeySignature::CalcTotalChromaticSteps"] = {
            test = finenv.IsRGPLua and finale.FCKeySignature.__class.CalcTotalChromaticSteps,
            error = requires_later_plugin_version("a custom key signature"),
        },
        ["FCCategory::SaveWithNewType"] = {
            test = client.get_lua_plugin_version() >= 0.58,
            error = requires_plugin_version("0.58"),
        },
        ["finenv.QueryInvokedModifierKeys"] = {
            test = finenv.IsRGPLua and finenv.QueryInvokedModifierKeys,
            error = requires_later_plugin_version(),
        },
        ["FCCustomLuaWindow::ShowModeless"] = {
            test = finenv.IsRGPLua,
            error = requires_rgp_lua("a modeless dialog")
        },
        ["finenv.RetainLuaState"] = {
            test = finenv.IsRGPLua and finenv.RetainLuaState ~= nil,
            error = requires_later_plugin_version(),
        },
        smufl = {
            test = finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1),
            error = requires_finale_version("27.1", "a SMUFL font"),
        },
    }

    function client.supports(feature)
        if features[feature].test == nil then
            error("a test does not exist for feature " .. feature, 2)
        end
        return features[feature].test
    end

    function client.assert_supports(feature)
        local error_level = finenv.DebugEnabled and 2 or 0
        if not client.supports(feature) then
            if features[feature].error then
                error(features[feature].error, error_level)
            end

            error("Your Finale version does not support " .. to_human_string(feature), error_level)
        end
        return true
    end
    return client
end
__imports["library.general_library"] = __imports["library.general_library"] or function()

    local library = {}
    local client = require("library.client")

    function library.group_overlaps_region(staff_group, region)
        if region:IsFullDocumentSpan() then
            return true
        end
        local staff_exists = false
        local sys_staves = finale.FCSystemStaves()
        sys_staves:LoadAllForRegion(region)
        for sys_staff in each(sys_staves) do
            if staff_group:ContainsStaff(sys_staff:GetStaff()) then
                staff_exists = true
                break
            end
        end
        if not staff_exists then
            return false
        end
        if (staff_group.StartMeasure > region.EndMeasure) or (staff_group.EndMeasure < region.StartMeasure) then
            return false
        end
        return true
    end

    function library.group_is_contained_in_region(staff_group, region)
        if not region:IsStaffIncluded(staff_group.StartStaff) then
            return false
        end
        if not region:IsStaffIncluded(staff_group.EndStaff) then
            return false
        end
        return true
    end

    function library.staff_group_is_multistaff_instrument(staff_group)
        local multistaff_instruments = finale.FCMultiStaffInstruments()
        multistaff_instruments:LoadAll()
        for inst in each(multistaff_instruments) do
            if inst:ContainsStaff(staff_group.StartStaff) and (inst.GroupID == staff_group:GetItemID()) then
                return true
            end
        end
        return false
    end

    function library.get_selected_region_or_whole_doc()
        local sel_region = finenv.Region()
        if sel_region:IsEmpty() then
            sel_region:SetFullDocument()
        end
        return sel_region
    end

    function library.get_first_cell_on_or_after_page(page_num)
        local curr_page_num = page_num
        local curr_page = finale.FCPage()
        local got1 = false

        while curr_page:Load(curr_page_num) do
            if curr_page:GetFirstSystem() > 0 then
                got1 = true
                break
            end
            curr_page_num = curr_page_num + 1
        end
        if got1 then
            local staff_sys = finale.FCStaffSystem()
            staff_sys:Load(curr_page:GetFirstSystem())
            return finale.FCCell(staff_sys.FirstMeasure, staff_sys.TopStaff)
        end

        local end_region = finale.FCMusicRegion()
        end_region:SetFullDocument()
        return finale.FCCell(end_region.EndMeasure, end_region.EndStaff)
    end

    function library.get_top_left_visible_cell()
        if not finenv.UI():IsPageView() then
            local all_region = finale.FCMusicRegion()
            all_region:SetFullDocument()
            return finale.FCCell(finenv.UI():GetCurrentMeasure(), all_region.StartStaff)
        end
        return library.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())
    end

    function library.get_top_left_selected_or_visible_cell()
        local sel_region = finenv.Region()
        if not sel_region:IsEmpty() then
            return finale.FCCell(sel_region.StartMeasure, sel_region.StartStaff)
        end
        return library.get_top_left_visible_cell()
    end

    function library.is_default_measure_number_visible_on_cell(meas_num_region, cell, staff_system, current_is_part)
        local staff = finale.FCCurrentStaffSpec()
        if not staff:LoadForCell(cell, 0) then
            return false
        end
        if meas_num_region:GetShowOnTopStaff() and (cell.Staff == staff_system.TopStaff) then
            return true
        end
        if meas_num_region:GetShowOnBottomStaff() and (cell.Staff == staff_system:CalcBottomStaff()) then
            return true
        end
        if staff.ShowMeasureNumbers then
            return not meas_num_region:GetExcludeOtherStaves(current_is_part)
        end
        return false
    end

    function library.calc_parts_boolean_for_measure_number_region(meas_num_region, for_part)
        if meas_num_region.UseScoreInfoForParts then
            return false
        end
        if nil == for_part then
            return finenv.UI():IsPartView()
        end
        return for_part
    end

    function library.is_default_number_visible_and_left_aligned(meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)
        current_is_part = library.calc_parts_boolean_for_measure_number_region(meas_num_region, current_is_part)
        if is_for_multimeasure_rest and meas_num_region:GetShowOnMultiMeasureRests(current_is_part) then
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultiMeasureAlignment(current_is_part)) then
                return false
            end
        elseif (cell.Measure == system.FirstMeasure) then
            if not meas_num_region:GetShowOnSystemStart() then
                return false
            end
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetStartAlignment(current_is_part)) then
                return false
            end
        else
            if not meas_num_region:GetShowMultiples(current_is_part) then
                return false
            end
            if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultipleAlignment(current_is_part)) then
                return false
            end
        end
        return library.is_default_measure_number_visible_on_cell(meas_num_region, cell, system, current_is_part)
    end

    function library.update_layout(from_page, unfreeze_measures)
        from_page = from_page or 1
        unfreeze_measures = unfreeze_measures or false
        local page = finale.FCPage()
        if page:Load(from_page) then
            page:UpdateLayout(unfreeze_measures)
        end
    end

    function library.get_current_part()
        local part = finale.FCPart(finale.PARTID_CURRENT)
        part:Load(part.ID)
        return part
    end

    function library.get_score()
        local part = finale.FCPart(finale.PARTID_SCORE)
        part:Load(part.ID)
        return part
    end

    function library.get_page_format_prefs()
        local current_part = library.get_current_part()
        local page_format_prefs = finale.FCPageFormatPrefs()
        local success = false
        if current_part:IsScore() then
            success = page_format_prefs:LoadScore()
        else
            success = page_format_prefs:LoadParts()
        end
        return page_format_prefs, success
    end
    local calc_smufl_directory = function(for_user)
        local is_on_windows = finenv.UI():IsOnWindows()
        local do_getenv = function(win_var, mac_var)
            if finenv.UI():IsOnWindows() then
                return win_var and os.getenv(win_var) or ""
            else
                return mac_var and os.getenv(mac_var) or ""
            end
        end
        local smufl_directory = for_user and do_getenv("LOCALAPPDATA", "HOME") or do_getenv("COMMONPROGRAMFILES")
        if not is_on_windows then
            smufl_directory = smufl_directory .. "/Library/Application Support"
        end
        smufl_directory = smufl_directory .. "/SMuFL/Fonts/"
        return smufl_directory
    end

    function library.get_smufl_font_list()
        local font_names = {}
        local add_to_table = function(for_user)
            local smufl_directory = calc_smufl_directory(for_user)
            local get_dirs = function()
                if finenv.UI():IsOnWindows() then
                    return io.popen("dir \"" .. smufl_directory .. "\" /b /ad")
                else
                    return io.popen("ls \"" .. smufl_directory .. "\"")
                end
            end
            local is_font_available = function(dir)
                local fc_dir = finale.FCString()
                fc_dir.LuaString = dir
                return finenv.UI():IsFontAvailable(fc_dir)
            end
            for dir in get_dirs():lines() do
                if not dir:find("%.") then
                    dir = dir:gsub(" Bold", "")
                    dir = dir:gsub(" Italic", "")
                    local fc_dir = finale.FCString()
                    fc_dir.LuaString = dir
                    if font_names[dir] or is_font_available(dir) then
                        font_names[dir] = for_user and "user" or "system"
                    end
                end
            end
        end
        add_to_table(true)
        add_to_table(false)
        return font_names
    end

    function library.get_smufl_metadata_file(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end
        local try_prefix = function(prefix, font_info)
            local file_path = prefix .. font_info.Name .. "/" .. font_info.Name .. ".json"
            return io.open(file_path, "r")
        end
        local user_file = try_prefix(calc_smufl_directory(true), font_info)
        if user_file then
            return user_file
        end
        return try_prefix(calc_smufl_directory(false), font_info)
    end

    function library.is_font_smufl_font(font_info)
        if not font_info then
            font_info = finale.FCFontInfo()
            font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
        end
        if client.supports("smufl") then
            if nil ~= font_info.IsSMuFLFont then
                return font_info.IsSMuFLFont
            end
        end
        local smufl_metadata_file = library.get_smufl_metadata_file(font_info)
        if nil ~= smufl_metadata_file then
            io.close(smufl_metadata_file)
            return true
        end
        return false
    end

    function library.simple_input(title, text)
        local return_value = finale.FCString()
        return_value.LuaString = ""
        local str = finale.FCString()
        local min_width = 160

        function format_ctrl(ctrl, h, w, st)
            ctrl:SetHeight(h)
            ctrl:SetWidth(w)
            str.LuaString = st
            ctrl:SetText(str)
        end

        title_width = string.len(title) * 6 + 54
        if title_width > min_width then
            min_width = title_width
        end
        text_width = string.len(text) * 6
        if text_width > min_width then
            min_width = text_width
        end

        str.LuaString = title
        local dialog = finale.FCCustomLuaWindow()
        dialog:SetTitle(str)
        local descr = dialog:CreateStatic(0, 0)
        format_ctrl(descr, 16, min_width, text)
        local input = dialog:CreateEdit(0, 20)
        format_ctrl(input, 20, min_width, "")
        dialog:CreateOkButton()
        dialog:CreateCancelButton()

        function callback(ctrl)
        end

        dialog:RegisterHandleCommand(callback)

        if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
            return_value.LuaString = input:GetText(return_value)

            return return_value.LuaString

        end
    end

    function library.is_finale_object(object)

        return object and type(object) == "userdata" and object.ClassName and object.GetClassID and true or false
    end

    function library.get_parent_class(classname)
        local class = finale[classname]
        if type(class) ~= "table" then return nil end
        if not finenv.IsRGPLua then
            local classt = class.__class
            if classt and classname ~= "__FCBase" then
                local classtp = classt.__parent
                if classtp and type(classtp) == "table" then
                    for k, v in pairs(finale) do
                        if type(v) == "table" then
                            if v.__class and v.__class == classtp then
                                return tostring(k)
                            end
                        end
                    end
                end
            end
        else
            for k, _ in pairs(class.__parent) do
                return tostring(k)
            end
        end
        return nil
    end

    function library.get_class_name(object)
        local class_name = object:ClassName(object)
        if class_name == "__FCCollection" and object.ExecuteModal then
            return object.RegisterHandleCommand and "FCCustomLuaWindow" or "FCCustomWindow"
        elseif class_name == "FCControl" then
            if object.GetCheck then
                return "FCCtrlCheckbox"
            elseif object.GetThumbPosition then
                return "FCCtrlSlider"
            elseif object.AddPage then
                return "FCCtrlSwitcher"
            else
                return "FCCtrlButton"
            end
        elseif class_name == "FCCtrlButton" and object.GetThumbPosition then
            return "FCCtrlSlider"
        end
        return class_name
    end

    function library.system_indent_set_to_prefs(system, page_format_prefs)
        page_format_prefs = page_format_prefs or library.get_page_format_prefs()
        local first_meas = finale.FCMeasure()
        local is_first_system = (system.FirstMeasure == 1)
        if (not is_first_system) and first_meas:Load(system.FirstMeasure) then
            if first_meas.ShowFullNames then
                is_first_system = true
            end
        end
        if is_first_system and page_format_prefs.UseFirstSystemMargins then
            system.LeftMargin = page_format_prefs.FirstSystemLeft
        else
            system.LeftMargin = page_format_prefs.SystemLeft
        end
        return system:Save()
    end

    function library.calc_script_name(include_extension)
        local fc_string = finale.FCString()
        if finenv.RunningLuaFilePath then

            fc_string.LuaString = finenv.RunningLuaFilePath()
        else


            fc_string:SetRunningLuaFilePath()
        end
        local filename_string = finale.FCString()
        fc_string:SplitToPathAndFile(nil, filename_string)
        local retval = filename_string.LuaString
        if not include_extension then
            retval = retval:match("(.+)%..+")
            if not retval or retval == "" then
                retval = filename_string.LuaString
            end
        end
        return retval
    end

    function library.get_default_music_font_name()
        local fontinfo = finale.FCFontInfo()
        local default_music_font_name = finale.FCString()
        if fontinfo:LoadFontPrefs(finale.FONTPREF_MUSIC) then
            fontinfo:GetNameString(default_music_font_name)
            return default_music_font_name.LuaString
        end
    end
    return library
end
function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 18, 2021"
    finaleplugin.CategoryTags = "Layout"
    return "Load SMuFL Engraving Defaults", "Load SMuFL Engraving Defaults", "Loads engraving defaults for the current SMuFL Default Music Font."
end
local luna = require("lunajson.lunajson")
local library = require("library.general_library")
function smufl_load_engraving_defaults()
    local font_info = finale.FCFontInfo()
    font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
    local font_json_file = library.get_smufl_metadata_file(font_info)
    if nil == font_json_file then
        finenv.UI():AlertError("The current Default Music Font (" .. font_info.Name .. ") is not a SMuFL font, or else the json file with its engraving defaults is not installed.", "Default Music Font is not SMuFL")
        return
    end
    local json = font_json_file:read("*all")
    io.close(font_json_file)
    local font_metadata = luna.decode(json)
    local evpuPerSpace = 24.0
    local efixPerEvpu = 64.0
    local efixPerSpace = evpuPerSpace * efixPerEvpu

    local music_char_prefs = finale.FCMusicCharacterPrefs()
    music_char_prefs:Load(1)
    local distance_prefs = finale.FCDistancePrefs()
    distance_prefs:Load(1)
    local size_prefs = finale.FCSizePrefs()
    size_prefs:Load(1)
    local lyrics_prefs = finale.FCLyricsPrefs()
    lyrics_prefs:Load(1)
    local smart_shape_prefs = finale.FCSmartShapePrefs()
    smart_shape_prefs:Load(1)
    local repeat_prefs = finale.FCRepeatPrefs()
    repeat_prefs:Load(1)
    local tie_prefs = finale.FCTiePrefs()
    tie_prefs:Load(1)
    local tuplet_prefs = finale.FCTupletPrefs()
    tuplet_prefs:Load(1)


    local beamSpacingFound = 0
    local beamWidthFound = math.floor(size_prefs.BeamThickness/efixPerEvpu + 0.5)

    local action = {
        staffLineThickness = function(v) size_prefs.StaffLineThickness = math.floor(efixPerSpace*v + 0.5) end,
        stemThickness = function(v) size_prefs.StemLineThickness = math.floor(efixPerSpace*v + 0.5) end,
        beamThickness = function(v)
            size_prefs.BeamThickness = math.floor(efixPerSpace*v + 0.5)
            beamWidthFound = math.floor(evpuPerSpace*v + 0.5)
        end,
        beamSpacing = function(v) beamSpacingFound = math.floor(evpuPerSpace*v + 0.5) end,
        legerLineThickness = function(v) size_prefs.LedgerLineThickness = math.floor(efixPerSpace*v + 0.5) end,
        legerLineExtension = function(v)
                size_prefs.LedgerLeftHalf = math.floor(evpuPerSpace*v + 0.5)
                size_prefs.LedgerRightHalf = size_prefs.LedgerLeftHalf
                size_prefs.LedgerLeftRestHalf = size_prefs.LedgerLeftHalf
                size_prefs.LedgerRightRestHalf = size_prefs.LedgerLeftHalf
            end,
        slurEndpointThickness = function(v)
                size_prefs.ShapeSlurTipWidth = math.floor(evpuPerSpace*v*10000.0 +0.5)
                smart_shape_prefs.SlurTipWidth = math.floor(evpuPerSpace*v*10000.0 +0.5)
            end,
        slurMidpointThickness = function(v)
                smart_shape_prefs.SlurThicknessVerticalLeft = math.floor(evpuPerSpace*v +0.5)
                smart_shape_prefs.SlurThicknessVerticalRight = math.floor(evpuPerSpace*v +0.5)
            end,
        tieEndpointThickness = function(v) tie_prefs.TipWidth = math.floor(evpuPerSpace*v*10000.0 +0.5) end,
        tieMidpointThickness = function(v)
            tie_prefs.ThicknessLeft = math.floor(evpuPerSpace*v +0.5)
            tie_prefs.ThicknessRight = math.floor(evpuPerSpace*v +0.5)
        end,
        thinBarlineThickness = function(v)
                size_prefs.ThinBarlineThickness = math.floor(efixPerSpace*v + 0.5)
                repeat_prefs.ThinLineThickness = math.floor(efixPerSpace*v + 0.5)
            end,
        thickBarlineThickness = function(v)
                size_prefs.HeavyBarlineThickness = math.floor(efixPerSpace*v + 0.5)
                repeat_prefs.HeavyLineThickness = math.floor(efixPerSpace*v + 0.5)
            end,
        dashedBarlineThickness = function(v) size_prefs.ThinBarlineThickness = math.floor(efixPerSpace*v + 0.5) end,
        dashedBarlineDashLength = function(v) size_prefs.BarlineDashLength = math.floor(evpuPerSpace*v + 0.5) end,
        dashedBarlineGapLength = function(v) distance_prefs.BarlineDashSpace = math.floor(evpuPerSpace*v + 0.5)end,
        barlineSeparation = function(v) distance_prefs.BarlineDoubleSpace = math.floor(efixPerSpace*v + 0.5) end,
        thinThickBarlineSeparation = function(v)
                distance_prefs.BarlineFinalSpace = math.floor(efixPerSpace*v + 0.5)
                repeat_prefs.SpaceBetweenLines = math.floor(efixPerSpace*v + 0.5)
            end,
        repeatBarlineDotSeparation = function(v)
                local text_met = finale.FCTextMetrics()
                text_met:LoadSymbol(music_char_prefs.SymbolForwardRepeatDot, font_info, 100)
                local newVal = evpuPerSpace*v + text_met:CalcWidthEVPUs()
                repeat_prefs:SetForwardSpace(math.floor(newVal + 0.5))
                repeat_prefs:SetBackwardSpace(math.floor(newVal + 0.5))
            end,
        bracketThickness = function(v) end,
        subBracketThickness = function(v) end,
        hairpinThickness = function(v) smart_shape_prefs.HairpinLineWidth = math.floor(efixPerSpace*v + 0.5) end,
        octaveLineThickness = function(v) smart_shape_prefs.LineWidth = math.floor(efixPerSpace*v + 0.5) end,
        pedalLineThickness = function(v) end,
        repeatEndingLineThickness = function(v) repeat_prefs.EndingLineThickness = math.floor(efixPerSpace*v + 0.5) end,
        arrowShaftThickness = function(v) end,
        lyricLineThickness = function(v) lyrics_prefs.WordExtLineThickness = math.floor(efixPerSpace*v + 0.5) end,
        textEnclosureThickness = function(v)
                size_prefs.EnclosureThickness = math.floor(efixPerSpace*v + 0.5)
                local expression_defs = finale.FCTextExpressionDefs()
                expression_defs:LoadAll()
                for def in each(expression_defs) do
                    if def.UseEnclosure then
                        local enclosure = def:CreateEnclosure()
                        if ( nil ~= enclosure) then
                            enclosure.LineWidth = size_prefs.EnclosureThickness
                            enclosure:Save()
                        end
                    end
                end
                local numbering_regions = finale.FCMeasureNumberRegions()
                numbering_regions:LoadAll()
                for region in each(numbering_regions) do
                    local got1 = false
                    for _, for_parts in pairs({false, true}) do
                        if region:GetUseEnclosureStart(for_parts) then
                            local enc_start = region:GetEnclosureStart(for_parts)
                            if nil ~= enc_start then
                                enc_start.LineWidth = size_prefs.EnclosureThickness
                                got1 = true
                            end
                        end
                        if region:GetUseEnclosureMultiple(for_parts) then
                            local enc_multiple = region:GetEnclosureMultiple(for_parts)
                            if nil ~= enc_multiple then
                                enc_multiple.LineWidth = size_prefs.EnclosureThickness
                                got1 = true
                            end
                        end
                    end
                    if got1 then
                        region:Save()
                    end
                end
                local separate_numbers = finale.FCSeparateMeasureNumbers()
                separate_numbers:LoadAll()
                for sepnum in each(separate_numbers) do
                    if sepnum.UseEnclosure then
                        local enc_sep = sepnum:GetEnclosure()
                        if nil ~= enc_sep then
                            enc_sep.LineWidth = size_prefs.EnclosureThickness
                        end
                        sepnum:Save()
                    end
                end
            end,
        tupletBracketThickness = function(v)
                tuplet_prefs.BracketThickness = math.floor(efixPerSpace*v + 0.5)
            end,
        hBarThickness = function(v) end
    }

    for k, v in pairs(font_metadata.engravingDefaults) do
        local action_function = action[k]
        if nil ~= action_function then
            action_function(tonumber(v))
        end
    end
    if 0 ~= beamSpacingFound then
        distance_prefs.SecondaryBeamSpace = beamSpacingFound + beamWidthFound




        local finale_prefix = "Finale "
        if finale_prefix == font_info.Name:sub(1, #finale_prefix) then
            distance_prefs.SecondaryBeamSpace = beamSpacingFound
        end
    end

    distance_prefs:Save()
    size_prefs:Save()
    lyrics_prefs:Save()
    smart_shape_prefs:Save()
    repeat_prefs:Save()
    tie_prefs:Save()
    tuplet_prefs:Save()
end
smufl_load_engraving_defaults()
