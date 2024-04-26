# Drive
## Summary
The purpose of the game is to drive.
That's it. I know.

It sounds so boring that only people with holes in their brains would play this.

We made it because we got frustrated at The Long Drives crappy multiplayer.

Also I wanna keep updating this. If you wanna get involved and have something to contribute, shoot me a message.

## Images
(put some images here bozo)

## Things you can do
Tiles!
- Boring tiles:
  - 1x1 desert tiles matching mods style
  - 1x1 straight road tiles matching mods style
  - These can have small obstacles but no loot, enemies or other POI-type stuff
- POIs:
   - Any-size desert tiles with buildings or other cool things that spawn far away from the road
   - Any-size tiles that spawn relative to the road. If they are 1x1, they can also be flipped. Could be like a giant pit in the road, shops by the road, or something another tile away from the road like a watch tower

Blueprints! If you have a cool blueprint that you want to feature (and it matches the style or we really like it) we'll add it to the game. Just send over your '_.blueprint_' file found in **AppData\Roaming\Axolot Games\Scrap Mechanic\User\[user]\Blueprints\[sort by date modified :D]**. Players will dismantle your buld for parts though so be mindfull.

Enemies, if you have any modelling skills and can add them to Scrap Mechanic, we can take them

**If you are a modder** you could lend us a helping hand by documenting, fixing or even refactoring our code

Anything in the TODO list, I accept github changes

You could also work on a wiki I guess but I'm pulling at straws here

## TODO (code-wise)
- ~Get rid of log book~
- ~Move player a bit when respawning~
- ~Custom joining code (players to join around host)~
- Fix bug where players joing having left on a previous world can't re-connect (literally no simple solution for this. potentially keep worlds stored? delete player data on leave) **ALSO THIS IS GAME BREAKING!! ┻━┻ ︵ ＼( °□° )／ ︵ ┻━┻**
- Add some enemies
- Make the bed actually work (speed up night while sleeping)
- Update food to actually heal the player
- ~Limit inventory size to just hotbar~ **still need to hide ui, check line 100 of SurvivalPlayer for ideas**
- Custom tunable radio with different stations at different frequencies
- ~Better player movement (no floaty movement)~ No way to do this nicely yet :(
- Add beautifull stars to the night sky

## Larger scope/experimental stuff
(some pretty insane ideas here, don't take them too seriously)
- Remove the ability to destroy things, players can still pick up/place blocks but everything else has to be welded, separate shapes by hitting them with a hammer
- Speedometer (shows speed of body in actual model)
- Distance meter (same as speedometer but shows how many worlds it has been through or something)
- Give engines a fuel meter that can be checked with a fuel gauge (connected with connector tool), and add a system where fuel canisters can be filled/emptied (will probably have to just use stack size as fill amount)
- Show players body and lock the game to first person (as god intended)
- Separate steering wheel from seat (connected to seat with connector tool) to put more focus on making visually interesting and usable cars
- Disable lift for more punishing experience
