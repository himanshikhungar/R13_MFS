#!/usr/bin/env wolframscript
(* ::Package:: *)

Print["RandomMain.wls — driver for random-geometry MFS run (R13)"];

ClearAll["Global`*"];

(* Parameters that affect BCs and MFS; adjust as needed *)
Rout = 1.0;
R0 = 0.5;
\[Tau] = 0.3;
fac = 1;
\[Chi]2 = 1;
v0 = 1;
vR = 0.0;
p0 = 0.0;
eps = 10^-5;
temperature0 = 0.; 
temperature1 = 0.; 

chi2BC[r_, theta_] = Piecewise[{
                            {chi2value, r == R0}, {chi2value, r == Rout}}]; 
temperatureBC[r_, theta_] = Piecewise[{
                            {temperature0, r == R0}, {temperature1, r == Rout}}]; 
vtBC[r_, theta_] = Piecewise[{
                            {vR, r == R0}, {(-v0)*Sin[theta], r == Rout}}]; 
vnBC[r_, theta_] = Piecewise[{
                            {0, r == R0}, {v0*Cos[theta], r == Rout}}]; 
pBC[r_, theta_] = Piecewise[{
                            {0, r == R0}, {p0*Cos[theta], r == Rout}}]; 
epspBC[r_, theta_] = Piecewise[{
                            {1, r == R0}, {1, r == Rout}}]; 
epsvBC[r_, theta_] = Piecewise[{
                            {eps, r == R0}, {1, r == Rout}}]; 

nn[R0] = -1; 
nn[Rout] = 1; 
tt[R0] = -1; 
tt[Rout] = 1; 
setup[r_, theta_] := {
  chi2 -> chi2BC[r, theta],
  temperatureW -> temperatureBC[r, theta], 
  vnW -> vnBC[r, theta], 
  vtW -> vtBC[r, theta], 
  pW -> pBC[r, theta], 
  epsp -> epspBC[r, theta], 
  epsv -> epsvBC[r, theta]}


(* Generate and persist random geometry *)
Print["generating geometry..."];
Get[FileNameJoin[{DirectoryName[$InputFileName], "Random", "RandomGeometry.wls"}]]; (* This creates Xb, Xs, Nlist, Tlist, filteredPoints, regionFunction, etc. *)

(* Run the MFS assembly and produce plots *)
Print["running MFS on random geometry..."];
Get[FileNameJoin[{DirectoryName[$InputFileName], "Random", "MFS_Random.wls"}]];

(* Evaluate velocities on filteredPoints (parallel) *)
Print["evaluating velocity on grid"];
velocities = ParallelTable[velMFS[filteredPoints[[i]]], {i, Length[filteredPoints]}];
velocityData = Transpose[{filteredPoints, velocities}];

(* Stream plot *)
Print["creating stream plot (stream_random.png)"];
streamPlot = ListStreamPlot[velocityData, RegionFunction -> regionFunction,
  FrameLabel -> {"x", "y"}, RotateLabel -> False, StreamPoints -> Fine,
  PlotRange -> {{-outerR - 0.05, outerR + 0.05}, {-outerR - 0.05, outerR + 0.05}},
  RegionBoundaryStyle -> Black, RegionFillingStyle -> Automatic, FrameStyle -> Black];
  
Export["stream_random.png", streamPlot];

Print["RandomMain done. Output images: stream_random.png"];