# LTN Console

## Explain why a stop is not working - `/ltn-diagnose [stop name]`

Hover an LTN stop (or open its GUI) and run `/ltn-diagnose`, or pass the stop name as a parameter. LTN prints:

- the stop's role (depot, provider/requester, fuel station) and network(s),
- problems such as a missing network id, a wiring error, or a disabled stop,
- for providers/requesters: every item and fluid signal reaching the lamp and whether it is above or below the request/provide threshold, the thresholds and length limits in effect, and how many depots and free trains exist in the stop's network,
- for depots: whether a train is parked and whether LTN knows about it,
- for fuel stations: the refuel thresholds,
- trains currently on deliveries to or from the stop.

Without a target it prints a summary of the whole network: stop counts by role, free trains, running deliveries, the default network id, and stops without a network id.

## List locomotives excluded from refueling - `/ltn-list-refuel-excluded`

Lists all locomotives that are not refueled by the internal refuel stations. These locomotives have been registered through the `exclude_from_fuel_schedule` API.

## List all stops that do not have a network id - `/ltn-list-no-network-id`

Lists all LTN stops that do not have a network id supplied. This is relevant if the default network id is 0 (recommended setting) and no network id signal is supplied (either missing from the circuit network or a connected combinator has been turned off).

## List all stops that use the default network id - `/ltn-list-default-network-id`

Lists all LTN stops that use the default network id. This is only relevant if the default network id is not 0. All stops that either have a circuit signal supplying the default network id or no circuit signal supplying a network id are listed (if no network id signal is present, the default network id is used).
