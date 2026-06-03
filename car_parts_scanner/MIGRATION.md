# OmniDrive UI/UX Modernization & Migration Guide

This guide documents the centralized design tokens and motion-helper utilities introduced during the visual and motion overhaul of the OmniDrive AI Flutter application.

---

## 1. Centralized Design Tokens (`lib/core/theme/`)

To achieve a cohesive, futuristic "Dark Neon / HUD" visual style, all hardcoded colors, spacing, and font sizes have been migrated to the core theme module.

### AppColors (`lib/core/theme/app_colors.dart`)
Centralized neon/dark color palette:
* `AppColors.background`: Deep space backdrop (`#07070C`).
* `AppColors.surface`: Dark structural base (`#0E0E18`).
* `AppColors.card`: Card container backdrop (`#16161F`).
* `AppColors.border`: Sleek element borders (`#24243A`).
* `AppColors.cyan` / `AppColors.cyanDark`: Primary customer action accents (`#22D3EE` / `#0EA5E9`).
* `AppColors.violet` / `AppColors.violetDark`: Secondary performance action accents (`#8B5CF6` / `#6366F1`).
* `AppColors.lime` / `AppColors.magenta`: Vibrant POP highlight accents.
* **Role Colors**:
  * `AppColors.customer` (Cyan)
  * `AppColors.vendor` (Amber, `#FBBF24`)
  * `AppColors.rider` (Violet, `#A78BFA`)
  * `AppColors.admin` (Rose/Red, `#FB7185`)
* **Text Contrast (WCAG AA Compliant)**:
  * `AppColors.textPrimary`: Pure white (`#FFFFFF`).
  * `AppColors.textSecondary`: Soft gray (`#B4B4CC`).
  * `AppColors.textMuted`: High-contrast slate-purple (`#8A8AAB`) with verified 5.4:1 contrast ratio against the `#07070C` background.

### AppSpacing (`lib/core/theme/app_spacing.dart`)
Standardized layout paddings, margins, and radii:
* Spacing Scale: `AppSpacing.xxs` (4pt), `AppSpacing.xs` (8pt), `AppSpacing.sm` (12pt), `AppSpacing.md` (16pt), `AppSpacing.lg` (24pt), `AppSpacing.xl` (32pt).
* Border Radii: `AppSpacing.radiusSm` (4px), `AppSpacing.radiusMd` (8px), `AppSpacing.radiusLg` (12px), `AppSpacing.radiusXl` (16px), `AppSpacing.radius2Xl` (24px).

### AppTypography (`lib/core/theme/app_typography.dart`)
Typography tokens using `GoogleFonts.inter`:
* Text scales are standardized to eliminate mismatching sizes and font weights.

### AppGradients (`lib/core/theme/app_gradients.dart`)
Centralized mesh and linear gradients:
* Gradients are provided for all 4 user roles (`customer`, `vendor`, `rider`, `admin`) to unify backgrounds and action buttons.

### AppShadows (`lib/core/theme/app_shadows.dart`)
Centralized shadows for high-tech glow effects:
* Cards and active neon indicators use glows rather than heavy opaque drop shadows.

---

## 2. Motion Helpers (`lib/core/motion/`)

Cohesive motion effects are integrated into all refactored screens.

### Staggered List Entrance (`lib/core/motion/motion_stagger.dart`)
* **Widget**: `StaggeredEntrance`
* **Usage**: Wraps list or grid children to introduce a staggered slide-up and fade-in entry.
* **Example**:
  ```dart
  ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => StaggeredEntrance(
      index: index,
      child: ItemCard(item: items[index]),
    ),
  )
  ```

### Interactive Touch Feedback (`lib/core/motion/motion_tappable.dart`)
* **Widget**: `TappableScale`
* **Usage**: Replaces generic buttons and gesture detectors with a haptic, responsive scale-down interaction.
* **Example**:
  ```dart
  TappableScale(
    onTap: () => doAction(),
    child: Container(
      padding: EdgeInsets.all(16),
      child: Text('Press Me'),
    ),
  )
  ```

### Animated Counters (`lib/core/motion/motion_counter.dart`)
* **Widget**: `MotionCounter`
* **Usage**: Animates number transitions and prices count-ups.
* **Example**:
  ```dart
  MotionCounter(
    value: price,
    prefix: 'Rs ',
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  )
  ```

### Route Transitions (`lib/core/motion/motion_transitions.dart`)
* **Route**: `PremiumPageRoute`
* **Usage**: Custom page router delivering smooth slide-and-fade page transactions.

---

## 3. Deprecation and Cleanup Guidelines

* **Opacity Deprecations**: Avoid using `withOpacity()`. Use `withValues(alpha: ...)` instead to comply with modern Flutter SDK guidelines:
  ```diff
  - Colors.black.withOpacity(0.5)
  + Colors.black.withValues(alpha: 0.5)
  ```
* **Hex Color Cleanups**: Never hardcode colors via `Color(0xFF...)` outside of `lib/core/theme/app_colors.dart`.
* **Reduced Motion Compliance**: All custom widgets (including `StaggeredEntrance`, `TappableScale`, and `MotionCounter`) respect `MediaQuery.of(context).disableAnimations`. If system-level reduced motion is toggled, animations instantly fall back to their static states.
