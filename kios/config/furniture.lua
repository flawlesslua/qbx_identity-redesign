--[[
    Furniture that can be placed inside a shop.

    Every shelf, fridge and register is a prop spawned by the script, so owners can move them
    around later (renovation mode). A spot is a place on the furniture that holds one product.

    model    : prop model. The models below are vanilla placeholders: swap them for the empty
               shelf props shipped with your MLO.
    spots    : list of { offset = vec3(right, forward, up), heading = degrees } relative to the
               furniture. Use `/kios spots` in game to click them into place and copy the result.
    register : only for checkout counters (see below).

    Convention: a furniture's front faces its local +Y. Spot heading 0 means the product faces
    the same way as the furniture's front; 180 means it faces the back side.
]]

Config.Furniture = {
    shelf_double = {
        label = 'Double shelf',
        category = 'shelf',
        model = 'v_ret_247shelves01',
        spots = Kios.grid({
            sides = { { y = 0.28, heading = 0.0 }, { y = -0.28, heading = 180.0 } },
            levels = { 0.32, 0.72, 1.12, 1.52 },
            columns = { -0.6, -0.2, 0.2, 0.6 },
        }),
    },

    shelf_single = {
        label = 'Wall shelf',
        category = 'shelf',
        model = 'v_ret_247shelves02',
        spots = Kios.grid({
            sides = { { y = 0.18, heading = 0.0 } },
            levels = { 0.32, 0.72, 1.12, 1.52 },
            columns = { -0.6, -0.2, 0.2, 0.6 },
        }),
    },

    fridge = {
        label = 'Drinks fridge',
        category = 'fridge',
        model = 'v_ret_ml_fridge',
        spots = Kios.grid({
            sides = { { y = 0.15, heading = 0.0 } },
            levels = { 0.45, 0.85, 1.25, 1.65 },
            columns = { -0.3, 0.0, 0.3 },
        }),
    },

    candy_stand = {
        label = 'Candy stand',
        category = 'shelf',
        model = 'v_ret_ml_sweet1',
        spots = Kios.grid({
            sides = { { y = 0.12, heading = 0.0 } },
            levels = { 0.2, 0.45 },
            columns = { -0.2, 0.0, 0.2 },
        }),
    },

    --[[
        Self-service checkout. Place the till on top of a counter.

        register.mode    : 'self' (customer pays alone). 'staff' arrives with the staffed register phase.
        register.anchor  : where the "Register" label floats (local offset)
        register.panel   : where the receipt panel floats (local offset)
        register.counter : slots on the counter where carried products are put down
        register.bag     : where the paid bag appears
    ]]
    register_self = {
        label = 'Self checkout',
        category = 'register',
        model = 'prop_till_01',
        spots = {},
        register = {
            mode = 'self',
            anchor = vec3(0.0, 0.0, 0.28),
            panel = vec3(0.0, 0.15, 0.85),
            counter = {
                vec3(-0.38, 0.05, 0.0), vec3(-0.58, 0.05, 0.0), vec3(-0.78, 0.05, 0.0),
                vec3(-0.38, 0.25, 0.0), vec3(-0.58, 0.25, 0.0), vec3(-0.78, 0.25, 0.0),
            },
            bag = vec3(0.42, 0.1, 0.0),
        },
    },
}

for key, furn in pairs(Config.Furniture) do
    furn.key = key
    furn.spots = furn.spots or {}
end
