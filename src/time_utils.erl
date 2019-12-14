%%------------------------------------------------------------------------------
%% @author kuba.odias
%% @copyright relayr 2009-2018
%% @doc Miscellaneous time conversion utilities.
%% @end
%%------------------------------------------------------------------------------
-module(time_utils).

%%------------------------------------------------------------------------------
%% Include files
%%------------------------------------------------------------------------------
-include("../include/time_utils.hrl").

%%------------------------------------------------------------------------------
%% Function exports
%%------------------------------------------------------------------------------
-export([
    get_os_timestamp/0,
    get_os_timestamp_in_microseconds/0,
    get_unix_timestamp/0,
    get_localtime/0,
    get_localtime/1,
    now_to_localtime/2,
    get_universal_time/0,
    get_universal_time/1,
    now_to_universal_time/2,
    correct_time/2,
    get_erl_ts_from_microseconds/1,
    unix_timestamp_to_rfc1123_string/1,
    datetime_to_epoch_seconds/1,
    epoch_seconds_to_datetime/1,
    millis/1,
    convert_timestamp/1
]).

%%------------------------------------------------------------------------------
%% Macros
%%------------------------------------------------------------------------------
-define(GREGORIAN_SECONDS_1970, calendar:datetime_to_gregorian_seconds({{1970, 1, 1}, {0,0,0}})).

%%------------------------------------------------------------------------------
%% Records
%%------------------------------------------------------------------------------

%%------------------------------------------------------------------------------
%% Types
%%------------------------------------------------------------------------------

-export_type([ts/0]).

%% =============================================================================
%% Exported functions
%% =============================================================================

%% @doc Get current OS timestamp in milliseconds. @end
-spec get_os_timestamp() -> Timestamp :: ts().
get_os_timestamp()->
    {MegaSecs, Secs, MicroSecs} = os:timestamp(),
    TimestampInMiliseconds = MegaSecs * 1000000000 + 1000*Secs + (MicroSecs div 1000),
    TimestampInMiliseconds.

%% @doc Get current OS timestamp in microseconds.
-spec get_os_timestamp_in_microseconds() -> Timestamp :: ts().
get_os_timestamp_in_microseconds() ->
	{MegaSecs, Secs, MicroSecs} = os:timestamp(),
    MegaSecs * 1000000000000 + Secs * 1000000 + MicroSecs.

%% @doc Get current OS timestamp in seconds.
-spec get_unix_timestamp() -> Timestamp :: ts().
get_unix_timestamp() ->
    {MegaSecs, Secs, _MicroSecs} = os:timestamp(),
    MegaSecs * 1000000 + Secs.

%% @doc Get local time (not formatted).
-spec get_localtime() -> LocalTime :: localtime().
get_localtime() ->
    get_localtime(false).

%% @doc Get local time formatted or not.
-spec get_localtime(FormatTime :: boolean()) -> LocalTime :: localtime().
get_localtime(FormatTime) ->
    now_to_localtime(os:timestamp(), FormatTime).

%% @doc Convert erlang:timestamp() tuple to a local date and time format.
-spec now_to_localtime(ErlangNow :: now(), FormatTime :: boolean()) -> LocalTime :: localtime(). 
now_to_localtime(ErlangNow, false) ->
    {Date, {H,M,S}} = calendar:now_to_local_time(ErlangNow),
    {_, _, MicroSecs} = ErlangNow,
    {Date, {H,M,S,MicroSecs}};
now_to_localtime(ErlangNow, true) ->
    {{Year, Month, Day}, {Hour, Minute, Second, MicroSec}} = now_to_localtime(ErlangNow, false),
    lists:flatten(    
        io_lib:format("~4.10.0b-~2.10.0b-~2.10.0b,~2.10.0b:~2.10.0b:~2.10.0b.~p",
            [Year, Month, Day, Hour, Minute, Second, MicroSec])
        ).

%% @doc Get universal time (not formatted).
-spec get_universal_time() -> UniversalTime :: localtime().
get_universal_time() ->
    get_universal_time(false).

%% @doc Get universal time  formatted or not.
-spec get_universal_time(FormatTime :: boolean()) -> UniversalTime :: localtime().
get_universal_time(FormatTime) ->
    now_to_universal_time(os:timestamp(), FormatTime).

%% @doc Convert erlang:timestamp() tuple to a universal date and time format.
-spec now_to_universal_time(ErlangNow :: now(), FormatTime :: boolean()) -> UniversalTime :: localtime(). 
now_to_universal_time(ErlangNow, false) ->
    {Date, {H,M,S}} = calendar:now_to_universal_time(ErlangNow),
    {_, _, MicroSecs} = ErlangNow,
    {Date, {H,M,S,MicroSecs}};
now_to_universal_time(ErlangNow, true) ->
    {{Year, Month, Day}, {Hour, Minute, Second, MicroSec}} = now_to_universal_time(ErlangNow, false),
    lists:flatten(    
        io_lib:format("~4.10.0b-~2.10.0b-~2.10.0b,~2.10.0b:~2.10.0b:~2.10.0b.~6.10.0b",
            [Year, Month, Day, Hour, Minute, Second, MicroSec])
        ).

-spec get_erl_ts_from_microseconds(T :: ts()) -> erlang:timestamp().
get_erl_ts_from_microseconds(T) ->
    Mega = T div (1000000 * 1000000),
    T0 = T - Mega * (1000000 * 1000000),
    Secs = T0 div 1000000,
    Micros = T0 rem 1000000,
    {Mega, Secs, Micros}.

-spec unix_timestamp_to_rfc1123_string(T :: ts()) -> string().
unix_timestamp_to_rfc1123_string(T)->
    httpd_util:rfc1123_date(calendar:now_to_local_time(get_erl_ts_from_microseconds(T*1000000))).

%% @doc Add diff to given time.
%% -spec correct_time(Time :: now(), Diff :: now()) -> NewTime :: now().
correct_time({MegaSecs, Secs, MicroSecs}, {0, 0, 0}) when MicroSecs >= 1000000 ->
    correct_time({MegaSecs, Secs + MicroSecs div 1000000, MicroSecs rem 1000000}, {0, 0, 0});
correct_time({MegaSecs, Secs, MicroSecs}, {0, 0, 0}) when MicroSecs < 0 ->
    correct_time({MegaSecs, Secs - 1, 1000000 + MicroSecs}, {0, 0, 0});
correct_time({MegaSecs, Secs, MicroSecs}, {0, 0, 0}) when Secs >= 1000000 ->
    correct_time({MegaSecs + Secs div 1000000, Secs rem 1000000, MicroSecs}, {0, 0, 0});
correct_time({MegaSecs, Secs, MicroSecs}, {0, 0, 0}) when Secs < 0 ->
    correct_time({MegaSecs - 1, 1000000 + Secs, MicroSecs}, {0, 0, 0});
correct_time(Time, {0, 0, 0}) ->
    Time;
correct_time({MegaSecs, Secs, MicroSecs}, {DiffMegaSecs, DiffSecs, DiffMicroSecs}) ->
    correct_time({MegaSecs + DiffMegaSecs, Secs + DiffSecs, MicroSecs + DiffMicroSecs}, {0, 0, 0}).

-spec datetime_to_epoch_seconds(DateTime :: calendar:datetime()) -> ts().
datetime_to_epoch_seconds(DateTime) ->
    calendar:datetime_to_gregorian_seconds(DateTime) - ?GREGORIAN_SECONDS_1970.

-spec epoch_seconds_to_datetime(Seconds :: ts()) -> calendar:datetime().
epoch_seconds_to_datetime(Seconds) ->
    calendar:gregorian_seconds_to_datetime(Seconds + ?GREGORIAN_SECONDS_1970).

-spec convert_timestamp(IsoDateTime :: iodata() | integer() | undefined) -> TsInMillis :: ts() | undefined.
convert_timestamp(undefined) ->
    undefined;
convert_timestamp(Timestamp) when is_integer(Timestamp), Timestamp < 0 ->
    erlang:throw({error, 400, <<"Bad timestamp. Expected valid ISO date or milliseconds number">>});
convert_timestamp(Timestamp) when is_integer(Timestamp), Timestamp >= 0->
    case is_max_unix_time_2038_year(Timestamp) of
        true ->
            erlang:throw({error, 400, <<"Warning. Max allowed timestamp 2038 year: 2147468400000 milliseconds">>});
        false ->
            Timestamp
    end;
convert_timestamp(IsoDateTime) ->
    iso8601_to_millis(IsoDateTime).

-spec iso8601_to_millis(IsoDateTime :: iodata()) -> TsInMillis :: ts().
iso8601_to_millis(IsoDateTime) ->
    try
        {Date, {H, M, FloatSeconds}} = iso8601:parse_exact(IsoDateTime),
        Seconds = trunc(FloatSeconds),
        Millis = round((FloatSeconds - Seconds) * 1000),
        TsInSeconds = datetime_to_epoch_seconds({Date, {H, M, Seconds}}),
        TsInSeconds * 1000 + Millis
    catch
        error:badarg ->
            erlang:throw({error, 400, <<"Not an ISO-8601 timestamp">>})
    end.

millis(N) when is_integer(N) -> N * 1000;
millis({N, s}) -> N * 1000;
millis({N, ms}) -> N.

%% =============================================================================
%% Local functions
%% =============================================================================

-spec is_max_unix_time_2038_year(Timestamp :: ts()) -> false | true.
is_max_unix_time_2038_year(Timestamp) when Timestamp > 2147468400000 ->
    true;
is_max_unix_time_2038_year(_Timestamp) ->
    false.