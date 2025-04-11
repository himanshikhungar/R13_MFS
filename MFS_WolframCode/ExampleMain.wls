#!/usr/bin/env wolframscript
(* ::Package:: *)

Print["Hello World!"];

ClearAll["Global`*"];


Print["Setup for a specific solution of R13."];

R0 = 1; (*Radius of inner circle*)
R1 = 2; (*Radius of outer circle*)
\[Tau] = 0.5; (*Knudsen number*)

(*Values of parameters in boundary conditions*)
facBC = 1; 
chi2value = 1; 
v0 = 1.; 
vR = -1.; 
p0 = 0.; 
eps = 10^(-5); 
temperature0 = 1.; 
temperature1 = 2.; 

chi2BC[r_, theta_] = Piecewise[{
                            {chi2value, r == R0}, {chi2value, r == R1}}]; 
temperatureBC[r_, theta_] = Piecewise[{
                            {temperature0, r == R0}, {temperature1, r == R1}}]; 
vtBC[r_, theta_] = Piecewise[{
                            {vR, r == R0}, {(-v0)*Sin[theta], r == R1}}]; 
vnBC[r_, theta_] = Piecewise[{
                            {0, r == R0}, {v0*Cos[theta], r == R1}}]; 
pBC[r_, theta_] = Piecewise[{
                            {0, r == R0}, {p0*Cos[theta], r == R1}}]; 
epspBC[r_, theta_] = Piecewise[{
                            {1, r == R0}, {1, r == R1}}]; 
epsvBC[r_, theta_] = Piecewise[{
                            {eps, r == R0}, {1, r == R1}}]; 

nn[R0] = -1; 
nn[R1] = 1; 
tt[R0] = -1; 
tt[R1] = 1; 
setup[r_, theta_] := {
  chi2 -> chi2BC[r, theta],
  temperatureW -> temperatureBC[r, theta], 
  vnW -> vnBC[r, theta], 
  vtW -> vtBC[r, theta], 
  pW -> pBC[r, theta], 
  epsp -> epspBC[r, theta], 
  epsv -> epsvBC[r, theta]}

(* initialize plots with dummy values *)
PlotExactTemperature = Nothing;
PlotExactVelocity = Nothing;
PlotMFSTemperature = Nothing;
PlotMFSVelocity = Nothing;


 (*use this command for an analytical solution *)
Get["AnalyticalExample.wls"]; 


(* use this command for an MFS solution *)
Get["MFS_Example.wls"];


Print["Saving a comparison as plot."];

output=Export["R13_MFS_analytical.png",
GraphicsRow[{   
   Show[{PlotExactVelocity, PlotMFSVelocity}, PlotLabel -> "Analytical (solid), MFS (symbols)"],
   Show[{PlotExactTemperature, PlotMFSTemperature}, PlotLabel -> "Analytical (solid), MFS (symbols)"]
}, 
   ImageSize -> 900]];

Print["Done: "<>output];
