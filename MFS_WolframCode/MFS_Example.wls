#!/usr/bin/env wolframscript
(* ::Package:: *)

(* this requires a specific problem setup for R13 *)


Print["*******"];
Print["MFS solution of R13."];

Rb = R1;  (*Radius of outer circle with boundary nodes*)
rb = R0;  (*Radius of inner circle with boundary nodes*)

\[Alpha] = 1.5; (*Dilation parameter*)
Rs = \[Alpha] Rb;  (*Radius of outer circle with singularities*)
rs = 1/\[Alpha]  rb;  (*Radius of inner circle with singularities*)
(*Nb = Ns = 60; *) (*number of boundary nodes and number of singularities *)

Get["MFS_Solution.wls"];


Print["Extract explicit variable fields."];

solutionvector = Partition[xSolut1, nn];
FF = Table[Transpose[Bn1[[i]]].solutionvector[[i]],{i,Length[solutionvector]}];

velMFS[{x_, y_}] := Plus @@ Table[{A[{x, y} - X$s[[i]]][[2]] . FF[[i]], 
                                   A[{x, y} - X$s[[i]]][[3]] . FF[[i]]}, {i, Ns}];
tempMFS[{x_, y_}] := Plus @@ Table[A[{x, y} - X$s[[i]]][[4]] . FF[[i]], {i, Ns}];                                   

dr = 0.1;

MFSresult = Table[ParallelTable[{r, tempMFS[{r*Cos[theta], r*Sin[theta]}]}, 
                                {r, rb, Rb, dr}], {theta, {0, Pi/4, Pi/2}}]; 

PlotMFSTemperature = ListPlot[MFSresult, PlotStyle -> {Blue, Red, Green}, 
    Frame -> True, FrameLabel -> {"radius r", "temperature"}, PlotRange -> Full, 
    PlotMarkers -> {"\[FilledCircle]", 12} 
   ]; 

MFSresult = Table[ParallelTable[{r, Norm[velMFS[{r*Cos[theta], r*Sin[theta]}]]}, 
                                {r, rb, Rb, dr}], {theta, {0, Pi/4, Pi/2}}]; 

PlotMFSVelocity = ListPlot[MFSresult, PlotStyle -> {Blue, Red, Green}, 
    PlotRange -> Full, Frame -> True, FrameLabel -> {"radius r", "speed"}, 
    PlotMarkers -> {"\[FilledCircle]", 12}
   ]; 

Print["MFS done."];