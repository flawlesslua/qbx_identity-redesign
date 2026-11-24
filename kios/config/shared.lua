Config = {}

Config.debug = false

-- ACE permission used for the /kios admin command (lib.addCommand "restricted").
Config.adminGroup = 'group.admin'

Config.currency = '$'

-- How many products a player can hold in their hands at once.
Config.maxCarry = 6

-- Targeting (aim at a product with the camera centre).
Config.target = {
    distance = 2.4,      -- max distance from the player to an interactable
    tolerance = 0.22,    -- max distance (metres) between the camera ray and the interactable
    dots = true,         -- draw small white dots on every visible spot
    dotDistance = 5.0,
}

-- GTA control ids. https://docs.fivem.net/docs/game-references/controls/
Config.keys = {
    primary = { control = 38, label = 'E' },          -- take / checkout / cash / take bag
    secondary = { control = 47, label = 'G' },        -- drop / card
    cancel = { control = 177, label = 'Backspace' },  -- cancel checkout / tools
    confirm = { control = 191, label = 'Enter' },     -- confirm in admin tools
}

-- What happens when someone walks out of the shop holding unpaid products.
--   'keep'   : the products go into their inventory for free (logged as theft)
--   'return' : the products go back on the shelves
Config.theft = {
    mode = 'keep',
    margin = 1.5,        -- extra metres outside the shop zone before it counts
}

Config.checkout = {
    scanTime = 650,      -- ms per item at a self-checkout
    walkAwayDistance = 7.0,
    bagModel = 'prop_paper_bag_small',
    bagTimeout = 300,    -- seconds; an unclaimed bag is handed to its owner automatically
    methods = { cash = true, card = true },
}

-- Seconds between database flushes of shelf stock.
Config.saveInterval = 15

-- Prop used when a configured model does not exist in the game files.
Config.fallbackModel = 'prop_ld_can_01'

-- Animations
Config.anims = {
    take = { dict = 'mp_common', name = 'givetake1_a', duration = 900, flag = 48 },
    place = { dict = 'mp_common', name = 'givetake1_b', duration = 900, flag = 48 },
}

-- Ped bones that carried products are attached to (first item right hand, second left hand).
Config.carryBones = { 28422, 60309 }
