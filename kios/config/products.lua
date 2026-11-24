--[[
    Products sold on shelves.

    key       : unique product id (used in the database)
    label     : name shown on the floating label and receipt
    item      : ox_inventory item given after payment (see install/ox_inventory_items.lua)
    price     : default price (owners can override per shop in a later phase)
    model     : prop spawned on the shelf and held in the hand
    capacity  : max units one spot can hold
    stack     : how many props are drawn on a spot and the step between them (local offset)
    zOffset   : lift the prop if its origin is not at the bottom of the model
    rot       : extra rotation for the prop on the shelf (x, y, z)
    hold      : attach offset/rotation when held in a hand

    Model names are vanilla GTA V props. Any model that does not exist falls back to
    Config.fallbackModel and prints a warning in the F8 console, so check the console the first
    time you test and swap names that are missing.
]]

local defaultStack = { count = 3, step = vec3(0.0, -0.09, 0.0) }

Config.Products = {
    noodle_cup = {
        label = 'Noodle cup', item = 'noodle_cup', price = 3, category = 'food',
        model = 'v_ret_247_noodle1', capacity = 6, stack = defaultStack,
    },
    kids_cereal = {
        label = 'Kids cereal', item = 'kids_cereal', price = 5, category = 'food',
        model = 'v_res_fa_cereal01', capacity = 4, stack = { count = 2, step = vec3(0.0, -0.08, 0.0) },
    },
    snack_mix = {
        label = 'Snack mix', item = 'snack_mix', price = 3, category = 'food',
        model = 'v_ret_ml_chips4', capacity = 6, stack = defaultStack,
    },
    chips = {
        label = 'Chips', item = 'chips', price = 2, category = 'food',
        model = 'v_ret_ml_chips1', capacity = 6, stack = defaultStack,
    },
    sandwich = {
        label = 'Sandwich', item = 'sandwich', price = 5, category = 'food',
        model = 'prop_sandwich_01', capacity = 5, stack = defaultStack,
    },
    ego_chaser = {
        label = 'Ego Chaser', item = 'ego_chaser', price = 2, category = 'candy',
        model = 'prop_choc_ego', capacity = 8, stack = { count = 4, step = vec3(0.0, -0.05, 0.0) },
    },
    pq_candy = {
        label = "P's & Q's", item = 'pq_candy', price = 2, category = 'candy',
        model = 'prop_candy_pqs', capacity = 8, stack = { count = 4, step = vec3(0.0, -0.05, 0.0) },
    },
    meteorite = {
        label = 'Meteorite bar', item = 'meteorite', price = 2, category = 'candy',
        model = 'prop_choc_meto', capacity = 8, stack = { count = 4, step = vec3(0.0, -0.05, 0.0) },
    },
    ecola = {
        label = 'eCola', item = 'ecola', price = 3, category = 'drinks',
        model = 'prop_ecola_can', capacity = 6, stack = { count = 2, step = vec3(0.0, 0.0, 0.125) },
    },
    sprunk = {
        label = 'Sprunk', item = 'sprunk', price = 3, category = 'drinks',
        model = 'prop_ld_can_01', capacity = 6, stack = { count = 2, step = vec3(0.0, 0.0, 0.125) },
    },
    orang_o_tang = {
        label = 'Orang-O-Tang', item = 'orang_o_tang', price = 3, category = 'drinks',
        model = 'prop_orang_can_01', capacity = 6, stack = { count = 2, step = vec3(0.0, 0.0, 0.125) },
    },
    water = {
        label = 'Small water', item = 'water', price = 2, category = 'drinks',
        model = 'prop_ld_flow_bottle', capacity = 6, stack = defaultStack,
    },
    milk = {
        label = 'Milk', item = 'milk', price = 4, category = 'drinks',
        model = 'prop_cs_milk_01', capacity = 4, stack = defaultStack,
    },
    energy_drink = {
        label = 'Energy drink', item = 'energy_drink', price = 4, category = 'drinks',
        model = 'prop_energy_drink', capacity = 6, stack = defaultStack,
    },
    beer_jakey = {
        label = "Jakey's", item = 'beer_jakey', price = 4, category = 'alcohol',
        model = 'prop_beer_jakey', capacity = 6, stack = defaultStack,
    },
    beer_stronzo = {
        label = 'Stronzo', item = 'beer_stronzo', price = 4, category = 'alcohol',
        model = 'prop_beer_stz', capacity = 6, stack = defaultStack,
    },
    beer_pisswasser = {
        label = 'Pißwasser', item = 'beer_pisswasser', price = 4, category = 'alcohol',
        model = 'prop_beer_pissh', capacity = 6, stack = defaultStack,
    },
    ketchup = {
        label = 'Ketchup', item = 'ketchup', price = 2, category = 'food',
        model = 'v_ret_247_ketchup1', capacity = 4, stack = defaultStack,
    },
}

-- Fill in defaults so the rest of the code can rely on every field existing.
for key, product in pairs(Config.Products) do
    product.key = key
    product.capacity = product.capacity or 6
    product.stack = product.stack or { count = 1, step = vec3(0.0, 0.0, 0.0) }
    product.zOffset = product.zOffset or 0.0
    product.rot = product.rot or vec3(0.0, 0.0, 0.0)
    product.hold = product.hold or { pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
end
