:- module parser.

:- interface.
:- import_module logic_expr, list, char, maybe.

:- pred parse(string::in, maybe(expr)::out) is det.

:- implementation.
:- import_module string, bool.

parse(S, Result) :-
    Chars = list.filter((pred(C::in) is semidet :- not char.is_whitespace(C)), string.to_char_list(S)),
    ( if parse_or_like(Chars, Expr, []) then
        Result = yes(Expr)
      else
        Result = no
    ).

:- pred parse_or_like(list(char)::in, expr::out, list(char)::out) is semidet.
parse_or_like(In, Expr, Out) :-
    parse_and_like(In, E1, Rest1),
    ( if accept('+', Rest1, Rest2) then
        parse_or_like(Rest2, E2, Out),
        Expr = or_expr(E1, E2)
      else if accept_pair('~', '|', Rest1, Rest2) then
        parse_or_like(Rest2, E2, Out),
        Expr = nor_expr(E1, E2)
      else if accept_pair('~', '^', Rest1, Rest2) then
        parse_or_like(Rest2, E2, Out),
        Expr = xnor_expr(E1, E2)
      else if accept_pair('^', '~', Rest1, Rest2) then
        parse_or_like(Rest2, E2, Out),
        Expr = xnor_expr(E1, E2)
      else if accept('^', Rest1, Rest2) then
        parse_or_like(Rest2, E2, Out),
        Expr = xor_expr(E1, E2)
      else
        Expr = E1, Out = Rest1
    ).

:- pred parse_and_like(list(char)::in, expr::out, list(char)::out) is semidet.
parse_and_like(In, Expr, Out) :-
    parse_not(In, E1, Rest1),
    ( if accept_pair('~', '&', Rest1, Rest2) then
        parse_and_like(Rest2, E2, Out),
        Expr = nand_expr(E1, E2)
      else if is_start_of_factor(Rest1) then
        parse_and_like(Rest1, E2, Out),
        Expr = and_expr(E1, E2)
      else
        Expr = E1, Out = Rest1
    ).

:- pred parse_not(list(char)::in, expr::out, list(char)::out) is semidet.
parse_not(In, Expr, Out) :-
    parse_primary(In, E1, Rest1),
    ( if accept('\'', Rest1, Rest2) then
        Expr = not_expr(E1), Out = Rest2
      else
        Expr = E1, Out = Rest1
    ).

:- pred parse_primary(list(char)::in, expr::out, list(char)::out) is semidet.
parse_primary([C | Rest], Expr, Out) :-
    ( if char.is_alpha(C) then
        Expr = var(string.from_char_list([char.to_upper(C)])),
        Out = Rest
      else if C = '0' then Expr = const(zero), Out = Rest
      else if C = '1' then Expr = const(one), Out = Rest
      else if C = '(' then
        parse_or_like(Rest, Expr, Rest1),
        accept(')', Rest1, Out)
      else
        fail
    ).

:- pred accept(char::in, list(char)::in, list(char)::out) is semidet.
accept(C, [C | Rest], Rest).

:- pred accept_pair(char::in, char::in, list(char)::in, list(char)::out) is semidet.
accept_pair(C1, C2, [C1, C2 | Rest], Rest).

:- pred is_start_of_factor(list(char)::in) is semidet.
is_start_of_factor([C | _]) :-
    ( char.is_alpha(C) ; C = '(' ; C = '0' ; C = '1' ).
