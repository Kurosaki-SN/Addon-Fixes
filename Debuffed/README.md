# Debuffed

An addon that tracks and displays debuffs on your current target. Filters are available to customise which debuffs are shown.

### Commands

•`//debuffed setup`

Toggles the visibility of your colored anchor boxes (the Red box for Debuffs and Blue box for Buffs).

While visible, you can click and drag the boxes anywhere on your screen to position your UI. Typing the command again hides the boxes and locks them in place.

•`//debuffed align`

Instantly teleports your Blue Box to the exact X and Y coordinates of your Red Box.

This removes the need to manually line things up and is essential for your custom "center-origin" layout where buffs and debuffs perfectly mirror each other.

If you line the boxes up side by side in setup mode and use this command, this will snap the blue box to match the height of the blue box. If you line up top to bottom it will snap to line up the sides of the boxes.

•`//debuffed buffdir`

Toggles the physical direction your Buff icons are drawn on the screen and saves the preference to your settings file.

Switches between "Reverse" (Right-to-Left) for the blue box (Buffs) where the icons are drawn from the right side of the blue box in setup mode to the left so there is no gap between buffs and debuffs if that is what you want and "Normal" (Left-to-Right) where the icons for the blue box (Buffs) are drawn normally from the left side of the box to the right.

•`//debuffed pos`

Allows you to manually set the exact X and Y pixel coordinates of your main anchor box using numbers, rather than clicking and dragging.

•`//debuffed mode`

Toggles between Icon mode and text mode, whichever you prefer.

•`//debuffed timers`

This toggles the display of timers for debuffs.

•`//debuffed interval <value>`

This allows you to adjust the refresh interval for the textbox. It will be updated every \<value\> number of seconds.

•`//debuffed hide`

This toggles the automatic removal of effects when their timer reaches zero.

•`//debuffed blacklist|whitelist add|remove <name>`

This adds or removes the spell \<name\> to the specified filter.

•`//debuffed filter`

Switches between blacklist and whitelist modes. Default set to blacklist



### Abbreviations

The following abbreviations are available for addon commands:
* `debuffed` to `dbf`
* `mode` to `m`
* `timers` to `t`
* `interval` to `i`
* `hide` to `h`
* `blacklist` to `b` or `blist` or `black`
* `whitelist` to `w` or `wlist` or `white`
* `add` to `a` or `+`
* `remove` to `r` or `-`
