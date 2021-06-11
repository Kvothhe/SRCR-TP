%--------------------------------- - - - - - - - - - -  -  -  -  -   -
% SIST. REPR. CONHECIMENTO E RACIOCINIO 
%--------------------------------- - - - - - - - - - -  -  -  -  -   -
% SICStus PROLOG: Declaracoes iniciais


:- set_prolog_flag( discontiguous_warnings,off ).
:- set_prolog_flag( single_var_warnings,off ).
:- set_prolog_flag( unknown,fail ).
:- set_prolog_flag(toplevel_print_options,[quoted(true), portrayed(true), max_depth(0)]). 

%--------------------------------- - - - - - - - - - -  -  -  -  -   -
% SICStus PROLOG: definicoes iniciais

:- op( 900,xfy,'::' ).
:- dynamic '-'/1.
:- dynamic(pontoRecolha/7).
:- op(  500,  fx, [ +, - ]).
:- op(  300, xfx, [ mod ]).
:- op(  200, xfy, [ ^ ]).


:- include('kb.pl').
:- include('grafo.pl').
:- use_module(library(lists)).
:- use_module(library(prolog_trace)).

%--------------------------------- auxiliars
adjacente(Nodo,ProxNodo):-
   aresta(Nodo, ProxNodo).

sucessor(Nodo, List) :- findall(X, adjacente(Nodo, X), List).

inverso(Xs, Ys):-
   inverso(Xs, [], Ys).

inverso([], Xs, Xs).
inverso([X|Xs],Ys, Zs):-
   inverso(Xs, [X|Ys], Zs).


seleciona(E, [E|Xs], Xs).
seleciona(E, [X|Xs], [X|Ys]):- seleciona(E, Xs, Ys).

remove(E, [E|Xs], Xs).
remove(E, [X|Xs], [X|Ys]) :- remove(E, Xs, Ys).

%--------------------------------- DfS Depth First Search
dfs(Nodo, Destino, [Nodo|Caminho]):-
    dfsr(Nodo, Destino, [Nodo], Caminho).

dfsr(Nodo, Destino, _, [Destino]):-
    adjacente(Nodo, Destino).

dfsr(Nodo, Destino, Visited, [ProxNodo|Caminho]):-
    adjacente(Nodo, ProxNodo),
    \+ member(ProxNodo, Visited),
    dfsr(ProxNodo, Destino, [Nodo|Visited], Caminho).

%--------------------------------- BfS Breadth First Search 

bfs(Start, End, Solution) :-
  bfsAux([[Start]], End, Solution).


bfsAux([[Node|Path]|_], End, Result) :-
  Node == End, ! , inverso([Node|Path], Result).

bfsAux([Path|Paths], End, Solution) :-
  extend(Path, NewPaths),
  append(Paths, NewPaths, Paths1),
  bfsAux(Paths1, End, Solution).

extend([Node|Path], NewPaths) :-
  findall([NewNode, Node|Path],
          (adjacente(Node, NewNode),
           \+ member(NewNode,[Node|Path]) ),
          NewPaths),!.

extend(Path, []).


%--------------------------------- Gulosa

greedy(Nodo, Destino, Caminho/LixoR):-
    estima(Nodo,Destino, E),
    estima(Nodo,V),
    agreedy([[Nodo]/V/E], InvCaminho/LixoR/_, Destino),
    inverso(InvCaminho,Caminho).

agreedy(Caminhos, Caminho, Destino):-
    get_best_g(Caminhos,Caminho),
    Caminho = [Nodo|_]/_/_,
    Nodo == Destino.

agreedy(Caminhos, SolucaoCaminho, Destino):-
    get_best_g(Caminhos, MelhorCaminho),
    seleciona(MelhorCaminho,Caminhos,OutrosCaminhos),
    expand_greedy(MelhorCaminho,ExpCaminhos, Destino),
    append(OutrosCaminhos,ExpCaminhos,NovoCaminhos),
    agreedy(NovoCaminhos,SolucaoCaminho, Destino).

get_best_g([Caminho],Caminho):- !.

get_best_g([Caminho1/Custo1/Est1,_/_/Est2|Caminhos], MelhorCaminho):-
    Est1 =< Est2,
    !,
    get_best_g([Caminho1/Custo1/Est1|Caminhos],MelhorCaminho).

get_best_g([_|Caminhos], MelhorCaminho):-
    get_best_g(Caminhos, MelhorCaminho).

expand_greedy(Caminho, ExpCaminhos, Destino):-
    findall(NovoCaminho, adjacente(Caminho, NovoCaminho, Destino), ExpCaminhos).

adjacente([Nodo|Caminho]/Custo/_, [ProxNodo,Nodo|Caminho]/NovoCusto/Est, Destino):-
    aresta(Nodo, ProxNodo),
    estima(ProxNodo, PassoCusto),
    \+ member(ProxNodo, Caminho),
    NovoCusto is Custo + PassoCusto,
    estima(ProxNodo, Destino, Est).

estima(P1,R):-
        pontoRecolha(_,_,_,_,P1,_,L1),
        getLixo(L1,R).

estima(P1,P2,R):-
        pontoRecolha(_,_,_,_,P1,_,L1),
        pontoRecolha(_,_,_,_,P2,_,L2),
        append(L1,L2,Lr),
        getLixo(Lr,R).

getLixo([(_, V)],V).
getLixo([(_, V1),(_, V2)|Tail],R):- RR is V1 + V2,
                                    getLixo([(_, RR)|Tail],R).


%--------------------------------- A*

aestrela(Origin, Goal, Caminho/Custo) :-
    estima(Origin, Goal, Estima),
    estima(Origin, V),
    axestrela([[Origin]/V/Estima], InvCaminho/Custo/_, Goal),
    inverso(InvCaminho, Caminho).

axestrela(Caminhos, Caminho, Goal) :-
    obtem_melhor(Caminhos, Caminho),
    Caminho = [Nodo|_]/_/_, Nodo == Goal.

axestrela(Caminhos, SolutionCaminho, Goal) :-
    obtem_melhor(Caminhos, MelhorCaminho),
    remove(MelhorCaminho, Caminhos, OutrosCaminhos),
    expande_aestrela(MelhorCaminho, ExpCaminhos, Goal),
    append(OutrosCaminhos, ExpCaminhos, NovoCaminhos),
        axestrela(NovoCaminhos, SolutionCaminho, Goal).        

obtem_melhor([Caminho], Caminho) :- !.

obtem_melhor([Caminho1/Custo1/Est1,_/Custo2/Est2|Caminhos], MelhorCaminho) :-
    Custo1 + Est1 =< Custo2 + Est2, !,   %>
    obtem_melhor([Caminho1/Custo1/Est1|Caminhos], MelhorCaminho).
    
obtem_melhor([_|Caminhos], MelhorCaminho) :- 
    obtem_melhor(Caminhos, MelhorCaminho).

expande_aestrela(Caminho, ExpCaminhos, Goal) :-
    findall(NovoCaminho, adjacente(Caminho, NovoCaminho, Goal), ExpCaminhos).


%--------------------------------- Numero de Lixos

%------------ dfs

getNumLixo(Nodo, Lixo, R):-
   pontoRecolha(_,_,_,_,Nodo,_,L1),
   getNumLixoAux(L1, Lixo,R).

list_sum([Item], Item).
list_sum([Item1,Item2 | Tail], Total) :-
    list_sum([Item1+Item2|Tail], Total).

getNumLixoAux([], Lixo,0).
getNumLixoAux([(Name,V)|Rest], Lixo,Num) :-
  getNumLixoAux(Rest, Lixo,Num1),
  (Name = Lixo -> Num is Num1 + 1; Num is Num1).

dfs_TL(Nodo, Destino, TipoLixo, [Nodo|Caminho]/Number):-
    getNumLixo(Nodo,Lixo,Acc),
    dfsr_TL(Nodo, Destino, TipoLixo, [Nodo], Caminho/Acc/Number).

dfsr_TL(Nodo, Destino, TipoLixo, _, [Destino]/Acc/Number):-
    adjacente(Nodo, Destino),
    getNumLixo(Destino,TipoLixo,Num),
    Number is Num + Acc.

dfsr_TL(Nodo, Destino, TipoLixo, Visited, [ProxNodo|Caminho]/Acc/Number):-
    adjacente(Nodo, ProxNodo),
    \+ member(ProxNodo, Visited),
    getNumLixo(Destino,TipoLixo,Num),
    NewAcc is Acc + Num,
    dfs_TL(ProxNodo, Destino, TipoLixo, [Nodo|Visited], Caminho/NewAcc/Number).

%------------ bfs

resolve_bfs_lixo(Start, End, Lixos, Solution) :-
  bfs_loja([[Start]], End, Lixos, Solution).


bfs_lixo([[Node|Path]|_], End, Lixos, Result) :-
  Node == End, ! , inverso([Node|Path], Result).

bfs_lixo([Path|Paths], End, Lixos, Solution) :-
  extend_loja(Path, NewPaths, Lixos),
  append(Paths, NewPaths, Paths1),
  bfs_lixo(Paths1, End, Lixos, Solution).

extend_lixo([Node|Path], NewPaths, Lixos) :-
  findall([NewNode, Node|Path],
          (adjacente_Lixo(Node, NewNode, Lixos),
           \+ member(NewNode,[Node|Path]) ),
          NewPaths),!.

extend_lixo(Path, [], Lixos).

%------------ gulosa

greedyTP(Nodo, Destino,TipoLixo, Caminho/LixoR):-
    estimaTP(Nodo,Destino, TipoLixo,E),
    estimaTP(Nodo,TipoLixo,V),
    agreedyTP([[Nodo]/V/E], TipoLixo,InvCaminho/LixoR/_, Destino),
    inverso(InvCaminho,Caminho).

agreedyTP(Caminhos, TipoLixo,Caminho, Destino):-
    get_best_gTP(Caminhos,Caminho),
    Caminho = [Nodo|_]/_/_,
    Nodo == Destino.

agreedyTP(Caminhos, TipoLixo,SolucaoCaminho, Destino):-
    get_best_gTP(Caminhos, MelhorCaminho),
    seleciona(MelhorCaminho,Caminhos,OutrosCaminhos),
    expand_greedyTP(MelhorCaminho,TipoLixo,ExpCaminhos, Destino),
    append(OutrosCaminhos,ExpCaminhos,NovoCaminhos),
    agreedyTP(NovoCaminhos,TipoLixo,SolucaoCaminho, Destino).

get_best_gTP([Caminho],Caminho):- !.

get_best_gTP([Caminho1/Custo1/Est1,_/_/Est2|Caminhos], MelhorCaminho):-
    Est1 =< Est2,
    !,
    get_best_gTP([Caminho1/Custo1/Est1|Caminhos],MelhorCaminho).

get_best_gTP([_|Caminhos], MelhorCaminho):-
    get_best_gTP(Caminhos, MelhorCaminho).

expand_greedyTP(Caminho, TipoLixo ,ExpCaminhos, Destino):-
    findall(NovoCaminho, adjacenteTP(Caminho, NovoCaminho, Destino), ExpCaminhos).

adjacenteTP([Nodo|Caminho]/Custo/_, [ProxNodo,Nodo|Caminho]/NovoCusto/Est, Destino):-
    aresta(Nodo, ProxNodo),
    estimaTP(ProxNodo, TipoLixo,PassoCusto),
    \+ member(ProxNodo, Caminho),
    NovoCusto is Custo + PassoCusto,
    estimaTP(ProxNodo, TipoLixo,Destino, Est).

estimaTP(P1,TipoLixo,R):-
        pontoRecolha(_,_,_,_,P1,_,L1),
        getLixoTP(L1,R).

estimaTP(P1,P2,TipoLixo,R):-
        pontoRecolha(_,_,_,_,P1,_,L1),
        pontoRecolha(_,_,_,_,P2,_,L2),
        append(L1,L2,Lr),
        getLixoTP(Lr,R).

getLixoTP([(_, V)],TipoLixo,V).
getLixoTP([L1,L2|Tail],TipoLixo,R):- 
   isLixo(L1,TipoLixo) -> ((isLixo(L2,TipoLixo) -> (getLixoV(L1,V1),getLixoV(L2,V2),RR is V1 + V2, getLixo([(_, RR)|Tail],TipoLixo,R) ;
                                                    getLixoTP(L1|Tail,TipoLixo,R)))
                           ;getLixoTP(L2|Tail,TipoLixo,R)).

isLixo((T,_),TipoLixo) :- T == TipoLixo.

getLixoV((_,V),Z) :- Z is V. 