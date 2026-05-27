# Compreis

iOS shopping list app built with SwiftUI and SwiftData.

## Features

### Lists
- **Multiple lists** — active and finalized lists in separate sections; swipe to delete
- **Templates** — default templates (Essencial, Do mês) and custom user templates; reusable across trips
- **Editable default templates** — add or remove items per category; changes are respected when creating new lists
- **"Use as template"** — convert any finalized list into a template (creates a copy; original stays intact)
- **Location** — search for a supermarket via Apple Maps or tap on the map; mini map preview in list details
- **Market date** — optional date and time for the shopping trip

### Items
- **Categories** — Hortifruti, Carnes, Peixaria, Laticínios, Padaria, Bebidas, Congelados, Mercearia, Higiene, Limpeza, Outros
- **Unit or kg pricing** — stepper for unit quantity; calculator-style right-to-left weight input for kg items
- **Cash-register price input** — digits fill right-to-left, always formatted as `X,XX`
- **Checkboxes** — mark items as picked; picked items collapse into a per-category cart section
- **Cart sheet** — tap the cart button in the footer to see all picked items grouped by category with subtotals
- **Price history** — autocomplete from past purchases (name, price, unit, category)
- **Open Food Facts search** — product suggestions from the Open Food Facts database while typing

### Totals & tracking
- **Real-time totals** — estimated total in the footer; switches to "R$ X in cart / of R$ Y estimated" as items are picked
- **Finalize** — close a trip; optionally edit the actual total paid and copy items to a new list

### Templates
- **Default section** — Essencial (~34 items) and Do mês (~62 items) always visible in Templates; fully editable
- **My templates** — create, edit and delete personal templates
- **Preview** — tap "Ver X itens incluídos" before creating a list to see all items by category

### Market prices
- **Per-market price history** — prices saved per product per market when confirming items in the cart
- **Cheapest market chip** — items show a green hint and an "Go" button when a cheaper price exists at another market
- **Market spending report** — finalized lists grouped by market with total spent and average per trip
- **Basket comparison** — ranks markets by total cost for products available in ≥2 markets (crown on cheapest)
- **Product detail** — tap a product in the catalogue to see its prices ranked by market

### Categories
- **Custom categories** — create categories with a custom name, icon (SF Symbols) and color
- **Predefined categories** — Hortifruti, Carnes, Peixaria, Laticínios, Padaria, Bebidas, Congelados, Mercearia, Higiene, Limpeza, Outros

### Prices
- **CONAB integration** — when a list has a location, typing a product name shows a reference price from CONAB/PROHORT (wholesale CEASA price for the list's state); covers ~48 produce and poultry items
- **Price seeding** — prices from ProdutoHistorico are applied to template items when a list is created

### Data & sync
- **Export** — generate a JSON file with all lists, items, categories, pick status, template flags and coordinates
- **Import** — import a JSON backup from another device; full round-trip fidelity
- **Google Sheets sync** — optional OAuth integration; syncs lists and items to a spreadsheet on finalize
- **iCloud** — SwiftData store backed by iCloud for automatic backup across devices

## Tech stack

| Layer | Choice |
|-------|--------|
| UI | SwiftUI |
| Persistence | SwiftData |
| Maps & search | MapKit + CLGeocoder |
| Price reference | CONAB PROHORT (Pentaho endpoint) + Open Food Facts |
| Deployment target | iOS 17+ |
| Language | Swift 6 |

## Getting started

Requirements: **Xcode 16+** and **[XcodeGen](https://github.com/yonaskolb/XcodeGen)**

```bash
# Install XcodeGen if needed
brew install xcodegen

# Clone and generate the Xcode project
git clone git@github.com:reisrb/compreis.git
cd compreis
xcodegen generate
open Compreis.xcodeproj
```

Sign with your Apple ID in **Signing & Capabilities**, select your device or simulator, and run.

## Running on a physical iPhone

1. Connect iPhone via USB
2. Enable **Developer Mode** on the device (Settings → Privacy & Security → Developer Mode)
3. In Xcode → Signing & Capabilities → set Team to your personal Apple ID
4. Select your device as the run target → ▶ Run

## Localization

Base language: **English** (`en.lproj/Localizable.strings`)  
Portuguese: `pt-BR.lproj/Localizable.strings`

SwiftUI `Text("key")` automatically resolves to the active locale via `LocalizedStringKey`. Add a new language by creating a `<locale>.lproj/Localizable.strings` file and registering the locale in Xcode project settings (Info → Localizations).

## License

MIT
