:- module main.

:- interface.
:- import_module io.

:- pred main(io::di, io::uo) is det.

:- implementation.

:- func prog_name = string.
:- func prog_version = string.
:- func author = string.
:- func license_date = int.

prog_name = "aurobool".
prog_version = "v0.1.0".
author = "Dongjun ""Aurorasphere"" Kim".
license_date = 20260510.

:- import_module parser, simplifier, logic_expr, cli_args.
:- import_module list, string, maybe, char, int, bool.

main(!IO) :-
    io.command_line_arguments(Args, !IO),
    run(normalize_args(Args), !IO).

:- pred run(list(string)::in, io::di, io::uo) is det.
run(Args, !IO) :-
    ( if Args = [] ; Args = ["-h"] ; Args = ["--help"] then
        print_help(!IO)
      else if Args = ["--version"] then
        (
            io.format("%s (AuroBool) %s\n", [s(prog_name), s(prog_version)], !IO),
            io.format("Copyright (C) %d %s\n", [i(license_date), s(author)], !IO),
            io.write_string("License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.\n", !IO),
            io.write_string("This is free software: you are free to change and redistribute it.\n", !IO),
            io.write_string("There is NO WARRANTY, to the extent permitted by law.\n", !IO)
        )
      else if Args = ["-s", ExprStr] then
        with_expr(ExprStr, (pred(E::in, IO0::di, IO1::uo) is det :-
            S = simplify(expand_derived(E)),
            io.format("%s\n", [s(to_string(S))], IO0, IO1)
        ), !IO)
      else if Args = ["--sop", ExprStr] then
        with_expr(ExprStr, (pred(E::in, IO0::di, IO1::uo) is det :-
            io.format("%s\n", [s(to_string(to_sop(E)))], IO0, IO1)
        ), !IO)
      else if Args = ["--pos", ExprStr] then
        with_expr(ExprStr, (pred(E::in, IO0::di, IO1::uo) is det :-
            io.format("%s\n", [s(to_string(to_pos(E)))], IO0, IO1)
        ), !IO)
      else if Args = ["--nand", ExprStr] then
        with_expr(ExprStr, (pred(E::in, IO0::di, IO1::uo) is det :-
            io.format("%s\n", [s(to_string(to_nand_only(expand_derived(E))))], IO0, IO1)
        ), !IO)
      else if Args = ["--nor", ExprStr] then
        with_expr(ExprStr, (pred(E::in, IO0::di, IO1::uo) is det :-
            io.format("%s\n", [s(to_string(to_nor_only(expand_derived(E))))], IO0, IO1)
        ), !IO)
      else if Args = ["-t", ExprStr] ; Args = ["--truth", ExprStr] then
        with_expr(ExprStr, print_truth_table, !IO)
      else if Args = ["--verbose", Opt, ExprStr] then
        run_verbose(Opt, ExprStr, !IO)
      else if Args = ["--eq", EqStr] then
        eval_eq(EqStr, !IO)
      else if Args = ["-e", EvalStr] ; Args = ["--eval", EvalStr] then
        eval_one(EvalStr, !IO)
      else
        ( io.write_string("Error: Invalid arguments.\n\n", !IO),
          print_help(!IO)
        )
    ).

:- pred run_verbose(string::in, string::in, io::di, io::uo) is det.
run_verbose(Opt, ExprStr, !IO) :-
    with_expr(ExprStr, (pred(E::in, IO0::di, IO1::uo) is det :-
        Ex = expand_derived(E),
        io.format("[input] %s\n", [s(to_string(E))], IO0, IOA),
        io.format("[expanded] %s\n", [s(to_string(Ex))], IOA, IOB),
        ( if Opt = "-s" then
            io.format("[result] %s\n", [s(to_string(simplify(Ex)))], IOB, IO1)
          else if Opt = "--sop" then
            io.format("[result] %s\n", [s(to_string(to_sop(Ex)))], IOB, IO1)
          else if Opt = "--pos" then
            io.format("[result] %s\n", [s(to_string(to_pos(Ex)))], IOB, IO1)
          else if Opt = "--nand" then
            io.format("[result] %s\n", [s(to_string(to_nand_only(Ex)))], IOB, IO1)
          else if Opt = "--nor" then
            io.format("[result] %s\n", [s(to_string(to_nor_only(Ex)))], IOB, IO1)
          else
            io.write_string("Error: --verbose only supports -s/--sop/--pos/--nand/--nor\n", IOB, IO1)
        )
    ), !IO).

:- pred with_expr(string::in, pred(expr, io, io)::in(pred(in, di, uo) is det), io::di, io::uo) is det.
with_expr(ExprStr, Goal, !IO) :-
    parse(ExprStr, MaybeExpr),
    (
        MaybeExpr = yes(Expr),
        Goal(Expr, !IO)
    ;
        MaybeExpr = no,
        io.write_string("Error: Failed to parse expression.\n", !IO)
    ).

:- pred print_help(io::di, io::uo) is det.
print_help(!IO) :-
    io.write_string(
"AuroBool - boolean algebra utility\n\n" ++
"Usage:\n" ++
"  aurobool -s <expr>\n" ++
"  aurobool --sop <expr>\n" ++
"  aurobool --pos <expr>\n" ++
"  aurobool --nand <expr>\n" ++
"  aurobool --nor <expr>\n" ++
"  aurobool -t|--truth <expr>\n" ++
"  aurobool -e|--eval \"<expr>, A = 1, B = 0\"\n" ++
"  aurobool --eq \"<expr1>, <expr2>\"\n" ++
"  aurobool -h|--help\n" ++
"  aurobool --version\n", !IO).

:- func to_nand_only(expr) = expr.
to_nand_only(var(S)) = var(S).
to_nand_only(const(one)) = const(one).
to_nand_only(const(zero)) = const(zero).
to_nand_only(const(dont_care)) = const(dont_care).
to_nand_only(not_expr(E)) = nand_expr(NE, NE) :- NE = to_nand_only(E).
to_nand_only(and_expr(A, B)) = nand_expr(T, T) :- T = nand_expr(to_nand_only(A), to_nand_only(B)).
to_nand_only(or_expr(A, B)) = nand_expr(nand_expr(NA, NA), nand_expr(NB, NB)) :-
    NA = to_nand_only(A),
    NB = to_nand_only(B).
to_nand_only(xor_expr(A, B)) = to_nand_only(expand_derived(xor_expr(A, B))).
to_nand_only(xnor_expr(A, B)) = to_nand_only(expand_derived(xnor_expr(A, B))).
to_nand_only(nand_expr(A, B)) = nand_expr(to_nand_only(A), to_nand_only(B)).
to_nand_only(nor_expr(A, B)) = to_nand_only(expand_derived(nor_expr(A, B))).

:- func to_nor_only(expr) = expr.
to_nor_only(var(S)) = var(S).
to_nor_only(const(one)) = const(one).
to_nor_only(const(zero)) = const(zero).
to_nor_only(const(dont_care)) = const(dont_care).
to_nor_only(not_expr(E)) = nor_expr(NE, NE) :- NE = to_nor_only(E).
to_nor_only(or_expr(A, B)) = nor_expr(T, T) :- T = nor_expr(to_nor_only(A), to_nor_only(B)).
to_nor_only(and_expr(A, B)) = nor_expr(nor_expr(NA, NA), nor_expr(NB, NB)) :-
    NA = to_nor_only(A),
    NB = to_nor_only(B).
to_nor_only(xor_expr(A, B)) = to_nor_only(expand_derived(xor_expr(A, B))).
to_nor_only(xnor_expr(A, B)) = to_nor_only(expand_derived(xnor_expr(A, B))).
to_nor_only(nor_expr(A, B)) = nor_expr(to_nor_only(A), to_nor_only(B)).
to_nor_only(nand_expr(A, B)) = to_nor_only(expand_derived(nand_expr(A, B))).

:- func vars(expr) = list(string).
vars(var(S)) = [S].
vars(const(_)) = [].
vars(not_expr(E)) = vars(E).
vars(and_expr(A, B)) = sort_and_uniq(vars(A) ++ vars(B)).
vars(or_expr(A, B)) = sort_and_uniq(vars(A) ++ vars(B)).
vars(xor_expr(A, B)) = sort_and_uniq(vars(A) ++ vars(B)).
vars(xnor_expr(A, B)) = sort_and_uniq(vars(A) ++ vars(B)).
vars(nand_expr(A, B)) = sort_and_uniq(vars(A) ++ vars(B)).
vars(nor_expr(A, B)) = sort_and_uniq(vars(A) ++ vars(B)).

:- func sort_and_uniq(list(string)) = list(string).
sort_and_uniq(L) = list.sort_and_remove_dups(L).

:- type env == list({string, logic_val}).

:- func eval(expr, env) = logic_val.
eval(var(S), Env) = lookup_env(S, Env).
eval(const(V), _) = V.
eval(not_expr(E), Env) = not_val(eval(E, Env)).
eval(and_expr(A, B), Env) = and_val(eval(A, Env), eval(B, Env)).
eval(or_expr(A, B), Env) = or_val(eval(A, Env), eval(B, Env)).
eval(xor_expr(A, B), Env) = xor_val(eval(A, Env), eval(B, Env)).
eval(xnor_expr(A, B), Env) = not_val(xor_val(eval(A, Env), eval(B, Env))).
eval(nand_expr(A, B), Env) = not_val(and_val(eval(A, Env), eval(B, Env))).
eval(nor_expr(A, B), Env) = not_val(or_val(eval(A, Env), eval(B, Env))).

:- func lookup_env(string, env) = logic_val.
lookup_env(S, []) = const_default(S).
lookup_env(S, [{K, V} | T]) = ( if S = K then V else lookup_env(S, T) ).

:- func const_default(string) = logic_val.
const_default(_) = zero.

:- func not_val(logic_val) = logic_val.
not_val(one) = zero.
not_val(zero) = one.
not_val(dont_care) = dont_care.

:- func and_val(logic_val, logic_val) = logic_val.
and_val(A, B) =
    ( if A = one, B = one then one
      else if A = zero ; B = zero then zero
      else dont_care
    ).

:- func or_val(logic_val, logic_val) = logic_val.
or_val(A, B) =
    ( if A = one ; B = one then one
      else if A = zero, B = zero then zero
      else dont_care
    ).

:- func xor_val(logic_val, logic_val) = logic_val.
xor_val(A, B) =
    ( if A = dont_care ; B = dont_care then dont_care
      else if A = B then zero
      else one
    ).

:- pred print_truth_table(expr::in, io::di, io::uo) is det.
print_truth_table(E, !IO) :-
    Vs = vars(E),
    io.format("Vars: %s\n", [s(string.join_list(",", Vs))], !IO),
    print_truth_rows(E, Vs, all_envs(Vs), !IO).

:- pred print_truth_rows(expr::in, list(string)::in, list(env)::in, io::di, io::uo) is det.
print_truth_rows(_, _, [], !IO).
print_truth_rows(E, Vs, [Env | T], !IO) :-
    Row = string.join_list(" ", list.map((func(V) = bit(eval(var(V), Env))), Vs)),
    io.format("%s | %s\n", [s(Row), s(bit(eval(E, Env)))], !IO),
    print_truth_rows(E, Vs, T, !IO).

:- func bit(logic_val) = string.
bit(one) = "1".
bit(zero) = "0".
bit(dont_care) = "x".

:- func all_envs(list(string)) = list(env).
all_envs([]) = [[]].
all_envs([V | T]) =
    list.map((func(E) = [{V, zero} | E]), all_envs(T)) ++
    list.map((func(E) = [{V, one} | E]), all_envs(T)).

:- func to_sop(expr) = expr.
to_sop(E) =
    ( if terms_from_truth(E, one, Terms), Terms \= [] then fold_or(Terms)
      else const(zero)
    ).

:- func to_pos(expr) = expr.
to_pos(E) =
    ( if terms_from_truth(E, zero, Terms), Terms \= [] then fold_and(Terms)
      else const(one)
    ).

:- pred terms_from_truth(expr::in, logic_val::in, list(expr)::out) is semidet.
terms_from_truth(E, Target, Terms) :-
    Vs = vars(E),
    Envs = all_envs(Vs),
    Terms = list.filter_map((func(Env) = R is semidet :-
        ( if eval(E, Env) = Target then
            ( if Target = one then R = minterm(Vs, Env) else R = maxterm(Vs, Env) )
          else
            fail
        )
    ), Envs).

:- func minterm(list(string), env) = expr.
minterm(Vs, Env) = fold_and(list.map((func(V) = (if eval(var(V), Env) = one then var(V) else not_expr(var(V)))), Vs)).

:- func maxterm(list(string), env) = expr.
maxterm(Vs, Env) = fold_or(list.map((func(V) = (if eval(var(V), Env) = one then not_expr(var(V)) else var(V))), Vs)).

:- func fold_or(list(expr)) = expr.
fold_or([]) = const(zero).
fold_or([H | T]) = ( if T = [] then H else or_expr(H, fold_or(T)) ).

:- func fold_and(list(expr)) = expr.
fold_and([]) = const(one).
fold_and([H | T]) = ( if T = [] then H else and_expr(H, fold_and(T)) ).

:- pred eval_eq(string::in, io::di, io::uo) is det.
eval_eq(S, !IO) :-
    Parts = string.split_at_string(",", S),
    ( if Parts = [A0, B0] then
        A = string.strip(A0),
        B = string.strip(B0),
        parse(A, MA),
        parse(B, MB),
        ( if MA = yes(E1), MB = yes(E2) then
            ( if equivalent(E1, E2) then io.write_string("1\n", !IO)
              else io.write_string("0\n", !IO)
            )
          else io.write_string("Error: Failed to parse expressions.\n", !IO)
        )
      else
        io.write_string("Error: Use --eq \"expr1, expr2\"\n", !IO)
    ).

:- pred equivalent(expr::in, expr::in) is semidet.
equivalent(E1, E2) :-
    Vs = sort_and_uniq(vars(E1) ++ vars(E2)),
    Envs = all_envs(Vs),
    list.all_true((pred(Env::in) is semidet :- eval(E1, Env) = eval(E2, Env)), Envs).

:- pred eval_one(string::in, io::di, io::uo) is det.
eval_one(S, !IO) :-
    Parts = string.split_at_string(",", S),
    ( if Parts = [ExprStr | AssignStrs] then
        parse(string.strip(ExprStr), MExpr),
        ( if MExpr = yes(E) then
            parse_assignments(AssignStrs, Env),
            io.format("%s\n", [s(bit(eval(E, Env)))], !IO)
          else
            io.write_string("Error: Failed to parse expression.\n", !IO)
        )
      else
        io.write_string("Error: Use -e \"expr, A = 1, B = 0\"\n", !IO)
    ).

:- pred parse_assignments(list(string)::in, env::out) is det.
parse_assignments([], []).
parse_assignments([S0 | T], [{K, V} | Out]) :-
    S = string.strip(S0),
    KV = string.split_at_string("=", S),
    ( if KV = [K0, V0] then
        K = string.to_upper(string.strip(K0)),
        V = ( if string.strip(V0) = "1" then one else zero )
      else
        K = "_",
        V = zero
    ),
    parse_assignments(T, Out).
