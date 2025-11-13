#!/usr/bin/env wolframscript
(* ::Package:: *)


(* ---------- geometry generator (reproducible) ---------- *)
MakeBoundaryGroup[center : {cx_, cy_}, r_, h_] := Module[
  {ni, angles, pts},
  ni = Max[1, Ceiling[2 Pi r/h]];
  angles = Table[2 Pi (k - 1)/ni, {k, 1, ni}];
  pts = Table[{cx + r Cos[θ], cy + r Sin[θ]}, {θ, angles}];
  <|"Center" -> center, "r" -> r, "ni" -> ni, "Angles" -> angles, 
   "BoundaryPts" -> pts|>
];

GenerateRandomCircles[n_Integer, dmin_, rRange : {rmin_, rmax_}] := Module[
  {circles = {}, attempt = 0, maxAttempts = 10000, r, x, y, valid},
  While[Length[circles] < n && attempt < maxAttempts,
    attempt++;
    r = RandomReal[{rmin, rmax}];
    {x, y} = RandomReal[{-1 + r + dmin, 1 - r - dmin}, 2];
    If[Sqrt[x^2 + y^2] + r + dmin > 1, Continue[]];
    valid = True;
    Do[
      If[Norm[{x, y} - {c[[1]], c[[2]]}] < r + c[[3]] + dmin,
        valid = False; Break[]
      ],
      {c, circles}
    ];
    If[valid, AppendTo[circles, {x, y, r}]];
  ];
  If[Length[circles] < n,
    Print["Warning: Could only place ", Length[circles], " circles after ", attempt, " attempts."]
  ];
  circles
];
 
SeedRandom[2143]; (* reproducible geometry *)
numInner = 7;
dmin = 0.04;
rRange = {0.1, 0.25};
h = 0.03;
alpha = 1.5;
includeOuterSing = True;
outerR = 1.0;

(* generate circles and groups *)
circles = GenerateRandomCircles[numInner, dmin, rRange];
Print["placed ", Length[circles], " inner circles."];

outerGroup = MakeBoundaryGroup[{0, 0}, outerR, h];
innerGroups = Map[Function[c, MakeBoundaryGroup[{c[[1]], c[[2]]}, c[[3]], h]], circles];
boundaryGroups = Prepend[innerGroups, outerGroup];

(* flatten boundary points *)
Xb = Flatten[Map[#["BoundaryPts"] &, boundaryGroups], 1];
Print["total boundary points Xb length = ", Length[Xb]];

(* singularities: same centers, scaled radii only *)
singularityGroups = MapIndexed[
  Function[{g, idx},
    Module[{i = First[idx], r = g["r"], center = g["Center"], rSing, singPts},
      rSing = If[i == 1,
        If[includeOuterSing, r*alpha, Missing["NoSing"]],
        r/alpha
      ];
      singPts = If[rSing === Missing["NoSing"], {}, Table[center + rSing {Cos[θ], Sin[θ]}, {θ, g["Angles"]}]];
      <|"Center" -> center, "rSing" -> rSing, "SingPts" -> singPts|>
    ]
  ],
  boundaryGroups
];

Xs = Flatten[Map[#["SingPts"] &, singularityGroups], 1];
Print["total singularity points Xs length = ", Length[Xs]];

(* normals and tangents (per boundary point, same order as Xb) *)
Nlist = Flatten[
  MapIndexed[
    Function[{g, idx},
      Module[{i = First[idx], angles = g["Angles"], sgn},
        sgn = If[i == 1, 1, -1];
        Table[sgn Normalize[{Cos[θ], Sin[θ]}], {θ, angles}]
      ]
    ],
    boundaryGroups
  ],
  1
];

Tlist = ({-#[[2]], #[[1]]} & /@ Nlist);

(* Extract centers/radii of inner circles for region construction *)
centers = Rest[boundaryGroups][[All, "Center"]];
radii = Rest[boundaryGroups][[All, "r"]];

(* Build region with holes (rr) and a convenient RegionFunction *)
rr = Fold[RegionDifference, Disk[{0, 0}, outerR], Table[Disk[centers[[i]], radii[[i]]], {i, Length[centers]}]];
regionFunction = Function[{x, y}, RegionMember[rr, {x, y}]];

(* Build grid and filteredPoints (user notebook used gridSpacing 0.05) *)
gridSpacing = 0.05;
boundingBox = {{-outerR, -outerR}, {outerR, outerR}};
gridPoints = Flatten[
  Table[{x, y}, {x, boundingBox[[1, 1]], boundingBox[[2, 1]], gridSpacing}, {y, boundingBox[[1, 2]], boundingBox[[2, 2]], gridSpacing}],
  1
];
filteredPoints = Select[gridPoints, regionFunction @@ # &];

Print["filtered grid points count = ", Length[filteredPoints]];

(* Visualization (optional) *)
 geom = Graphics[{LightGray, Disk[{0, 0}, outerR], 
  Blue, Table[Disk[centers[[i]], radii[[i]]], {i, Length[centers]}],
   Red, PointSize[0.01], Point[Xb],
   Green, PointSize[0.01], Point[Xs],
   Orange, Arrowheads[0.02],
   Table[Arrow[{Xb[[i]], Xb[[i]] + 0.08 Nlist[[i]]}], {i, 1, Length[Xb], Max[1, Floor[Length[Xb]/170]]}],
   Table[Arrow[{Xb[[i]], Xb[[i]] + 0.08 Tlist[[i]]}], {i, 1, Length[Xb], Max[1, Floor[Length[Xb]/170]]}]},
  AspectRatio -> 1, PlotRange -> All];
Export["geom.png", geom]

Print["RandomGeometry.wls done. Geometry variables available: boundaryGroups, Xb, Xs, Nlist, Tlist, centers, radii, rr, filteredPoints, regionFunction"];
