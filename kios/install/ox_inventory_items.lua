--[[
    Paste these into ox_inventory/data/items.lua (skip any item your server already has,
    e.g. 'water' or 'sandwich'). Item names must match `item` in kios/config/products.lua.

    Eating / drinking effects are left out on purpose: hook them into whatever consumable
    system your framework uses (qbx_smallresources, esx_basicneeds, ox_inventory client.status...).
]]

['noodle_cup']      = { label = 'Noodle cup',      weight = 250, stack = true, close = true },
['kids_cereal']     = { label = 'Kids cereal',     weight = 400, stack = true, close = true },
['snack_mix']       = { label = 'Snack mix',       weight = 150, stack = true, close = true },
['chips']           = { label = 'Chips',           weight = 120, stack = true, close = true },
['sandwich']        = { label = 'Sandwich',        weight = 200, stack = true, close = true },
['ego_chaser']      = { label = 'Ego Chaser',      weight = 60,  stack = true, close = true },
['pq_candy']        = { label = "P's & Q's",       weight = 60,  stack = true, close = true },
['meteorite']       = { label = 'Meteorite bar',   weight = 60,  stack = true, close = true },
['ecola']           = { label = 'eCola',           weight = 350, stack = true, close = true },
['sprunk']          = { label = 'Sprunk',          weight = 350, stack = true, close = true },
['orang_o_tang']    = { label = 'Orang-O-Tang',    weight = 350, stack = true, close = true },
['water']           = { label = 'Water',           weight = 500, stack = true, close = true },
['milk']            = { label = 'Milk',            weight = 1000, stack = true, close = true },
['energy_drink']    = { label = 'Energy drink',    weight = 350, stack = true, close = true },
['beer_jakey']      = { label = "Jakey's",         weight = 500, stack = true, close = true },
['beer_stronzo']    = { label = 'Stronzo',         weight = 500, stack = true, close = true },
['beer_pisswasser'] = { label = 'Pißwasser',       weight = 500, stack = true, close = true },
['ketchup']         = { label = 'Ketchup',         weight = 300, stack = true, close = true },
