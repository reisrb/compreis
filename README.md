# Compreis

iOS shopping list app built with SwiftUI and SwiftData.

## Features

- **Shopping lists** — create named lists with an optional market date and pinned location
- **Item tracking** — add products with price per unit or per kg; stepper for quantities; calculator-style right-to-left weight input for kg items
- **Automatic totals** — real-time subtotal per item and grand total at the bottom of the list
- **Price history** — autocomplete suggestions from past purchases when adding items; autocompletes name, price and unit
- **Finalize & copy** — mark a shopping trip as done; optionally copy all items to a new list for the next trip
- **Location** — search for a supermarket via Apple Maps when creating a list; details view shows a mini map with a pin at the chosen location
- **Report** — monthly spending totals, average per trip, last 7 days; tap "Examples" to preview with mock data
- **Locale-aware currency** — currency symbol and format follow the device region (BRL in Brazil, USD in the US, EUR in Europe, etc.)
- **Dark mode** — follows system appearance

## Screenshots

| Lists | Items | Details | Report |
|-------|-------|---------|--------|
| Active and finalized lists with totals | Items with unit/kg pricing and total | Mini map + metadata | Monthly totals and averages |

## Tech stack

| Layer | Choice |
|-------|--------|
| UI | SwiftUI |
| Persistence | SwiftData |
| Maps & search | MapKit |
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

## License

MIT
