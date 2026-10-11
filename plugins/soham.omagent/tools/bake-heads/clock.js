/**
 * A deterministic stand-in for the browser's frame clock, installed before any
 * page script runs. The library advances its simulation from the rAF timestamp
 * delta, so a fixed step makes the whole animation reproducible.
 *
 * Exposes window.__clock.tick(dtSeconds), which delivers one frame to every
 * queued rAF callback with a monotonically increasing timestamp.
 */
(() => {
  let now = 0;
  const callbacks = new Map();
  let nextId = 1;

  window.requestAnimationFrame = (cb) => {
    const id = nextId++;
    callbacks.set(id, cb);
    return id;
  };
  window.cancelAnimationFrame = (id) => {
    callbacks.delete(id);
  };

  // The library clamps dt to 0.1s; stay well under that.
  window.__clock = {
    tick(dt) {
      now += Math.round(dt * 1000);
      const pending = [...callbacks.entries()];
      for (const [id, cb] of pending) {
        callbacks.delete(id);
        cb(now);
      }
    },
  };
})();
