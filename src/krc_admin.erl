%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc Ops tools.
%%% @end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%_* Module declaration ===============================================
-module(krc_admin).

%%%_* Exports ==========================================================
-export([ list/5
        , list/7
        , update/3
        , update/4
        , update/6
	]).

%%%_* Includes =========================================================
-include_lib("stdlib2/include/prelude.hrl").

%%%_* Code =============================================================
%%%_ * API -------------------------------------------------------------
%% @equiv
%% list(Bucket, '$bucket', {match '$bucket'}, KeyPred, ValPred, KeyOrd, ValOrd)
list(Bucket, KeyPred, ValPred, KeyOrd, ValOrd) ->
  list(Bucket, '$bucket,', {match, '$bucket'}, KeyPred, ValPred, KeyOrd, ValOrd).

%% @doc List all objects matching IdxKey in Idxx of Bucket, for whose
%% keys KeyPred returns true and for whose values ValPred returns true.
%% The output is a list of objects sorted first by KeyOrd applied to
%% their keys, then ValOrd applied to their values.
list(Bucket, Idx, IdxKey, KeyPred, ValPred, KeyOrd, ValOrd) ->
  sort(do_list(Bucket, Idx, IdxKey, KeyPred, ValPred),
       KeyOrd,
       ValOrd).

%% @doc Update object Key in Bucket.
update(Bucket, Key, F) ->
  do_update(?unlift(krc:get(krc_server, Bucket, Key)), F).

%% @equiv update(Bucket, '$bucket', {match, '$bucket'}, KeyPred, ValPred, F)
update(Bucket, KeyPred, ValPred, F) ->
  update(Bucket, '$bucket', {match, '$bucket'}, KeyPred, ValPred, F).

%% @doc Update all objects matching IdxKey in Idx of Bucket.
update(Bucket, Idx, IdxKey, KeyPred, ValPred, F) ->
  _ = [ok = do_update(Obj, F) ||
        Obj <- do_list(Bucket, Idx, IdxKey, KeyPred, ValPred)],
  ok.

%%%_ * Internals -------------------------------------------------------
do_list(Bucket, Idx, IdxKey, KeyPred, ValPred) ->
  {ok, Keys} = krc:get_index_keys(krc_server, Bucket, Idx, IdxKey),
  lists:flatmap(
    fun(K) ->
      {ok, Obj} = krc:get(krc_server, Bucket, K),
      case ValPred(krc_obj:val(Obj)) of
        true  -> [Obj];
        false -> []
      end
    end, [K || K <- Keys, KeyPred(K)]).

sort(Objs, KeyOrd, ValOrd) ->
  lists:sort(
    fun(Obj1, Obj2) -> ValOrd(krc_obj:val(Obj1), krc_obj:val(Obj2)) end,
    lists:sort(
      fun(Obj1, Obj2) -> KeyOrd(krc_obj:key(Obj1), krc_obj:key(Obj2)) end,
      Objs)).

do_update(Obj, F) ->
  krc:put(krc_server, krc_obj:set_val(Obj, F(krc_obj:val(Obj)))).

%%%_* Tests ============================================================
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

-endif.

%%%_* Emacs ============================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
