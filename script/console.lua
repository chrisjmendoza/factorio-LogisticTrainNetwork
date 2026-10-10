------------------------------------------------------------------------
-- LTN console
------------------------------------------------------------------------

local tools = require('script.tools')

---@class ltn.Console
local Console = {}

---@param data CustomCommandData
local function list_refuel_excluded(data)
    -- player_index is nil when the command comes from the server console
    local player = data.player_index and game.get_player(data.player_index) or nil
    local excluded_locos = { '' }

    for name, status in pairs(storage.ExcludedFromRefuel) do
        if status then
            local local_name = prototypes.entity[name] and prototypes.entity[name].localised_name or name
            excluded_locos[#excluded_locos + 1] = local_name
            excluded_locos[#excluded_locos + 1] = ', '
        end
    end
    excluded_locos[#excluded_locos] = nil

    tools.printmsg(0, function() return { '', { 'console.ltn_command_list_refuel_excluded_msg' }, ' ', excluded_locos } end, player)
end

---@param data CustomCommandData
---@param text string
---@param network_id integer
local function list_network(data, text, network_id)
    local player = data.player_index and game.get_player(data.player_index) or nil
    local stops = {}
    for stop_id, stop in pairs(storage.LogisticTrainStops) do
        if tools.isStopConsistent(stop) then
            if stop.network_id == network_id then
                stops[#stops + 1] = stop
            end
        else
            RemoveStop(stop_id)
        end
    end
    if #stops == 0 then
        tools.printmsg(0, function() return { 'console.ltn_command_list_' .. text .. '_network_id_no', table_size(storage.LogisticTrainStops) } end, player)
    else
        tools.printmsg(0, function() return { 'console.ltn_command_list_' .. text .. '_network_id_yes', #stops, table_size(storage.LogisticTrainStops) } end, player)

        local count = 0
        local msg
        for _, stop in pairs(stops) do
            if count % 10 == 0 then
                if count > 0 then tools.printmsg(0, function() return msg end, player) end
                msg= {''}
            end
            msg[#msg + 1] = tools.richTextForStop(stop.entity)
            count = count + 1
        end
        if #msg > 1 then tools.printmsg(0, function() return msg end, player) end
    end
end

---@param data CustomCommandData
local function list_default_network_id(data)
    return list_network(data, 'default', LtnSettings.default_network)
end

---@param data CustomCommandData
local function list_zero_network_id(data)
    return list_network(data, 'zero', 0)
end

------------------------------------------------------------------------
-- /ltn-diagnose: explain why a stop is not working
------------------------------------------------------------------------

---@param player LuaPlayer
---@param msg LocalisedString
local function say(player, msg)
    tools.printmsg(0, function() return msg end, player)
end

---@param stop ltn.TrainStop
---@return LocalisedString
local function role_name(stop)
    local stop_type = GetStationType(stop)
    if stop_type == station_type.depot then return { 'console.diag_role_depot' } end
    if stop_type == station_type.fuel_stop then return { 'console.diag_role_fuel' } end
    return { 'console.diag_role_station' }
end

--- Count free trains that could serve the given network.
---@param network_id integer
---@return integer free
---@return integer with_cargo_wagons
---@return integer with_fluid_wagons
local function count_free_trains(network_id)
    local dispatcher = tools.getDispatcher()
    local free, cargo, fluid = 0, 0, 0
    for _, train in pairs(dispatcher.availableTrains) do
        if train.train.valid and bit32.band(train.network_id, network_id) ~= 0 then
            free = free + 1
            if train.capacity > 0 then cargo = cargo + 1 end
            if train.fluid_capacity > 0 then fluid = fluid + 1 end
        end
    end
    return free, cargo, fluid
end

---@param stop ltn.TrainStop
---@param player LuaPlayer
local function diagnose_station(stop, player)
    -- read the live signals at the lamp and classify every item / fluid signal
    local signals = stop.input.valid and stop.input.get_signals(defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
    local seen = false
    if signals then
        for _, signal in pairs(signals) do
            local signal_type = signal.signal.type or 'item'
            if signal_type == 'item' or signal_type == 'fluid' then
                seen = true
                local pretty = tools.prettyPrint { type = signal_type, name = signal.signal.name, quality = signal.signal.quality or 'normal' }
                local count = signal.count
                if count >= stop.providing_threshold then
                    say(player, { 'console.diag_provides', tostring(count), pretty })
                elseif count > 0 then
                    say(player, { 'console.diag_below_provide', tostring(count), pretty, tostring(stop.providing_threshold) })
                elseif -count >= stop.requesting_threshold then
                    say(player, { 'console.diag_requests', tostring(-count), pretty })
                elseif count < 0 then
                    say(player, { 'console.diag_below_request', tostring(-count), pretty, tostring(stop.requesting_threshold) })
                end
            end
        end
    end
    if not seen then say(player, { 'console.diag_no_signals' }) end

    say(player, { 'console.diag_thresholds', tostring(stop.requesting_threshold), tostring(stop.providing_threshold) })
    if (stop.requesting_threshold_stacks or 0) > 0 or (stop.providing_threshold_stacks or 0) > 0 then
        say(player, { 'console.diag_stack_thresholds', tostring(stop.requesting_threshold_stacks or 0), tostring(stop.providing_threshold_stacks or 0) })
    end
    if stop.min_carriages > 0 or stop.max_carriages > 0 then
        say(player, { 'console.diag_length', tostring(stop.min_carriages), tostring(stop.max_carriages) })
    end

    -- is there a depot with a free train that can serve this stop?
    local depots = tools.findMatchingStops(tools.getDepots(), stop.network_id)
    local depot_count = table_size(depots)
    if depot_count == 0 then
        say(player, { 'console.diag_no_depots' })
    else
        local free, cargo, fluid = count_free_trains(stop.network_id)
        say(player, { 'console.diag_depots', tostring(depot_count), tostring(free), tostring(cargo), tostring(fluid) })
        if free == 0 then say(player, { 'console.diag_no_trains' }) end
    end
end

---@param stop ltn.TrainStop
---@param player LuaPlayer
local function diagnose_depot(stop, player)
    local dispatcher = tools.getDispatcher()
    if stop.parked_train_id and stop.parked_train and stop.parked_train.valid then
        ---@type LocalisedString
        local state
        if dispatcher.Deliveries[stop.parked_train_id] then
            state = { 'console.diag_train_on_delivery' }
        elseif tools.isTrainAvailable(stop.parked_train_id) then
            state = { 'console.diag_train_available' }
        else
            state = { 'console.diag_train_not_registered' }
        end
        say(player, { 'console.diag_depot_train', tools.richTextForTrain(stop.parked_train), state })
    else
        say(player, { 'console.diag_depot_no_train' })
    end
end

---@param stop ltn.TrainStop
---@param player LuaPlayer
local function diagnose_fuel_station(stop, player)
    local names = {}
    for _, fuel_signal in pairs(stop.fuel_signals or {}) do
        names[#names + 1] = string.format('[item=%s] %s', fuel_signal.first_signal.name, tostring(fuel_signal.constant))
    end
    if #names > 0 then
        say(player, { 'console.diag_fuel_signals', table.concat(names, ', ') })
    else
        say(player, { 'console.diag_fuel_no_signals' })
    end
end

---@param stop ltn.TrainStop
---@param player LuaPlayer
local function diagnose_stop(stop, player)
    local dispatcher = tools.getDispatcher()
    local network_ids, network_count = tools.networkList(stop.network_id)

    say(player, { 'console.diag_header', tools.richTextForStop(stop.entity), stop.entity.backer_name, role_name(stop), { 'ltn-message.network', network_count, network_ids } })

    if stop.error_code == 1 then say(player, { 'console.diag_error_disabled' }) end
    if stop.network_id == 0 then say(player, { 'console.diag_no_network' }) end

    local stop_type = GetStationType(stop)
    if stop_type == station_type.depot then
        diagnose_depot(stop, player)
    elseif stop_type == station_type.fuel_stop then
        diagnose_fuel_station(stop, player)
    else
        diagnose_station(stop, player)
    end

    if #stop.active_deliveries > 0 then
        local trains = {}
        for _, train_id in pairs(stop.active_deliveries) do
            local delivery = dispatcher.Deliveries[train_id]
            if delivery and delivery.train and delivery.train.valid then
                trains[#trains + 1] = tools.richTextForTrain(delivery.train)
            end
        end
        say(player, { 'console.diag_deliveries', table.concat(trains, ', ') })
    end
end

---@param player LuaPlayer
local function diagnose_summary(player)
    local dispatcher = tools.getDispatcher()
    local total, depots, fuel, stations = 0, 0, 0, 0
    local zero_network = {}

    for _, stop in pairs(storage.LogisticTrainStops) do
        if tools.isStopConsistent(stop) then
            total = total + 1
            local stop_type = GetStationType(stop)
            if stop_type == station_type.depot then
                depots = depots + 1
            elseif stop_type == station_type.fuel_stop then
                fuel = fuel + 1
            else
                stations = stations + 1
            end
            if stop.network_id == 0 then zero_network[#zero_network + 1] = tools.richTextForStop(stop.entity) end
        end
    end

    local free = 0
    for _, train in pairs(dispatcher.availableTrains) do
        if train.train.valid then free = free + 1 end
    end

    say(player, { 'console.diag_summary', tostring(total), tostring(depots), tostring(fuel), tostring(stations), tostring(free),
        tostring(table_size(dispatcher.Deliveries)), tostring(LtnSettings.default_network),
        LtnSettings.dispatcher_enabled and { 'console.diag_on' } or { 'console.diag_off' } })

    if #zero_network > 0 then
        local shown = {}
        for i = 1, math.min(10, #zero_network) do shown[i] = zero_network[i] end
        say(player, { 'console.diag_summary_zero_network', tostring(#zero_network), table.concat(shown, ', ') })
    end

    say(player, { 'console.diag_hint' })
end

---@param entity any
---@return ltn.TrainStop?
local function ltn_stop_from_entity(entity)
    if type(entity) ~= 'userdata' or entity.object_name ~= 'LuaEntity' or not entity.valid then return nil end
    if not ltn_stop_entity_names[entity.name] then return nil end
    local stop = storage.LogisticTrainStops[entity.unit_number]
    return (stop and tools.isStopConsistent(stop)) and stop or nil
end

---@param data CustomCommandData
local function diagnose(data)
    local player = data.player_index and game.get_player(data.player_index) or nil
    if not player then return end

    local name = data.parameter and data.parameter:match('^%s*(.-)%s*$') or ''
    if #name > 0 then
        local found = false
        for _, stop in pairs(storage.LogisticTrainStops) do
            if tools.isStopConsistent(stop) and stop.entity.backer_name == name then
                found = true
                diagnose_stop(stop, player)
            end
        end
        if not found then say(player, { 'console.diag_not_found', name }) end
        return
    end

    -- the stop under the cursor, or the stop whose GUI is open
    local stop = ltn_stop_from_entity(player.selected) or ltn_stop_from_entity(player.opened)
    if stop then
        diagnose_stop(stop, player)
    else
        diagnose_summary(player)
    end
end

function Console:registerCommands()
    commands.add_command('ltn-list-refuel-excluded', { 'console.ltn_command_list_refuel_excluded' }, list_refuel_excluded)
    commands.add_command('ltn-list-default-network-id', { 'console.ltn_command_list_default_network_id' }, list_default_network_id)
    commands.add_command('ltn-list-no-network-id', { 'console.ltn_command_list_zero_network_id' }, list_zero_network_id)
    commands.add_command('ltn-diagnose', { 'console.ltn_command_diagnose' }, diagnose)
end

return Console
