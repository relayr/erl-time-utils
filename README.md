# time_utils

[![Build Status](https://img.shields.io/github/workflow/status/relayr/erl-time-utils/Erlang%20CI)](https://github.com/relayr/erl-time-utils/actions?query=workflow%3A%22Erlang+CI%22) [![Hex.pm](https://img.shields.io/hexpm/v/time_utils.svg?style=flat)](https://hex.pm/packages/time_utils) [![Coverage Status](https://coveralls.io/repos/github/relayr/erl-time-utils/badge.svg?branch=master)](https://coveralls.io/github/relayr/erl-time-utils?branch=master)

Erlang time conversion utilities.

## Exported types

```
-type ts() :: non_neg_integer().
```

## Examples

Get current OS timestamp in milliseconds.
```
1> time_utils:get_os_timestamp().
1576132864898
```

Get current OS timestamp in seconds.
```
2> time_utils:get_unix_timestamp().
1576132898
```

Get current local date and time.
```
3> time_utils:get_localtime().
{{2019,12,12},{7,42,25,518036}}
```

Get current date and time in UTC.
```
4> time_utils:get_universal_time().
{{2019,12,12},{6,43,29,5331}}
```

Convert microseconds to Erlang's `now()` tuple.
```
5> time_utils:get_erl_ts_from_microseconds(1576132864898702).
{1576,132864,898702}
```

Convert UNIX timestamp to RFC1123 date format.
```
6> time_utils:unix_timestamp_to_rfc1123_string(1576132864).
"Thu, 12 Dec 2019 06:41:04 GMT"
```

Convert ISO8601 formatted time to timestamp in milliseconds.
```
7> time_utils:iso8601_to_millis("2019-12-19T13:37:12+01:00").
1576759032000
```
