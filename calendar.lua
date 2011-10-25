--[[
	Calendar - Jednoducha (ale plne funkcna) implementacia kalendara pre vyuzitie v simulaciach v jazyku Lua.
	Michal Kottman, 2011
	
	Priklad pouzitia:
	
	local c = Calendar:new { pocet = 0, obsadene = 0, uspesnych = 0, max = 30 }
	c:runSimulation(8*60*60, {
		INIT = function(event)
			c:schedule(randExp(10), 'volanie')
		end,
		volanie = function(event)
			pocet = pocet + 1
			if obsadene < max then
				obsadene = obsadene + 1
				uspesnych = uspesnych + 1
				c:schedule(randExp(60), 'koniec')
			end
			c:schedule(randExp(10), 'udalost')
		end,
		koniec = function(event)
			obsadene = obsadene - 1
		end
	})
	print('Celkovo:', c.pocet)
	print('Uspesnych:', c.uspesnych)
	
	Poskytovane API:
	
	random.uniform(min, max) - nahodne cislo s rovnomernym rozdelenim
	random.exp(mean)         - nahodne cislo s exp. rozdelenim
	random.normal(mi, sigma) - nahodne cislo s normalnym rozdelenim
	
	Calendar:new(o) -> [cal]
		Vytvori novy objekt kalendaru. `o` je nepovinny parameter typu tabulka, moze osahovat stav.
		
	cal:schedule(relTime, type, event)
		Naplanuje udalost typu `type` (string) v relativnom case `relTime`. `event` je nepovinna tabulka
		ktora moze obsahovat dalsie informacie o udalosti, bude predana ako parameter spracovania udalosti.

	cal:runSimulation(maxTime, handlers)
		Spusti simulaciu, ktora pobezi po cas `maxTime`. `handlers` je tabulka, kde kluce su nazvy udalosti
		a hodnoty su typu function(event), mozu priamo pristupovat k stavovym premennym kalendara. Na
		zaciatku je zavolana udalost "INIT". Ak existuje, na konci bude zavolana udalost "FINISH".
		
	cal.debug
		Ak je nastavene (nie je nil) tak `runSimulation` vypisuje priebeh simulacie (cas, sprava). 
		
	cal.time
		Aktualny cas simulacie.
]]

math.randomseed(os.time())

-- Ako datova struktura je vyuzita binary heap s prioritizaciou podla casu
require 'heap'

-- Porovna dva objekty na zaklade ich casu
local function timeCompare(a, b) return a.time < b.time end

-- Tu budu ulozene funkcie pre generovanie nahodnych cisiel
random = {}

-- Nahodne cislo v intervale [min, max)
function random.uniform(min, max)
	return math.random() * (max - min) + min
end

-- Vracia nahodne cislo s exponencialnym rozdelenim
function random.exp(mean)
	local r = 0
	while r == 0 do
		r = math.random()
	end
	return -mean * math.log(r)
end

-- Nahodne cislo v normalnom (Gaussovom) rozdeleni, mi = stredna hodnota, sigma = rozptyl
function random.normal(mi, sigma)
	local tmp = math.sqrt(2 * math.pi) * sigma
	local tmp2 = 2 * sigma^2
	local tmp3 = 5 * sigma
	while true do
		local res = random.uniform(mi - tmp3, mi + tmp3)
		local res2 = random.uniform(0, 1/tmp)
		local tmp4 = math.exp( - (res-mi)^2 / tmp2) / tmp
		if tmp4 >= res2 then return res end
	end
end




-- Vytvorenie "triedy" Calendar
Calendar = {}
Calendar.__index = Calendar

-- Konstruktor, ako volitelny parameter berie tabulku, v ktorej moze byt ulozeny stav
function Calendar:new(o)
	o = o or {}
	o.heap = heap:new(timeCompare)
	o.time = 0
	return setmetatable(o, self)
end

-- Naplanuje objekt `event` (nepovinne) typu `type` (retazec) v relativnom case `relTime` od sucasneho
function Calendar:schedule(relTime, type, event)
	event = event or {} -- ak nie je dodany event, vytvor novu tabulku
	event.time = self.time + relTime
	event.type = type
	self.heap:insert(event) -- heap sa postara o vlozenie na spravne miesto
end

-- Spusti simulaciu a bezi az po cas `maxTime`. 
function Calendar:runSimulation(maxTime, handlers)
	self.time = 0
	self:schedule(0,'INIT')
	
	-- "magia" ktora umozni pristup k stavovym premennym bez pouzitia "self.xxx"
	local env = setmetatable({}, {
		__index = function(t,k) return self[k] or _G[k] end,
		__newindex = function(t,k,v) if self[k] then self[k] = v else _G[k] = v end end
	})
	for k,v in pairs(handlers) do
		if type(v) == 'function' then setfenv(v, env) end
	end
	
	while not self.heap:empty() and self.time < maxTime do
		local event = self.heap:pop()
		self.time = event.time
		if self.debug then print(event.time, event.type) end
		if not handlers[event.type] then
			error('No handler for event type: ' .. event.type)
		else
			handlers[event.type](event)
		end
	end
	if handlers.FINISH then handlers.FINISH() end
end

return Calendar