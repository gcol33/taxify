# Build the animated hex logo man/figures/logo.svg.
#
# A polar classification tree of nine genera across plants, animals and fungi,
# kingdom -> phylum -> class -> order -> family -> genus, with each genus's
# classification read from taxify's published genus register. Behind it a
# polar graticule: one ring per rank and spokes from the root. The spokes turn
# slowly about the root, one step (15 degrees) every twelve seconds, so the
# end frame is the start frame and the loop never jumps, and the leaves pulse
# gently out of step with each other. Under prefers-reduced-motion still
# copies of the spokes and leaves replace the moving ones.
#
# Run from the package root:  Rscript data-raw/logo.R

out <- "man/figures/logo.svg"

col <- c(border = "#2B3A4A", paper = "#F5F6F8", grat = "#BCC2C9", branch = "#5C6166",
         Plantae = "#3F7A3D", Animalia = "#9E5E0F", Fungi = "#7A4F9E",
         name = "#2E6F9E")

# Hex geometry: pointy top, circumradius R, centred in a 520 x 600 viewBox.
W <- 520; H <- 600; R <- 300; cx <- W / 2; cy <- H / 2
hex_pts <- function(r) {
  a <- pi / 2 + (0:5) * pi / 3
  cbind(cx + r * cos(a), cy - r * sin(a))
}
pts_attr <- function(m) paste(sprintf("%.1f,%.1f", m[, 1], m[, 2]), collapse = " ")

# Classification from the genus register.
genera <- c("Quercus", "Pinus", "Poa",
            "Panthera", "Corvus", "Apis",
            "Amanita", "Boletus", "Aspergillus")
ranks <- c("kingdom", "phylum", "class", "order", "family", "genus")
reg <- vectra::tbl(taxify:::ensure_register(verbose = FALSE)) |>
  vectra::filter(genus %in% genera) |>
  vectra::collect()
reg <- as.data.frame(reg)[, ranks]
stopifnot(nrow(reg) == length(genera), !anyNA(reg))

# Fungi on the left, plants over the top, animals on the right; inside a
# kingdom the leaves follow the classification.
reg$kingdom <- factor(reg$kingdom, levels = c("Fungi", "Plantae", "Animalia"))
reg <- reg[do.call(order, reg[ranks]), ]
reg$kingdom <- as.character(reg$kingdom)

# Polar layout: the root sits above the name band; depth d lies on ring d.
# The fan spans 150 degrees and every leaf sits well inside the hex; the
# graticule behind it overfills the hex and is clipped. Nothing reaches into
# the name band.
ox <- cx; oy <- 330
ring_r <- 33
fan <- c(165, 15)
deg <- pi / 180
polar <- function(r, a) cbind(ox + r * cos(a * deg), oy - r * sin(a * deg))

n <- nrow(reg)
reg$angle <- seq(fan[1], fan[2], length.out = n)
paths <- lapply(seq_along(ranks), function(d) {
  apply(reg[, ranks[seq_len(d)], drop = FALSE], 1, paste, collapse = "/")
})
branch_d <- character()
node_angle <- function(d, key) mean(reg$angle[paths[[d]] == key])
for (d in seq_along(ranks)) {
  keys <- unique(paths[[d]])
  for (key in keys) {
    a <- node_angle(d, key)
    p0 <- polar((d - 1) * ring_r, a); p1 <- polar(d * ring_r, a)
    branch_d <- c(branch_d, sprintf("M%.1f,%.1fL%.1f,%.1f", p0[1], p0[2], p1[1], p1[2]))
  }
  # Arc on the parent's ring joining its children.
  if (d > 1) {
    for (parent in unique(paths[[d - 1]])) {
      kids <- unique(paths[[d]][paths[[d - 1]] == parent])
      if (length(kids) < 2) next
      ka <- vapply(kids, function(k) node_angle(d, k), 1)
      r <- (d - 1) * ring_r
      p0 <- polar(r, max(ka)); p1 <- polar(r, min(ka))
      branch_d <- c(branch_d, sprintf("M%.1f,%.1fA%g,%g 0 %d 1 %.1f,%.1f",
                                      p0[1], p0[2], r, r,
                                      as.integer(max(ka) - min(ka) > 180), p1[1], p1[2]))
    }
  }
}

leaf <- polar(length(ranks) * ring_r, reg$angle)
reg$x <- leaf[, 1]; reg$y <- leaf[, 2]
# Leaves breathe: the radius swells by about a fifth and back over three
# seconds, eased, each leaf at its own phase (golden-ratio steps, so
# neighbours never pulse together). SMIL, like the spokes, with a still copy
# for reduced motion.
t_pulse <- 3
leaf_r <- 12
dot <- function(i, animate) {
  anim <- if (animate) {
    sprintf('<animate attributeName="r" values="%g;%g;%g" dur="%gs" begin="-%.2fs" repeatCount="indefinite" calcMode="spline" keyTimes="0;0.5;1" keySplines="0.45 0 0.55 1;0.45 0 0.55 1"/>',
            leaf_r, 1.2 * leaf_r, leaf_r, t_pulse, t_pulse * ((i * 0.618034) %% 1))
  } else ""
  sprintf('<circle cx="%.1f" cy="%.1f" r="%g" fill="%s">%s</circle>',
          reg$x[i], reg$y[i], leaf_r, col[[reg$kingdom[i]]], anim)
}
leaves_moving <- vapply(seq_len(n), dot, "", animate = TRUE)
leaves_still <- vapply(seq_len(n), dot, "", animate = FALSE)

# Graticule: one ring per rank (still) and spokes every 15 degrees from the
# root, long enough to reach every corner of the hex. The turning copy rotates
# by exactly one spoke step per cycle, linear in time, so the loop is seamless.
# The turn is SMIL (animateTransform), which runs inside an <img> in every
# browser and can be seeked for the frame check.
step <- 15
rings_d <- paste(vapply(seq_len(length(ranks) + 3), function(d) {
  r <- d * ring_r
  sprintf("M%.1f,%.1fa%g,%g 0 1 0 %g,0a%g,%g 0 1 0 %g,0", ox - r, oy, r, r, 2 * r, r, r, -2 * r)
}, ""), collapse = "")
spoke_len <- 520
spokes_d <- paste(vapply(seq(0, 360 - step, by = step), function(a) {
  p <- polar(spoke_len, a)
  sprintf("M%.1f,%.1fL%.1f,%.1f", ox, oy, p[1], p[2])
}, ""), collapse = "")
t_turn <- 6

css <- sprintf('
.grat { fill: none; stroke: %1$s; stroke-width: 2; }
.branch { fill: none; stroke: %2$s; stroke-width: 4.5; stroke-linecap: round; }
.still { display: none; }
@media (prefers-reduced-motion: reduce) {
  .moving { display: none; }
  .still { display: inline; } }
', col[["grat"]], col[["branch"]])

name_y <- 472
svg <- c(
  sprintf('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" role="img" aria-label="taxify logo">', W, H, W, H),
  "<title>taxify logo</title>",
  sprintf("<style>%s</style>", css),
  "<defs>",
  sprintf('<clipPath id="inner"><polygon points="%s"/></clipPath>', pts_attr(hex_pts(R - 12))),
  "</defs>",
  sprintf('<polygon points="%s" fill="%s"/>', pts_attr(hex_pts(R - 12)), col[["paper"]]),
  '<g clip-path="url(#inner)">',
  sprintf('<path class="grat" d="%s"/>', rings_d),
  sprintf('<g class="grat moving"><path d="%s"/><animateTransform attributeName="transform" type="rotate" from="0 %.1f %.1f" to="-%d %.1f %.1f" dur="%gs" repeatCount="indefinite"/></g>',
          spokes_d, ox, oy, step, ox, oy, t_turn),
  sprintf('<path class="grat still" d="%s"/>', spokes_d),
  sprintf('<path class="branch" d="%s"/>', paste(branch_d, collapse = "")),
  sprintf('<circle cx="%.1f" cy="%.1f" r="9" fill="%s"/>', ox, oy, col[["branch"]]),
  '<g class="moving">', leaves_moving, '</g>',
  '<g class="still">', leaves_still, '</g>',
  sprintf('<text x="%.1f" y="%d" text-anchor="middle" font-family="Georgia, \'Times New Roman\', serif" font-style="italic" font-weight="bold" font-size="78" fill="%s" stroke="%s" stroke-width="10" stroke-linejoin="round" paint-order="stroke">taxify</text>',
          cx, name_y, col[["name"]], col[["paper"]]),
  "</g>",
  sprintf('<polygon points="%s" fill="none" stroke="%s" stroke-width="18" stroke-linejoin="round"/>', pts_attr(hex_pts(R - 9)), col[["border"]]),
  "</svg>"
)

dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
writeLines(svg, out, useBytes = TRUE)
message(sprintf("%s: %.0f KB", out, file.size(out) / 1024))
