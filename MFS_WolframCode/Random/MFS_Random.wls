#!/usr/bin/env wolframscript
(* ::Package:: *)


(* Load R13 support files (assumed present in the same folder) *)
Print["MFS_Random: Loading R13 auxiliary scripts..."];

Get[FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName]], "Core", "R13FundamentalSolution.wls"}]];

Get[FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName]], "Core", "R13BoundaryConditions.wls"}]];
outerR=1;
Rout = outerR; (* outer radius *)
R0 = 0.5;
\[Tau] = 0.3;
\[Mu] = \[Tau];
Kn = \[Tau];
fac = 1;
\[Chi]2 = 1;
facBC = 1; 
chi2value = 1; 
v0 = 1;
vR = 0.0;
p0 = 0.0;
eps = 10^-5;

\[Theta]0 = 0.0;
\[Theta]1 = 0.0;




rBC[i_] := If[Norm[Xb[[i]]] == outerR, outerR, R0];


 boundarySetup[i_] := setup[rBC[i], ArcTan @@ Xb[[i]]]

Bn0 = BC . Trafo;
Bn1 = Table[
   Bn0 /. Join[Thread[{nx, ny} -> Nlist[[i]]], Thread[{tx, ty} -> Tlist[[i]]]] /. boundarySetup[i],
   {i, Length[Xb]}
];

bb$ = Flatten[Table[-BCrhs /. boundarySetup[i], {i, Length[Xb]}]];

(* parallel kernel launch *)
Print["launching parallel kernels"];
LaunchKernels[];

(* compute relative position arrays rValues and adj$collect *)
Print["computing relative position vectors and adjoint evaluations"];
rValues = Table[N[Xb[[i]] - Xs[[j]]], {i, Length[Xb]}, {j, Length[Xs]}];

adj$collect = ParallelTable[A[rValues[[i, j]]], {i, Length[Xb]}, {j, Length[Xs]}];

(* assemble big M matrix M$col *)
Print["assembling global matrix M$col"];
M$col = Table[0, {i, 6 Length[Xb]}, {j, 6 Length[Xs]}];

Do[
  M$col[[(i - 1)*6 + 1 ;; i*6, (j - 1)*6 + 1 ;; j*6]] =
    Bn1[[i]] . adj$collect[[i, j]] . Transpose[Bn1[[j]]],
  {i, Length[Xb]}, {j, Length[Xs]}
];


(* solve least squares *)
Print["solving least squares system"];
xSolut1 = LeastSquares[M$col, bb$, Method -> "IterativeRefinement"];
res = Norm[M$col . xSolut1 - bb$];
Print["MFS_Random: residual norm = ", res];

(* diagnostics *)
{u, v, w} = SingularValueDecomposition[M$col];
\[Sigma]r = Min[Select[Diagonal[v], Positive]];
\[Kappa]eff = Norm[bb$]/(\[Sigma]r  Norm[xSolut1]);

Print["effective cond (kappa_eff) = ", \[Kappa]eff];

(* build solution vectors and FF *)
solutionvector = Partition[xSolut1, 6];
FF = Table[Transpose[Bn1[[i]]] . solutionvector[[i]], {i, Length[solutionvector]}];

(* define velocity and temperature MFS evaluation functions (vectorized) *)
velMFS[{x_, y_}] := Plus @@ Table[
    {A[{x, y} - Xs[[i]]][[2]] . FF[[i]], A[{x, y} - Xs[[i]]][[3]] . FF[[i]]},
    {i, Length[Xs]}
];

tempMFS[{x_, y_}] := Plus @@ Table[
    A[{x, y} - Xs[[i]]][[4]] . FF[[i]],
    {i, Length[Xs]}
];

