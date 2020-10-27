;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; Structure of the code ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; In the code:
;  - extensions are loaded (e.g. GIS for spatial data)
;  - global, fish and landscape variables and parameters are defined
;  - life stages, or "breeds", are defined
;  - the "setup" procedure calls all procedures needed to intitialise the model before the spin up (e.g. sets up spawning area etc.), and sets the parameter values
;  - the procedure "go" then calls all procedures in a time-step
;  - the "spin-up" procedure calls "go" for 10 years, i.e. spins the model up for 10 years. Conditional statements are used to filter what should happen in the spin-up, and what should happen in the actual simulation
;  - "go-ABC" calls "go" for as many years as we have data for ABC

; This can all be controlled from the interface using the appropriate buttons

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; Required extensions are imported ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions
[
  gis                           ; for remote-sensing and other spatial data
  time                          ; tracks the date in a simulation
  profiler                      ; provides diagnostics on the model
  nw
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; A list of global variables and parameters ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals                         ; variables and parameters are defined here, but their values are set later on
[
  start-date
  current-date
  rm                            ; multiplier used to change parameter values etc. depending on whether the model is high or low resoltuion (see above)
  z                             ; index for initialisation loop

  report-tick-pre-spawn-mig     ; time-step on which the pre-spawning migration is triggered (depends on which year in the simulation it is, Feb 1st)
  report-tick-post-spawn-mig    ; the same for the feeding migration
  report-tick-pre-overwinter-mig; and again for the overwintering migration (October 1st)
  run-year                      ; the current year in the simulation (0-8)
  actual_year                   ; current "actual" year, i.e. start year + run-year
  ann_step                      ; annual time-step, i.e. current time step in a year
  month                         ; approximate simulation month (but some error due to 5-day time-step, i.e. 1-12)
  month_days                    ; number of days in current month (e.g. 31 for Jan; used to apportion F among months appropriately)
  start-spawn                   ; time-step on which spawning can commence (March 1st)
  end-spawn                     ; final day that spawning can occur

  raster                        ; a path to chl data
  rasterSST                     ; the same for SST
  phyto-data                    ; phytoplankton datasets
  SST-data                      ; SST datasets
  photo-data
  currents-data
  spawning_SST                  ; a list of SST on the spawning grounds each time-step over March, April and May. The mean of this list is used as input to the stock recruitment relationship
  lat-data
  lon-data
  bath-data                     ; bathymetry
  land                          ; shapefile of land (Ireland and Iceland)
  ICES                          ; shapefile of ICES statistical rectangles
  directory                     ; file path string used to load data
  num-recruits                  ; the number of recruits to the juvenile stage (reset each year)
  num-matured                   ; number of individuals that have reached sexual maturity (reset each year)
  num-eaten                     ; number of individuals eaten explicitly by other mackerel (reset each year)
  R_energy
  egg-production                ; number of eggs produced each year
  larval-production             ; the number of eggs that survive to larval stage each year
  FeedingSSB                    ; biomass of mature individuals in the feeding area in mid July
  sp_SSB                        ; SSB on May 1st
  SumSSB                        ; biomass of mature individuals in mid July
  MProp0                        ; proportion of 0 year olds mature
  MProp1                        ; proportion of 1 year olds mature
  MProp2                        ; and 2 yr olds
  MProp3                        ; etc.
  MProp4                        ; etc..
  M-at-36                       ; average body mass of fish in the 36cm size class (for comparison with data we have)

  min_lat_always_light

  S0                            ; normalizing constant for SMR
  A0                            ; normalizing constant for AMR
  Cmax                          ; maximum ingestion rate g/day
  Xprop_mac
  boltz                         ; Boltzmann's constant eV K-1
  Ea                            ; Activation energy (eV)
  Ep                            ; energy content of phytoplankton kJ/g
  Ae                            ; Assimilation efficiency
  Ef                            ; energy content of flesh kJ/g
  El                            ; energy content of lipid kJ/g
  Fs                            ; energy costs of synthesising flesh kJ/g
  Ls                            ; energy costs of synthesising lipid kJ/g
  egg-mass
  k                             ; Bertalanffy growth constant (day-1)
  Loo                           ; Average maximum length (asymptotic length, cm)
  L1                            ; maximum length after first growing season
  k1                            ; maximum growth rate
  Gmax                          ; age at maximum growth in first growing season
  K2                            ; Bertalanffy growth constant in units of 1/y
  F                             ; Age-dependent fishing mortality (year-1)
  F_multiplier
  catch                         ; cumulative monthly catch
  prop_catch_4a
  C_lim                         ; limit fishing mortality used to prevent excessive redistribution of F outside closed areas
  annual_c_lim                  ; sum of the monthly catch limits each year
  Tref                          ; Reference temperature for the energy budget (12 °C or 285.15 k)
  ;Me                            ; egg mortality mortality (day-1, specified on interface)
  Ar                            ; caudal fin aspect ratio
  A                             ; swimming speed normalizing constant
  Lm                            ; threshold length (cm) for maturity
  Ma                            ; adult background mortality / day
  Lhatch                        ; length at hatch
  n_batch                            ; number of batches of eggs
  Bint                          ; inter-batch interval length (days)
  n_cohort                            ; Number of super-individuals in a cohort
  a_w                           ; scaling exponent 1 for swimming veolicty
  b_w                           ; scaling exponent 2 for swimming velocity
  a_f                           ; coefficient for fecundity
  b_f                           ; scaling exponent for fecundity
  a_R
  b_R
  c_R


  SA-TSB                        ; TSB for the SA for plot comparison
  SA-SSB                        ; Same as above for SSB
  SA-Rec                        ; and for recruitment
  TSB                           ; Total Stock Biomass
  SSB                           ; Spawning Stock Biomass
  spawning-SSB                  ; SSB at spawning time
  ldist                         ; length distribution calculated in quarter 1 on March 10th (i.e. the average date that surveys were conducted)
  adist                         ; age distribution on feeding grounds on Aug 1 to match data
  feb-adist
  Q4ldist                       ; Quarter 4 length distribution calculated on November 18th to correspond with data
  febldist                      ; length distribution on the feeding grounds on Aug 1
  W3                            ; average weight at age 3 on the feeding grounds
  W4                            ; and at age 4...
  W5                            ; age 5 etc.
  W6
  W7
  W8
  W9
  W10
  w11
  w12
  w13
  dens-index
  L-index
  p-index
  feed-area                     ; total area of patches visited by adult mackerel in the feeding period (km-2)
  n_encounters                  ; number of encounters between predators and prey
  catch-series

  spin-up-rec
  ssb_t0
  month_n

;;;; some data for comparison with model outputs on the interface ;;;;

  iessns_w3
  iessns_w4
  iessns_w5
  iessns_w6
  iessns_w7
  sa_ssb

;;;; summary stats for ABC ;;;;

  ABC-SSB                       ; SSB in mid July in years for which we have data for ABC
  ABC-spawn-SSB
  ABC-egg                       ; the same for eggs
  ABC-rec
  ABC-sum-w3
  ABC-sum-w4
  ABC-sum-w5
  ABC-sum-w6
  ABC-sum-w7
  ABC-sum-w8
  ABC-sum-w9
  ABC-sum-w10
  ABC-sum-w11
  ABC-sum-w12
  ABC-sum-w13
  ABC-sp-w3
  abc-sp-w4
  abc-sp-w5
  abc-sp-w6
  abc-sp-w7
  abc-sp-w8
  abc-sp-w9
  abc-sp-w10
  abc-sp-w11
  abc-sp-w12

;;;; summary stats for feeding strategy paper ;;;;

  feed-ssb
  output-area

]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; Patch (landscape) variables ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

patches-own                     ; patch variables
[
  depth
  X_phyto                 ; phytoplankton biomass (g m-2, calculated from chl)
  SST                           ; Sea Surface temperature °C
  photo_mult
  u
  v
  PreSArea                      ; southern part of the spawning area where individuals aggregate before spawning (boolean)
  SArea                         ; spawning area (bbolean)
  Ricker_spawn_area             ; box defined as spawning area used to obtain mean SST when fitting the Ricker stock-recruitment model. SST is averaged in this box over March, April and May for input to the stock recrtuitment relationship
  NArea                         ; nursery area (boolean)
  OWArea                        ; overwintering area (boolean)
  shelf-edge
  FArea                         ; feeding area (boolean)
  latitude                           ; latitude
  longitude                           ; longitude
  true_north_heading
  true_west_heading
  A6                            ; FAO fishing area 6 (west of Scotland/ north of Ireland)
  A5                            ; FAO fishing area 5 (Icelandic shelf)
  A4
  row                           ; ICES rectangle row
  column                        ; ICES rectangle column
  rectangle                     ; ICES rectangle defined by its row and column
  feed-dist                     ; the rank of distance from feeding area (Shetland Isles) of all shelf edge patches. This is used to direct movement towards the feeding area along the shelf edge
  spawn-dist
  processed
  spawn-processed

  mac-density                   ; the density of mackerel on a patch at the end of a time-step (g patch-1)
  mac-L                         ; average body length of mackerel on the current patch
  feed-range                    ; whether or not any mackerel have visited the patch in the current feeding period
  ocean                         ; whether or not the patch is in the ocean
  North_Sea
  coast
  traditional_feeding_area?
  presence
  feeding_cue
  profitability

]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; Turtle (fish) variables ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

turtles-own                     ; turtle variales
[
  L                             ; length cm
  standard-L                    ; standard length (head to base of tail fork, cm)
  std-mass                      ; standard mass as calculated from length using known relationship (g)
  structural-mass               ; structural mass, i.e. total mass - gonad mass - lipid mass (g)
  total-mass                    ; structural mass + lipid mass + gonad mass (g)
  gonad-mass                    ; mass of the gonads (eggs, g)
  energy-reserve                ; kJ
  maintenance-energy            ; 10% of the energy stored at the beginning of spawning is saved for maintenance costs while fasting on the spawning grounds
  Arrhenius                     ; Arrhenius function in the form exp(-Ea/K*SST) used to calculate temperature dependence of metabolic rate. Temp dependence of ingestion and growth is given relative to Tref and without reference to this variable in the code
  ingestion-rate                ; ingestion of a whiole super-individual (needed to calc. predation mortality) g/day
  individual-IR                 ; sub-individual's ingestion rate g/ day
  energy-assimilated            ; kJ/day
  energy-reserve-max            ; kJ
  func-response                 ; Holling type II functional response adjusts ingestion rate based on food and predator density
  prey-choices                  ; identities of potential prey mackerel
  prey-choice                   ; a randomly chosen individual from the potential prey
  prey-fat-prop                 ; the proportion of a prey individual that is fat - used to calculate its energy content
  prey-available
  super-mass                    ; the mass of a super-individual (i.e. individual mass * number of individuals)
  energy-tracker                ; tracks the amount of energy assimilated before the energy budget costs are calculated. This is used to determine whether or not growth is limited by food

  MR                            ; either active (AMR) and standard (SMR) metabolic rate depending on the conditions (kJ/day)

  max-growth-rate               ; maximum amount of length that can be added in a day (cm)
  growth-rate                   ; realised amount of length added in a day if insufficient energy to grow maximally (cm)
  growth-costs                  ; energy cost of adding new length and mass

  max-R                         ; energy costs of synthesising a full season's eggs (kJ)
  max-batch-R                   ; energy costs of synthesising a max sized batch of eggs (5 batches are deposited, kJ)
  R                             ; energy accumulated for reproduction (kJ)
  batches                       ; tracks the number of batches deposited and signals the end of spawning when reaching 5
  spawning                      ; boolean
  potential-fecundity           ; the potential number of eggs that can be produced
  realised-fecundity            ; the actual number of eggs produced, depending on energy reserves
  Amat                          ; the age at which an individual matured (yrs)
  Lmat                          ; the length at which an individual matured (cm)

  migrating                     ; boolean. Prevents individuals "moving locally" if true
  feeding                       ; boolean. If individuals are feeding then they cannot return back down the shelf edge to the spawning areas
  FK                            ; condition factor = 100*(W/L^3)
  V_min                ; max sustainable cruising speed (S_a)
  realised-speed                ; realised speed when migrating, i.e. within the limits of cruising speed with some random noise
  divert-x                      ; the x coordinate of the patch to which an individual diverts if migration is obstructed by land
  divert-y                      ; the y coordinate of the patch to which an individual diverts if migration is obstructed by land

  embryo-duration               ; total number of days it takes an egg to develop and hatch
  development                   ; the number of days remaining before an egg hatches

  abundance               ; the actual number of individuals represented by a superindividual
  age                           ; age (yrs)
  Dage                          ; age (days)
  gender                        ; male or female

  exp-cohort                    ; All individuals in the 2007-year class. Variable is used to track them and check everything is working
  Fa                            ; fishing mortality rate
  Fda                           ; daily fishing mortality rate
  num-fished                    ; proportion of a super-individual fished in a day
  report-fished                 ; actual number of individuals in a super-individual fished per day
  num-M                         ; proportion of a super-individual killed by background mortlaity per day
  report-M                      ; actual number of indivuals removed from a super-individual by fishing
  M                             ; natural mortlaity rate (year -1)
  Mda                           ; M / day
  inedible                    ; boolean; is the turtle a potential prey item to another? Used to determine if it is subject to explicit predation, or background mortality
  spawners

  cornered_x
  cornered_y
  optimal_x
  optimal_y
  d_x
  d_y
  d_cue_x
  d_cue_y
  gradient_x
  gradient_y
  Gx
  Gy
  mg
  delta_Dx
  delta_Dy
  delta_Rx
  delta_Ry
  delta_Cx
  delta_Cy
  new_X
  new_Y
  optimal_orientation
  Rs
  p_quality_t-1
  better_patch
  launch_pad_R

]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; Life stages ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

breed [eggs egg]                ; Eggs
breed [YS-larvae YS-larva]      ; Yolk-sac larvae
breed [larvae larva]            ; larvae
breed [juveniles juvenile]      ; juveniles
breed [adults adult]            ; adults

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Everything is set up prior to the spin-up ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup                        ; initialization procedures
  clear-all                     ; all variables are reset
  ;clear-plot

  ifelse high-res = true
  [
    resize-world 0 round(478 / 3) 0 round(381 / 3)
    set-patch-size 4
    set rm 1
  ]
  [
    resize-world 0 round(478 / 6) 0 round(381 / 6)
    set-patch-size 8
    set rm 5
  ]

  if enviro_inputs = "RS"
  [
    set start_year 1995
    ;set constant_rec? true
  ]
  ;[
  ;  ;set start_year 1981
  ;  set constant_rec? false
  ;]

  set month_n (start_year - 1981) * 12

  setup-dates                   ; time extension sets up the start date and it progresses by 1 every time-step
  setup-chl                     ; loads initial chl
  setup-SST                     ; load initial SST
  setup-bathymetry               ; bathymetry is loaded in
  setup-land                    ; loads land shapefile
  setup-coords                  ; assigns each patch a value for longitude and latitude
  setup-ocean
  setup-fishing-areas           ; sets the FAO fishing areas according to long and lat
  setup-feeding-grounds         ; feeding grounds setup
  setup-nursery-grounds         ; nursery grounds setup
  setup-overwintering-grounds   ; overwintering grounds setup
  setup-shelf-edge
  setup-navigation
  setup-spawning-grounds        ; spawning grounds setup, needs to be done after shelf-edge, upon which it relies, is set up
  setup-F                       ; fishing mortlaity is loaded in
  setup-spin-up-recruits                 ; the population is loaded in from the spin-up simulation


;;;; parameter values are specified (excluding those on interface). A multiplier is used to obtain the appropriate parameter values depending on the temporal resolution ;;;;

  set S0 44546413 * rm       ; Hermann and Enders (2000), see TRACE
  set Cmax (0.69 * rm)              ; Hatanaka et al. 1957, see TRACE
  set boltz (8.62 * (10 ^ -5))           ;
  set Ea 0.5                             ; (Gillooly et al. 2002; Sibly et al. 2015)
  set ep 6.02                            ; (Annis et al. 2011)
  set Ae 0.95                            ; (Lambert 1985)
  set Ef 7                               ; (Peters 1983)
  set El 39.3                            ; (Schmidt-nielsen 1997)
  set Ls 14.7                            ; Pullar and Webster (1977), see TRACE
  set Fs 6                               ; (Moses et al. 2008)
  set egg-mass 0.001                     ; (Sibly et al. 2015)
  set k 0.314 * rm            ; see TRACE
  set Loo 42.4                             ; see TRACE
  set Tref 285.15                        ; reference temperature for growth (arbitrary)
  set A 0.15                             ; Sambilay jr (1990)
  set A0 88557766 * rm       ; Dickson et al. (2000) see TRACE
  set Ar 4.01                            ; (fishbase, froese and Pualy 2016)
  set L1 20                            ; Villamor et al. 2004 see TRACE
  set k1 0.0255 * rm          ; Villamore et al. 2004 see TRACE
  set Lm 26.2                            ; fishbase, see TRACE                             ; see TRACE
  set Ma 0.000411 * rm       ; from the stock assessment
  set Lhatch 0.3
  set n_batch 5
  set Bint 10
  set n_cohort 70
  set a_w 0.62  ; Sambilay jr 1990
  set b_w 0.35  ; Sambilay jr 1990
  set a_f 8.8
  set b_f 3.02
  set a_R 1.145121e-06
  set b_R -1.323e-13
  set c_R 7.019e-01
  set Xprop_mac 0.064

  ;set c 1e-11
  ;set Me 0.105

  set run-year 0
  setup-turtles

  reset-ticks
end

;;;; Dates are aligned to the "tick" counter using the time extension ;;;;

to setup-dates                                                                       ; ticks are aligned to the corresponding date
  set start-date time:create word start_year "-01-01"                                            ; start date is Jan 1 1974 so that after the 10 year spin-up we begin on Jan 1 2004
  set current-date time:anchor-to-ticks start-date (1 * rm) "days"       ; each tick progresses the date by the appropriate number of days (1 for high res and 4 for low res)
  set month 1
  set month_days 31
end

;;;; Initial phytoplankton and SST are loaded in ;;;;

to setup-chl
  ;gis:load-coordinate-system ("F:/PhD/S.scombrus_movement_model/esriwkt.txt") ; See load-chl and load-SST procedure for full details
  ifelse enviro_inputs = "RS"
  [set phyto-data gis:load-dataset "F:/SEASIM-MAC_2020/inputs/sst_chl/phyto_1.asc"]
  [set phyto-data gis:load-dataset (word "F:/SEASIM-MAC_2020/inputs/ESM_inputs/GFDL_" RCP "chl_1.asc")]
  gis:set-world-envelope gis:envelope-of phyto-data
  gis:apply-raster phyto-data X_phyto

  ;ask patches
  ;[
  ;  set-color
  ;]

end

to set-color                                                                         ; Generates colour bins for heatmap-style visual of phytoplankton on the interface. Can't use auto colouring because the values differ too much and scaling it is very computationally demanding
  if X_phyto > 0
  [
    set pcolor scale-color green (log X_phyto 10) (log 0.001 10) (log 3 10)
  ]

  ; if X_phyto < 0.5
  ;  [set pcolor sky]
  ; if X_phyto > 0.5 and X_phyto <= 0.75
  ;  [set pcolor cyan]
  ; if X_phyto > 0.75 and X_phyto <= 1.25
  ;  [set pcolor lime]
  ; if X_phyto > 1.25 and X_phyto <= 2.25
  ;  [set pcolor green]
  ; if X_phyto > 2.25 and X_phyto <= 5
  ;  [set pcolor yellow]
  ; if X_phyto > 5 and X_phyto <= 7.5
  ;  [set pcolor orange]
  ; if X_phyto > 7.5
  ;  [set pcolor red]
  ;]
  ;[]
end

to setup-SST
  ifelse enviro_inputs = "RS"
  [set SST-data gis:load-dataset "F:/SEASIM-MAC_2020/inputs/sst_chl/sst_1.asc"]
  [set SST-data gis:load-dataset (word "F:/SEASIM-MAC_2020/inputs/ESM_inputs/GFDL_" RCP "tos_1.asc")]
  gis:apply-raster SST-data SST
end


;;;; bathymetric data is loaded in ;;;;

to setup-bathymetry
  set bath-data gis:load-dataset "F:/SEASIM-MAC_2020/inputs/sst_chl/bath.asc"
  gis:apply-raster bath-data depth
end

;;;; land masses (Iceland and Ireland) are loaded in using shapefiles ;;;;

to setup-land
  set land gis:load-dataset "F:/SEASIM-MAC_2020/inputs/na50km_50m_coast_lines.shp"
  foreach gis:feature-list-of land
  [
    gis:set-drawing-color brown ; land is coloured grey
    gis:draw ? 1.0             ; land is drawn with no transparency
    gis:fill ? 2.0             ; land is filled
  ]
end

;;;; ICES fishing areas are defined using latitude and longitude ;;;;

to setup-fishing-areas
  ask patches
  [
    ifelse (latitude >= 54.5) and (latitude <= 60) and (longitude >= -12) and (longitude <= -6.5)          ; Division 6 (West of Scotland)
    [set A6 true]
    [set A6 false]

    ifelse (X_phyto >= 0) and (latitude > 57.5) and (latitude <= 62.5) and (longitude > -4) and (longitude < 7)
    [set A4 true]
    [set A4 false]

    ifelse (longitude <= -11) and (latitude >= 62)                                              ; Division 5 (Icelandic waters)
    [set A5 true]
    [set A5 false]
  ]
end

;;;; coordinates of each patch are defined ;;;;

to setup-coords
  set lon-data gis:load-dataset "F:/SEASIM-MAC_2020/inputs/sst_chl/lon.asc"
  gis:set-world-envelope gis:envelope-of lon-data
  gis:apply-raster lon-data longitude

  set lat-data gis:load-dataset "F:/SEASIM-MAC_2020/inputs/sst_chl/lat.asc"
  gis:set-world-envelope gis:envelope-of lat-data
  gis:apply-raster lat-data latitude

  ask patches with [((latitude >= 0) or (latitude <= 0)) and ((longitude >= 0) or (longitude <= 0))]
  [
    set longitude precision longitude 3
    set latitude precision latitude 3
  ]

  let north-data gis:load-dataset "F:/SEASIM-MAC_2020/inputs/true_north.asc"
  gis:set-world-envelope gis:envelope-of lat-data
  gis:apply-raster north-data true_north_heading

  let west-data gis:load-dataset "F:/SEASIM-MAC_2020/inputs/true_west2.asc"
  gis:set-world-envelope gis:envelope-of lat-data
  gis:apply-raster west-data true_west_heading
end

;;;; Now migration "stop off" areas are defined (ie spawning, feeding, overwintering and nursery) ;;;;

to setup-spawning-grounds
  ask patches
  [
    ifelse ((shelf-edge = true) and (longitude > -12) and (longitude < -8) and (latitude  > 55) and (latitude  < 58.5) ) or ( (shelf-edge = true) and (longitude > -13.5) and (longitude < -9) and (latitude  > 54.5) and (latitude  <= 55))
          or ((shelf-edge = true) and (longitude > -16) and (longitude < -10) and (latitude  >= 51.5) and (latitude  <= 54.5) ) or ((shelf-edge = true) and (longitude > -16) and (longitude < -7.5) and (latitude  >= 50.5) and (latitude  <= 51.5))
          or ((shelf-edge = true) and (longitude >= -14) and (longitude < -6) and (latitude  >= 49) and (latitude  <= 50.5)) or ((shelf-edge = true) and (longitude >= -14) and (longitude <= -4) and (latitude  >= 47) and (latitude  <= 49)) and (sst >= 0)
      [
        set SArea true
        ;set pcolor yellow
      ]
      [set SArea false]

    ifelse (X_phyto >= 0) or (SST >= 0)                          ; average-SST and chl are used to distinguish between land and water
    []
    [set SArea false]

    ifelse (SArea = true) and (pycor < 10)
      [set PreSArea true]
      [set PreSArea false]

    ask patches with [((longitude > -12) and (longitude < -8) and (latitude  > 55) and (latitude  < 58.5)) or ((longitude > -13.5) and (longitude < -9) and (latitude  > 54.5) and (latitude  <= 55))
                    or ((longitude > -16) and (longitude < -10) and (latitude  >= 51.5) and (latitude  <= 54.5)) or ((longitude > -16) and (longitude < -7.5) and (latitude  >= 50.5) and (latitude  <= 51.5))
                    or ((longitude >= -14) and (longitude < -6) and (latitude  >= 49) and (latitude  <= 50.5)) or ((longitude >= -14) and (longitude <= -4) and (latitude  >= 47) and (latitude  <= 49))]
    [set Ricker_spawn_area true]
  ]
end

to setup-feeding-grounds                                                        ; Everything above 62°N is a potential feeding area
  ask patches
  [
    ifelse ((latitude >= 60) and (X_phyto >= 0)) or ((latitude > 57.5) and (latitude <= 62.5) and (longitude > -4) and (longitude < 7) and (ocean = true))
    [set FArea true]
    [set FArea false]
    ;if FArea = true
    ;[set pcolor black]
    if (latitude > 55) and (latitude < 72) and (longitude > -6.5) and (longitude <= 18)
    [set traditional_feeding_area? true]
  ]
end

to setup-nursery-grounds                                              ; nursery grounds are defined by coords and by depth (< 200m deep, Jansen et al. 2014)
  ask patches
  [
    ifelse (latitude > 50) and (latitude < 60) and (depth >= -200) and (longitude < -4) and (longitude > -12) and (sst >= 0) and (X_phyto >= 0)
    [
      set NArea true
      ;set pcolor red
      ]
    [set NArea false]
  ]
end

to setup-overwintering-grounds                                        ; Corresponds to FAO fishing area 6
  ask patches
  [
    ifelse ((latitude > 57.5) and (latitude <= 62.5) and (longitude > -4) and (longitude < 7)) or ((latitude > 54) and (latitude <= 60) and (longitude > -12) and (longitude < -4)) and (X_phyto >= 0)
    [set OWArea true]
    [set OWArea false]
    ;if OWArea = true
    ;[set pcolor blue]
  ]
end

to setup-shelf-edge
  ask patches
  [
    if ((depth >= -550) and (depth <= -50) and (longitude < 4) and (longitude > -13)) and ((longitude < -5) or ((longitude > 4) or (latitude < 50) or (latitude > 58.5)))
    [
      set shelf-edge true
      set pcolor brown
    ]
  ]

end

 ;; to set up the position of the "destination" patches for each migration

to setup-navigation

   ask patch 49 28
   [
      set feed-dist 1
      set processed true
      ;set plabel feed-dist
   ]

  while [150 < count patches with [(ocean = true) and (processed != true)]]                    ; The while condition is set at 20 <.... because there are 20 patches that satisfy the conditions to be "shelf-edge", but are separated from the shelf by deep water
  [
  ask patches with [(ocean = true)]           ; i.e. patch 37 26, then more on next step
  [
    if processed != true [stop]
    ask neighbors4 with [(processed != true) and (ocean = true)]      ; ask neighbours on shelf edge that have not yet been processed
    [
      set feed-dist ([feed-dist] of myself) + 1
      set processed true
      ;set plabel precision feed-dist 2
    ]
  ]
  ]

  ask patches [set processed 0]

  ask patch 46 3
  [
      set spawn-dist 1
      set processed true
      ;set plabel spawn-dist
  ]

  while [40 < count patches with [(ocean = true) and (processed != true) and (shelf-edge = true)]]                    ; The while condition is set at 20 <.... because there are 20 patches that satisfy the conditions to be "shelf-edge", but are separated from the shelf by deep water
  [
  ask patches with [(ocean = true) and (shelf-edge = true)]           ; i.e. patch 37 26, then more on next step
  [
    if processed != true [stop]
    ask neighbors4 with [(processed != true) and (ocean = true) and (shelf-edge = true)]      ; ask neighbours on shelf edge that have not yet been processed
    [
      set spawn-dist ([spawn-dist] of myself) + 1
      set processed true
      ;set plabel precision spawn-dist 2
    ]
  ]
  ]
end

;;;; fishing mortalities-at-age are setup ;;;;

to setup-F
  file-open (word "F:/SEASIM-MAC_2020/inputs/F/" start_year ".txt")
  set F (list file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read)
  file-close
end

to setup-spin-up-recruits

  set spin-up-rec (list 5811487 5081028 3613849 3372139 4359034 4140770 4128829 4388517 3762477 3573130 3214451 3346363 3456082 3112788 2943059 2792843 2994638 2926988 2977574 3528098 2952146 4749644 5646271 3696698 5397194 7070591
    6866257 5176997 4658201 4188877 5507435 7152461 5944485 5795704 5807466 5273724 7454724 8514386 8417954 8417954)

end

;;;; The initial population is imported ;;;;

to setup-turtles

  file-open (word "F:/SEASIM-MAC_2020/inputs/initial_numbers/" start_year ".txt")
  let initial_numbers (list file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read)
  file-close

set z 0
  while [z < 13]
  [
    create-turtles n_cohort                                ; a turtles is created for each row from the file
    [
      set age z + 0.5
      set dage round (age * 365)
      ifelse age < 3
      [
        set breed juveniles
        set size 1
      ]
      [
        set breed adults
        set size 2
      ]

      set L 42.4 * (1 - exp (- 0.314 * age))
      set abundance ((item z initial_numbers) / n_cohort) * 0.8 * 1000
      ifelse who mod 2 = 0
      [set gender 0]
      [set gender 1]
    ]
    set z z + 1
  ]

      ask turtles
    [
      ifelse breed = juveniles                                ; life stage is determined by the "size" of the individual.
      [
        set color grey
        set shape "fish"
        set std-mass 0.00285 * (L ^ (3.325))
        set energy-reserve-max ((std-mass * 0.59) * 39.3)
        set energy-reserve energy-reserve-max * 0.5
        set structural-mass (std-mass * 0.76)
        set total-mass structural-mass + (energy-reserve / 39.3)
        set standard-L (L - 0.1561) / 1.1396
        set migrating false
        set Mda (0.15 / 73)
        move-to one-of patches with [(NArea = true) and (ocean = true)]
      ]
      [
        set color grey
        set shape "fish"
        set std-mass 0.00285 * (L ^ (3.325))
        set energy-reserve-max ((std-mass * 0.59) * 39.3)
        set energy-reserve energy-reserve-max * 0.5
        set structural-mass (std-mass * 0.76)
        set total-mass structural-mass + (energy-reserve / 39.3)
        set standard-L (L - 0.1561) / 1.1396
        set migrating false
        set Mda (0.15 / 73)
        move-to one-of patches with [(OWArea = true) and (sst >= 0)]
      ]
      hatch n_multiplier - 1
      [
        set abundance abundance / n_multiplier
      ]
      set abundance abundance / n_multiplier
    ]
end

to setup-ocean
   ask patches with [((SST >= 0) or (SST <= 0)) and (X_phyto >= 0)]
   [set ocean true]
   ask patches
   [
     if count neighbors4 with [ocean = true] < 4
       [set coast true]
   ]

   ask patches with [(longitude > -3) and (latitude > 51) and (latitude < 59.1)]
   [
     set pcolor grey
     set North_Sea true
   ]

   set spawning_sst []
end

;;;; "loop-chl" and "loop-SST" are called only in the spin-up. They repeat the forcing for 2007 ;;;;

to loop-chl
  if ((ticks - (run-year * (365 / rm))) mod (10 / rm) != 0) and (ticks - (run-year * (365 / rm)) != 73)     ; Every n days (depending on high or low res) a new chl map is loaded. This is not done over winter due to a lack of data
  [
    set directory "F:/SEASIM-MAC_2020/inputs/sst_chl"                                                         ; location on pc of chl data
    set raster (word directory "/phyto_" (((((ticks - (run-year * (365 / rm))) + 1) / (10 / rm)))) ".asc")                                  ; appropriate file identified
    set phyto-data gis:load-dataset  raster
    gis:set-world-envelope gis:envelope-of phyto-data                                                                  ; model extent set to that of the data
    gis:apply-raster phyto-data X_phyto                                                                          ; patches are given values for phytoplankton biomass from the phyto-data

    ask patches
    [
      set-color                                                                                                        ; set patch colour according to its chl
    ]
  ]
end

to loop-SST                                                                                                            ; SST is loaded in the same way as chl
  if (ticks >= (60 / rm)) and ((ticks - (run-year * (365 / rm))) mod (10 / rm) != 0) and (ticks - (run-year * (365 / rm)) != 73)
  [
    set directory "F:/SEASIM-MAC_2020/inputs/sst_chl"
    set rasterSST (word directory "/sst_" (((((ticks - (run-year * (365 / rm))) + 1) / (10 / rm)))) ".asc")
    set SST-data gis:load-dataset  rasterSST
    gis:apply-raster SST-data SST
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; The procedures called by "go" are evaluated on every time step during the actual simulations ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; Here the spine of the model can be seen and the sequence in which procedures are implemented. See process, overview and scheduling section
;;;; in TRACE section 2 for a written description of the model schedule ;;;;

to go
  tick
  set ann_step ann_step + 1

  ; stop the simulation if using remote-sensing inputs and it is 2019

  if (enviro_inputs = "RS") and (ticks = 1752)
  [stop]

;;;; SST and phytoplankton are loaded in first ;;;;

  ifelse enviro_inputs = "ESM"
  [
    load-ESM-inputs
  ]
  [
    ifelse run-year >= 10   ; if run year is less than 10 (i.e. still in the spin up), and inputs are remote-sensing data, then inputs are run on a loop
    [
      load-chl
      load-SST
    ]
    [
      loop-chl
      loop-SST
    ]
  ]

;;;; SSt on the spawning grounds is recorded over the months March, April and May. The mean of these SST recordings is used as input the the stock-recruitment relationship

  if (ann_step >= (60 / rm)) and (ann_step < (120 / rm))
  [calc-spawning-SST]

  calc-run-year   ; the current run year is calculated and used for other procedures

  calc_month

  time:go   ; this aligns NetLogo "ticks" with real dates that are shown on the interface

;;;; Fishing mortality is loaded on the first day of each year ;;;;

  if ticks - (run-year * (365 / rm)) = 1 and (((constant_rec? = true) and (run-year >= 10)) or ((constant_rec? = false))) ; new fishing mortality is only loaded if we're greater than 10 years in, i.e. the spin up is finished
  [load-F]                                                              ; fishing mortality data is loaded in

;;;; If in the spin-up, recruits enter the model at the end of each year. After the spin-up this procedure is not called because adults spawn eggs and recruitment emerges

  if (((ticks < (3650 / rm)) and (force_spin_up_rec = true)) or (Recruitment = "Ricker")) and (ticks - (run-year * (365 / rm)) = (360 / rm))
  [input-recruits]

;;;; Migration departure dates are then calculated ;;;;

  if (ticks - (run-year * (round(365 / rm))) = 2) or (ticks = 0)   ; at the start of each year the time-step on which migrations are triggered is calculated
  [
   calc-migration-ticks
  ]

;;;; On the first day of each year annual population metrics are reset ;;;;

  if (ticks mod (365 / rm) = 0) or (ticks = 0)
  [
    set num-recruits 0
    set num-matured 0
    set egg-production 0
    set num-eaten 0
    set larval-production 0
    set R_energy 0
    set ann_step 0
    set annual_c_lim 0
    set catch 0
    set spawning_SST []  ; start an empty list for spawning SST each year. This will be population with mean SST on spawning grounds each time-step over MArch, April and May, then averaged for use in the RIcker model
    ask patches
    [
      set feed-range false
      set presence 0
    ]
    ask turtles
    [
      set better_patch false
    ]
  ]

;;;; individuals then perform their daily routine ;;;

;;;; Restricted area search mechanism for adult movement while feeding ;;;;

 repeat 5  ; repeated 5 times per time-step, i.e. once per day
 [
   ask adults
   [
   if (feeding_strategy = "GAS") and (feeding = true)
          [
            calc-patch-quality ; calculates current patch quality
            GAS  ; bases new movement on whether or no new location is more profitable than the old
          ]
   ]
 ]

  ask turtles
  [

;;;; Mortality is calculated first ;;;;

    calc-F    ; fishing mortality
    calc-M      ; background or "natural" mortality
    calc-starvation      ; starvation mortality

;;;; After mortality individuals move ;;;;

    if breed != eggs   ; eggs don't move or have an energy budget
    [
      calc-V_min      ; minimum swimming velocity is calculated
      drift           ; egg and larval drift

;;;; migrations ;;;;

      if (breed = juveniles) or (breed = adults)
      [
        spawn-migrate
        feed-migrate
        overwinter-migrate

        ifelse (feeding_strategy = "GAS") and (feeding = true) and (ticks > 3650 / rm)
        []
        [move-locally]                                                       ; individuals move locally if not migrating
      ]
;;;; A certain form of the Arrhenius function is needed for metabolic rate calculations and is calculated here ;;;;

      if (SST <= 0) or (SST >= 0)
      [
        set Arrhenius exp(- Ea / (boltz * (SST + 273.15)))
      ]


;;;; the appropriate elements of the energy budget are calculated (minus reproduction). Energy is allocated to the processes in different orders depending on life stage and time of year. Energy storage is called by the growth procedure for juveniles and adults, wheras larvae do not store energy ;;;;

      calc-ingestion
      calc-assimilation
      calc-maintenance
      calc-growth
      calc-total-mass
    ]

;;;; Individuals can then transform into the next life stage if they satisfy certain conditions ;;;;

    transform
  ]

;;;; Next, at the start of the spawning period, adults calculate their potential fecundity and the associated energy costs ;;;;

  ask adults
  [
    if ticks = start-spawn - 1
    [calc-reproduction]
    spawn    ; when in the spawning period, individuals allocate the required amount of energy to developing eggs in the procedure "spawn". This procedure then calls another, "deposit eggs", in which batches of eggs are introduced into the model
  ]

;;;; New egg individuals calculate their development, which must occur after they are spawned ensure they develop from age 0 (days) ;;;;

  ask eggs
  [calc-egg-development]

;;;; Individuals age (days post hatch) ;;;;

  ask turtles with [breed != eggs]
    [-age-]


;;;; scale_SSB (interface chooser) can be used to either hold SSB at a constant level, or to make it decrease at a fixed rate ;;;;

  if (ticks - (run-year * (365 / rm)) = round(121 / rm)) and (ticks > (3650 / rm)) and (scale_SSB != false) ; SSB is scaled just before the feeding period after spawning on May 1st
  [
    ifelse scale_SSB = "constant"
    [
      if run-year = 10
      [set ssb_t0 sum [total-mass * abundance] of adults]
      let scaler ssb_t0 / (sum [total-mass * abundance] of adults)
      ask turtles
      [
        set abundance abundance * scaler  ; SSB is held constant at ssb_t0 (SSB in 2005) by scaling the abundance n of each individual in equal proportion, hence retaining the population structure
      ]
    ]
    [
      if run-year = 10
      [set ssb_t0 sum [total-mass * abundance] of adults]
      let j run-year - 10
      let scaler (ssb_t0 - (( j * 0.075) * ssb_t0)) / (sum [total-mass * abundance] of adults) ; here SSB is reduced by a constant fraction of SSB_t0
      ask turtles
      [
        set abundance abundance * scaler
      ]
    ]
  ]

;;;; Patches calculate their mackerel density at the end of a time-step ;;;;

  calc_summer_distribution_stats

;;;; Various plots are updated ;;;;

  plot-outputs

;;;; And various population dynamics are calculated for analysis outside of NetLogo ;;;;

  if (ticks - (run-year * (365 / rm)) = (40 / rm)) and (run-year != 10)                  ; on Feb 10 each year the proportion of each age class that is mature is calculated
  [calc-maturity]

  if (ticks - (run-year * (365 / rm)) = round(355 / rm))                                      ; recruitment is calculated near the end of the year
  [calc-recruitment]

  if ticks - (run-year * (365 / rm)) = round(70 / rm)                                         ; length distribution calculated in early march in FAO area 6 to match data
  [calc-length-distribution]

  if ticks - (run-year * (365 / rm)) = round(322 / rm)                                        ; again in october to match data
  [calc-Q4-length-distribution]

  if ticks - (run-year * (365 / rm)) = round(213 / rm)                                        ; Aug 1 for comparison with IESSNS age distribution
  [
    calc-age-distribution
    calc-weight-at-age
  ]

  if ticks - (run-year * (365 / rm)) = round(122 / rm)
  [calc-spawning-SSB]

  if ticks - (run-year * (365 / rm)) = round(27 / rm)
  [
    calc-Feb-length-distribution
    calc-feb-age-distribution
  ]

  if ticks - (run-year * (365 / rm)) = (365 / rm)
  [set SumSSB sum [(abundance * total-mass)] of adults]

  if any? turtles with [(L > 36) and (L < 37)]
  [set M-at-36 mean [total-mass ] of turtles with [(L > 36) and (L < 37)]]; mean mass of fish in the 36cm length class


;;;; Including some for ABC

  if run-year >= 10
  [

    if (ticks - (run-year * (365 / rm)) = round(213 / rm))
    [
      ifelse run-year = 10
      [
        set ABC-SSB sum [total-mass * abundance] of adults
        set ABC-egg egg-production
        set ABC-sum-w3 mean [total-mass] of turtles with [(age > 3) and (age < 4)]
        set ABC-sum-w4 mean [total-mass] of turtles with [(age > 4) and (age < 5)]
        set ABC-sum-w5 mean [total-mass] of turtles with [(age > 5) and (age < 6)]
        set ABC-sum-w6 mean [total-mass] of turtles with [(age > 6) and (age < 7)]
        set ABC-sum-w7 mean [total-mass] of turtles with [(age > 7) and (age < 8)]
        set ABC-sum-w8 mean [total-mass] of turtles with [(age > 8) and (age < 9)]
        set ABC-sum-w9 mean [total-mass] of turtles with [(age > 8) and (age < 9)]
        set ABC-sum-w10 mean [total-mass] of turtles with [(age > 9) and (age < 10)]
        set ABC-sum-w11 mean [total-mass] of turtles with [(age > 10) and (age < 11)]
        set ABC-sum-w12 mean [total-mass] of turtles with [(age > 11) and (age < 12)]
        set ABC-sum-w13 mean [total-mass] of turtles with [(age > 12) and (age < 13)]
      ]
      [
        set ABC-SSB (list ABC-SSB (sum [total-mass * abundance] of adults))
        set ABC-egg (list ABC-egg (egg-production))
        set ABC-sum-w3 (list ABC-sum-w3 (mean [total-mass] of turtles with [(age > 3) and (age < 4)]))
        set ABC-sum-w4 (list ABC-sum-w4 (mean [total-mass] of turtles with [(age > 4) and (age < 5)]))
        set ABC-sum-w5 (list ABC-sum-w5 (mean [total-mass] of turtles with [(age > 5) and (age < 6)]))
        set ABC-sum-w6 (list ABC-sum-w6 (mean [total-mass] of turtles with [(age > 6) and (age < 7)]))
        set ABC-sum-w7 (list ABC-sum-w7 (mean [total-mass] of turtles with [(age > 7) and (age < 8)]))
        set ABC-sum-w8 (list ABC-sum-w8 (mean [total-mass] of turtles with [(age > 8) and (age < 9)]))
        set ABC-sum-w9 (list ABC-sum-w9 (mean [total-mass] of turtles with [(age > 9) and (age < 10)]))
        set ABC-sum-w10 (list ABC-sum-w10 (mean [total-mass] of turtles with [(age > 10) and (age < 11)]))
        if any? turtles with [age > 11]
        [set ABC-sum-w11 (list ABC-sum-w11 (mean [total-mass] of turtles with [(age > 11) and (age < 12)]))]
        if any? turtles with [age > 12]
        [set ABC-sum-w12 (list ABC-sum-w12 (mean [total-mass] of turtles with [(age > 12) and (age < 13)]))]
        if any? turtles with [age > 13]
        [set ABC-sum-w13 (list ABC-sum-w13 (mean [total-mass] of turtles with [(age > 13) and (age < 14)]))]
       ]
    ]

    if (ticks - (run-year * (365 / rm)) = round(121 / rm))
    [
      ifelse run-year = 10
      [
        set ABC-spawn-SSB sum [total-mass * abundance] of adults
        set sp_SSB sum [total-mass * abundance] of adults
      ]
      [
        set ABC-spawn-SSB (list ABC-spawn-SSB (sum [total-mass * abundance] of adults))
        set sp_SSB sum [total-mass * abundance] of adults
      ]
    ]
    if (ticks - (run-year * (365 / rm)) = round(121 / rm))
    [
      ifelse run-year = 10
      [
        set ABC-sp-w3 mean [total-mass] of turtles with [(age > 3) and (age < 4)]
        set ABC-sp-w4 mean [total-mass] of turtles with [(age > 4) and (age < 5)]
        set ABC-sp-w5 mean [total-mass] of turtles with [(age > 5) and (age < 6)]
        set ABC-sp-w6 mean [total-mass] of turtles with [(age > 6) and (age < 7)]
        set ABC-sp-w7 mean [total-mass] of turtles with [(age > 7) and (age < 8)]
        set ABC-sp-w8 mean [total-mass] of turtles with [(age > 8) and (age < 9)]
        set ABC-sp-w9 mean [total-mass] of turtles with [(age > 9) and (age < 10)]
        set ABC-sp-w10 mean [total-mass] of turtles with [(age > 10) and (age < 11)]
        set ABC-sp-w11 mean [total-mass] of turtles with [(age > 11) and (age < 12)]
        set ABC-sp-w12 mean [total-mass] of turtles with [(age > 12) and (age < 13)]
      ]
      [
        set ABC-sp-w3 (list ABC-sp-w3 (mean [total-mass] of turtles with [(age > 3) and (age < 4)]))
        set ABC-sp-w4 (list ABC-sp-w4 (mean [total-mass] of turtles with [(age > 4) and (age < 5)]))
        set ABC-sp-w5 (list ABC-sp-w5 (mean [total-mass] of turtles with [(age > 5) and (age < 6)]))
        set ABC-sp-w6 (list ABC-sp-w6 (mean [total-mass] of turtles with [(age > 6) and (age < 7)]))
        set ABC-sp-w7 (list ABC-sp-w7 (mean [total-mass] of turtles with [(age > 7) and (age < 8)]))
        set ABC-sp-w8 (list ABC-sp-w8 (mean [total-mass] of turtles with [(age > 8) and (age < 9)]))
        set ABC-sp-w9 (list ABC-sp-w9 (mean [total-mass] of turtles with [(age > 9) and (age < 10)]))
        set ABC-sp-w10 (list ABC-sp-w10 (mean [total-mass] of turtles with [(age > 10) and (age < 11)]))
        set ABC-sp-w11 (list ABC-sp-w11 (mean [total-mass] of turtles with [(age > 11) and (age < 12)]))
        set ABC-sp-w12 (list ABC-sp-w12 (mean [total-mass] of turtles with [(age > 12) and (age < 13)]))
       ]
    ]

    if ((ticks - (run-year * (365 / rm)) = round(361 / rm)))
    [
      ifelse run-year = 10
      [
        set ABC-rec num-recruits
        set catch-series catch
      ]
      [
        set ABC-rec (list ABC-rec num-recruits)
        set catch-series (list catch-series catch)
       ]
    ]
  ]

  ;;;; and some for spatial statistics

  if (ticks - (run-year * (365 / rm)) = round(360 / rm)) and (run-year >= 10)
  [
    ifelse run-year = 10
    [set output-area feed-area]
    [set output-area (list output-area feed-area)]
  ]

  if (ticks - (run-year * (365 / rm)) = round(213 / rm)) and (run-year >= 10)
  [
    ifelse run-year = 10
    [set feed-ssb SumSSB]
    [set feed-ssb (list feed-ssb SumSSB)]

  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; Spin up repeats "go" for 3650 days, i.e. 10 years ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to spin-up
  repeat round(3650 / rm) [go]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; To repeat go for as many years as we have data for ABC ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go-ABC
  repeat (((2018 - (start_year + 10)) + 1) * 73) - 5 [go]
end

to go_forecast
  repeat ((2050 - (start_year + 10)) + 1) * 73 [go]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; This procedure calculates the execution speed of other procedures and is not called by go ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to profile
  reset-timer                                       ; This is called by its own button on the interface
  profiler:reset
  profiler:start
  repeat (365 / rm) [go]
  profiler:stop
  let fname "F:/PhD/Model/Outputs/Profiler.csv"     ; A file is written to this location with the diagnostics
  ;file-open fname
  ;file-print profiler:report
  ;file-close
  print profiler:report
  print timer
end

to calc-run-year                                    ; run year is used to determine on what time-step annual processes should happen
  if ticks mod (365 / rm) = 0
  [
    set run-year ticks / (365 / rm)
    set actual_year start_year + run-year
  ]

end

;;;; F varies within each year so we calculate simulation month below and can then use this to distribute F properly ;;;;

to calc_month
  if ticks mod (365 / rm) = 0
  [
    set month 1
    set month_days 31
    set prop_catch_4a 0.016
    set F_multiplier 0.22
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim
  ]

  if (ticks - (run-year * (365 / rm))) = round(32 / rm)
  [
    set month 2
    set month_days 28
    set F_multiplier 0.07
    set prop_catch_4a 0.018
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim
  ]

  if (ticks - (run-year * (365 / rm))) = round(60 / rm)
  [
    set month 3
    set month_days 30
    set F_multiplier 0.14
    set prop_catch_4a 0.0014
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim
  ]

  if (ticks - (run-year * (365 / rm))) = round(91 / rm)
  [
    set month 4
    set month_days 30
    set F_multiplier 0.12
    set prop_catch_4a 0.01
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim
  ]

  if (ticks - (run-year * (365 / rm))) = round(121 / rm)
  [
    set month 5
    set month_days 31
    set F_multiplier 0.004
    set prop_catch_4a 0.06
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim

    set min_lat_always_light 70.5

    set directory "F:/SEASIM-MAC_2020/inputs/photoperiod"
    set raster (word directory "/photo__" month ".asc")
    set photo-data gis:load-dataset  raster
    gis:apply-raster photo-data photo_mult

    set directory "F:/SEASIM-MAC_2020/inputs/currents"

    set raster (word directory "/" month "_u.asc")
    set currents-data gis:load-dataset  raster
    gis:apply-raster currents-data u

    set raster (word directory "/" month "_v.asc")
    set currents-data gis:load-dataset  raster
    gis:apply-raster currents-data v
  ]

  if (ticks - (run-year * (365 / rm))) = round(152 / rm)
  [
    set month 6
    set month_days 30
    set prop_catch_4a 0.04
    set F_multiplier 0.02
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim

    set min_lat_always_light 65.9

    set directory "F:/SEASIM-MAC_2020/inputs/photoperiod"
    set raster (word directory "/photo__" month ".asc")
    set photo-data gis:load-dataset  raster
    gis:apply-raster photo-data photo_mult

    set directory "F:/SEASIM-MAC_2020/inputs/currents"

    set raster (word directory "/" month "_u.asc")
    set currents-data gis:load-dataset  raster
    gis:apply-raster currents-data u

    set raster (word directory "/" month "_v.asc")
    set currents-data gis:load-dataset  raster
    gis:apply-raster currents-data v
  ]

  if (ticks - (run-year * (365 / rm))) = round(182 / rm)
  [
    set month 7
    set month_days 31
    set F_multiplier 0.08
    set prop_catch_4a 0.14
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim

    set min_lat_always_light 67.5

    set directory "F:/SEASIM-MAC_2020/inputs/photoperiod"
    set raster (word directory "/photo__" month ".asc")
    set photo-data gis:load-dataset  raster
    gis:apply-raster photo-data photo_mult

    set directory "F:/SEASIM-MAC_2020/inputs/currents"

    set raster (word directory "/" month "_u.asc")
    set currents-data gis:load-dataset  raster
    gis:apply-raster currents-data u

    set raster (word directory "/" month "_v.asc")
    set currents-data gis:load-dataset  raster
    gis:apply-raster currents-data v
  ]

  if (ticks - (run-year * (365 / rm))) = round(213 / rm)
  [
    set month 8
    set month_days 31
    set prop_catch_4a 0.16
    set F_multiplier 0.08
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim

    set min_lat_always_light 70.5

    set directory "F:/SEASIM-MAC_2020/inputs/photoperiod"
    set raster (word directory "/photo__" month ".asc")
    set photo-data gis:load-dataset  raster
    gis:apply-raster photo-data photo_mult

    set directory "F:/SEASIM-MAC_2020/inputs/currents"

    set raster (word directory "/" month "_u.asc")
    set currents-data gis:load-dataset  raster
    gis:apply-raster currents-data u

    set raster (word directory "/" month "_v.asc")
    set currents-data gis:load-dataset  raster
    gis:apply-raster currents-data v
  ]

  if (ticks - (run-year * (365 / rm))) = round(244 / rm)
  [
    set month 9
    set month_days 30
    set F_multiplier 0.09
    set prop_catch_4a 0.58
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim

    set min_lat_always_light 60 ; arbitrarily low as the end of the feeding period is signified and individuals should stop seeking out longest photoperiods

    set directory "F:/SEASIM-MAC_2020/inputs/photoperiod"
    set raster (word directory "/photo__" month ".asc")
    set photo-data gis:load-dataset  raster
    gis:apply-raster photo-data photo_mult
  ]

  if (ticks - (run-year * (365 / rm))) = round(274 / rm)
  [
    set month 10
    set month_days 31
    set F_multiplier 0.11
    set prop_catch_4a 0.84
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim

    set directory "F:/SEASIM-MAC_2020/inputs/photoperiod"
    set raster (word directory "/photo__" month ".asc")
    set photo-data gis:load-dataset  raster
    gis:apply-raster photo-data photo_mult
  ]

  if (ticks - (run-year * (365 / rm))) = round(305 / rm)
  [
    set month 11
    set month_days 30
    set F_multiplier 0.05
    set prop_catch_4a 0.70
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim
  ]

  if (ticks - (run-year * (365 / rm))) = round(335 / rm)
  [
    set month 12
    set month_days 31
    set F_multiplier 0.02
    set prop_catch_4a 0.69
        set c_lim sum [(((item (floor age) F) * F_multiplier) / (((item (floor age) F) * F_multiplier) + (M / 12))) * (1 - exp(- (((item (floor age) F) * F_multiplier) + (M / 12)))) * (total-mass * abundance)] of turtles
    set annual_c_lim annual_c_lim + c_lim
  ]

end


;;;; Fishing mortality F from the appropriate year is loaded into the model ;;;;

to load-F
  ifelse actual_year > 2018
  [
    if (future_annual_F = "unfished") or (future_annual_F = 1)
    [set F (list 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)]

    if future_annual_F = "hist_mean"
    [set F (list 0.00771794871794872 0.0286666666666667 0.0532564102564103 0.117692307692308 0.204974358974359 0.242948717948718 0.301205128205128 0.35125641025641 0.35125641025641 0.35125641025641 0.35125641025641 0.35125641025641 0.35125641025641 0.35125641025641 0.35125641025641 0.35125641025641)]

    if (future_annual_F = "F_MSY") or (future_annual_F = 2)
    [
      file-open (word "F:/PhD/mac_model_v3/inputs/F/FMSY.txt")
      set F (list file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read) ; there is a file for each year's F-at-age in the directory. it is read in here
      file-close
    ]

    if (future_annual_F = "F_lim") or (future_annual_F = 3)
    [
      file-open (word "F:/SEASIM-MAC_2020/inputs/F/Flim.txt")
      set F (list file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read) ; there is a file for each year's F-at-age in the directory. it is read in here
      file-close
    ]
  ]
  [
    print "F successfully loaded"
    file-open (word "F:/SEASIM-MAC_2020/inputs/F/" (run-year + start_year) ".txt")
    set F (list file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read file-read) ; there is a file for each year's F-at-age in the directory. it is read in here
    file-close
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; Phytoplankton biomass and SST are loaded from satellite data ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to load-chl
  if ((ticks - (run-year * (365 / rm))) mod (10 / rm) != 0)   ; Every tenth day the appropriate chl map is loaded in.
  [
    set directory "F:/SEASIM-MAC_2020/inputs/sst_chl"                                                           ; location on pc of chl data
    set raster (word directory "/phyto_" (((((ticks - (run-year * (365 / rm))) + 1) / (10 / rm)) + ((run-year - 10) * 36)) + 36) ".asc")           ; appropriate file identified
    set phyto-data gis:load-dataset  raster
    gis:apply-raster phyto-data X_phyto                                                                            ; patches are given values for phytoplankton biomass from the phyto-data

    ask patches
    [
      set-color                                                                                                        ; set patch colour according to its chl
    ]
  ]
end

to load-SST   ; SST is loaded in the same way as chl
  if (ticks >= (round(60 / rm))) and ((ticks - (run-year * (round(365 / rm)))) mod (10 / rm) != 0) and (ticks - (run-year * (365 / rm)) != 73)
  [
    set directory "F:/SEASIM-MAC_2020/inputs/sst_chl"
    set rasterSST (word directory "/sst_" (((((ticks - (run-year * (365 / rm))) + 1) / (10 / rm)) + ((run-year - 10) * 36)) + 36) ".asc")
    set SST-data gis:load-dataset  rasterSST
    gis:apply-raster SST-data SST
  ]
end

;;;; from ESM ;;;;

to load-ESM-inputs

  if (ticks mod (365 / rm) = 1) or (ticks mod (365 / rm) = round(32 / rm)) or (ticks mod (365 / rm) = round(60 / rm)) or (ticks mod (365 / rm) = round(91 / rm)) or (ticks mod (365 / rm) = round(121 / rm)) or (ticks mod (365 / rm) = round(152 / rm))
  or (ticks mod (365 / rm) = round(182 / rm)) or (ticks mod (365 / rm) = round(213 / rm)) or (ticks mod (365 / rm) = round(244 / rm)) or (ticks mod (365 / rm) = round(274 / rm)) or (ticks mod (365 / rm) = round(305 / rm)) or (ticks mod (365 / rm) = round(335 / rm))
  [
    set month_n month_n + 1
    set directory "F:/SEASIM-MAC_2020/inputs/ESM_inputs"

    ifelse (actual_year > 2005) and (actual_year < 2019)
    [set raster (word directory "/rcp_mean_chl_" (month_n - 300) ".asc")]
    [set raster (word directory "/GFDL_" RCP "chl_" month_n ".asc")]
    set phyto-data gis:load-dataset  raster
    gis:apply-raster phyto-data X_phyto

    ask patches
    [
      ifelse (X_phyto >= 0)
      [set ocean true]
      [set ocean false]
      set-color                                                                                                        ; set patch colour according to its chl
    ]

    ifelse (actual_year > 2005) and (actual_year < 2019)
    [set rasterSST (word directory "/rcp_mean_sst_" (month_n - 300) ".asc")]
    [set rasterSST (word directory "/GFDL_" RCP "tos_" month_n ".asc")]
    set SST-data gis:load-dataset  rasterSST
    gis:apply-raster SST-data SST
  ]
end

;;;; sst on the spawning grounds is calculated over March, April and May. The mean of these values is then used as input to the Ricker stock recruitment function ;;;;

to calc-spawning-SST
  set spawning_SST lput (mean [SST] of patches with [(Ricker_spawn_area = true) and (SST >= 0)]) spawning_SST
end

;;;; recruits are input at the end of each year in the spin-up ;;;;

to input-recruits
  create-turtles n_cohort * n_multiplier
    [
      set size 1
      set L L1 - (3 * random-float 1)
      ifelse run-year < 10
      [
        ifelse constant_rec? = true
        [
          set abundance (item (start_year - 1980) spin-up-rec * 0.8 * 1000) / (n_multiplier * 70)  ; stock assessment estimate of recruitment scaled by 0.8 to refelct the fact we only represent the western component
          set num-recruits (item (start_year - 1980) spin-up-rec * 0.8 * 1000)
        ]
        [
          let p start_year - 1980
          set abundance (item (run-year + p) spin-up-rec * 0.8 * 1000) / (n_multiplier * 70)
          set num-recruits (item (run-year + p) spin-up-rec * 0.8 * 1000)
        ]
      ]
      [
        let sp_SST mean spawning_SST
        print sp_SST
        print sp_SSB
        set abundance (a_R * sp_SSB * exp((b_R * sp_SSB) + (c_R * sp_SST))) / (70 * n_multiplier)
        set num-recruits (a_R * sp_SSB * exp((b_R * sp_SSB) + (c_R * sp_SST)))
      ]

      set age (365 - 91) / 365
      set dage 365 - 91
      ifelse who mod 2 = 0
      [set gender 0]
      [set gender 1]
      set breed juveniles
      set color grey
      set shape "fish"
      set std-mass 0.00285 * (L ^ (3.325))
      set energy-reserve-max ((std-mass * 0.59) * 39.3)
      set energy-reserve energy-reserve-max * 0.5
      set structural-mass (std-mass * 0.76)
      set total-mass structural-mass + (energy-reserve / 39.3)
      set M 0.15
      set Mda M / 73
      set Fda 0.00001
      set standard-L (L - 0.1561) / 1.1396
      set migrating false
      move-to one-of patches with [(NArea = true) and (sst >= 0)]
    ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; Calculation of mortalities ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calc-starvation
  if (breed != eggs) and (breed != YS-larvae)                          ; eggs and ys-larvae cannot starve as they are nourished by the yolk-sac
  [
  if total-mass < structural-mass                                     ; if total-mass becomes < structural mass then die
    [die]
  ]

  if abundance < 1                                                    ; an individual is removed from the model if all of its "actual" individuals die
    [die]
end

;;;; Fishing mortality ;;;;

;;;; this procedure calculates the rates of fishing mortality inflicted on each individual based on annual F and month, and calculates the associated catch in weight on the patch ;;;;

to calc-F                                                             ; age-specific instantaneous rates of F are set, then converted to the proportion of a superindividual's abundance that dies
  set Fa item (floor age) F

  ifelse (close_A4 = 2) or ((close_A4 = 1) and ((ticks - (run-year * (round(365 / rm)))) < (round(212 / rm))) and ((ticks - (run-year * (round(365 / rm)))) > round(46 / rm))) ; i.e. if in 4a when it is closed
  [
    ifelse A4 = true  ;; if in 4a when it is closed
    [
      set Fda 0
      set num-fished 0
      set report-fished 0
    ]
    [
      ifelse (redistribute_F = true) or (redistribute_F = 0)
      [
        let mass_in sum [abundance] of turtles with [((floor age) = [floor age] of myself) and (a4 = true)]
        let mass_tot sum [abundance] of turtles with [(floor age) = [floor age] of myself]
        let prop_in mass_in / mass_tot
        set Fda ((Fa * F_multiplier) / round(month_days / rm)) * ((1 - prop_in) ^ -1)
      ]
      [set Fda (Fa * F_multiplier) / round(month_days / rm)]
    ]
  ]
  [ ;; if outside of closed season or if F is not spatially-explicit
    ifelse ((match_closure_F = true) or (match_closure_F = 0)) and (actual_year > 2018)
    [
      let mass_in sum [(abundance)] of turtles with [((floor age) = [floor age] of myself) and (a4 = true)]
      let mass_tot sum [(abundance)] of turtles with [(floor age) = [floor age] of myself]
      let prop_in mass_in / mass_tot
      let redistributed_F (Fa * F_multiplier) / round(month_days / rm) * ((1 - prop_in) ^ -1)
      set Fda (Fa * F_multiplier) / round(month_days / rm)
      set Fda Fda - (redistributed_F - Fda)
    ]
    [set Fda (Fa * F_multiplier) / round(month_days / rm)]
  ]

  set catch catch + ((Fda / (Fda + Mda)) * (1 - exp(- (Fda + Mda))) * (total-mass * abundance))

  set num-fished 1 - exp(- Fda)                                         ; proportion dying
  set report-fished abundance * num-fished
  set abundance abundance - (num-fished * abundance)
  set abundance (floor abundance)                                       ; this ensures that fractional numbers of fish cannot remain

end

;;;; Background  mortality Mback ;;;;

to calc-M
  ifelse breed = juveniles  ; individuals are only susceptible to M if they are not susceptible to explicit predation (ie if they are < 3.312 cm, or there aren't any other mackerel close by and > 3.5x larger)
  [
    set inedible true                                              ; i.e. cannot be explicitly eaten
    ifelse L < Lm                                                    ; if a juvenile is less than the threshold length for maturity
    [
      set Mda Ma * (Lm / L)                                          ; equation 16
      set M Mda * round(365 / rm)
    ]
    [
      set Mda Ma                                                     ; M becomes constant at rate Ma when they reach Lthresh
      set M Mda * round(365 / rm)
    ]
    set num-M 1 - exp (- Mda)                                        ; M is converted to a proportion of the super-individual dying
    set abundance abundance - (num-M * abundance)
    set abundance (floor abundance)                      ; this ensures fractional "actual" individuals cannot exist in the model
    if age >= 15 [die]
  ]
  [
    if (breed = YS-larvae) or (breed = larvae) or (breed = eggs)                      ; larval mortality is constant
    [
      set inedible false
      set Mda Me * rm
      set M Mda * round(365 / rm)
      set num-M 1 - exp (- (Me * rm))
      set abundance abundance - (num-M * abundance)
      set abundance (floor abundance)
    ]

    if breed = adults
    [
      set M Ma * round(365 / rm)                                                 ; adult mortality is constant
      set Mda Ma
      set num-M 1 - exp (- Mda)
      set abundance abundance - (num-M * abundance)
      set abundance (floor abundance)
      if age >= 15                                                  ; individuals are removed from the model when turning 15
      [die]
    ]
  ]
end

;;;; Transformation into next life stage ;;;;

to transform
  ask eggs
  [
    if development >= embryo-duration                    ; when eggs have developed for as many days as calculated using the Arrhenius function, they hatch into larvae
    [
      set breed YS-larvae
      set color black
      set size 1
      set shape "fish"
      set L Lhatch                                         ; Villamore et al. (2004, cm)
      set standard-L (L - 0.1561) / 1.1396
      set std-mass 0.001                                ; g (Sibly et al. 2015)
      set energy-reserve-max 0                          ; larvae do not store energy, they feed continuously to grow
      set migrating false
      set larval-production larval-production + abundance
    ]
  ]

  ask YS-larvae
  [
    if L >= 0.61                                        ; size threshold (Sette)
    [
      set breed larvae
      set color black
      set size 1
      set shape "fish"
      set std-mass 0.00285 * L ^ (3.325)  ; Equation 13. For larvae we do not represent gonad and structural mass separately, rather we just use standard mass
    ]
  ]

  ask larvae
  [
    if L >= 3                                           ; size threshold (Sette)
    [
      set breed juveniles
      set color grey
      set size 1
      set shape "fish"
      set energy-reserve-max ((std-mass * 0.59) * 39.3)
      set energy-reserve 0
    ]
  ]

  ask juveniles
  [
    if ((ticks > (3650 / rm)) and (L >= Lm) and (ticks = (report-tick-pre-spawn-mig - 1))) or ((ticks < round(3650 / rm)) and (age < 3) and (age > 2) and (ticks = (report-tick-pre-spawn-mig - 1)))   ; juveniles can only mature on Feb 1st, and if they meet size and condition thresholds
    [
      set breed adults
      set color grey
      ;set size 2
      set shape "fish"
      set migrating false
      set Amat age
      set Lmat L
      set num-matured num-matured + abundance                           ; number of individuals that have reached sexual maturity is calculated each year
    ]
  ]
end

;;;; the speed at which individuals can sustainably swim  ;;;;

to calc-V_min
  set V_min A * (standard-L ^ (a_w)) * (Ar ^ (b_w))                ; Sambilay Jr (1990, equation 1)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; Migrations ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; "report-tick" procedure simply calculates the time-step on which migrations should begin in the current year ;;;;

to calc-migration-ticks
  set report-tick-pre-spawn-mig (run-year * (365 / rm)) + round(31 / rm)
  set report-tick-post-spawn-mig (run-year * (365 / rm)) + round(122 / rm)
  set report-tick-pre-overwinter-mig (run-year * (365 / rm)) + round(274 / rm)
  set start-spawn (run-year * (365 / rm)) + round(61 / rm)
  set end-spawn (run-year * (365 / rm)) + round(212 / rm)
end

;;;; spawning migration ;;;;

to spawn-migrate                                                                           ; Spawning migration from overwintering to southern part of the spawning grounds
  if breed = adults
  [
    if ticks < round(31 / rm)
      [set migrating false]                                                                    ; this must be set to avoid syntax errors at the start of a simulation

    ifelse (ticks > start-spawn) and (SArea = true)
    [stop]                                                                                    ; if an individual is in the spawning ground during the spawning period, it stops calling the migration procedure and begins the spawning procedure instead
    [
      if ticks >= (report-tick-pre-spawn-mig) and ticks <= (report-tick-pre-spawn-mig + round(90 / rm))   ; migration can occur for no more than 90 days (though it is extremely unlikely this would happen anyway)
      [
        ifelse (PreSArea = false)                                                             ; once the spawning area is reached, movement becomes local until spawning begins
        [
          set migrating true

          let x0 xcor
          let y0 ycor
          let dist spawn-dist

          ifelse (shelf-edge = true)
          [
            move-to min-one-of patches with [(shelf-edge = true) and (spawn-dist > 0) and (X_phyto >= 0) and (North_Sea != true)] in-radius ((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1)))) [spawn-dist] ;
          ]
          [
            move-to min-one-of patches with [(spawn-dist != 0)]  [distance myself]
          ]

          set realised-speed ((distance patch x0 y0 * 60) / (24 * rm))

        ]
        [set migrating false]
    ]
    ]
  ]
end

;;;; Northward feeding migration after spawning ;;;;

to feed-migrate                                                                       ; feeding migration
  if breed = adults
  [
    ifelse (batches >= n_batch) ; migrate after all batches of eggs have been spawned
    [
      if ticks = report-tick-post-spawn-mig  ; set a random number between one and 5 indicating the distance from the target destination patch at which the migration will end and feeding movement will begin. This is just to prevent all individuals congregating on same destination patch
      [set launch_pad_R random 5]

      if (ticks >= report-tick-post-spawn-mig) and (ticks <= report-tick-post-spawn-mig + round(150 / rm))
      [
        ifelse ((Feed-dist > launch_pad_R) and  (feeding != true)) and (ann_step < 35)                                        ; migrate until the randomly-selected distance from the feeding destination, at which point the migration ends
        [
          set migrating true

          let x0 xcor
          let y0 ycor
          let dist feed-dist

          move-to min-one-of patches with [(feed-dist <= dist) and (feed-dist > 0) and (X_phyto >= 0) and (shelf-edge = true)] in-radius ((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1)))) [feed-dist] ;

          set realised-speed ((distance patch x0 y0 * 60) / (24 * rm))

        ]
        [ ;; if close enough to the feeding destination patch then stop migrating
          set migrating false
          set feeding true
        ]
      ]
    ]
    []
  ]
end

;;;; migration after feeding to the overwintering area ;;;;

to overwinter-migrate
  if breed = adults
  [
    if (ticks >= report-tick-pre-overwinter-mig) and (ticks <= report-tick-pre-overwinter-mig + round(60 / rm)) ; migration occurs for up to 60 days, meaning all individuals can reach the overwintering area in time
    [
      set feeding false

      ifelse (OWArea = false)                                                                       ; once the spawning area is reached, movement becomes local
      [
        set migrating true

        if [feed-dist] of patch-here = 0
        [
          move-to min-one-of patches with [(feed-dist > 0)] [distance myself]
        ]

        let dist feed-dist
        let x0 xcor
        let y0 ycor

        ifelse any? patches with [(X_phyto >= 0) and (feed-dist < dist) and (feed-dist != 0)] in-radius ((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))
        [
          move-to min-one-of patches with [(feed-dist < dist) and (feed-dist > 0) and (X_phyto >= 0)] in-radius ((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1)))) [feed-dist] ;
        ]
        [
          ifelse dist = 1
          [move-to one-of patches with [(feed-dist < 5) and (OWarea = true)]]
          [move-to min-one-of patches with [(X_phyto >= 0) and (feed-dist < dist) and (feed-dist > 0)] [distance myself]]]

        set realised-speed ((distance patch x0 y0 * 60) / (24 * rm))
      ]
      [set migrating false]
    ]
  ]
end

to drift                                                                                            ; larvae drift towards the nursery areas from where they were spawned. For lack of better estimate, they move half a patch towards the nursery every other day, with random walks in between
  if (breed = YS-larvae) or (breed = larvae)
  [
    ifelse (NArea = false)
    [
      set migrating true
      face one-of patches with [(NArea = true) and (X_phyto >= 0) and (SST >= 0)]
      fd 0.5 / rm
      ifelse (X_phyto >= 0) and (sst >= 0)
      []
      [move-to min-one-of patches with [(sst >= 0) and (X_phyto >= 0)] [distance myself]]
      ]
    [set migrating false]
  ]
end

;;;; when not migrating, seeking out the best feeding locations, or spawning, individuals move locally with random walk ;;;;

to move-locally

  let ID [who] of self                                                                                                                                                     ; this variable allows us to ID the focal turtle and determine its maximum swimmable distance when in a patch context

  if ((spawning = false) or (spawning = 0)) and ((migrating = false) or (migrating = 0))                                                                                    ; If not migrating or spawning
  [
    if (breed = adults) and (PreSArea = true)                                                                                                                             ; and in the spawning area
    [
      ifelse any? patches with [(PreSArea = true) and (X_phyto >= 0) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID) and (depth < 0)]
      [move-to one-of patches with [(PreSArea = true) and (X_phyto >= 0) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID)]]
      [move-to min-one-of patches with [(PreSArea = true) and (X_phyto >= 0)] [distance myself]]                          ; random walk to a patch in the same area
    ]
    if NArea = true
    [
      ifelse breed = adults                                                                                                                                               ; there is overlap between the nursery and overwintering areas - this ensures adults and juveniles go to the right one
      [
        if not any? patches with [(OWArea = true) and (X_phyto >= 0) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID)]                            ; as juveniles transform into adults, they are often too far from the overwintering grounds for this procedure to work. Because their spawning migration begins the following day, they simply remain where they are until then
        [stop]
        move-to one-of patches with [(OWArea = true) and (X_phyto >= 0) and (sst > 0) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID)]
      ]
      [
        ifelse any? patches with [(NArea = true) and (X_phyto >= 0) and (sst >= 0) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID) and (depth < 0)]
        [move-to one-of patches with [(NArea = true) and (X_phyto >= 0) and (SST >= 0) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID) and (depth < 0)]]
        [move-to min-one-of patches with [(NArea = true) and (X_phyto >= 0)  and (SST >= 0) and (depth < 0)] [distance myself]]                                     ; occasionally individuals end too far from the nursery area and this brings them back
      ]
    ]
    if (OWArea = true)    and (feeding != true)                                                                                                                                                   ; again, because overwintering and nursery areas overlap, this ensures adults and juveniles go to the correct one
    [
      ifelse breed = adults
      [
        if not any? patches with [(OWArea = true) and (X_phyto >= 0) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID)]
        [stop]
        move-to one-of patches with [(OWArea = true) and (X_phyto >= 0) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID)]
      ]                                                                                                                                                                   ; again, because of overlap in OW area and N area, adults must be kept in the former and vice versa for juveniles
      [move-to one-of patches with [(NArea = true) and (X_phyto >= 0) and (SST >= 0) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID)]]
    ]
    if (feeding = true)                                                                                                                                                   ; random walk in the feeding area
    [
      if feeding_strategy = "IDF"
      [
        ideal-free-distribution
      ]

      if feeding_strategy = "Random"
      [
        ifelse any? patches with [(FArea = true) and (X_phyto >= 0) and (SST >= 7) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID)]
        [move-to one-of patches with [(FArea = true) and (X_phyto >= 0) and (SST >= 7) and (distance myself < [((V_min * (24 * rm)) / (30 + (7.5 * (rm - 1))))] of turtle ID)]]
        [move-to min-one-of patches with [(FArea = true) and (X_phyto >= 0) and (SST >= 7)] [distance myself]]
      ]
    ]
  ]

    ask juveniles                                                                                                                                                          ; Occasionally larvae transform into juveniles before reaching the nursery area. If so, it is transported to the nursery area
    [
      if (NArea = false)
      [
        move-to min-one-of patches with [(NArea = true) and (X_phyto >= 0) and (SST > 0)] [distance myself]
        set migrating false
      ]
      if pxcor = round(82 / rm)
      [set migrating false]                                                                                                                                               ; this prevents juveniles getting stuck on the boundary of the nursery areas
    ]
end

to GAS

ifelse better_patch = false ;; if the current environment is not better than the environment in the previous day
[
;; First we set up the directed or "search" part of movement. Individuals spend 12 hrs a day actively "searching"

;; This begins with the orientation part of the search

;; we calculate the distances in x,y dimension to the patches with the highest value of the appropriate cue

  let x0 xcor
  let y0 latitude

  let x [pxcor] of patch-here
  let y [pycor] of patch-here

  ask neighbors4 with [sst >= 0]  ; individuals can detect the environment in the neighbouring patches in x and y dimensions. If a patch does not have a value for SST, i.e. is on land, individuals will not move towards it
  [
    set feeding_cue Cmax * photo_mult * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) *
        X_phyto / (h + X_phyto + (c * (sum [total-mass * abundance] of turtles-here)))    ; Equation 4. This is modified when we use the other feeding cue which is given by equation 2

    if (coast = true)
    [set feeding_cue feeding_cue * 0.5]  ; individuals are discincentivised from moving towards land

    if (sst < 7) or (sst > 13) or (not (photo_mult > 0) or (not (X_phyto > 0)))
    [set feeding_cue 0]  ; cue is set to 0 on patche where SST < 7 as individuals cannot tolerate those temperartures
  ]

  ifelse any? neighbors4 with [(pycor = y) and (ocean = true) and (coast != true) and (sst >= 7) and (photo_mult > 0) and (X_phyto > 0)] ; if there are any possible patches to move to in the x dimension, i.e. with the same ycor but different xcor
  [
    set optimal_x [pxcor] of max-one-of neighbors4 with [(pycor = y) and (ocean = true) and (coast != true) and (photo_mult > 0) and (X_phyto > 0)] [feeding_cue] ; identify the optimal patch in x dimension
    set d_x optimal_x - xcor  ; calculate the distance to the centre of the optimal patch in x dimension
    set cornered_x false ; if cornered = true, then there are no possible neighbours to which an individual can move in x dimension
  ]
  [
    set cornered_x true
  ]

;; same as above but in the y dimension

  ifelse any? neighbors4 with [(pxcor = x) and (ocean = true) and (coast != true) and (sst >= 7) and (photo_mult > 0) and (X_phyto > 0)]
  [
    set optimal_y [pycor] of max-one-of neighbors4 with [(pxcor = x) and (ocean = true) and (coast != true) and (photo_mult > 0) and (X_phyto > 0)] [feeding_cue]
    set d_y optimal_y - ycor
    set cornered_y false
  ]
  [
    set cornered_y true
  ]

  set Rs (V_min * 12) + ((V_min * 12)   * random-float 1)

;; now we calculate the difference between the cue at the current location, and the cue at the patch with highest value of cue (this will be 0 if the current patch is optimal), in x,y dimensions

    set d_cue_x ([feeding_cue] of patch optimal_x y) - Cmax * photo_mult * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) * X_phyto / (h + X_phyto + (c * (sum [total-mass * abundance] of turtles-here)))
    set d_cue_y ([feeding_cue] of patch x optimal_y) - Cmax * photo_mult * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) * X_phyto / (h + X_phyto + (c * (sum [total-mass * abundance] of turtles-here)))

;; and we now have eveything needed to calculate the cue gradients in x,y. If individuals are already on the optimal patch in x or y, then the gradient in that dimension is set to zero

    ifelse (d_x != 0)
    [set gradient_x d_cue_x / d_x]
    [set gradient_x 0]

    ifelse (d_y != 0)
    [set gradient_y d_cue_y / d_y]
    [set gradient_y 0]

;; and from this we can calculate the direction unit vectors Gx, Gy using mg which is the magnitude of the cue gradient

    set mg sqrt ((gradient_x ^ 2) + (gradient_y ^ 2))  ; part of equation 6

    ifelse mg != 0  ; if individuals are already on the optimal patch in both x and y dimensions, then the cue gradients and hence mg is zero. In this case individuals are assumed to remain on the current patch
    [
      set Gx gradient_x / mg
      set Gy gradient_y / mg

;; and now we can get difference in x and difference in y using all of the above. Note that Rs is scaled so that it is converted into NetLogo distance, given the spatial resolution

      set delta_dx (Rs / 60) * Gx  ; part of equation 6
      set delta_Dy (Rs / 60) * Gy
    ]
    [
      set delta_Dx 0
      set delta_Dy 0
    ]

;;;; now for the second 12hr slot in each day we add a random movement ;;;;

  let random_S (V_min * 12) / 60

  set heading (true_north_heading - 90) + random 180

  set delta_Rx random_S * dx
  set delta_Ry random_S * dy

]

;; and now if the current environment IS better than the previous day. Need to go back to the start of this procedure to see how this fits in
[
  set Rs (V_min * 12) + ((V_min * 12)   * random-float 1)

  facexy ((Rs / 60) * Gx) ((Rs / 60) * Gy)

  ifelse [sst] of patch-ahead (Rs / 60) >= 7
  [
    set delta_Dx ((Rs / 60) * Gx)
    set delta_Dy ((Rs / 60) * Gy)
  ]
  [
    set heading heading - 180  ; individuals do a U-turn if they would end up on an intolerably cold patch

    set delta_Dx (Rs / 60) * dx
    set delta_Dy (Rs / 60) * dy
  ]

 ;; and the random component

  let random_S (V_min * 12) / 60

  set heading (true_north_heading - 90) + random 180

  set delta_Rx random_S * dx
  set delta_Ry random_S * dy
]

ifelse (u > 0) or (u < 0) ; i.e. if there is current data for this patch, calculate its effects on fish displacement. If there is no current data (small number of coastal patches), then assume currents have no effect
[
  let delta_currents_x ((u * 24) / 60)
  let delta_currents_y ((v * 24) / 60)

  set heading true_west_heading
  set delta_Cx delta_currents_y * dx

  set heading true_north_heading
  set delta_Cy delta_currents_y * dy
]
[
  set delta_Cx 0
  set delta_Cy 0
]

; now the new x and new y coordinates are calculated from the sum of the directed, random and current-driven movements

set new_X xcor + delta_Dx + delta_Rx + delta_Cx
set new_Y ycor + delta_Dy + delta_Ry + delta_Cy

ifelse (new_x > max-pxcor) or (new_x < min-pxcor) or (new_y > max-pycor) or (new_y < min-pycor) or ([ocean] of patch new_x new_y != true) or ([SST] of patch new_x new_y <= 7) or ([SST] of patch new_x new_y > 13)
[
  move-to min-one-of patches with [(ocean = true) and (SST >= 7) and (sst <= 13)] [distance myself]
]
[
  setxy new_X new_Y
]

ifelse p_quality_t-1 > Cmax * photo_mult * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) * X_phyto / (h + X_phyto + (c * (sum [total-mass * abundance] of turtles-here)))
[set better_patch false]
[set better_patch true]

ask patch-here
[set feed-range true]

set realised-speed ((Rs / 12) + V_min) / 2

end

to calc-patch-quality
  set p_quality_t-1 Cmax * photo_mult * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) * X_phyto / (h + X_phyto + (c * (sum [total-mass * abundance] of turtles-here)))
end

;;;; the simpler ideal free distribution feeding strategy ;;;;

to ideal-free-distribution
  let x0 xcor
  let y0 ycor

  let ID [who] of self

  let search_radius (((V_min * 12) * 5) + (((V_min * 12) * 5) * random-float 1)) / 60

  ask patches with [sst >= 0] in-radius search_radius
  [
    set feeding_cue (Cmax * photo_mult * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) *
        X_phyto / (h + X_phyto + (c * (sum [total-mass * abundance] of turtles-here))))  ; equation 4, can be modified to equation 2

    ;if pycor >= y0
    ;[set feeding_cue feeding_cue * 1.5] ; upweight values of cues on patches with greater latitude to reflect prevailing northward current
  ]

  ifelse (count patches with [(sst >= 7) and (feeding_cue >= 0) and (photo_mult > 0)] in-radius search_radius) >= 1
  [
  move-to max-one-of patches with [(sst >= 7) and (photo_mult > 0)] in-radius search_radius [feeding_cue]
]
[ ;; if there are not possible patches in the search area to which individuals can move, then they move to the closest possible patch

  move-to min-one-of patches with [(sst >= 7) and (photo_mult > 0)] [distance myself]
]

  set realised-speed V_min + ((V_min)  * random-float 1)     ; we add some random noise to Vmin to get realised speed to account for vertical movement and finer scale deviations
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; The energy budget ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calc-ingestion                                                                                                        ; ingestion of food (either phytoplankton or smaller mackerel) and the associated predation mortality is calculated here
  if (breed != eggs) and (breed != YS-larvae)                                                                            ; eggs and ys larvae are sustained by the yolk sac and do not feed
  [
    set super-mass total-mass * abundance
    set prey-choices turtles-here with [(who != [who] of myself) and (L < [L] of myself / 3.5) and (L <= 0.33)]         ; other mackerel that are > 3.5 x smaller and in the search area of the focal individual, are potential prey
    ifelse any? prey-choices                                                                                             ; if there are any available mackerel prey the predator "switches" to eating fish over plankton
    [
      set prey-available true
      set prey-choice [who] of one-of prey-choices                                                                       ; a random potential prey individual is chosen to be eaten
      set prey-fat-prop ([total-mass - structural-mass] of turtle prey-choice) / ([total-mass] of turtle prey-choice)    ; the proportion of the prey that is fat is used to calculate its energy content
      set func-response (X_phyto / (h + X_phyto + (c * (sum [total-mass * abundance] of turtles-here with [(breed != eggs) and (breed != ys-larvae)])))) ; functional response for fish prey
      if breed != adults
      [set n_encounters n_encounters + 1]
    ]
    [                                                                                                                    ; if there aren't any available fish prey
      set prey-available false
      set prey-choices "none"
      set prey-choice "none"

      set func-response X_phyto / (h + X_phyto + (c * (sum [total-mass * abundance] of turtles-here)))

    ]

    ifelse breed = adults
    [
      ifelse (batches >= n_batch) and (ticks < report-tick-pre-overwinter-mig) ; adults fast from overwintering until the end of spawning, but immature individuals feed constantly. Batches >= n_batch indicates spawning is over
      [
        set individual-IR Cmax * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) * func-response * (total-mass ^ (2 / 3)) ; equation 7
        set ingestion-rate individual-IR * abundance  ; ingestion rates are calculated for super-individuals so that predation mortality can be calculated
      ]
      [
        set ingestion-rate 0
        set individual-IR 0
      ]
    ]
     [
       set individual-IR Cmax * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) * func-response * (total-mass ^ (2 / 3))  ; equation 7
       set ingestion-rate individual-IR * abundance
     ]

     if prey-available = true
     [
       let predation (ingestion-rate * Xprop_mac) / ([total-mass] of turtle prey-choice)  ; the number of "actual" prey individuals eaten
       ask turtle prey-choice
       [
         set abundance abundance - predation  ; eaten "actual" individuals are removed from the super-individual
         set abundance floor abundance
         set num-eaten num-eaten + predation
       ]
     ]
  ]
end

;;;; Assimilation ;;;;

to calc-assimilation                                                                                     ; a proportion of ingested energy, an assimilation efficiency, is assimilated
  ifelse prey-available = true                                                                           ; i.e. if the individual has eaten fish
  [
    let mac-energy ((individual-IR * Xprop_mac * prey-fat-prop * El * Ae) + (individual-IR * Xprop_mac * (1 - prey-fat-prop) * Ef * Ae)) ; if mackerel prey are available, a proportion (Xprop_mac) of energy comes from mackerel, while accounting for the lipid content of the prey
    let phyto-energy individual-IR * (1 - Xprop_mac) * ep * Ae ; The rest of the energy (1-Xprop_mac) comes from baseline food (phytoplankton)
    set energy-assimilated mac-energy + phyto-energy
  ] ; the energy content of prey depends on its fat content

  [set energy-assimilated individual-IR * ep * Ae]
  set energy-tracker energy-assimilated                                                                  ; this is used to track how much energy is assimilated so that we can determine if growth is limited by food
end

;;;; Maintenance (metabolic rate) ;;;;

to calc-maintenance
    ifelse (migrating = false) and (feeding = false)                                       ; individuals operate at SMR when not migrating or actively searching for food, and AMR when migrating
    [
      set MR S0 * (total-mass ^ (0.75)) * Arrhenius                                        ; equation 3
    ]
    [
      ifelse breed = larvae                                                                ; larvae have migrating set to "true", so that they don't "move-locally". But they don't operate at AMR because they are drifiting
      [
        set MR S0 * (total-mass ^ (0.75)) * Arrhenius
      ]
      [
        if breed != YS-larvae                                                              ; we don't calc. MR for ys-larvae as they have a yolk-sac so have enough energy
        [set MR A0 * (total-mass ^ (0.75)) * realised-speed * Arrhenius]                   ; AMR equation applies to fish that are migrating or feeding where movement is highly active. The equation is derived from Dickson et al. (2002) (ODD equation 4)
      ]
    ]

  ifelse energy-assimilated > MR                                                           ; if enough energy is available in "assimilated" store to pay maintenance costs
  [
    set energy-assimilated energy-assimilated - MR                                         ; subtract these costs from the store
  ]
  [                                                                                        ; if not,
    set energy-reserve energy-reserve + energy-assimilated                                 ; add the assimilated energy to the reserves
    set energy-reserve energy-reserve - MR                                                 ; then subtract the costs of maintenance
    set energy-assimilated 0                                                               ; and set energy reserves 0
  ]                                                                                        ; the individual will die (in the procedure "calc-starvation") if this results in empty energy reserves
end

;;;; Reproduction ;;;;

to calc-reproduction                                                                ; the energy costs of reproduction are calculated
    set potential-fecundity a_f * (L ^ (b_f))                                      ; equation 14
    set max-R (potential-fecundity * egg-mass * (Ef + Fs))                          ; equation 15
    set max-batch-R (max-R / n_batch) / (Bint / rm)                                      ; inter batch intervals, equation 15
    set maintenance-energy energy-reserve * 0.1                                     ; at the beginning of spawning 10% of an individuals energy is set aside to cover maintenance costs while spawning (this energy is left in reserve and cannot be used for spawning)
end

;;;; spawning (including movement on spawning grounds and energy allocation to reproduction) ;;;;

to spawn
   if (ticks mod (round(365 / rm)) = 0)
   [set batches 0]                                                                           ; batches variable is used to determine whether or not 5 batches have been spawned and thus if spawning should continue

   ifelse (ticks > end-spawn) or (batches >= n_batch) or (SArea = false)                           ; conditions in which spawning should not occur
   [
     set spawning false
     stop
   ]
   [
     if (batches < n_batch) and (ticks > start-spawn) and (SArea = true)                            ; the conditions where spawning should occur
     [set spawning true]

     if (ticks > start-spawn) and (ticks < end-spawn) and ((ticks - start-spawn) mod (Bint / rm) = 0) ; every Bint days in the spawning period new egg individual are introduced
     [
       set batches batches + 1
       set realised-fecundity (R / (max-batch-R * (Bint / rm))) * potential-fecundity     ; realised fecundtiy is the ratio of energy accumulated to the amount needed to produce the max number of eggs in a batch multiplied by potential fecundity. This is updated every time a batch is spawner
       set R 0                                                                               ; reproduction stores R are reset
       set gonad-mass 0                                                                       ; gonad mass is reset because the eggs are gone
       if who = [who] of max-one-of adults [who]
       [
         ask n-of ((n_cohort / n_batch) * n_multiplier) adults with [gender = 0] ; this is just a way of getting the correct number of egg individuals introduced into the model
         [deposit-eggs]                                                                      ; another procedure is called that sets all egg variables, e.g. embryo duration and number of "actual" eggs
       ]
     ]

     if (batches < n_batch) and (ticks > start-spawn)                                              ; needs to be asked again because when batches becomes five there is a syntax error
     [
       if ((ticks - (run-year * (365 / rm))) + start-spawn) mod 3 = 0            ; i.e. every ((time-step length) * 3) days, spawn some eggs.
       [
         let y ycor
         ifelse any? neighbors with [(pycor = y + 1) and (Sarea = true) and (shelf-edge = true) and (SST >= 10) and (SST <= 14)]
         [move-to one-of neighbors with [(pycor = y + 1) and (Sarea = true) and (shelf-edge = true) and (SST >= 10) and (SST <= 14)]]
         [
           ifelse any? patches with [(pycor = y + 1) and (Sarea = true) and (SST >= 10) and (shelf-edge = true) and (SST <= 14)]
           [move-to min-one-of patches with [(pycor = y + 1) and (Sarea = true) and (shelf-edge = true) and (SST >= 10) and (SST <= 14)] [distance myself]]
           [move-to min-one-of patches with [(Sarea = true) and (SST >= 8) and (shelf-edge = true) and (SST <= 14)] [distance myself]]
         ]
         ifelse (X_phyto >= 0) and (SST >= 0)                                                                ; determines if a patch has NA for plankton, i.e. it is land. If so, individuals divert
         []
         [
           set divert-x [pxcor] of max-one-of patches with [(pycor = [pycor] of myself) and (pxcor < [pxcor] of myself) and (X_phyto >= 0)] [pxcor]
           set divert-y [pycor] of self
           move-to patch divert-x divert-y
         ]
       ]

       ifelse (energy-reserve - maintenance-energy) >= max-batch-R                             ; if there is enough energy after the maintenance energy (see "calc-reproduction") is set aside, the maximum amount is sent to the reproduction store R
       [
         set R R + max-batch-R
         set R_energy R_energy + (max-batch-R * abundance)
         set gonad-mass gonad-mass + (max-batch-R / (Ef + Fs))                                 ; gonad mass is calculated from the energy that went in to producing the eggs
         set energy-reserve energy-reserve - max-batch-R
       ]
       [
         if energy-reserve > maintenance-energy                                                ; the amount of energy allocated to R is reduced if there is insufficient energy
         [
           set R R + (energy-reserve - maintenance-energy) / (round(bint / rm))
           set R_energy R_energy + (((energy-reserve - maintenance-energy) / round(Bint / rm)) * abundance)
           set gonad-mass (energy-reserve / (round(bint / rm))) / (Ef + Fs)
           set energy-reserve energy-reserve - ((energy-reserve - maintenance-energy) / (round(bint / rm)))
         ]
       ]
      ]
     ]
end

;;;; deposition of eggs ;;;;

to deposit-eggs        ; egg super-individuals are "hatched" and their variables are set. Most must e set to 0 otherwise they are inherited from the parent
  set gonad-mass 0
  if ((ticks > (round(3650 / rm))) or (force_spin_up_rec = false)) and (Recruitment = "Emergent")
  [
    hatch-eggs 1
    [
      set color white
      set shape "dot"
      set size 0.5
      set std-mass 0.001
      set L 0.1
      set standard-L (L - 0.1561) / 1.1396
      set energy-reserve 0
      set structural-mass std-mass
      set total-mass std-mass
      set development 1
      set abundance (sum [(realised-fecundity * abundance)] of adults with [gender = 0]) / (n_multiplier * 70)    ; in the actual simulation egg production is the sum of the fecundities of all spawning females
      set egg-production egg-production + abundance
      set MR 0
      set ingestion-rate 0
      set spawning 0
      set batches 0
      set potential-fecundity 0
      set max-r 0
      set R 0
      set growth-rate 0
      set max-growth-rate 0
      set growth-costs 0
      set V_min 0
      set func-response 0
      set energy-assimilated 0
      set prey-choice 0
      set prey-choices 0
      set fk 0
      set migrating 0
      set prey-available false
      set age 0
      set Dage 0
      set gonad-mass 0
      ifelse run-year = 0
      [set exp-cohort true]
      [set exp-cohort false]
      ifelse who mod 2 = 0
      [set gender 0]
      [set gender 1]
      set embryo-duration 5  ; embryo duration is set at 5 days for simplicity
      set gonad-mass 0
      set Mda Me * rm
    ]
  ]
end

;;;; egg development ;;;;

to calc-egg-development
  set development development + (1 * rm)      ; eggs get 1 day closer to hatching each time-step
end

;;;; Maximum growth rate ;;;;

to calc-growth                                                                                                        ; if t < 240 days then grow according to Gompertz, and von bertalanffy if not

  ifelse Dage > 240
  [
    if ((batches >= 5) and (ticks < report-tick-pre-overwinter-mig)) or (breed != adults)                             ; fasting adults, i.e. where batches are < 5 (spawning) or it is fter the overwintering migration, do not feed
    [
      ifelse breed = adults
      [set max-growth-rate ((k / 365) * 2) * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) * (Loo - L)]   ; equation 12
      [set max-growth-rate (k / 365) * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) * (Loo - L)]         ; equation 7 for immature individuals

      ifelse L < Loo
      [grow]
      [stop]
    ]
  ]
  [
    set max-growth-rate k1 * exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) * L * ln (L1 / L)              ; equation 12
    grow
  ]
end

;;;; to grow and pay energy costs ;;;;

to grow
  let possible-L L + max-growth-rate
  set growth-costs ((0.0022 * (possible-L ^ 3.325)) - structural-mass) * (Fs + Ef)          ; the energy costs of adding new structural mass
  ifelse breed = larvae                                                                     ; larvae allocate all surplus energy to growth
  [
    ifelse energy-assimilated >= growth-costs                                               ; if eneough energy is assimilated to cover max growth individuals grow maximally
    [
      set L L + max-growth-rate                                                             ; length is updated
      set standard-L (L - 0.1561) / 1.1396                                                  ; this is a different measure of length needed for swimming speed calc.
      set structural-mass 0.00222 * (L ^ (3.325))                                           ; new structural mass is calculated
      set total-mass structural-mass                                                        ; because larvae do not store lipid, their structural mass is equal to their total mass
      set energy-assimilated energy-assimilated - growth-costs                              ; subtract the costs of growth from the assimilated energy
    ]
    [
      set growth-rate (max-growth-rate / growth-costs) * energy-assimilated                 ; growth rate is adjusted if there is not enough energy
      set L L + growth-rate
      set standard-L (L - 0.1561) / 1.1396
      set structural-mass 0.0022 * (L ^ (3.325))
      set energy-assimilated 0
    ]
  ]
  [
    if breed != YS-larvae
    [
    ifelse (energy-assimilated * 0.5) >= growth-costs                                       ; juveniles and adults allocate energy equally to growth in length and to fat reserves
    [
      set L L + max-growth-rate
      set standard-L (L - 0.1561) / 1.1396
      set structural-mass 0.0022 * (L ^ (3.325))                                            ; the new structural mass is calculated. Their total mass is calculated later, after they have stored lipid
      set energy-assimilated energy-assimilated - growth-costs
      calc-storage                                                                          ; a procedure "calc-storage" is called that converts remaining energy to lipid stores
    ]
    [
      set growth-rate (max-growth-rate / growth-costs) * (energy-assimilated * 0.5)         ; sub-optimal growth rate if energy is insufficient
      set L L + growth-rate
      set structural-mass 0.0022 * (L ^ (3.325))
      set energy-assimilated energy-assimilated * 0.5
      calc-storage
    ]
    ]
  ]
  if breed = YS-larvae                                                                      ; yolk sac larvae are nourished by the yolk so grow maximally
  [
    set growth-rate max-growth-rate
    set L L + max-growth-rate
    set standard-L (L - 0.1561) / 1.1396
    set structural-mass 0.0022 * (L ^ (3.325))
    set total-mass structural-mass
  ]
end


;;;; Storage of lipid ;;;;

to calc-storage                                                                             ; juveniles and adults store any remaining energy as lipid
  set energy-reserve-max ((structural-mass * 0.78) * El)                                   ; individual can store no more lipid than the equivalent of 78% of their structural mass (see TRACE for why)
  if energy-assimilated > 0
  [
    set energy-reserve energy-reserve + (energy-assimilated * (El / (El + Ls)))            ; costs of synthesis are accounted for in storing lipid
  ]
  if energy-reserve > energy-reserve-max
  [
    set energy-reserve energy-reserve-max
  ]
end

;;;; total mass (structural + lipid + gonad) is calculated ;;;;

to calc-total-mass
  ifelse energy-reserve > 0
  [set total-mass structural-mass + (energy-reserve / El) + gonad-mass]; total mass is the sum of structural, fat and gonad mass
  [set total-mass structural-mass + gonad-mass]
  set FK 100 * (total-mass / (L ^ (3)))                                          ; Fulton's condition factor
end

;;;; Individuals age ;;;;

to -age-
  set age age + 1 / round(365 / rm)                                              ; age (yrs)
  set Dage Dage + (1 * rm)                                                  ; age (days)
end

;;;; patches calculate their mackerel density ;;;;

to calc_summer_distribution_stats
  ask patches ;with [farea = true]
  [
    ifelse (any? adults-here) and (ticks - (run-year * (round(365 / rm))) >= round(185 / rm)) and (ticks - (run-year * (round(365 / rm))) <= round(275 / rm))
    [
      set feed-range true
      set feed-area (count patches with [feed-range = true]) * 3600

    set mac-density sum [total-mass * abundance] of adults-here

    set mac-L mean [L] of adults-here

    set profitability exp((- Ea / Boltz) * ((1 / (SST + 273.15)) - (1 / Tref))) * (X_phyto / (h + X_phyto))

    set presence 1
    ]
    [
      set mac-density 0
      set mac-L 0
    ]
  ]

  if (run-year >= 10) and (ticks - (run-year * (round(365 / rm))) >= round(185 / rm)) and (ticks - (run-year * (round(365 / rm))) <= round(243 / rm)) and (run-year >= 10) and ((export_distribution = 0) or (export_distribution = true))
  [
    set dens-index dens-index + 1
    let dens-output gis:patch-dataset mac-density
    let sst-output gis:patch-dataset sst
    let plank-output gis:patch-dataset x_phyto
    let prof-output gis:patch-dataset profitability

    ;gis:store-dataset dens-output (word "F:/SEASIM-MAC_2020/outputs/summer_distribution/" future_annual_F "_" RCP "_" sim_n "_" dens-index ".asc")
    gis:store-dataset sst-output ( word "F:/SEASIM-MAC_2020/outputs/summer_distribution/sst_" RCP "_" dens-index ".asc" )
    gis:store-dataset plank-output ( word "F:/SEASIM-MAC_2020/outputs/summer_distribution/plank_" RCP "_" dens-index ".asc" )
    gis:store-dataset prof-output ( word "F:/SEASIM-MAC_2020/outputs/summer_distribution/prof_" RCP "_" dens-index ".asc" )

    ;gis:store-dataset dens-output ( word "F:/PhD/mac_model_v3/outputs/Scenarios/summer_dist/" future_annual_F RCP "_" dens-index ".asc" )

    ;set L-index L-index + 1
    ;let L-output gis:patch-dataset X_phyto
    ;gis:store-dataset L-output ( word "F:/PhD/mac_model_v3/outputs/Scenarios/summer_dist/plank_" RCP "_" L-index ".asc" )

    ;set p-index p-index + 1
    ;let presence-output gis:patch-dataset presence
    ;gis:store-dataset presence-output ( word "F:/PhD/S.scombrus_movement_model/Outputs/Spatial distribution/presence" p-index ".asc" )
  ]

  ;if (ticks - (run-year * (round(365 / rm))) = (275 / 5)) and (run-year >= 10)
  ;[
  ;  let catch-output gis:patch-dataset catch
  ;  gis:store-dataset catch-output ( word "F:/PhD/mac_model_v3/outputs/Catch/catch/catch_" actual_year ".asc" )
  ;]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; Most interface plots are setup here ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to plot-outputs
  if ticks >= round(60 / rm)
  [
    set-current-plot "Length distribution"
    set-current-plot-pen "Length distribution"
    clear-plot
    let counts 0
    while [counts < 44]
    [
      plotxy counts ((sum [abundance] of (turtles with [floor L = counts])) / 1000)
      set counts (counts + 1)
    ]
  ]

  if ticks >= round(60 / rm)
  [
    set-current-plot "Adult summer age distribution"
    set-current-plot-pen "Age"
    clear-plot
    let counter 0
    while [counter < 12]
    [
      plotxy counter ((sum ([abundance] of turtles with [(floor age = counter) and (ycor >= (157 / (0.5 * rm)))])))
      set counter (counter + 1)
    ]

    set-current-plot "Annual biomass"
    if (ticks mod round(365 / rm) = 0) or (ticks = round(60 / rm))
    [
      set-current-plot-pen "Model-TSB"
      plot sum [total-mass * abundance] of turtles / 1000000
    ]
    if ticks - (run-year * (round(365 / rm))) = round(122 / rm)
    [
      set-current-plot-pen "Model-SSB"
      plot sum [total-mass * abundance] of adults / 1000000
    ]

    set-current-plot "Av. condition factors"
    set-current-plot-pen "Adults"
    plot mean [FK] of adults
    set-current-plot-pen "Juveniles"
    plot mean [FK] of juveniles

    set-current-plot "Recruitment (age 0)"
    ifelse ticks != (run-year * (round(365 / rm)) + (round(361 / rm)))
    [stop]
    [
      set-current-plot-pen "IBM"
      plot num-recruits / 1000
    ]
  ]

end

;;;; Outputs for analysis ;;;;

to calc-maturity                                                                                                                                                           ; the proportion of each age class that is mature is calculated. Thsi is only called on Jan 1 each year,
  if any? turtles with [(age >= 0) and (age < 1)]                                                                                                                                                           ; the proportion of each age class that is mature is calculated. Thsi is only called on Jan 1 each year,
    [set MProp0 precision ((sum [(abundance)] of adults with [(age >= 0) and (age < 1)]) / (sum [(abundance)] of turtles with [(age >= 0) and (age < 1)])) 3]    ; to match the available data.
  if any? turtles with [(age >= 1) and (age < 2)]
    [set MProp1 precision ((sum [(abundance)] of adults with [(age >= 1) and (age < 2)]) / (sum [(abundance)] of turtles with [(age >= 1) and (age < 2)])) 3]
  if any? turtles with [(age >= 2) and (age < 3)]
    [set MProp2 precision ((sum [(abundance)] of adults with [(age >= 2) and (age < 3)]) / (sum [(abundance)] of turtles with [(age >= 2) and (age < 3)])) 3]
  if any? turtles with [(age >= 3) and (age < 4)]
    [set MProp3 precision ((sum [(abundance)] of adults with [(age >= 3) and (age < 4)]) / (sum [(abundance)] of turtles with [(age >= 3) and (age < 4)])) 3]
end

to calc-biomass
  set TSB sum [total-mass * abundance] of turtles / 1000000
  set SSB sum [total-mass * abundance] of adults / 1000000

end

to calc-recruitment
  ask turtles with [age < 1]
  [set num-recruits num-recruits + abundance]
end

to calc-length-distribution
  let i 1
  while [i <= 44]
  [
    ifelse i = 1
    [set ldist 0]
    [set ldist (list ldist (sum [abundance] of turtles with [(A6 = true) and (floor L = i)]))]
    set i i + 1
  ]
end

to calc-Q4-length-distribution
  let i 1
  while [i <= 44]
  [
    ifelse i = 1
    [set Q4ldist 0]
    [set Q4ldist (list Q4ldist (sum [abundance] of turtles with [(A6 = true) and (floor L = i)]))]
    set i i + 1
  ]
end


to calc-Feb-length-distribution
  let i 1
  while [i <= 44]
  [
    ifelse i = 1
    [set febldist 0]
    [set febldist (list febldist (sum [abundance] of turtles with [(floor L = i)]))]
    set i i + 1
  ]
end

to calc-age-distribution
  let j 1
  while [j <= 11]
  [
    ifelse j = 1
    [set adist 0]
    [set adist (list adist (sum [abundance] of turtles with [(FArea = true) and (floor age = j)]))]
    set j j + 1
  ]
end

to calc-feb-age-distribution
  let j 0
  while [j <= 14]
  [
    ifelse j = 0
    [set feb-adist sum [abundance] of turtles with [floor age = 0]]
    [set feb-adist (list feb-adist (sum [abundance] of turtles with [(floor age = j)]))]
    set j j + 1
  ]
end

to calc-weight-at-age
  set W3 mean ([total-mass] of turtles with [(age > 3) and (age < 4)])
  set W4 mean ([total-mass] of turtles with [(age > 4) and (age < 5)])
  set W5 mean ([total-mass] of turtles with [(age > 5) and (age < 6)])
  set W6 mean ([total-mass] of turtles with [(age > 6) and (age < 7)])
  set W7 mean ([total-mass] of turtles with [(age > 7) and (age < 8)])
  set W8 mean ([total-mass] of turtles with [(age > 8) and (age < 9)])
  set W9 mean ([total-mass] of turtles with [(age > 9) and (age < 10)])
  set W10 mean ([total-mass] of turtles with [(age > 10) and (age < 11)])
  if any? turtles with [age >= 11] [set W11 mean ([total-mass] of turtles with [(age > 11) and (age < 12)])]
  if any? turtles with [age >= 12] [set W12 mean ([total-mass] of turtles with [(age > 12) and (age < 13)])]
  if any? turtles with [age >= 13] [set W13 mean ([total-mass] of turtles with [(age > 13) and (age < 14)])]
;;;; and the data for comparison ;;;;


end

to calc-spawning-SSB
  set spawning-SSB sum [abundance * total-mass] of adults
end
@#$#@#$#@
GRAPHICS-WINDOW
209
10
867
561
-1
-1
8.0
1
10
1
1
1
0
0
0
1
0
80
0
64
1
1
1
ticks
30.0

BUTTON
72
10
135
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
73
80
136
113
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
212
34
537
107
Date
current-date
17
1
18

PLOT
886
11
1201
154
Length distribution
Length class (cm)
Number (000s)
0.0
50.0
0.0
10.0
true
false
"" ""
PENS
"Length distribution" 1.0 1 -16777216 true "" ""

PLOT
886
159
1496
303
Daily biomass
Time since initialisation (days)
Biomass (tonnes)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"TSB" 1.0 0 -16777216 true "" "plot sum [total-mass * abundance] of turtles"
"SSB" 1.0 0 -11053225 true "" "plot sum [total-mass * abundance] of adults"

PLOT
1502
12
1804
154
Av. condition factors
Time since initialisation (days)
K
0.0
10.0
0.5
1.5
true
true
"" ""
PENS
"Adults" 1.0 0 -16777216 true "" ""
"Juveniles" 1.0 0 -7500403 true "" ""

MONITOR
1509
529
1593
590
Mean Amat
mean [Amat] of turtles with [Amat > 0]
4
1
15

MONITOR
1643
461
1805
522
No. super-individuals
count turtles
17
1
15

PLOT
1207
309
1497
454
Recruitment (age 0)
Run year
Recruits (thousands)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"IBM" 1.0 1 -16777216 true "" ""
"SAM" 1.0 1 -7500403 true "" ";if ticks = (run-year * (365 / 5) + (300 / 5)) [plot item (run-year + 1) spin-up-rec * 0.8]"

PLOT
888
461
1202
593
Mean phytoplankton density
NIL
g / m2
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"Biomass" 1.0 0 -16777216 true "" "plot mean [X_phyto] of patches with [X_phyto >= 0]"

PLOT
1208
461
1497
593
Mean SST
NIL
°C
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [SST] of patches with [(SST >= 0) and (longitude > -15) and (latitude < 66)]"

PLOT
1502
160
1804
303
Annual biomass
NIL
Biomass (tonnes)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Model-TSB" 1.0 0 -16777216 true "" ""
"Model-SSB" 1.0 0 -7500403 true "" ""
"SAM-SSB" 1.0 0 -2674135 true "" ";if (ticks - (run-year * (365 / rm)) = round(122 / rm)) [plot item run-year sa_ssb * 0.8]"

MONITOR
1507
461
1612
522
Mean Lmat
mean [Lmat] of adults
17
1
15

MONITOR
1613
531
1808
588
Maturity ogive (ages 0-3)
(list MProp0 MProp1 MProp2 MProp3)
17
1
14

PLOT
887
308
1203
454
TEP
Run year
No. eggs
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Egg production" 1.0 1 -16777216 true "" "if ticks - (run-year * (365 / rm)) = (200 / rm) [plot egg-production]"

SLIDER
22
272
194
305
Me
Me
0.045
0.36
0.287
0.01
1
NIL
HORIZONTAL

PLOT
1206
12
1495
154
Adult summer age distribution
Age
Number (000s)
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Age" 1.0 1 -16777216 true "" ""

PLOT
1504
309
1805
455
Post-larval abundance
Time since initialisation
Abundance
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Abundance" 1.0 0 -16777216 true "" "plot sum ([abundance] of turtles with [((breed = adults) or (breed = juveniles)) and (dage > 190)])"

BUTTON
67
185
138
218
Profiler
profile
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
67
114
140
147
NIL
go-ABC
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
68
46
140
79
NIL
spin-up
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
39
353
177
398
Close_A4
Close_A4
0 1 2
0

TEXTBOX
42
399
192
441
0 = uniformly distributed F\n1 = 4a closed for half of year\n2 = 4a always closed
11
0.0
1

SLIDER
22
237
194
270
c
c
0
1e-8
9.7E-12
1e-14
1
NIL
HORIZONTAL

CHOOSER
36
701
174
746
high-res
high-res
true false
1

PLOT
635
574
867
763
Feeding area ( mil. km-2)
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "if (ticks - (run-year * (365 / rm)) = (360 / rm)) [plot feed-area / 1000000]"

CHOOSER
35
548
173
593
feeding_strategy
feeding_strategy
"Random" "IDF" "GAS"
2

PLOT
1510
597
1805
818
Continuous mean weight at age
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"0" 1.0 0 -16777216 true "" "if any? turtles with [age < 1] [plot mean [total-mass] of turtles with [age < 1]]"
"1" 1.0 0 -7500403 true "" "if any? turtles with [(age < 2) and (age > 1)] [plot mean [total-mass] of turtles with [(age > 1) and (age < 2)]]"
"2" 1.0 0 -2674135 true "" "if any? turtles with [(age < 3) and (age > 2)] [plot mean [total-mass] of turtles with [(age > 2) and (age < 3)]]"
"3" 1.0 0 -955883 true "" "if any? turtles with [(age < 4) and (age > 3)] [plot mean [total-mass] of turtles with [(age > 3) and (age < 4)]]"
"4" 1.0 0 -6459832 true "" "if any? turtles with [(age < 5) and (age > 4)] [plot mean [total-mass] of turtles with [(age > 4) and (age < 5)]]"
"5" 1.0 0 -1184463 true "" "if any? turtles with [(age < 6) and (age > 5)] [plot mean [total-mass] of turtles with [(age > 5) and (age < 6)]]"
"6" 1.0 0 -10899396 true "" "if any? turtles with [(age < 7) and (age > 6)] [plot mean [total-mass] of turtles with [(age > 6) and (age < 7)]]"
"7" 1.0 0 -13840069 true "" "if any? turtles with [(age < 8) and (age > 7)] [plot mean [total-mass] of turtles with [(age > 7) and (age < 8)]]"

CHOOSER
36
600
174
645
spawning_strategy
spawning_strategy
"Shelf_edge" "IDF"
0

CHOOSER
36
652
174
697
Recruitment
Recruitment
"Emergent" "Ricker"
0

CHOOSER
12
749
198
794
n_multiplier
n_multiplier
0 1 2 3 4 5
1

PLOT
401
574
631
763
No. cannibalised
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot num-eaten"

MONITOR
210
575
398
620
No. pred-prey encounters
n_encounters
17
1
11

CHOOSER
229
634
367
679
constant_rec?
constant_rec?
true false
1

CHOOSER
229
813
367
858
scale_SSB
scale_SSB
"constant" "decreasing" false
2

SLIDER
23
309
195
342
h
h
0
100
1.26
1.95
1
NIL
HORIZONTAL

SLIDER
211
681
383
714
sim_n
sim_n
0
100
4
1
1
NIL
HORIZONTAL

CHOOSER
35
797
173
842
start_year
start_year
2004 1981 1991 2001 2002 1992 1995 2005 1990 1986
6

CHOOSER
229
717
367
762
enviro_inputs
enviro_inputs
"RS" "ESM"
0

CHOOSER
229
765
367
810
RCP
RCP
85 26
1

CHOOSER
370
766
508
811
future_annual_F
future_annual_F
"unfished" "hist_mean" "F_MSY" "F_lim" 1 2 3
2

PLOT
1091
597
1497
818
F-at-age
NIL
NIL
0.0
10.0
0.0
1.0E-8
true
true
"" ""
PENS
"5" 1.0 0 -16777216 true "" "plot mean [Fda] of turtles with [(age > 5) and (age < 6)]"
"3" 1.0 0 -7500403 true "" "plot mean [Fda] of turtles with [(age > 3) and (age < 4)]"
"7" 1.0 0 -2674135 true "" "plot mean [Fda] of turtles with [(age > 7) and (age < 8)]"
"9" 1.0 0 -955883 true "" "plot mean [Fda] of turtles with [(age > 9) and (age < 10)]"

BUTTON
54
149
152
182
NIL
go_forecast
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
370
812
508
857
export_distribution
export_distribution
true 0 false 1
2

PLOT
889
597
1086
818
Cumulative annual catch
NIL
tonnes
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot catch / 1000000"

CHOOSER
35
493
173
538
redistribute_F
redistribute_F
true 0 false 1
0

CHOOSER
34
444
172
489
match_closure_F
match_closure_F
true 0 false 1
2

CHOOSER
512
767
650
812
force_spin_up_rec
force_spin_up_rec
true false
0

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

The first thing a user should do is decide on the model's resolution. There are two options: high, in which time-steps are one day and the spatial resolution is 30 x 30 km; and low, in which time-steps are 4 days and the spatial resolution in 60 x 60 km. To specify the resolution the user must go "settings" and set the number of patches to 102 x 114 for high resolution, or 51 x 57 for low resolution. The model code then does the rest.

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="All metrics" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="803"/>
    <metric>egg-production</metric>
    <metric>num-recruits</metric>
    <metric>num-matured</metric>
    <metric>sum [total-mass * num-individuals] of turtles</metric>
    <metric>sum [total-mass * num-individuals] of adults</metric>
    <metric>MProp0</metric>
    <metric>MProp1</metric>
    <metric>MProp2</metric>
    <metric>MProp3</metric>
    <metric>ldist</metric>
    <metric>adist</metric>
    <metric>Q4ldist</metric>
    <metric>W3</metric>
    <metric>W4</metric>
    <metric>W5</metric>
    <metric>W6</metric>
    <metric>W7</metric>
    <metric>W8</metric>
    <metric>W9</metric>
    <metric>W10</metric>
    <metric>sum [num-individuals] of adults</metric>
    <metric>spawning-SSB</metric>
    <metric>M-at-36</metric>
  </experiment>
  <experiment name="SST and plank in nursery areas" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="3275"/>
    <metric>mean [plank-biomass] of patches with [(plank-biomass &gt; 0) and (SArea = true)]</metric>
    <metric>mean [SST] of patches with [(sst &gt; 0) and (SArea = true)]</metric>
    <metric>num-recruits</metric>
    <metric>egg-production</metric>
  </experiment>
  <experiment name="growth" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>[span] of turtle 115</metric>
  </experiment>
  <experiment name="Equilibrium?" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>loop-go</go>
    <timeLimit steps="7300"/>
    <metric>sum [num-individuals * total-mass] of turtles</metric>
    <metric>sum [num-individuals] of turtles</metric>
    <metric>sum [num-individuals * total-mass] of adults</metric>
    <enumeratedValueSet variable="Me">
      <value value="0.2"/>
      <value value="0.25"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Rectangles">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Closure_experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="3285"/>
    <metric>sum [num-individuals] of adults</metric>
    <metric>sum [total-mass * num-individuals] of adults</metric>
    <metric>num-recruits</metric>
    <metric>febldist</metric>
    <metric>(sum [num-individuals] of turtles with [a4 = true]) / (sum [num-individuals] of turtles with [a4 = false])</metric>
    <metric>feb-adist</metric>
    <metric>mean [L] of adults</metric>
    <enumeratedValueSet variable="Close_A4">
      <value value="0"/>
      <value value="0"/>
      <value value="0"/>
      <value value="0"/>
      <value value="0"/>
      <value value="1"/>
      <value value="1"/>
      <value value="1"/>
      <value value="1"/>
      <value value="1"/>
      <value value="2"/>
      <value value="2"/>
      <value value="2"/>
      <value value="2"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Me">
      <value value="0.295"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="3280"/>
    <metric>mean [plank-biomass] of patches with [(sarea = true) and (depth &gt;= -300) and (depth &lt;= -200) and (ocean = true)]</metric>
    <metric>mean [plank-biomass] of patches with [(narea = true) and (ocean = true)]</metric>
    <metric>mean [sst] of patches with [(narea = true) and (ocean = true)]</metric>
  </experiment>
  <experiment name="Feeding_range" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="803"/>
    <metric>feed-area</metric>
    <metric>sum [total-mass * num-individuals] of adults</metric>
    <metric>num-recruits</metric>
  </experiment>
  <experiment name="feeding_coords" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="803"/>
    <metric>[latitude] of adults</metric>
    <metric>[longitude] of adults</metric>
    <metric>count adults with [traditional_feeding_area? = true]</metric>
    <metric>count adults</metric>
    <metric>sum [total-mass * num-individuals] of adults</metric>
    <metric>feed-area</metric>
  </experiment>
  <experiment name="Launch_pad_sens" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="803"/>
    <metric>mean [latitude] of adults</metric>
    <metric>mean [longitude] of adults</metric>
    <enumeratedValueSet variable="launch_pad">
      <value value="&quot;topleft&quot;"/>
      <value value="&quot;topright&quot;"/>
      <value value="&quot;bottomleft&quot;"/>
      <value value="&quot;bottomright&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="tracker" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="803"/>
    <metric>[xcor] of adult 1400</metric>
    <metric>[ycor] of adult 1400</metric>
  </experiment>
  <experiment name="adj_SST" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="803"/>
    <metric>sum [num-individuals * total-mass] of adults</metric>
    <metric>num-recruits</metric>
    <enumeratedValueSet variable="SST_adjuster">
      <value value="-1"/>
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="density_dependence" repetitions="1" runMetricsEveryStep="false">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="803"/>
    <metric>ABC-sum-w3</metric>
    <metric>ABC-sum-w4</metric>
    <metric>ABC-sum-w5</metric>
    <metric>ABC-sum-w6</metric>
    <metric>ABC-sum-w7</metric>
    <metric>ABC-sum-w8</metric>
    <metric>ABC-sum-w9</metric>
    <metric>ABC-sum-w10</metric>
    <metric>ABC-sum-w11</metric>
    <metric>ABC-sum-w12</metric>
    <metric>ABC-sum-w13</metric>
    <metric>ABC-spawn-SSB</metric>
  </experiment>
  <experiment name="feed_area" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="803"/>
    <metric>feed-area</metric>
  </experiment>
  <experiment name="recruitment" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="949"/>
    <metric>ann_step</metric>
    <metric>num-recruits</metric>
  </experiment>
  <experiment name="spawning_environment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="803"/>
    <metric>mean [plank-biomass] of patches with [(plank-biomass &gt; 0) and (pycor &lt; 25) and ((narea = true) or (shelf-edge = true))]</metric>
    <metric>mean [sst] of patches with [(sst &gt; 0) and (pycor &lt; 25) and ((narea = true) or (shelf-edge = true))]</metric>
  </experiment>
  <experiment name="forecasts" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="2920"/>
    <metric>sum [total-mass * abundance] of adults</metric>
  </experiment>
  <experiment name="Validation" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="2190"/>
    <metric>actual_year</metric>
    <metric>ann_step</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 2) and (age &lt; 3)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 3) and (age &lt; 4)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 4) and (age &lt; 5)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 5) and (age &lt; 6)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 6) and (age &lt; 7)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 7) and (age &lt; 8)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 8) and (age &lt; 9)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 9) and (age &lt; 10)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 10) and (age &lt; 11)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 11) and (age &lt; 12)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 12) and (age &lt; 13)]</metric>
    <metric>sum [total-mass * abundance] of adults</metric>
  </experiment>
  <experiment name="effects_of_closing_4a" repetitions="5" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="2190"/>
    <metric>actual_year</metric>
    <metric>ann_step</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 2) and (age &lt; 3)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 3) and (age &lt; 4)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 4) and (age &lt; 5)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 5) and (age &lt; 6)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 6) and (age &lt; 7)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 7) and (age &lt; 8)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 8) and (age &lt; 9)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 9) and (age &lt; 10)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 10) and (age &lt; 11)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 11) and (age &lt; 12)]</metric>
    <metric>mean [total-mass] of turtles with [(age &gt; 12) and (age &lt; 13)]</metric>
    <metric>sum [total-mass * abundance] of adults</metric>
    <steppedValueSet variable="Close_A4" first="0" step="1" last="2"/>
    <enumeratedValueSet variable="future_annual_F">
      <value value="&quot;hist_mean&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="1314"/>
    <metric>mean [sst] of patches with [sst &gt; 0]</metric>
    <metric>mean [plank-biomass] of patches with [plank-biomass &gt; 0]</metric>
    <enumeratedValueSet variable="RCP">
      <value value="26"/>
      <value value="85"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="feeding_distribution" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="1020"/>
    <steppedValueSet variable="sim_n" first="1" step="1" last="5"/>
  </experiment>
  <experiment name="summer_distribution" repetitions="5" runMetricsEveryStep="false">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <timeLimit steps="1022"/>
    <steppedValueSet variable="sim_n" first="1" step="1" last="5"/>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
spin-up</setup>
    <go>go</go>
    <metric>mean [SST] of patches with [SST &gt; 0]</metric>
    <metric>mean [x_phyto] of patches with [X_phyto &gt; 0]</metric>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
