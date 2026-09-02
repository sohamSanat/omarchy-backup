```text
 (        )                 (                                    
 )\ )  ( /(  (  (           )\ )  (  (       (                   
(()/(  )\()) )\))(   ' (   (()/(  )\))(   '  )\     (   (   (    
 /(_))((_)\ ((_)()\ )  )\   /(_))((_)()\ )((((_)(   )\  )\  )\   
(_))    ((_)_(())\_)()((_) (_))  _(())\_)())\ _ )\ ((_)((_)((_)  
| _ \  / _ \\ \((_)/ /| __|| _ \ \ \((_)/ /(_)_\(_)\ \ / / | __| 
|  _/ | (_) |\ \/\/ / | _| |   /  \ \/\/ /  / _ \   \ V /  | _|  
|_|    \___/  \_/\_/  |___||_|_\   \_/\_/  /_/ \_\   \_/   |___| 
                                                                 
```

# Omarchy Powerwave Plugin

A lightweight Omarchy Quattro plugin that adds a aniamtion on the screen when AC power is connected.

## Features

* Runs on all connected monitors
* Uses UPower directly
* No polling or additional daemon

## Installation

```bash
omarchy plugin add https://github.com/sjgng/omarchy-powerwave-plugin.git --enable
```

Restart the shell:

```bash
omarchy-restart-shell
```

## Removal

```bash
omarchy plugin remove x692137x.powerwave
```

## Configuration

The plugin does not overwrite user configuration files.

## Dependencies

No additional background services or external packages are installed by the plugin.
