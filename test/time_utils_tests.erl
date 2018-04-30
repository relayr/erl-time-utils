%%------------------------------------------------------------------------------
%% @author kuba.odias
%% @copyright relayr 2009-2018
%%------------------------------------------------------------------------------
-module(time_utils_tests).

%%------------------------------------------------------------------------------
%% Include files
%%------------------------------------------------------------------------------

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

%% =============================================================================
%% Unit tests
%% =============================================================================

millis_test() ->
    ?assertEqual(1000, time_utils:millis(1)),
    ?assertEqual(1000, time_utils:millis({1000, ms})),
    ?assertEqual(1000, time_utils:millis({1, s})).

correct_time_test() ->
	?assertEqual({1,2,3}, time_utils:correct_time({1,2,3}, {0,0,0})),
	?assertEqual({1,2,3}, time_utils:correct_time({0,0,0}, {1,2,3})),
	?assertEqual({1,2,0}, time_utils:correct_time({1,2,3}, {0,0,-3})),
	?assertEqual({1,1,999999}, time_utils:correct_time({1,2,3}, {0,0,-4})),
	?assertEqual({1,3,0}, time_utils:correct_time({1,2,999993}, {0,0,7})),
	?assertEqual({2,4,1}, time_utils:correct_time({1,2,999993}, {1,0,1000008})),
	?assertEqual({1,0,999999}, time_utils:correct_time({1,2,3}, {0,0,-1000004})),
	?assertEqual({0,999999,999999}, time_utils:correct_time({1,2,3}, {0,0,-2000004})),
	?assertEqual({-2,999998,999999}, time_utils:correct_time({2,3,4}, {-3,-4,-5})).

datetime_to_epoch_seconds_test() ->
    Ts = 1388661914,
    DateTime = {{2014, 1, 2}, {11, 25, 14}},
    ?assertEqual(Ts, time_utils:datetime_to_epoch_seconds(DateTime)).

epoch_seconds_to_datetime_test() ->
    Ts = 1388662283,
    DateTime = {{2014, 1, 2}, {11, 31, 23}},
    ?assertEqual(DateTime, time_utils:epoch_seconds_to_datetime(Ts)).

now_to_localtime_test() ->
    % get difference between local and universal time
    TsUTC = {{2000,1,1},{0,0,0}},
    Ts = calendar:universal_time_to_local_time(TsUTC),
    {DaysDiff, {HourDiff, MinsDiff, SecsDiff}} = calendar:time_difference(TsUTC, Ts),
    TotalSecsDiff =
        DaysDiff * 24 * 60 * 60 +
        HourDiff * 60 * 60 +
        MinsDiff * 60 +
        SecsDiff,

    % 1388662283 -> 2014-01-02,11:31:23 UTC
    {MegaSecs, Secs, MicroSecs} = {1388, 662283, 342651},
    TotalSecs = MegaSecs * 1000000 + Secs - TotalSecsDiff,
    % add time correction
    MegaSecsCorrected = TotalSecs div 1000000,
    SecsCorrected = TotalSecs - MegaSecsCorrected * 1000000,
    NowUTC = {MegaSecsCorrected, SecsCorrected, MicroSecs},

    % actual test
    ?assertEqual({{2014, 1, 2}, {11, 31, 23, 342651}}, time_utils:now_to_localtime(NowUTC, false)),
    ?assertEqual("2014-01-02,11:31:23.342651", time_utils:now_to_localtime(NowUTC, true)).

get_erl_ts_from_microseconds_test() ->
    ?assertEqual({0,0,0}, time_utils:get_erl_ts_from_microseconds(0)),
    ?assertEqual({1396,251976,790046}, time_utils:get_erl_ts_from_microseconds(1396251976790046)).

unix_timestamp_to_rfc1123_string_test() ->
    ?assertEqual("Thu, 01 Jan 1970 00:00:00 GMT", time_utils:unix_timestamp_to_rfc1123_string(0)),
    ?assertEqual("Fri, 25 Apr 2014 10:52:08 GMT", time_utils:unix_timestamp_to_rfc1123_string(1398423128)).

get_timestamp_test() ->
    TsMs = time_utils:get_os_timestamp(),
    TsUs = time_utils:get_os_timestamp_in_microseconds(),
    TsS = time_utils:get_unix_timestamp(),
    % compare timestamps in seconds
    ok = compare_timestamps(TsS, TsMs div 1000),
    ok = compare_timestamps(TsS, TsUs div 1000000).

convert_timestamp_test() ->
    ?assertEqual(undefined, time_utils:convert_timestamp(undefined)),
    Ts0 = 0,
    ?assertEqual(Ts0, time_utils:convert_timestamp(Ts0)),
    Ts1 = 1396252079000,
    ?assertEqual(Ts1, time_utils:convert_timestamp(Ts1)),
    Ts2 = 1330519032000,    % leap year
    ?assertEqual(Ts2, time_utils:convert_timestamp(Ts2)),
    Ts3 = 2450234098000,
    ?assertThrow({error, 400, <<"Warning. Max allowed timestamp 2038 year: 2147468400000 milliseconds">>}, time_utils:convert_timestamp(Ts3)),
    Ts4 = -1,
    ?assertThrow({error, 400, <<"Bad timestamp. Expected valid ISO date or milliseconds number">>}, time_utils:convert_timestamp(Ts4)),

    % ISO 8601 dates
    Date0 = "1970-01-01T01:00:00+01:00",
    ?assertEqual(Ts0, time_utils:convert_timestamp(Date0)),
    Date1 = "2014-03-31T09:47:59+02:00",
    ?assertEqual(Ts1, time_utils:convert_timestamp(Date1)),
    Date2 = "2012-02-29T13:37:12+01:00",    % leap year
    ?assertEqual(Ts2, time_utils:convert_timestamp(Date2)),
    Date3 = "2047-08-24T04:34:58",
    ?assertEqual(Ts3, time_utils:convert_timestamp(Date3)),
    Date4 = "Wed, 29 Feb 2012 13:37:12 +01:00",
    ?assertThrow({error, 400, <<"Not an ISO-8601 timestamp">>}, time_utils:convert_timestamp(Date4)).

now_to_universaltime_test() ->
    Now1 = {0,0,0},
    Now2 = {1396,252079,61387},
    % leap year
    Now3 = {1330,519032,123456},
    ?assertEqual({{1970,1,1}, {0,0,0,0}}, time_utils:now_to_universal_time(Now1, false)),
    ?assertEqual({{2014,3,31},{7,47,59,61387}}, time_utils:now_to_universal_time(Now2, false)),
    ?assertEqual({{2012,2,29},{12,37,12,123456}}, time_utils:now_to_universal_time(Now3, false)),
    ?assertEqual("1970-01-01,00:00:00.000000", time_utils:now_to_universal_time(Now1, true)),
    ?assertEqual("2014-03-31,07:47:59.061387", time_utils:now_to_universal_time(Now2, true)),
    ?assertEqual("2012-02-29,12:37:12.123456", time_utils:now_to_universal_time(Now3, true)).

%% =============================================================================
%% Local functions
%% =============================================================================

compare_timestamps(Ts1, Ts2) ->
    % timestamps in test should differ by no more than 1 second
    compare_timestamps(Ts1, Ts2, 1).

compare_timestamps(Ts1, Ts2, MaxDelta) when Ts1 > Ts2 ->
    compare_timestamps(Ts2, Ts1, MaxDelta);
compare_timestamps(Ts1, Ts2, MaxDelta) ->
    ?assert(Ts2 - Ts1 =< MaxDelta).

-endif.
