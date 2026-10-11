import React from 'react';
import { createRoot } from 'react-dom/client';
import { flushSync } from 'react-dom';
import { RobotHead } from 'robot-heads';

/**
 * Offline head baker. Mounts one RobotHead and drives it with a synthetic
 * fixed-step clock so every bake is byte-identical (the library's animation is
 * a deterministic function of elapsed time and its seed prop).
 */
const STATES = ['idle', 'thinking', 'searching', 'working', 'error', 'happy'];

/** Head outline. Set by the baker (see SHAPE in bake.mjs); defaults to the
 *  library's own default so a bare `qs`-less run still works. */
const SHAPE = window.__BAKE_SHAPE || 'rectangle';

let currentState = 'idle';
let currentPalette = null;
let root = null;

/** Synchronous commit so the tick stream is always aligned to the DOM. */
function paint() {
  flushSync(() => {
    root.render(
      React.createElement(RobotHead, {
        state: currentState,
        shape: SHAPE,
        size: 56,
        seed: 0.37,
        speed: 1,
        interactive: false,
        floorShadow: false,
        antenna: true,
        ...currentPalette,
      })
    );
  });
}

function ensureRoot() {
  if (!root) {
    root = createRoot(document.getElementById('root'));
    paint();
  }
}

window.__bake = {
  setState(state) {
    ensureRoot();
    currentState = state;
    paint();
  },
  setPalette(palette) {
    ensureRoot();
    currentPalette = palette;
    paint();
  },
  /** Device-pixel size of the head canvas, for the atlas layout. */
  canvasInfo() {
    const c = document.querySelector('canvas');
    return { width: c.width, height: c.height };
  },
  /** Capture the current canvas as a PNG data URL. */
  capture() {
    const c = document.querySelector('canvas');
    return c.toDataURL('image/png');
  },
};

ensureRoot();
