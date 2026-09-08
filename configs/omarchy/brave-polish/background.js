// Omarchy Brave Polish — background service worker.
//
// Currently a no-op keeper: reserves the service worker slot so future
// versions can react to theme updates (e.g. tabs.reload on watched hosts).
// No permissions required beyond what manifest declares.
chrome.runtime.onInstalled.addListener(() => {
  // Managed by omarchy-sync-brave. Nothing to initialise.
});
