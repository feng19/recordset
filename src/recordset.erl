-module(recordset).

-author('David Reid <dreid@mochimedia.com>').
-copyright('2011 Mochi Media, Inc.').

-export_type([recordset/0]).

-record(recordset, {
          max_size :: undefined | pos_integer(),
          identity_function :: cmp_fun(),
          sort_function :: cmp_fun(),
          set = [] :: list()
         }).

-opaque recordset() :: #recordset{}.
-type cmp_fun() :: {fun((term(), term()) -> boolean())}.
-type option() :: {atom(), term()}.

-export([new/3, to_list/1, add/2]).

-spec new(cmp_fun(), cmp_fun(), [option()]) -> recordset().
new(IdentityFun, SortFun, Options) ->
    #recordset{max_size=proplists:get_value(max_size, Options),
               identity_function=IdentityFun,
               sort_function=SortFun}.



-spec add(term(), recordset()) -> recordset().
add(Term, RecordSet = #recordset{set=[]}) ->
    RecordSet#recordset{set=[Term]};
add(Term, RecordSet = #recordset{
            max_size=MaxSize,
            identity_function=IdentityFun,
            sort_function=SortFun,
            set=Set}) ->
    Set1 = case add_1(Term, IdentityFun, SortFun, Set) of
               Set0 when is_integer(MaxSize),
                         length(Set0) > MaxSize ->
                   truncate(Set0, length(Set0) - MaxSize);
               Set0 ->
                   Set0
           end,
    RecordSet#recordset{set=Set1}.

add_1(Term, IdentityFun, SortFun, [H | Set] = FullSet) ->
    case SortFun(Term, H) of
        true ->
            case IdentityFun(Term, H) of
                true ->
                    FullSet;
                false ->
                    [Term | FullSet]
            end;
        false ->
            case IdentityFun(Term, H) of
                true ->
                    add_1(Term, IdentityFun, SortFun, Set);
                false ->
                    [H | add_1(Term, IdentityFun, SortFun, Set)]
            end
    end;
add_1(Term, _IdentityFun, _SortFun, []) ->
    [Term].



-spec to_list(recordset()) -> list().
to_list(#recordset{set=Set}) ->
    Set.



truncate(S, 0) ->
    S;
truncate([_H | Set], I) ->
    truncate(Set, I-1).
