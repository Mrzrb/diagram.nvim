local d2 = require("diagram/renderers/d2")
local gnuplot = require("diagram/renderers/gnuplot")
local mermaid = require("diagram/renderers/mermaid")
local plantuml = require("diagram/renderers/plantuml")
local svg = require("diagram/renderers/svg")

return {
  mermaid = mermaid,
  plantuml = plantuml,
  d2 = d2,
  gnuplot = gnuplot,
  svg = svg,
}
