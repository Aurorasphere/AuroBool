:- module logic_expr.

:- interface.
:- import_module string.

:- type logic_val
  ---> zero
  ; one
  ; dont_care.

:- type expr
    ---> var(string)              
    ; const(logic_val)        
    ; not_expr(expr)          
    ; and_expr(expr, expr)    
    ; or_expr(expr, expr)      
    ; xor_expr(expr, expr)    
    ; xnor_expr(expr, expr)  
    ; nand_expr(expr, expr)   
    ; nor_expr(expr, expr).  

% ---------- External Predicates ----------
:- func expand_derived(expr) = expr. % (XOR, XNOR, NAND, NOR) -> Combinations of (AND, OR, NOT)
:- func to_string(expr) = string. % Convert expr to string for printing

:- implementation.

:- import_module list.

expand_derived(var(S)) = var(S).
expand_derived(const(V)) = const(V).
expand_derived(not_expr(E)) = not_expr(expand_derived(E)).
expand_derived(and_expr(L, R)) = and_expr(expand_derived(L), expand_derived(R)).
expand_derived(or_expr(L, R)) = or_expr(expand_derived(L), expand_derived(R)).

expand_derived(xor_expr(L, R)) = or_expr(and_expr(L, not_expr(R)), and_expr(not_expr(L), R)).
expand_derived(xnor_expr(L, R)) = or_expr(and_expr(L, R), and_expr(not_expr(L), not_expr(R))).
expand_derived(nand_expr(L, R)) = not_expr(and_expr(L, R)).
expand_derived(nor_expr(L, R)) = not_expr(or_expr(L, R)).

to_string(var(S)) = S.
to_string(const(zero)) = "0".
to_string(const(one)) = "1".
to_string(const(dont_care)) = "x".
to_string(not_expr(E)) = 
    ( if (E = var(_) ; E = const(_)) then to_string(E) ++ "'"
      else "(" ++ to_string(E) ++ ")'" ).
to_string(and_expr(L, R)) =
    string.join_list("", list.map(term_to_string_in_and, sort_exprs(flatten_and(and_expr(L, R))))).
to_string(or_expr(L, R)) =
    string.join_list(" + ", list.map(to_string, sort_exprs(flatten_or(or_expr(L, R))))).
to_string(xor_expr(L, R)) = "(" ++ to_string(L) ++ "^" ++ to_string(R) ++ ")".
to_string(nand_expr(L, R)) = "~&(" ++ to_string(L) ++ "," ++ to_string(R) ++ ")".
to_string(nor_expr(L, R)) = "~|(" ++ to_string(L) ++ "," ++ to_string(R) ++ ")".
to_string(xnor_expr(L, R)) = "(" ++ to_string(L) ++ "~^" ++ to_string(R) ++ ")".

:- func term_to_string_in_and(expr) = string.
term_to_string_in_and(E) =
    ( if (E = or_expr(_, _) ; E = xor_expr(_, _) ; E = xnor_expr(_, _) ; E = nor_expr(_, _))
      then "(" ++ to_string(E) ++ ")"
      else to_string(E)
    ).

:- func flatten_and(expr) = list(expr).
flatten_and(E) =
    ( if E = and_expr(L, R) then flatten_and(L) ++ flatten_and(R)
      else [E]
    ).

:- func flatten_or(expr) = list(expr).
flatten_or(E) =
    ( if E = or_expr(L, R) then flatten_or(L) ++ flatten_or(R)
      else [E]
    ).

:- func sort_exprs(list(expr)) = list(expr).
sort_exprs(Es) = list.sort_and_remove_dups(Es).
