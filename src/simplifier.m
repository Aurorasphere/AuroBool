:- module simplifier.

:- interface.
:- import_module logic_expr.

% Final simplifier function
:- func simplify(expr) = expr.

:- implementation.
:- import_module list, string, std_util, bool.

simplify(Expr) =
    ( if simplify_step(Expr, NextExpr) then
        simplify(NextExpr)
      else
        Expr
    ).

:- pred simplify_step(expr::in, expr::out) is semidet.

simplify_step(Expr, NextExpr) :-
    ( if rule(Expr, R) then
        NextExpr = R
      else if Expr = not_expr(E), simplify_step(E, NextE) then
        NextExpr = not_expr(NextE)
      else if Expr = and_expr(L, R) then
        ( if simplify_step(L, NextL) then NextExpr = and_expr(NextL, R)
          else if simplify_step(R, NextR) then NextExpr = and_expr(L, NextR)
          else fail
        )
      else if Expr = or_expr(L, R) then
        ( if simplify_step(L, NextL) then NextExpr = or_expr(NextL, R)
          else if simplify_step(R, NextR) then NextExpr = or_expr(L, NextR)
          else fail
        )
      else if Expr = xor_expr(L, R) then
        ( if simplify_step(L, NextL) then NextExpr = xor_expr(NextL, R)
          else if simplify_step(R, NextR) then NextExpr = xor_expr(L, NextR)
          else fail
        )
      else if Expr = xnor_expr(L, R) then
        ( if simplify_step(L, NextL) then NextExpr = xnor_expr(NextL, R)
          else if simplify_step(R, NextR) then NextExpr = xnor_expr(L, NextR)
          else fail
        )
      else if Expr = nand_expr(L, R) then
        ( if simplify_step(L, NextL) then NextExpr = nand_expr(NextL, R)
          else if simplify_step(R, NextR) then NextExpr = nand_expr(L, NextR)
          else fail
        )
      else if Expr = nor_expr(L, R) then
        ( if simplify_step(L, NextL) then NextExpr = nor_expr(NextL, R)
          else if simplify_step(R, NextR) then NextExpr = nor_expr(L, NextR)
          else fail
        )
      else
        fail
    ).

:- pred rule(expr::in, expr::out) is semidet.

rule(Expr, NextExpr) :-
    ( if Expr = and_expr(A, B) then
        ( if B = const(one) then NextExpr = A                           % 1. Identity
          else if A = const(one) then NextExpr = B
          else if B = const(zero) then NextExpr = const(zero)           % 2. Null
          else if A = const(zero) then NextExpr = const(zero)
          else if A = B then NextExpr = A                               % 3. Idempotent
          else if B = not_expr(A) then NextExpr = const(zero)           % 4. Complement
          else if A = not_expr(B) then NextExpr = const(zero)
          else if compare((>), A, B) then NextExpr = and_expr(B, A)      % 6. Commutative
          else if A = and_expr(InnerA, InnerB) then                     % 7. Associative
            NextExpr = and_expr(InnerA, and_expr(InnerB, B))
          % 12. Consensus (Dual): (A+B)(A'+C)(B+C) = (A+B)(A'+C)
          else if B = and_expr(or_expr(NotA, C), or_expr(B_cons, C_cons)),
                  A = or_expr(A_cons, B_cons_A),
                  NotA = not_expr(A_cons),
                  B_cons = B_cons_A,
                  C = C_cons
          then
            NextExpr = and_expr(A, or_expr(not_expr(A_cons), C))
          else if A = or_expr(A1, A2), B = or_expr(B1, B2) then        % 8. Distributive: (A+B)(A+C) = A + BC
            ( if A1 = B1 then NextExpr = or_expr(A1, and_expr(A2, B2))
              else if A1 = B2 then NextExpr = or_expr(A1, and_expr(A2, B1))
              else if A2 = B1 then NextExpr = or_expr(A2, and_expr(A1, B2))
              else if A2 = B2 then NextExpr = or_expr(A2, and_expr(A1, B1))
              else fail
            )
          else if B = or_expr(InnerB1, InnerB2) then                    % 9. Absorption / 11. Redundancy
            ( if A = InnerB1 then NextExpr = A                          % 9. Absorption: A(A+B) = A
              else if A = InnerB2 then NextExpr = A
              else if InnerB1 = not_expr(A) then                        % 11. Redundancy: A(A'+B) = AB
                NextExpr = and_expr(A, InnerB2)
              else if InnerB2 = not_expr(A) then
                NextExpr = and_expr(A, InnerB1)
              else fail
            )
          else if A = or_expr(InnerA1, InnerA2) then
            ( if B = InnerA1 then NextExpr = B                          % 9. Absorption
              else if B = InnerA2 then NextExpr = B
              else if InnerA1 = not_expr(B) then                        % 11. Redundancy
                NextExpr = and_expr(B, InnerA2)
              else if InnerA2 = not_expr(B) then
                NextExpr = and_expr(B, InnerA1)
              else fail
            )
          else
            fail
        )
      else if Expr = or_expr(A, B) then
        ( if B = const(zero) then NextExpr = A                          % 1. Identity
          else if A = const(zero) then NextExpr = B
          else if B = const(one) then NextExpr = const(one)              % 2. Null
          else if A = const(one) then NextExpr = const(one)
          else if A = B then NextExpr = A                               % 3. Idempotent
          else if B = not_expr(A) then NextExpr = const(one)            % 4. Complement
          else if A = not_expr(B) then NextExpr = const(one)
          else if compare((>), A, B) then NextExpr = or_expr(B, A)       % 6. Commutative
          else if A = or_expr(InnerA, InnerB) then                      % 7. Associative
            NextExpr = or_expr(InnerA, or_expr(InnerB, B))
          % 12. Consensus: AB + A'C + BC = AB + A'C
          else if B = or_expr(and_expr(NotA, C), and_expr(B_cons, C_cons)),
                  A = and_expr(A_cons, B_cons_A),
                  NotA = not_expr(A_cons),
                  B_cons = B_cons_A,
                  C = C_cons
          then
            NextExpr = or_expr(A, and_expr(not_expr(A_cons), C))
          else if A = and_expr(A1, A2), B = and_expr(B1, B2) then       % 8. Distributive: AB + AC = A(B+C)
            ( if A1 = B1 then NextExpr = and_expr(A1, or_expr(A2, B2))
              else if A1 = B2 then NextExpr = and_expr(A1, or_expr(A2, B1))
              else if A2 = B1 then NextExpr = and_expr(A2, or_expr(A1, B2))
              else if A2 = B2 then NextExpr = and_expr(A2, or_expr(A1, B1))
              else fail
            )
          else if B = and_expr(InnerB1, InnerB2) then                   % 9. Absorption / 11. Redundancy
            ( if A = InnerB1 then NextExpr = A                          % 9. Absorption: A + AB = A
              else if A = InnerB2 then NextExpr = A
              else if InnerB1 = not_expr(A) then                        % 11. Redundancy: A + A'B = A + B
                NextExpr = or_expr(A, InnerB2)
              else if InnerB2 = not_expr(A) then
                NextExpr = or_expr(A, InnerB1)
              else if remove_and_factor(not_expr(A), B, Reduced) then   % Generalized redundancy: A + A'X = A + X
                NextExpr = or_expr(A, Reduced)
              else fail
            )
          else if A = and_expr(InnerA1, InnerA2) then
            ( if B = InnerA1 then NextExpr = B                          % 9. Absorption
              else if B = InnerA2 then NextExpr = B
              else if InnerA1 = not_expr(B) then                        % 11. Redundancy
                NextExpr = or_expr(B, InnerA2)
              else if InnerA2 = not_expr(B) then
                NextExpr = or_expr(B, InnerA1)
              else if remove_and_factor(not_expr(B), A, Reduced) then
                NextExpr = or_expr(B, Reduced)
              else fail
            )
          else
            fail
        )
      else if Expr = not_expr(E) then
        ( if E = not_expr(InnerE) then NextExpr = InnerE                % 5. Involution
          else if E = const(zero) then NextExpr = const(one)
          else if E = const(one) then NextExpr = const(zero)
          else if E = and_expr(L, R) then                               % 10. De Morgan
            NextExpr = or_expr(not_expr(L), not_expr(R))
          else if E = or_expr(L, R) then                                % 10. De Morgan
            NextExpr = and_expr(not_expr(L), not_expr(R))
          else fail
        )
      else if Expr = xor_expr(A, B), compare((>), A, B) then NextExpr = xor_expr(B, A)
      else if Expr = xnor_expr(A, B), compare((>), A, B) then NextExpr = xnor_expr(B, A)
      else if Expr = nand_expr(A, B), compare((>), A, B) then NextExpr = nand_expr(B, A)
      else if Expr = nor_expr(A, B), compare((>), A, B) then NextExpr = nor_expr(B, A)
      else fail
    ).

:- pred remove_and_factor(expr::in, expr::in, expr::out) is semidet.
remove_and_factor(Factor, and_expr(L, R), Reduced) :-
    ( if L = Factor then
        Reduced = R
      else if R = Factor then
        Reduced = L
      else if remove_and_factor(Factor, L, NewL) then
        Reduced = and_expr(NewL, R)
      else if remove_and_factor(Factor, R, NewR) then
        Reduced = and_expr(L, NewR)
      else
        fail
    ).
remove_and_factor(_, _, _) :-
    fail.
