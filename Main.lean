import VersoSlides
import Slides

open VersoSlides

def myExtraCss : CssFile where
  filename := "custom.css"
  contents := ⟨include_str "custom.css"⟩

def main : IO UInt32 :=
  slidesMain
    (config := {
      theme := "dracula",
      slideNumber := true,
      transition := "slide",
      extraCss := #[myExtraCss]
      }
    )
    (doc := %doc Slides)
