--[[ Copyright (c) 2017 Optera
 * Part of Logistics Train Network
 *
 * See LICENSE.md in the project directory for license information.
--]]

-- The 'order' field controls the position in the mod settings GUI. Settings a casual player
-- needs on the first day come first (group a), performance and debugging knobs come last (group z).

data:extend {
    -- ------------------------------------------------------------------------------------
    -- a: the essentials
    -- ------------------------------------------------------------------------------------
    {
        type = 'int-setting',
        name = 'ltn-stop-default-network',
        order = 'aa',
        setting_type = 'runtime-global',
        default_value = 1, -- every stop without a network signal is in network 1; 0 = "no network"
    },
    {
        type = 'int-setting',
        name = 'ltn-dispatcher-requester-threshold',
        order = 'ab',
        setting_type = 'runtime-global',
        default_value = 1000,
        minimum_value = 1,
        maximum_value = 2147483647, -- prevent 32bit signed overflow
    },
    {
        type = 'int-setting',
        name = 'ltn-dispatcher-provider-threshold',
        order = 'ac',
        setting_type = 'runtime-global',
        default_value = 1000,
        minimum_value = 1,
        maximum_value = 2147483647, -- prevent 32bit signed overflow
    },
    {
        type = 'string-setting',
        name = 'ltn-interface-console-level',
        order = 'ad',
        setting_type = 'runtime-global',
        default_value = '2',
        allowed_values = { '0', '1', '2', '3' },
    },
    {
        type = 'bool-setting',
        name = 'ltn-interface-console-messages',
        order = 'ae',
        setting_type = 'runtime-per-user',
        default_value = true,
    },
    {
        type = 'bool-setting',
        name = 'ltn-interface-message-gps',
        order = 'af',
        setting_type = 'runtime-global',
        default_value = true, -- clickable map locations in messages
    },
    {
        type = 'bool-setting',
        name = 'ltn-interface-factorio-alerts',
        order = 'ag',
        setting_type = 'runtime-per-user',
        default_value = true,
    },
    {
        type = 'bool-setting',
        name = 'ltn-dispatcher-enabled',
        order = 'ah',
        setting_type = 'runtime-global',
        default_value = true,
    },

    -- ------------------------------------------------------------------------------------
    -- b: how trains and stops behave
    -- ------------------------------------------------------------------------------------
    {
        type = 'int-setting',
        name = 'ltn-dispatcher-depot-inactivity',
        order = 'ba',
        setting_type = 'runtime-global',
        default_value = 5,     -- 5s
        minimum_value = 1,     -- 1s
        maximum_value = 36000, -- 10h
    },
    {
        type = 'int-setting',
        name = 'ltn-dispatcher-stop-timeout',
        order = 'bb',
        setting_type = 'runtime-global',
        default_value = 120,   -- 2min
        minimum_value = 0,     -- 0:off
        maximum_value = 36000, -- 10h
    },
    {
        type = 'int-setting',
        name = 'ltn-dispatcher-delivery-timeout',
        order = 'bc',
        setting_type = 'runtime-global',
        default_value = 600,   -- 10min
        minimum_value = 60,    -- 1min
        maximum_value = 36000, -- 10h
    },
    {
        type = 'bool-setting',
        name = 'ltn-dispatcher-finish-loading',
        order = 'bd',
        setting_type = 'runtime-global',
        default_value = true,
    },
    {
        type = 'bool-setting',
        name = 'ltn-dispatcher-requester-delivery-reset',
        order = 'be',
        setting_type = 'runtime-global',
        default_value = false,
    },
    {
        type = 'bool-setting',
        name = 'ltn-schedule-reselect-depot',
        order = 'bf',
        setting_type = 'runtime-global',
        default_value = false,
    },
    {
        type = 'bool-setting',
        name = 'ltn-depot-reset-filters',
        order = 'bg',
        setting_type = 'runtime-global',
        default_value = true,
    },
    {
        type = 'double-setting',
        name = 'ltn-depot-fluid-cleaning',
        order = 'bh',
        setting_type = 'runtime-global',
        default_value = 0,
        minimum_value = -1,
    },

    -- ------------------------------------------------------------------------------------
    -- c: refuelling
    -- ------------------------------------------------------------------------------------
    {
        type = 'bool-setting',
        name = 'ltn-schedule-fuel-station',
        order = 'ca',
        setting_type = 'runtime-global',
        default_value = false,
    },
    {
        type = 'bool-setting',
        name = 'ltn-fuel-station-interrupt',
        order = 'cb',
        setting_type = 'runtime-global',
        default_value = true,
    },
    {
        type = 'bool-setting',
        name = 'ltn-schedule-reset-interrupts',
        order = 'cc',
        setting_type = 'runtime-global',
        default_value = false,
    },

    -- ------------------------------------------------------------------------------------
    -- d: advanced
    -- ------------------------------------------------------------------------------------
    {
        type = 'bool-setting',
        name = 'ltn-provider-show-existing-cargo',
        order = 'da',
        setting_type = 'runtime-global',
        default_value = true,
    },
    {
        type = 'bool-setting',
        name = 'ltn-provider-ignore-stopped-train',
        order = 'db',
        setting_type = 'runtime-global',
        default_value = false,
    },
    {
        type = 'bool-setting',
        name = 'ltn-dispatcher-schedule-circuit-control',
        order = 'dc',
        setting_type = 'runtime-global',
        default_value = false,
    },
    {
        type = 'int-setting',
        name = 'ltn-depot-fudge-factor',
        order = 'dd',
        setting_type = 'runtime-global',
        default_value = 0,
        minimum_value = 0,
    },
    {
        type = 'bool-setting',
        name = 'ltn-advanced-cross-surface-delivery',
        order = 'de',
        setting_type = 'runtime-global',
        default_value = false,
    },

    -- ------------------------------------------------------------------------------------
    -- z: performance and debugging
    -- ------------------------------------------------------------------------------------
    {
        type = 'int-setting',
        name = 'ltn-dispatcher-nth_tick',
        order = 'za',
        setting_type = 'runtime-global',
        default_value = 2,
        minimum_value = 1,
        maximum_value = 60, -- one stop per second
    },
    {
        type = 'int-setting',
        name = 'ltn-dispatcher-stop-updates-per-tick',
        order = 'zb',
        setting_type = 'runtime-global',
        default_value = 2,
        minimum_value = 1,
        maximum_value = 100, -- processing too many stops per tick will produce lag spikes
    },
    {
        type = 'int-setting',
        name = 'ltn-dispatcher-updates-per-tick',
        order = 'zc',
        setting_type = 'runtime-global',
        default_value = 1,
        minimum_value = 1,
        maximum_value = 100, -- processing too many requests per tick will produce lag spikes
    },
    {
        type = 'int-setting',
        name = 'ltn-dispatcher-route-cache-lifetime',
        order = 'zd',
        setting_type = 'runtime-global',
        default_value = 10,
        minimum_value = 2,
        maximum_value = 120,
    },
    {
        type = 'int-setting',
        name = 'ltn-limit-eligible-trains',
        order = 'ze',
        setting_type = 'runtime-global',
        default_value = 0, -- no limits
        minimum_value = 0,
    },
    {
        type = 'int-setting',
        name = 'ltn-interface-debug-logfile',
        order = 'zf',
        setting_type = 'runtime-global',
        default_value = 0,
        allowed_values = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    },
}

data:extend {
    {
        type = 'string-setting',
        name = 'ltn-depot-stop-limit-trains',
        order = 'aa',
        setting_type = 'startup',
        default_value = '0',
        allowed_values = { '0', '1', '2' },
    },
}
