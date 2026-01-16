## Waffle

A recreation of Windoes. It's WIP!

- If you install illogical-impulse fully, you can press Super+Alt+W to switch to this style.
- If you're just copying the Quickshell config, run the config as usual (`qs -c ii`) then run `qs -c ii ipc call panelFamily cycle`

### Challenges

- Qt is not Gtk and definitely not React
  - We don't get directional border on QtQuick `Rectangle`s like in CSS. I was able to get around this with manual drawing, but it was a bit more work

- Fluent Icons is difficult to use, compared to Material Symbols
  - No React, so no clean use via a library.
  - If we use the font, there's no proper, searchable **codepoint** cheatsheet like Nerd Fonts, and there's no ligatures
  - I resorted to downloading individual SVGs. Not that nice, but it's better than scanning the whole table of icons every time I want one. For this we have fluenticon.com and fluenticons.co, but icons are awkwardly named and there's no alias. Why is the reload/refresh icon called "arrow-sync"? Well, the name is not misleading, but arguably reload/refresh are more common actions. From Fluent Design's [page on Iconography](https://fluent2.microsoft.design/iconography):

  > Fluent system icons are literal metaphors and are named for the shape or object they represent, not the functionality they provide

  "sync" is functionality.

