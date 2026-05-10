:- module cli_args.

:- interface.

:- import_module list, string, char.

:- func normalize_args(list(string)) = list(string).

:- implementation.

normalize_args(Args) = Norm :-
    ( if Args = ["--verbose", SubOpt | Rest], Rest \= [] then
        Norm = ["--verbose", SubOpt, strip_outer_quotes(string.join_list(" ", Rest))]
      else if Args = [Opt | Rest], Rest \= [], takes_single_expr_opt(Opt) then
        Norm = [Opt, strip_outer_quotes(string.join_list(" ", Rest))]
      else
        Norm = Args
    ).

:- pred takes_single_expr_opt(string::in) is semidet.
takes_single_expr_opt("-s").
takes_single_expr_opt("--sop").
takes_single_expr_opt("--pos").
takes_single_expr_opt("--nand").
takes_single_expr_opt("--nor").
takes_single_expr_opt("-t").
takes_single_expr_opt("--truth").
takes_single_expr_opt("--eq").
takes_single_expr_opt("-e").
takes_single_expr_opt("--eval").

:- func strip_outer_quotes(string) = string.
strip_outer_quotes(S) = Out :-
    Chars = string.to_char_list(string.strip(S)),
    ( if Chars = ['"' | T], remove_trailing_quote(T, Mid) then
        Out = string.from_char_list(Mid)
      else
        Out = string.strip(S)
    ).

:- pred remove_trailing_quote(list(char)::in, list(char)::out) is semidet.
remove_trailing_quote(In, Out) :-
    Rev = list.reverse(In),
    Rev = ['"' | RevTail],
    Out = list.reverse(RevTail).
