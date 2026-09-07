# Dark maze and flashlight

## Requirements

Medium and Hard mazes are dark: no sun, black fog in the corridors, and very low ambient
light. Easy stays fully lit and has no flashlight.

The flashlight:

- Toggles with **F**. It starts on and fully charged with 30 seconds of light.
- The battery drains only while the light is on and the player is not inside a math
  prompt. Switching it off saves charge.
- In the last six seconds the beam flickers.
- When the battery is dead, pressing F opens a math problem. A correct answer fully
  recharges the battery and turns the light back on. Wrong answers keep the prompt open;
  there is no key penalty.
- The heads-up display shows the seconds of light left, "off" with the charge remaining,
  or "dead - press F to solve and recharge".

Orbs glow in the dark, so keys can be found without the beam.

## Decisions

- **Easy stays lit** so the youngest players are not scared off; darkness is the scary
  ingredient, added only where it is chosen.
- **Drains only while on**, so a child can conserve the battery by switching off in a
  corridor they already know.
- **Recharge by arithmetic.** The fear mechanic doubles as practice, the same lock as
  everything else in the game.
- **The monster keeps hunting during a recharge prompt.** Standing in the dark to solve a
  problem is a risk the player chooses.

## Planned

- **audio-polish** — footsteps and other sound touches in the dark.
- **map-overlay** — a map of visited corridors, useful in the dark.
