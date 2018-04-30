%%------------------------------------------------------------------------------
%% @author kuba.odias
%% @copyright relayr 2009-2018
%% @doc Types used for time utilities.
%% @end
%%------------------------------------------------------------------------------

-ifndef(time_utils_hrl).

-define(time_utils_hrl, true).

%%------------------------------------------------------------------------------
%% Include files
%%------------------------------------------------------------------------------

%%------------------------------------------------------------------------------
%% Types
%%------------------------------------------------------------------------------
-type ts()				:: non_neg_integer().
-type now()				:: calendar:t_now().
-type localtime()		:: {{1970..10000,1..12,1..31},{0..23,0..59,0..59,0..999999}} | 
                           nonempty_string().

%%------------------------------------------------------------------------------
%% Macros
%%------------------------------------------------------------------------------

-endif.