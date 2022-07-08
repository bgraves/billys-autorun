# billys-autorun
Factorio autorun mod

# Notes
There were two difficult problems to tackle to get this autorun functioning properly:
    (1) Only key-down events are provided
    (2) There's no way to tell if the movekeys are disabled/hijacked such as when the full-screen map or technology page are open

(1) Key-down Only
Having only key-down events may not immediately seem like a problem. The issue arises because of the possibility of moving diagonally. For instance, let's say the player pressed move-right and then a second later they press move-up. If they released move-right before pressing move-up, their final movement direction will be north. However, if they're still holding the move-right key down, their final movement direction will be northeast instead. And I have no direct way of checking which of these two sequence of presses happened.

I came up with two alternative workarounds, each with different drawbacks:
    (a) Only support autorun in the cardinal directions
    (b) When a movekey is pressed, hand control back to the normal game for a tick to see which way the character ends up moving
I ended up using option (b) since I really wanted to allow diagonal autorunning. The only issue occurs when releasing one of two pressed keys. For instance, normally if you're pressing up and right simulataneously, the player will move northeast. If you release the up key but continue holding right, the player will switch to moving purely east. Unfortunately I can't detect this key-up event so I have to just accept that player movement will be slightly different while autorun is enabled.

(2) Disabled/Hijacked Movekeys
This issue became obvious when I would open the full-screen map while autorun was enabled. While the map is open, wasd pan the map view rather than move the player. However, the events continue firing the usual move-up, move-down, etc. After a lot of searching, there doesn't seem to be a reliable way of directly checking the state of the full-screen map. You can hook the toggle-map hotkey, but that misses the case where the user clicks the minimap to open the map. And plus there are other screens, like the tech and tips/tricks panes, which disable wasd.

To solve this, I wait for a movekey to be pressed and then I check if the player is walking on the 2nd tick after that press. If the movekeys are enabled, player.walking_state.walking should be true. If they're not walking, I roll back the autorun state to whatever it was before the key press.
