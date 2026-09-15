{
  "manifest_version": 3,
  "name": "Omarchy Brave Polish",
  "version": "1.0.0",
  "description": "Dynamically matches Brave-Origin NTP and YouTube/GitHub/Reddit to the active Omarchy system theme. Managed by omarchy-sync-brave.",
  "author": "Omarchy",
  "homepage_url": "https://omarchy.org",
  "permissions": ["topSites"],
  "host_permissions": [],
  "theme": {
    "colors": {
      "frame": [{{ background_rgb }}],
      "frame_inactive": [{{ background_rgb }}],
      "toolbar": [{{ background_rgb }}],
      "tab_text": [{{ foreground_rgb }}],
      "tab_background_text": [{{ muted_rgb }}],
      "bookmark_text": [{{ foreground_rgb }}],
      "ntp_background": [{{ background_rgb }}],
      "ntp_text": [{{ foreground_rgb }}],
      "ntp_link": [{{ accent_rgb }}],
      "ntp_header": [{{ background_rgb }}],
      "button_background": [{{ background_rgb }}]
    },
    "tints": {
      "buttons": [0.5, 0.5, 0.5]
    },
    "properties": {
      "ntp_logo_alternate": 1
    }
  },
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
      "resources": ["global.css", "theme.json", "ntp.css", "polish.css"],
      "matches": ["*://*/*"]
    }
  ]
}
