# Factorio - Logistic Train Network

Factorio mod adding "logistic-train-stops" acting as anchor points for building a train powered logistic network.

You tell each stop what it has and what it needs with circuit signals. LTN picks a free train from a depot, writes its schedule, sends it to a provider and then to the requester, and brings it back. It can handle multiple train configurations and will pick the best available train for a delivery.

This is a fork of [hgschmie/factorio-LogisticTrainNetwork](https://github.com/hgschmie/factorio-LogisticTrainNetwork) focused on making LTN easier to pick up. See the [changelog](changelog.txt) for what differs.

## Quick start: your first delivery

You need three stops and one train. Every stop is a **Logistic Train Stop** (research "Logistic Train Network"). When you place one, a small lamp (the **input**) and a combinator (the **output**) appear next to it. **All signals go into the lamp.** Never wire the lamp, the output and the stop itself together.

1. **Depot.** Place a stop, name it `Depot`. Put a constant combinator next to it, set the signal `LTN Depot` = 1, and wire the combinator to the stop's lamp. A depot is where idle trains wait.
2. **Train.** Build a train with at least one cargo wagon. Give it a schedule with **only** the `Depot` stop (no wait condition needed) and set it to automatic. When it arrives at the depot, LTN takes it over. The depot lamp turns blue.
3. **Provider.** Place a stop at your iron plate output, name it `Iron pickup`. Wire the chests that hold the plates to the stop's lamp. A **positive** signal (for example `iron-plate` = 4000) means "I have this to give away".
4. **Requester.** Place a stop where you need plates, name it `Iron dropoff`. Put a constant combinator with `iron-plate` = **-4000** next to it, wire the combinator **and** the unloading chests to the lamp. A **negative** total means "I need this". The chests' contents are added, so the request shrinks as the chests fill.
5. **Thresholds.** LTN only acts when a request is at least 1000 items and a provider has at least 1000 items (map settings "Request threshold" and "Provide threshold"). The numbers above clear both. You can override them per stop with the `LTN Request Threshold` and `LTN Provide Threshold` signals.
6. **Network.** All stops without an `LTN Network ID` signal share network 1 (map setting "Default network ID"). Nothing more to do for a single network.

Within a few seconds you will see `[LTN] Creating delivery from Iron pickup to Iron dropoff` in chat and the train leaves. Lamp colours: green = idle, yellow = a delivery is on its way, blue = a train is parked, red = wiring error or disabled.

If nothing happens, hover the stop and run `/ltn-diagnose` in the console. It tells you what the stop sees, whether it is below a threshold, and whether a depot with a free train exists in its network.

## How it works

| Term | Meaning |
|------|---------|
| **Depot** | A stop that receives `LTN Depot` ≥ 1. Trains wait here between deliveries. A train becomes an LTN train by arriving at a depot in automatic mode with only the depot in its schedule. LTN overwrites the schedule from then on. |
| **Provider** | A stop whose lamp receives a positive item or fluid signal of at least the provide threshold. |
| **Requester** | A stop whose lamp receives a negative item or fluid signal of at least the request threshold. A stop can provide some items and request others at the same time. |
| **Threshold** | Minimum amount before LTN acts. Map setting (default 1000 each) or per stop via the threshold signals. Keeps trains from running half empty. |
| **Network ID** | A bitmask that groups stops, depots and trains. 1, 2, 4, 8 ... are separate networks; 3 means "1 and 2"; -1 means all. Trains only serve stops that share a bit with their depot. Set per stop with `LTN Network ID`, otherwise the map default (1) applies. 0 means "no network", such a stop is ignored. |
| **Delivery** | One trip: depot → provider (load) → requester (unload) → depot. LTN adds wait conditions for the exact amounts and a 2-second inactivity wait so inserters finish. |
| **Stop timeout** | If loading or unloading takes longer than 120 seconds (map setting) the train is forced out and you get a "missing cargo" or "left over cargo" alert. |
| **Locked slots** | `LTN Locked Slots per Wagon` tells LTN how many slots per wagon it may not fill, for filtered or reserved wagon slots. |
| **Priority** | `LTN Request Priority` / `LTN Provide Priority` / `LTN Depot Priority`: higher is served or chosen first. |
| **Train length** | `LTN Minimum Train Length` / `LTN Maximum Train Length` restrict which trains may use a stop (locomotives + wagons). |
| **Max trains** | `LTN Max Trains to this Stop` limits how many trains may be on their way to a stop at once. |

All LTN signals have tooltips in the signal picker. The [LTN Combinator Modernized](https://mods.factorio.com/mod/LTN_Combinator_Modernized) mod gives you a GUI to set them without a constant combinator. [LTN Manager](https://mods.factorio.com/mod/LtnManager) shows every stop, train and delivery in one window.

## Troubleshooting

| Message or symptom | Cause | Fix |
|--------------------|-------|-----|
| `... has no network ID (network 0)` | The stop has no `LTN Network ID` signal and the map setting "Default network ID" is 0. | Set the map setting to 1, or send the signal. `/ltn-list-no-network-id` lists all such stops. |
| `no stop currently provides X` | No provider has at least the provide threshold of X in a shared network, or the provider's lamp is not wired to the chests. | Check the provider with `/ltn-diagnose`; lower the threshold or add stock. |
| `N stop(s) provide X but none can be used: ...` | Providers exist but something blocks each one. The list says why: network mismatch, stop is full, train too short, unreachable ... | Fix the listed reason. "Unreachable" means no rail path from the depot: check signals and track. |
| `no free train ... parked at a depot` | No train is waiting at a depot in that network, or the trains there have the wrong wagon type. | Park a train at a depot in automatic mode. Check the depot lamp is blue. |
| `there is no depot in network N` | No stop with `LTN Depot` shares a network bit with the requester. | Add the depot signal to a stop, give it a matching network ID. |
| `Stop X wants N x Y but its request threshold is T` | The request is smaller than the threshold. | Request more, send `LTN Request Threshold` to the stop, or lower the map setting. |
| `Stop X is wired incorrectly` (lamp red) | The stop, its lamp and its output are on the same circuit network. | Wire only the lamp. Remove wires between lamp, output and stop. |
| `Train X stopped at LTN stop Y without a delivery` | A train in automatic mode arrived at a provider or requester that LTN did not send. Usually the depot signal is missing on the stop you meant as depot. | Give the train a schedule with only the depot stop. |
| `Train X left provider Y with missing cargo` | Loading took longer than the stop timeout (120 s). | Faster inserters, bigger buffer, or raise the "Stop timeout" map setting. |
| `Train X left requester Y with cargo still on board` | Unloading took longer than the stop timeout, or the chests were full. | Faster inserters, more chest space, or raise the timeout. The cargo stays on the train and goes to the depot. |
| `Delivery ... removed: the train has not reached its next stop for N minutes` | Delivery timeout (10 min). The train is stuck, blocked or out of fuel. | Click the train in the message. Check fuel and signals. |
| `LTN is turned off` | The "LTN active" map setting is off (Ctrl+Shift+D toggles it). | Turn it back on. |
| Train arrives at the wrong stop with the same name | Stops share names and the game picked the nearest one. | Give LTN stops unique names, or let LTN handle it: it adds temporary waypoints, but refuel interrupts can still redirect trains. |

## FAQs

### I get error messages: "No station supplying ... found in networks 0x0"

LTN uses "Network Id" to allow creating multiple networks that can act separately. A lot of examples assume that there is only one network ("the LTN network"). When using only a single network, all stations have the same network id. The network id is provided either through a signal sent into the Station Lamp *OR* as a default setting in LTN. Many "getting started" examples assume that the stations get their station id from that default setting.

Up until 2.2.0, the default network id was "-1" (which actually translates to "all LTN networks"). This is fine, as long as there is only one network.

For more elaborate setups with multiple networks, this default value caused a problem: Any station that is built and that does not get an explicit network signal (e.g. through a LTN Combinator) will show up in "all LTN networks". This especially happens when the LTN combinator is fully configured but then turned *off*. So trains from all the networks will show up at the station because there was a signal *missing*. This was hard to reason about and hard to debug.

For that reason, the "default network id" was changed in release 2.2.0 from "-1" to "0". This fork changes it again to "1" for new maps: a newly built LTN train stop is part of network 1 unless there is an explicit network id signal sent into the station. If you run several networks and every station sends its own network id, set the default back to "0" so that a station with a missing signal does not join network 1 by accident.

If you see `No station supplying ... found in networks 0x0` or `has no network ID (network 0)`, go to `Settings -> Mod Settings -> Map -> LTN - Logistic Train Network -> "Default network ID"` and change the value from "0" to e.g. "1". You can also use the old default ("-1").

### I get error messages: "No train to transport from ... to ... in networks ..."

If trains with the right length are available and they are in the right network, then it is possible that the provider is not accessible from the depot. LTN checks whether it can send a train from the depot to the provider by asking the game to resolve the path and if no path exists, it drops the train.

Starting with 2.8.2, if multiple providers exist, LTN will retry with another provider. However, this still means that it is possible that you have a provider that is never accessed by a train. If this message persists and LTN consistently chooses another provider (especially if it is further away than the "best" provider, has the wrong priority or fewer items), check whether there is e.g. a rail signal on the wrong side of the track or a break in the track that leading to the provider. Messages contain clickable map tags to quickly navigate to the provider.

### What is 'Advanced Cross-Surface Delivery'?

If you are not using a expansion that allows trains to travel between surfaces (planets, moons, orbital etc.) such as [Space Exploration](https://mods.factorio.com/mod/space-exploration) and the [LTN - Space Exploration](https://mods.factorio.com/mod/ltn-space-exploration) mod, this setting is not for you and you should leave it off.

This setting is for games where the train network stretches across multiple surfaces *that are connected*. This is not true if you e.g. use the same network id on two planets (e.g. Gleba and Nauvis) that are not connected.

If you have a network across multiple surfaces, then normally a train can be dispatched to a provider on the same surface as the depot, go through the space elevator into orbit and deliver to a requester on a different surface, then return back to the depot on the original surface. LTN will not schedule anything else, the provider *must* be on the same surface as the depot.

With this setting, LTN will schedule trains to go through the space elevator first if necessary to pick up a delivery from a different surface. It may even schedule a delivery where both provider and requester are on a different surface as the depot. The train will still return to its original depot.

### I have a really large base with multiple networks and I see lag-spikes when LTN choose a train for delivery

Managing performance for LTN boils down to a single thing: Managing the cache that holds the precomputed routes between depot stops and providers. The better the cache hit rate is, the fewer actual route computations LTN has to do. This is a consequence of the 2.x introduction of [LuaTrainManager](https://lua-api.factorio.com/latest/classes/LuaTrainManager.html). There are a few settings that are most relevant here:

- `Performance: request updates per tick` controls how many trains are scheduled per tick. Each train requires some work so updating many trains per tick will lead to lags. For a larger base, leave at 1.
- `Performance: route cache lifetime (min)` controls how long a route is cached. If your network is fairly static (not a lot of changes to the rails), you can crank this up to the maximum (120 minutes). If your network is under construction (adding new routes, removing existing routes etc.), reduce it (the minimum is 2 minutes). The longer a route is cached, the fewer actual route lookups need to be done.
- `Performance: max trains considered per delivery` controls how many trains are evaluated to cover a route. This limits the size of the group of trains that can serve a route. Choosing from a subset may lead to slightly sub-optimal choices but in any case, if there is at least one eligible train, it will be chosen. For a large network, limit this to 5-10 trains.

[LTN - Space Exploration](https://mods.factorio.com/mod/ltn-space-exploration) fully supports this.

If you are using [Space Exploration LTN integration](https://mods.factorio.com/mod/se-ltn-glue), you need to verify that it was updated to support advanced scheduling, otherwise your trains will stall with "No path found".

### Train Schedule Interrupts (since 2.3.0)

Factorio 2.x trains support "Train Schedule Interrupts" which trigger under certain conditions. Starting with 2.3.0, LTN will not change any interrupts in the train schedule unless explicitly configured with the `ltn-schedule-reset-interrupts` setting.

### Refueling support (since 2.3.0)

Starting with 2.3.0, LTN supports a new station type: 'Fuel Station'. Fuel station support must be explicitly enabled by setting the `ltn-schedule-fuel-station` setting.

Similar to a depot, there is a virtual signal that declares a stop to be a fuel station. This stop needs to receive additional signals:

- A network id signal that describes for which networks this fuel station is valid. Use `-1` for all networks.
- Fuel signals ('coal', 'wood', 'solid fuel', 'rocket fuel', 'nuclear fuel' in the base game) with a value that is used as the threshold for refueling. A fuel station does not need to send only the signals for fuels that it provides; the signals are used to create the condition for the fuel interrupt.

E.g. a station that receives 'wood' = 250 and 'rocket-fuel' = 200 for network id 1 will create a refuel interrupt for all locomotives in the network 1 that will send any locomotive to this refuel stop if they use either wood or rocket fuel and the count drops under 250 for wood or 200 for rocket fuel.

If a station receives both the depot and the fuel station signal, it is considered a depot and will not be used as a fuel station.

A fuel station has a cyan-colored station lamp to signify that it is a fuel station. Starting with 2.5.0, if a fuel station has no actual fuel signal, it will turn its lamp grey.

Trains arriving at a fuel station will leave if either all locomotives are fully fueled or there are 120 ticks (two seconds) of inactivity. When a train leaves a fuel station, the refuel interrupt is temporarily removed (it gets re-added when the train arrives at a depot that is part of a network that supports refueling).

LTN refueling is very limited and only looks at the fuel count across all locomotives. By disabling the resetting of Train Schedule interrupts and the builtin refueling support, other mods can be used to control refueling without LTN interfering.

### Depot changing (since 2.3.0)

A train that is added to the LTN network will return to a depot when it finishes a delivery. If the 'ltn-schedule-reselect-depot' option is disabled, a train will always return to the depot it was assigned to (the depot that it was sent to when sit registered with the LTN network).

If this setting turned on and also 'ltn-dispatcher-requester-delivery-reset' is enabled, then LTN will, as soon as the train leaves the requester, select one of the depots that accepts trains in the current network at random. Trains may go to a different depot in that case. This is especially important if a depot serves multiple networks. A train that gets sent to a depot that serves multiple networks becomes eligible to requests in those networks (assuming that capacity, length etc. also match).

This setting has the potential to pile up trains in depots that are too small to accommodate all trains that are sent there. Use with caution.

### Controlling LTN Stops with the circuit network (or logistics network)

LTN stops are managed by the central dispatcher and require some settings that will be enforced. Each LTN stop will always have "Read train contents" and "Send to train" activated, even if no circuit network is connected.

The 'Priority' 'Enable/Disable', 'Read stopped train', 'Read train count' and 'Set priority' fields can be manually changed.

#### Depot stop train limits [Since 2.7.0]

LTN manages train limits for all stops automatically. For normal operations, it will remove any train limit (and disable setting through the circuit network) as this interferes with the dispatcher. For most stop types (requester, provider and fuel station), this can not be changed.

The train limit for depot stops can be modified by changing the startup option 'ltn-depot-stop-limit-trains'. There are three possible values:

- Reset Train Limit: This is the default. Depot stops behave like all other station types: Any limit is reset and can not be modified
- Set Train Limit to 1: Sets a limit of one train for each depot stop.
- Do not modify Train limit: LTN stops managing the train limit setting for depot stops and it can now managed like the other fields listed above.

#### Support locomotive types that do not need refueling

Some mods add locomotive types that do not need refueling. LTN now supports excluding such locomotives from refueling by exposing a remote API that is compatible to [Automatic Train Refueler](https://mods.factorio.com/mod/auto-train-refuel) or [Automatic Train Fuel Stop](https://mods.factorio.com/mod/FuelTrainStop).

By default, the mod automatically ignores electric locomotives named 'et-electric-locomotive-1', 'et-electric-locomotive-2' and 'et-electric-locomotive-3' which are provided by various mods that add electric trains.

### API

[LTN Settings Documentation](SETTINGS.md)
[LTN Console Documentation](CONSOLE.md)
[LTN API Documentation](API.md)
[LTN additional Documentation](MANUAL.md)

Starting with version 2.1.0, LTN supports quality for requester and provider signals. To support this, there are a few *minimal*, *backwards compatible* API changes. If you maintain a mod that uses the LTN remote API, the changes are documented [LTN API Documentation](API.md#changelog)

### Contact

- [Forum](https://mods.factorio.com/mod/LogisticTrainNetwork/discussion) (changed from pre-2.x!)
- [Upstream bug reports](https://github.com/hgschmie/factorio-LogisticTrainNetwork/issues)
- [Upstream source code](https://github.com/hgschmie/factorio-LogisticTrainNetwork)
- [Download](https://mods.factorio.com/mod/LogisticTrainNetwork/downloads)
- [Manual (on the LTN subforum)](https://forums.factorio.com/viewtopic.php?f=214&t=51072)

### How you can help

If you maintain an LTN mod and stopped working on it, consider porting it to 2.x!

----

## Legal

LTN is (C) 2017-2018 by Optera [under a restrictive license](LICENSE.md).

The 2.x port is maintained with permission by @hgschmie
