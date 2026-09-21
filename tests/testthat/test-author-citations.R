# author_citations_agree(): the last concept test in pick_own_concept(). The
# pairs are citations of one name as two sources write it, taken from the
# wcvp asset against COL, WFO and GBIF.

test_that("citations of one name written differently agree", {
  same <- list(
    c("Greuter", "(Rech.f.) Greuter"),
    c("Chr.P.Sm. ex Link", "C.Sm. ex Link"),
    c("Ruiz & Pav. ex Wawra", "Wawra"),
    c("Rech.fil. & Schiman-Czeika", "Rech.f. & Schiman-Czeika"),
    c("(Sch.Bip. ex Klatt) R.K.Jansen, N.A.Harriman & Urbatsch",
      "(Klatt) R.K.Jansen, N.A.Harriman & Urbatsch"),
    c("D.Styles", "D.G.A.Styles"),
    c("(Bemth.) N.A.Wakef.", "(Benth.) N.A.Wakef."),
    c("A.St.-Hil.", "A.St.-Hil. & Moq."),
    c("Y.Wan & Chang C.Huang", "Y.Wan & C.C.Huang"),
    c("Vell.", "(Vell.) Triana"),
    c("Millsp.", "Millsp. ex Greenm."),
    c("(Blume ex C.Müll.) Kalkman", "(Blume ex Müll.Berol.) Kalkman"),
    c("Wall. ex A.DC.", "Wall. ex G.Don"),
    c("Mc Coy", "T.N.McCoy"),
    c("(Benth. ex A.DC.) A.Heller", "(Benth.) Jeps.")
  )
  for (p in same) {
    expect_true(author_citations_agree(p[1], p[2]), info = paste(p, collapse = " / "))
    expect_true(author_citations_agree(p[2], p[1]), info = paste(p, collapse = " / "))
  }
})

test_that("citations of different names do not agree", {
  different <- list(
    c("Michx.", "Hoppe & Hornsch. ex Bluff & Fingerh."),
    c("L.f.", "L."),
    c("L.", "Mill."),
    c("Rose", "Lowe"),
    c("(Lam.) Mez", "(Sw.) Mez"),
    c("Labill.", "Maiden, Blakely & Simmonds"),
    c("(Jord. & Fourr.) Baker", "(Haw.) Baker"),
    c("Costea & Stefanović", "Costea & M.A.R.Wright")
  )
  for (p in different) {
    expect_false(author_citations_agree(p[1], p[2]), info = paste(p, collapse = " / "))
  }
  expect_false(author_citations_agree(NA_character_, "L."))
})
