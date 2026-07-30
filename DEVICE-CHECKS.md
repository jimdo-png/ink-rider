# iPhone checks only you can do

Everything else was verified by measurement in a desktop browser. These six need the real phone,
because a desktop browser reports fake values for them (it says the safe-area insets are zero, it
has no haptics engine, and it never runs iOS's edge gestures).

Open **https://jimdo-png.github.io/ink-rider/** in Safari on the iPhone, then work down this list.

### 1. Readability outdoors
Go outside in daylight, screen at its normal brightness, and play level 1.
**Pass:** you can clearly see the line you just drew while you are drawing it.
**Fail:** the line washes out or disappears against the sky.

### 2. Frame rate
Play three levels in a row, then turn on Low Power Mode (Settings → Battery) and play three more.
**Pass:** the bike moves smoothly throughout; no stutter when it crashes and the screen shakes.
**Fail:** visible chop, especially during crashes or when confetti fires.

### 3. Edge swipes
Draw ten roads that start hard against the left edge of the screen, and ten that run along the very
bottom edge.
**Pass:** every stroke draws normally.
**Fail:** Safari goes back a page, or the app switcher appears, instead of drawing.

### 4. Haptics
Crash into a saw, collect a star, and finish a level.
**Pass:** you feel a short buzz on each.
**Fail:** nothing. (Note: iOS often suppresses vibration in Safari — if you feel nothing at all,
that is an iOS limitation, not a bug in the game. Worth knowing either way.)

### 5. Install to the home screen, then go offline
Share button → **Add to Home Screen** → open it from the home screen icon.
Then turn on Airplane Mode and open it again from the icon.
**Pass:** it opens with no Safari address bar at all, fills the whole screen, and still plays with no
signal.
**Fail:** address bar still visible, or it fails to load in Airplane Mode.

### 6. Notch and home indicator
With the phone turned sideways, look at all four edges.
**Pass:** no button is hidden under the notch or Dynamic Island, and nothing sits under the thin home
bar at the bottom.
**Fail:** anything is clipped or hard to press near an edge.

---

Tell me which numbers failed and what you saw, and I'll fix them.
