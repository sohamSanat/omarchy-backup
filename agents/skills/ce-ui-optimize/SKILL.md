---
name: ce-ui-optimize
description: "Autonomous UI optimization and smoothness engine for web browser and phone/mobile interfaces. Use after implementation and initial review to ensure interfaces are buttery smooth (60/120fps hardware-accelerated animations, organic easing, tactile press feedback, zero-jank layout stability) and fully responsive for the target form factor (web browser desktop/tablet or phone app)."
argument-hint: "[target directory or URL, e.g. index.html or /home/soham/Projects/...]"
---

# Autonomous UI Optimization & Buttery Smoothness (`ce-ui-optimize`)

Execute this specialized Compound Engineering optimization pass after code implementation and adversarial review are complete. 
Your goal is to transform functional, reviewed UI into an elite, buttery-smooth, production-grade interface tailored precisely for its target environment: **Web Browser** or **Phone / Mobile App**.

---

## 1. Target Form Factor Detection

Examine the codebase and user intent to categorize the project:

1. **Web Browser Experience (Website, SaaS, Web Dashboard, Landing Page)**:
   - Must look spectacular on Desktop viewports (1440x900, 1280x800).
   - Must be fully responsive on Tablet (1024x768, 768x1024) and Mobile browsers (375x812, 390x844).
   - Features fluid typography, dynamic grid/flex wrapping, desktop hover micro-interactions, and responsive collapsing navigation.

2. **Phone / Mobile App Experience (PWA, Mobile App, Native/Hybrid, Mobile Dashboard)**:
   - Mobile-first ergonomics: bottom navigation bar or floating pill navigation, thumb-zone optimized.
   - Fixed header with frosted glass backdrop blur (`backdrop-filter: blur(12px)` / `-webkit-backdrop-filter: blur(12px)`).
   - Safe-area insets (`padding-top: env(safe-area-inset-top)`, `padding-bottom: env(safe-area-inset-bottom)`).
   - Fast tap response (`touch-action: manipulation`) to eliminate 300ms mobile tap delay and accidental zoom.
   - Smooth touch momentum scrolling (`-webkit-overflow-scrolling: touch`).

---

## 2. Dual-Viewport Audit (Mandatory Screenshots)

Never assume responsiveness without visual proof:

1. **Desktop Audit**:
   ```bash
   omagent-screenshot <path_or_url> desktop_audit.png
   ```
2. **Phone / Mobile Audit**:
   ```bash
   omagent-screenshot <path_or_url> mobile_audit.png --mobile
   ```
3. **Inspect the Visuals**:
   - Inspect both images using your file/image viewing tool.
   - **Horizontal Scroll Check**: Confirm no element forces horizontal body overflow (`overflow-x: hidden` on root).
   - **Text Wrapping Check**: Verify no heading text breaks awkwardly or collides with badges.
   - **Tap Target Check**: Confirm interactive buttons and links have at least 44x44px clickable area on mobile.

---

## 3. "Smooth as Butter" Animation & Interaction Engineering

A UI is only "smooth as butter" when animations run at 60–120fps with zero layout thrashing. Implement these strict engineering rules:

### A. Zero-Jank Hardware Acceleration (Composite-Only Animations)
- **THE GOLDEN RULE**: ONLY animate `transform` and `opacity`.
  - **NEVER** animate `height`, `width`, `top`, `left`, `margin`, or `padding` on hover or transitions. These trigger CPU layout recalculation (reflow) and cause micro-stutter.
  - To expand or collapse: use `transform: scaleY(...)` or CSS grid `grid-template-rows: 0fr -> 1fr` with `opacity`.
  - To move elements: use `transform: translateY(...)` or `translateX(...)`.
- **GPU Promotion**: Apply `will-change: transform` or `transform: translateZ(0)` to high-frequency moving elements (drawers, modal sheets, sticky headers) to promote them to dedicated GPU layers.

### B. Organic Easing Curves (No Linear or Stiff Transitions)
Ditch default `linear` or standard `ease`. Use organic, spring-damped cubic bezier curves:
- **Snappy Tactile Hover / Press**:
  `cubic-bezier(0.16, 1, 0.3, 1)` (snappy spring deceleration, duration: 150ms–220ms).
- **Smooth Drawer / Sheet Slide**:
  `cubic-bezier(0.32, 0.72, 0, 1)` (fluid iOS-grade sheet transition, duration: 280ms–350ms).
- **Subtle Elevation / Lift**:
  `cubic-bezier(0.2, 0, 0, 1)` (Apple-style natural rise, duration: 200ms–240ms).

### C. Tactile Micro-Interactions on Every Interactive Element
Every button, card, and interactive control must feel alive and responsive under cursor and touch:
- **Buttons & Interactive Pills**:
  ```css
  .btn {
    transition: transform 180ms cubic-bezier(0.16, 1, 0.3, 1),
                box-shadow 180ms cubic-bezier(0.16, 1, 0.3, 1),
                background-color 150ms ease;
  }
  .btn:hover {
    transform: translateY(-1.5px);
    box-shadow: 0 6px 20px -4px rgba(0, 0, 0, 0.15);
  }
  .btn:active {
    transform: scale(0.96) translateY(0);
    box-shadow: 0 2px 8px -2px rgba(0, 0, 0, 0.1);
  }
  ```
- **Cards & Interactive Containers**:
  - Gentle lift on hover: `transform: translateY(-2px);`
  - Subtle border highlight or inner glow.
- **Tabs, Segmented Controls & Toggles**:
  - Use an active indicator pill that slides smoothly between options with `transform: translateX(...)` rather than abrupt color switching.

### D. Layout Stability & Zero Cumulative Layout Shift (CLS = 0)
- Explicit aspect ratios on media containers (`aspect-ratio: 16/9`, `aspect-ratio: 1/1`).
- Avoid jumping layouts while content loads; provide skeleton shapes or fixed minimum container bounds.

### E. Scroll Polish
- `html { scroll-behavior: smooth; }`
- Clean sleek scrollbar styling:
  ```css
  ::-webkit-scrollbar { width: 6px; height: 6px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: rgba(150, 150, 150, 0.3); border-radius: 9999px; }
  ::-webkit-scrollbar-thumb:hover { background: rgba(150, 150, 150, 0.5); }
  ```

### F. Motion Accessibility
Always respect user preferences:
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

---

## 4. Verification & Output Checklist
- [ ] Captured both desktop and mobile screenshots.
- [ ] Confirmed zero horizontal scrolling on mobile.
- [ ] Verified hardware-accelerated animations (transform/opacity only).
- [ ] Verified tactile `:hover` and `:active` scale/press feedback on buttons.
- [ ] Verified responsive layout collapses gracefully on narrow screens.
- [ ] Final visual re-inspection with `omagent-screenshot`.
