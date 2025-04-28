#!/usr/bin/env wolframscript
(* ::Package:: *)

(* this requires a specific problem setup for R13 *)


Print["Constructing the MFS solution of R13 for a two-circle-geometry."];

Get["R13FundamentalSolution.wls"];

Get["R13BoundaryConditions.wls"];

nBC = nn = Length[BCrhs];  (* number of boundary conditions = number of boundary controls *)

Kn = \[Tau];  (*Knudsen number*)

d = 0.1; (*Grid spacing*)

NbOuter = Floor[2 \[Pi] Rb/d]; (*Number of points on outer circle*)
NbInner = Floor[2 \[Pi] rb/d]; (*Number of points on inner circle*)

NsOuter = NbOuter; NsInner = NbInner; (*Equal number of singularity and boundary points*)
\[Delta]\[Theta]bOuter = (2.0 \[Pi])/NbOuter; (* equispaced angles *)
\[Delta]\[Theta]bInner = (2.0 \[Pi])/NbInner; 

circlePtsOuter = Table[{Cos[(i - 1)*\[Delta]\[Theta]bOuter], Sin[(i - 1)*\[Delta]\[Theta]bOuter]}, {i, NbOuter}]; 
circlePtsInner = Table[{Cos[(i - 1)*\[Delta]\[Theta]bInner], Sin[(i - 1)*\[Delta]\[Theta]bInner]}, {i, NbInner}]; 

X$b = Join[Rb*circlePtsOuter, rb*circlePtsInner];  (*POSITION VECTORS OF BOUNDARY NODES*)
X$s = Join[Rs*circlePtsOuter, rs*circlePtsInner];  (*POSITION VECTORS OF SINGULARITIES*)
N$ = Join[circlePtsOuter, -circlePtsInner];  (*NORMALS AND TANGENTS*)
T$ = Cross /@ N$;

Nb = Length[X$b];
Ns = Length[X$s];

Print["Total boundary nodes = Total singularities = " ,Nb]

Print["Computing the boundary values."];

rBC[i_] := If[Norm[X$b[[i]]] > (R0 + R1)/2, R1, R0] (*To distinguish boundary conditions on inner and outer circle*)
boundarySetup[i_] := setup[rBC[i], ArcTan @@ X$b[[i]]]
Bn1 = Table[BC . Trafo /. Join[Thread[{nx, ny} -> N$[[i]]], Thread[{tx, ty} -> T$[[i]]]] /. boundarySetup[i], {i, Nb}]; 
bb$ = Flatten[Table[-BCrhs /. boundarySetup[i], {i, Nb}]]; 

Print["Launching parallel kernels for faster assembly."];
LaunchKernels[8];

Print["MFS matrix assembly."];

rValues = Table[N[X$b[[i]] - X$s[[j]]], {i, Nb}, {j, Ns}]; (*calculating relative position vectors*)
adj$collect = ParallelTable[A[rValues[[i,j]]], {i, Nb}, {j, Ns}]; 

M$col = Table[0, {i, nBC*Nb}, {j, nn*Ns}]; 
Do[M$col[[(i - 1)*nBC + 1 ;; i*nBC,(j - 1)*nn + 1 ;; j*nn]] = 
   Bn1[[i]] . adj$collect[[i,j]] . Transpose[Bn1[[j]]], {i, Nb}, {j, Ns}]

Print["Main least squares solve:"];

xSolut1 = LeastSquares[M$col, bb$, Method -> "IterativeRefinement"];
res = Norm[M$col . xSolut1 - bb$];

{u, v, w} = SingularValueDecomposition[M$col];
sigmar = Min[Select[Diagonal[v], Positive]];
\[Kappa]eff = Norm[bb$]/(sigmar  Norm[xSolut1]);

Print[" -least squares residual = ",res];
Print[" -effective condition number = ",\[Kappa]eff];
