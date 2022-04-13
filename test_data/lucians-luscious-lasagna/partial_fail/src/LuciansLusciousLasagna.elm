module LuciansLusciousLasagna exposing (elapsedTimeInMinutes, expectedMinutesInOven, preparationTimeInMinutes)


expectedMinutesInOven =
    40000


preparationTimeInMinutes layers =
    2 * layers


elapsedTimeInMinutes layers passedAlready =
    passedAlready + preparationTimeInMinutes layers
