require 'calendar'

local randExp = random.exp

for i=1,60 do
	local c = Calendar:new {
		liniek = i, pouzitych = 0,
		prijatych = 0, zamietnutych = 0, celkovo = 0,
		hovoru = 0, priemerLiniek = 0
	}
	c:runSimulation(8*60*60, {
		INIT = function(e)
			c:schedule(randExp(10), 'volaA')
			c:schedule(randExp(12), 'volaB')
		end,
		volaA = function(e)
			c:schedule(0, 'volanie')
			c:schedule(randExp(10), 'volaA')
		end,
		volaB = function(e)
			c:schedule(0, 'volanie')
			c:schedule(randExp(12), 'volaB')
		end,
		volanie = function(e)
			celkovo = celkovo + 1
			priemerLiniek = priemerLiniek + pouzitych
			if pouzitych < liniek then
				pouzitych = pouzitych + 1
				prijatych = prijatych + 1
				local cas = randExp(240)
				hovoru = hovoru + cas
				c:schedule(cas, 'koniec')
			else
				zamietnutych = zamietnutych + 1
			end
		end,
		koniec = function(e)
			pouzitych = pouzitych - 1
		end,
		FINISH = function()
			print('Liniek: ', liniek)
			print('Prijatych: ', prijatych)
			print('Zamietnutych: ', zamietnutych)
			print('Celkovo: ', celkovo)
			print('Pomer: ', zamietnutych / celkovo * 100)
			print('Vytazenost: ', hovoru / liniek / (8*60*60) * 100)
			print('Priemer: ', priemerLiniek / celkovo)
		end
	})
end
