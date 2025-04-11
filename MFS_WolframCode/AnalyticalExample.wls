#!/usr/bin/env wolframscript
(* ::Package:: *)

(* this requires a specific problem setup for R13 *)


Print["*******"];
Print["Analytical solution of R13."];

Get["AnalyticalSolution.wls"];


Print["Solving for integration constants."];

Kn = \[Tau];

solbc = Solve[BCeqns == 0, coefs][[1]];


Print["Converting to cartesian coordinates."];

basis[cphi_] = {{Cos[cphi], Sin[cphi]},{-Sin[cphi], Cos[cphi]}};

temperatureC[x_, y_] = temperature[Sqrt[x^2 + y^2], ArcTan[x, y]] /. scaling /. solbc /. ruleBessel;
rhoC[x_, y_] = rho[Sqrt[x^2 + y^2], ArcTan[x, y]] /. scaling /. solbc /. ruleBessel;

{ux[x_, y_], uy[x_, y_]} = {ur[Sqrt[x^2 + y^2], ArcTan[x, y]], 
                            uTheta[Sqrt[x^2 + y^2], ArcTan[x, y]]}.basis[ArcTan[x, y]] /. scaling /. solbc /. ruleBessel;

plotLegends = Placed[
   SwatchLegend[{Blue, Red, Black}, 
            (Style[#1, FontSize -> 15,FontFamily -> "Century Schoolbook"] & ) /@ {"\[CurlyTheta]=0", "\[CurlyTheta]=\[Pi]/4", "\[CurlyTheta]=\[Pi]/2"}], Scaled[{0.15, 0.86}]]

PlotExactTemperature = Plot[
    {temperatureC[r, 0], temperatureC[r*Cos[Pi/4], r*Sin[Pi/4]], temperatureC[r*Cos[Pi/2], r*Sin[Pi/2]]}, {r, R0, R1}, 
    Frame -> True, FrameLabel -> {"radius r", "temperature"}, PlotStyle -> {Blue, Red, Black},
    PlotLegends -> plotLegends,AspectRatio -> 1 ,BaseStyle -> {FontFamily -> "Century Schoolbook", FontSize -> 18}, PlotTheme -> "Grid"]; 

PlotExactVelocity = Plot[
    {Norm[{ux[r, 0], uy[r, 0]}], Norm[{ux[r*Cos[Pi/4], r*Sin[Pi/4]], uy[r*Cos[Pi/4], r*Sin[Pi/4]]}], 
     Norm[{ux[r*Cos[Pi/2], r*Sin[Pi/2]], uy[r*Cos[Pi/2], r*Sin[Pi/2]]}]}, {r, R0, R1}, 
     Frame -> True, FrameLabel -> {"radius r", "speed"}, PlotStyle -> {Blue, Red, Black},
     PlotLegends -> plotLegends,AspectRatio -> 1 ,BaseStyle -> {FontFamily -> "Century Schoolbook", FontSize -> 18}, PlotTheme -> "Grid"]; 



(* if necessary the solution can be saved as 3D surface plot here 
Get["AnalyticalPlot3D.wls"]; *)
