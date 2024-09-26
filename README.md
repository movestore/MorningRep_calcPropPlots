# Morning Report Property Plots PDF
MoveApps

Github repository: *github.com/movestore/MorningRep_calcPropPlots*

## Description
This App creates a multipage pdf downloadable file with time-plots of calculated data attributes for each individual track: net square displacement, daily number of positions, daily traveled distance and average daily distance to a given position. So, you get additional information about your animals and tag performance. 

## Documentation
A multipage pdf is created of 4 calculated data properties across time: net square displacement (in km, calculated by Vincenty Ellipsoid method), daily number of positions ("N Positions"), daily traveled distance in km (sum of successive pairwise Vincenty Ellipsoid distances; "Displ. (km)") and average daily distance to a given position in km ("Dist. to Posi. (km)"). The plotted time window is defined by the reference timestamp (either user-defined or by default NOW) and the time duration that defines how long before the reference timestamp the x-axis of the plots shall start.

### Application scope
#### Generality of App usability
This App was developed for any taxonomic group. 

#### Required data properties
The App should work for any kind of (location) data. Specially useful for live feed data.

### Input type
`move2::move2_loc`

### Output type
`move2::move2_loc`

### Artefacts
`MorningReport_NSDdailyProp.pdf`: PDF with a multiple properties plots on each page showing the time series of the four calculated properties for one animal.

### Settings 
**Reference time (`time_now`):** reference timestamp towards which all analyses are performed. Generally (and by default) this is NOW, especially if in the field and looking for one or the other animal or wanting to make sure that it is still doing fine. When analysing older data sets, this parameter can be set to other timestamps so that the to be plotted data fall into a selected back-time window. 

**Track time duration. (`time_dur`):** time duration into the past that the attributes have to be plotted for. So, if the time duration is selected as 7 days then the x-axis ranges from the reference timestamp to 7 days before it. Unit: days

**Reference longitude (`posi_lon`):** longitude of the position to which average daily distances are to be calculated. Typically this is the observer position in the field, if one wants to find out if any tagged animals are in the surroundings. This might be the catching site. If none provided the default is the first available position

**Reference latitude (`posi_lat`):** latitude of the position to which average daily distances are to be calculated. Typically this is the observer position in the field, if one wants to find out if any tagged animals are in the surroundings.This might be the catching site. If none provided the default is the first available position


### Changes in output data
The input data remains unchanged.

### Most common errors

### Null or error handling
**Setting `time_now`:** If this parameter is left empty (NULL) the reference time is set to NOW. The present timestamp is extracted in UTC from the MoveApps server system. If the data are older and no reference timestamp is specified, no pdf will be produced. 

**Setting `posi_lon`:** If this parameter is left empty (NULL), for each animal the longitude of the first available position is used as reference for the calculation of average daily distances to a position. This might be the catching site.

**Setting `posi_lat`:** If this parameter is left empty (NULL), for each animal the latitude of the first available position is used as reference for the calculation of average daily distances to a position. This might be the catching site.
