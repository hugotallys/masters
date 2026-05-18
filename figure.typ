#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge, shapes

#set page(width: auto, height: auto, margin: 1cm)

#diagram(
  spacing: 2cm,
  cell-size: 1cm,
  
  // === NODES ===
  
  // Environment (Bottom)
  node(
    (2.25, 3), 
    [Environment], 
    shape: shapes.rect, 
    stroke: 1.2pt, 
    corner-radius: 6pt, 
    width: 3.5cm, 
    height: 1.2cm
  ),
  
  // Value Function / Critic (Middle Left)
  node(
    (1.5, 1.5), 
    align(center)[Value\ Function], 
    shape: shapes.rect, 
    stroke: 1pt, 
    width: 2.2cm, 
    height: 1.3cm
  ),
  node((1.0, 1.0), text(size: 9pt, style: "italic")[Critic]),
  
  // Policy / Actor (Top Right)
  node(
    (3.0, 0), 
    [Policy], 
    shape: shapes.rect, 
    stroke: 1pt, 
    width: 1.8cm, 
    height: 0.9cm
  ),
  node((3.0, 0.6), text(size: 9pt, style: "italic")[Actor]),
  
  // === PARAMETER ADJUSTMENT ARROWS ===
  
  // Policy update arrow (points up-left)
  edge((3.4, 0.4), (2.6, -0.4), "->", stroke: 0.8pt),
  
  // Value function update arrow (points down-left)
  edge((1.8, 1.1), (1.2, 1.9), "->", stroke: 0.8pt),

  // === EDGES & ROUTING ===
  
  // State path originating from Environment going left
  edge((2.25, 3), (0, 3), stroke: 1pt),
  
  // Vertical state tracking line with label correctly attached to the edge
  edge((0, 3), (0, 0), stroke: 1pt, label: text(size: 10pt)[state], label-side: left),
  
  // State entering Value Function (Critic)
  edge((0, 1.5), (1.5, 1.5), "->", stroke: 1pt),
  // Labels for the Critic input line ($s_t$ and $V(s_t)$)
  node((0.8, 1.25), [$s_t$]),
  node((0.8, 1.75), [$V(s_t)$]),
  
  // State entering Policy (Actor)
  edge((0, 0), (3.0, 0), "->", stroke: 1pt),
  
  // Reward path going straight up from Environment to Critic
  edge((1.5, 3), (1.5, 1.5), "->", stroke: 1pt),
  node((1.8, 2.3), text(size: 9pt)[reward]),
  
  // Action path (Red thick line) looping around the right side
  edge((3.0, 0), (4.5, 0), (4.5, 3), (2.25, 3), "->", stroke: (paint: red, thickness: 1.5pt)),
  node((4.8, 1.5), text(size: 10pt)[action]),
  
  // TD Error feedback loop from Critic to Actor's adjustment line
  edge((1.5, 1.5), (2.8, 0.2), "->", bend: -55deg, stroke: 0.8pt),
  node((2.3, 0.9), align(center)[#text(size: 9pt)[TD \ error]])
)