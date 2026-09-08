{
  "manifest_version": 3,
  "name": "Omarchy Brave Polish",
  "version": "1.0.0",
  "description": "Dynamically matches Brave-Origin NTP and YouTube/GitHub/Reddit to the active Omarchy system theme. Managed by omarchy-sync-brave. Dark Reader left untouched.",
  "author": "Omarchy",
  "homepage_url": "https://omarchy.org",
  "permissions": ["topSites"],
  "host_permissions": [],
  "background": {
    "service_worker": "background.js"
  },
  "content_scripts": [
    {
      "matches": ["*://*/*"],
      "js": ["global.js"],
      "run_at": "document_start",
      "all_frames": false
    }
  ],
  "web_accessible_resources": [
    {
      "resources": ["global.css", "theme.json"],
      "matches": ["*://*/*"]
    }
  ]
}
