---
name: ns-android-debug
description: Debug the NS Android app (QA/debug build) - read logcat, find network/serialization errors (e.g. autosuggest v2/locations parsing), and compare API responses to the app's models. Use when the user wants to see why the NS app fails to parse or show API results.
---

# NS Android app debugging

Sources: `/Users/andre/Develop/NS/Android/ns-app-android`

Package ids: `nl.ns.android.activity` (prod), `.debug`, `.qa` suffixes.

## Logs

Use the helper script `nsdebug` (in `~/dotfiles/scripts`, on PATH):

```
nsdebug [qa|debug|prod] [all|errors|network|parse|crash|dump] [extra-regex]
```

- `nsdebug qa parse` - serialization / `NetworkException` failures
- `nsdebug qa network` - OkHttp request lines (BASIC level, no bodies)
- `nsdebug qa dump parse` - one-off dump of the buffer, non-following

Requires a connected device/emulator (`adb devices`) and the app running.
When using the agent, run it with `dump` mode (or a timeout) so it does not follow forever.

## Raw HTTP bodies

Chucker is built in (QA/debug builds). Open its notification in the app to see
request/response bodies. OkHttp logging is only `BASIC`.

## Parsing errors

Errors look like:
`NetworkException$Serialization: Field 'X' is required for type with serial name 'T' ... at path: $[N]`
- `$[N]` is the zero-based index in the response array. One bad item fails the whole list.

Autosuggest models: `plugin/autosuggest/src/main/kotlin/nl/ns/plugin/autosuggest/search/data/model/LocationResponse.kt`
- Json config in `search/data/api/AutosuggestApiService.kt` (`ignoreUnknownKeys`, `isLenient`,
  discriminator `locationType`).
- Mapping in `search/data/mapper/LocationResponseMapper.kt` (stations are looked up by `uicCode` in
  the local DB; unknown ones are silently dropped).

Required fields (no default) cause failures when missing: `description` for POI/OV_FIETS/PARK_AND_RIDE,
`geoLocation`/`nearbyMeLocationId` for all except POI, address fields, `stopType`/`stopCode`,
`stationCode`/`uicCode`.

## Workflow

1. Run `nsdebug qa parse` while reproducing in the app.
2. Take the `$[N]` index, fetch the same response (Chucker or curl) and inspect item N.
3. Compare with the model above to find the missing/mistyped field.
