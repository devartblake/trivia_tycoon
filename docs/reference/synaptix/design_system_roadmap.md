# Synaptix "Neon Glass" Design System Roadmap

This document tracks the bespoke components of the Synaptix Design System, establishing a unique identity beyond standard Material or Cupertino designs.

## 🏗️ Core Components

| ID | Component | Status | Description |
| :--- | :--- | :--- | :--- |
| 1 | `SynaptixScaffold` | ✅ | The master foundation with demographic-aware gradients and touch-responsive atmosphere. |
| 2 | `GlassAppBar` | ✅ | Translucent header with glowing, mode-aware titles. |
| 3 | `NeonButton` | ✅ | Metallic, tactile button with integrated haptics and neon glows. |
| 4 | `NeuralBloomIndicator` | ✅ | Pulsing, biological replacement for standard loading spinners. |
| 5 | `NeuralProgressBar` | ✅ | Non-linear progress tracking using interconnected glowing energy nodes. |
| 6 | `AdaptiveGlassCard` | ✅ | Morphing container that adjusts geometry (radius/blur) per demographic mode. Optimized for Impeller. |
| 7 | `HolographicDialog` | ✅ | 3D-interactive modals that tilt based on user touch/parallax. |
| 8 | `InteractiveGlowSurface` | ✅ | Global layer rendering "liquid neon" trails that follow user movement. |
| 9 | `GlowTypography` | ✅ | High-fidelity text with multi-layered neon shadows and mode-based font selection. |
| 10 | `SegmentedSelectionHub` | ✅ | A floating glass lens for navigation that "liquifies" as it slides between options. |
| 11 | `DemographicAssetWrapper` | ✅ | Smart component that swaps icons and animations based on the user's age group. |

---

## 🎨 Component Breakdown

### 10. `SegmentedSelectionHub` (Next)
- **Concept**: A premium replacement for tabs or segmented buttons.
- **Logic**: A background "lens" stretches and morphs (liquifies) as it travels between items.

### 11. `DemographicAssetWrapper` (Next)
- **Concept**: Centralized demographic logic for assets.
- **Logic**: A single wrapper that renders different images or Lottie files depending on whether the user is in Kids, Teen, or Adult mode.

---

## 🎨 Design Principles
- **Demographic Adaptivity**: Every component must look and feel appropriate for the user's age.
- **Spatial Cohesion**: Use `Hero` and glass physics to make the UI feel like a physically connected space.
- **Sensory Juice**: High-fidelity haptics and particle feedback for all meaningful interactions.
- **Impeller Safety**: Avoid excessive `BackdropFilter` layers; use tinted containers with subtle blurs where performance is critical.
