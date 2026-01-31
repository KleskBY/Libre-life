# Libre-life

**Libre-life** is an experimental, open-source effort to reimplement *Half-Life* gameplay logic, entities, and asset pipelines on top of a **modern Quake-derived engine**, primarily **DarkPlaces**.

---

## Why Libre-life?

Half-Life introduced a rich entity system, scripted interactions, and immersive world logic that still holds up today.  
At the same time, Quake-derived engines such as DarkPlaces offer:

- Modern rendering (PBR, realtime lights, shadows)
- Cross-platform support
- A easy way for mod developers to release their mod as independet standalone game
- Open-source engines, formats and tooling
- Powerful scripting via QuakeC and extended compilers (FTEQCC)
- Preserve Half-Life's workflow and design
- Enable experimentation, education, and long-term preservation

---

## Why not just use Xash?
Although the merits of the Xash engine should not be underestimated, it represents a completely different workflow, and the Half-Life implementation on Xash is not superior. Currently, the FTE Quake engine is the absolute dominant force in technical terms and adds many technical solutions that are not present in Xash. Quake engines are more advanced and are developing much faster than Xash. What was implemented in Darkplaces in the 2010s is only relatively recently appearing in Xash.

---

## Project Goals

### Core Goals
- Reimplement Half-Life gameplay logic using **QuakeC**
- Port core entities and monster logic.
- Match original behavior as closely as possible, but fix common bugs that do not have hisotrical value.

---

## Technical Overview

### Engine
- **Primary target**: Zircon (DarkPlaces)
- **Secondary compatibility**: FTEQW / FTE-based engines

### Language & Tooling
- QuakeC (FTEQCC recommended)
- DarkPlaces engine extensions
- TrenchBroom for level design
- Blender for model conversion
- Custom conversion pipelines for:
  - Models (MDL/MD3/IQM)
  - Animations
  - Materials & textures

---

## Assets & Content Policy

Libre-life **does not include**:
- Valve's original models
- Valve's original textures
- Valve's sounds, maps, or scripts

### Asset Handling
- Users may supply their **own legally obtained assets**
- Conversion tools are provided
- Converted assets are for **personal use only**

---

## Legal & Licensing

### Project License
- **GPL-2.0**
- All original code written for Libre-life is open source

### Intellectual Property
*Half-Life* and related assets are © Valve Corporation property
This project is **not affiliated with Valve Corporation**.  
All trademarks belong to their respective owners.
Libre-life **does not contain Valve source code**.


## Project Status

🚧 **Work in progress**

Current focus areas:
- Entity system compability and complete Half-life BSP map support
- Weapon logic and HEV suit logic
- Mod compability

---

## Disclaimer

This project is **not affiliated with Valve Corporation**.  
All trademarks belong to their respective owners.

Libre-life exists to explore *how* Half-Life worked — not to replace it.

---

## Contributing

Contributions are welcome:
- QuakeC code
- Documentation
- Behavioral analysis
- Testing against original Half-Life behavior
- Providing or making assets (models, sounds, etc) with appropriate license

Please ensure all contributions are:
- Original work
- Free of proprietary code or assets

---

## Name Rationale

**Libre-life** emphasizes:
- *Libre* as in freedom, not price
- Open implementation
- Transparency and education
- Respect for original creators

---

If you enjoy this project, consider supporting open engines, open tooling, and open knowledge.
