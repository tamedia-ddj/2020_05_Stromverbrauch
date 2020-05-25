library(tidyverse)
library(readxl)
library(lubridate)

## Set working directory
setwd("WORKING_DIRECORY")

## Basics ####

## Datum definieren
date_lockdown = "2020-03-16"
date_end = "2020-04-30"
baseline_start = "2020-02-01"
baseline_end = "2020-02-29"
date_today = "2020-05-19"

## typen für einlesen
types <- rep("numeric", 65)
types[1] <- "date"

## Verbrauch EU ####

## Daten einlesen
prepare_EU <- function(filename, country_EU, return_type="day"){
  
  # read data
  EU_in <- read_csv(str_c("Data_input/", filename), n_max = Inf)
  
  # get types and colnames right
  EU_x_colnames_orig <- colnames(EU_in)
  assign("EU_x_colnames_orig", colnames(EU_in), envir = .GlobalEnv)
  colnames(EU_in) <- c("time_delta", "load_forecast", "load_actual")
  EU_in$load_forecast <- as.numeric(EU_in$load_forecast)
  EU_in$load_actual <- as.numeric(EU_in$load_actual)
  
  # get date right
  EU_dat <- EU_in[!(is.na(EU_in$load_actual)), ]
  EU_dat <- EU_dat %>%  separate(time_delta, into = c("date", "time"), sep = " ", remove = FALSE)
  EU_dat[, "date"] <- lubridate::as_date(EU_dat$date, format = "%d.%m.%Y", tz = "GMT")
  
  ## ACHTUNG: In DE sind Werte pro Viertelstunde!! --> Umrechnen für MWh
  ## ACHTUNG: In UK sind Werte pro halbe Stunde!! --> Umrechnen für MWh
  if(country_EU == "DE"){
    EU_dat <- EU_dat %>% mutate(MWh_actual = load_actual/4)
  } else if(country_EU == "UK"){
    EU_dat <- EU_dat %>% mutate(MWh_actual = load_actual/2)
  } else{
    EU_dat <- EU_dat %>% mutate(MWh_actual = load_actual)
  }
  
  # Nach Tag gruppieren
  EU_agg_day <- EU_dat %>% group_by(date) %>%
                           summarise(MWh_actual_day = sum(MWh_actual)) %>% 
                           filter(date < date_today) %>% 
                           mutate(country = country_EU)
  
  
  # baseline berechnen
  EU_baseline <- EU_agg_day %>% filter((date >= baseline_start) & (date <= baseline_end)) %>% 
                                summarise(baseline_mean = mean(MWh_actual_day))
  
  # baseline hinzufügen
  EU_agg_day[, "baseline"] <- EU_baseline
  EU_agg_day[, "load_vs_baseline"] <- (EU_agg_day$MWh_actual_day / EU_agg_day$baseline) - 1
  
  # floor wochen hinzufügen für Aggregierung
  EU_agg_day[, "Week"] <- lubridate::floor_date(EU_agg_day$date, unit = 'weeks')
  
  # aggregieren auf Wochen
  EU_agg_week <- EU_agg_day %>% group_by(Week) %>% summarise(mean_MWh_day = mean(MWh_actual_day)) %>% 
                                filter(Week < max(Week)) %>% 
                                filter(Week > min(Week)) %>% 
                                mutate(country = country_EU) # make sure only full weeks are considered
  
  EU_agg_week[, "baseline"] <- EU_baseline
  EU_agg_week[, "load_vs_baseline"] <- (EU_agg_week$mean_MWh_day / EU_agg_week$baseline) - 1
  
  if(return_type == "day"){return(EU_agg_day)}
  if(return_type == "week"){return(EU_agg_week)}
}


## Daten einlesen und vorbereiten

# Daten täglich aggregiert
df_agg_eu <- data.frame()
df_agg_eu <- rbind(df_agg_eu, prepare_EU(filename = "DE_19.05.2020.csv", country_EU = "DE"))
df_agg_eu <- rbind(df_agg_eu, prepare_EU(filename = "FR_19.05.2020.csv", country_EU = "FR"))
df_agg_eu <- rbind(df_agg_eu, prepare_EU(filename = "IT_19.05.2020.csv", country_EU = "IT"))
df_agg_eu <- rbind(df_agg_eu, prepare_EU(filename = "CH_25.05.2020.csv", country_EU = "CH"))
df_agg_eu <- rbind(df_agg_eu, prepare_EU(filename = "SE_19.05.2020.csv", country_EU = "SE"))
df_agg_eu <- rbind(df_agg_eu, prepare_EU(filename = "UK_19.05.2020.csv", country_EU = "UK"))

# Daten wöchentlich aggregiert
df_agg_eu_week <- data.frame()
df_agg_eu_week <- rbind(df_agg_eu_week, prepare_EU(filename = "DE_19.05.2020.csv", country_EU = "DE", return_type = "week"))
df_agg_eu_week <- rbind(df_agg_eu_week, prepare_EU(filename = "FR_19.05.2020.csv", country_EU = "FR", return_type = "week"))
df_agg_eu_week <- rbind(df_agg_eu_week, prepare_EU(filename = "IT_19.05.2020.csv", country_EU = "IT", return_type = "week"))
df_agg_eu_week <- rbind(df_agg_eu_week, prepare_EU(filename = "CH_25.05.2020.csv", country_EU = "CH", return_type = "week"))
df_agg_eu_week <- rbind(df_agg_eu_week, prepare_EU(filename = "SE_19.05.2020.csv", country_EU = "SE", return_type = "week"))
df_agg_eu_week <- rbind(df_agg_eu_week, prepare_EU(filename = "UK_19.05.2020.csv", country_EU = "UK", return_type = "week"))


## Plot täglich aggregiert
df_plot <- df_agg_eu %>% filter(1 == 1) %>% 
                         filter(date >= "2020-01-01") %>% 
                         filter(date <= date_today)

# Absolute Werte (MWh)
df_plot %>% ggplot(aes(x = date, y = MWh_actual_day, group = country, colour = country)) +
            geom_line() +
            labs(x = 'Datum',
                 y =  "MWh / Tag") +
            geom_vline(xintercept = as.Date(date_lockdown)) +
            ggtitle("Gesamtverbrauch pro Tag")

# wide machen für Export nach Datawrapper
write.table(pivot_wider(df_plot, id_cols = "date", names_from = "country", values_from = "MWh_actual_day"), "clipboard", sep="\t", row.names = FALSE)

# Relative Werte (% Baseline)
df_plot %>% ggplot(aes(x = date, y = load_vs_baseline, group = country, colour = country)) +
            geom_line() +
            labs(x = 'Datum',
                 y =  "Veränderung gegenüber Baseline") +
            geom_vline(xintercept = as.Date(date_lockdown)) +
            ggtitle("Gesamtverbrauch pro Tag")

# wide machen für Export nach Datawrapper
write.table(pivot_wider(df_plot, id_cols = "date", names_from = "country", values_from = "load_vs_baseline"), "clipboard", sep="\t", row.names = FALSE)


## Plot wöchentlich aggregiert
df_plot <- df_agg_eu_week %>% filter(1 == 1)

# Absolute Werte (MWh)
df_plot %>% ggplot(aes(x = Week, y = mean_MWh_day , group = country, colour = country)) +
            geom_line() +
            labs(x = 'Woche vom',
                 y =  "Mittlere MWh / Tag") +
            geom_vline(xintercept = as.Date(date_lockdown)) +
            ggtitle("Gesamtverbrauch pro Tag")
# wide machen für Export nach Excel
write.table(pivot_wider(df_plot, id_cols = "Week", names_from = "country", values_from = "mean_MWh_day"), "clipboard", sep="\t", row.names = FALSE)


# Relative Werte (% Baseline)
df_plot %>% ggplot(aes(x = Week, y = load_vs_baseline, group = country, colour = country)) +
            geom_line() +
            labs(x = 'Datum',
                 y =  "Veränderung gegenüber Baseline") +
            geom_vline(xintercept = as.Date(date_lockdown)) +
            ggtitle("Gesamtverbrauch pro Tag")
# wide machen für Export nach Excel
write.table(pivot_wider(df_plot, id_cols = "Week", names_from = "country", values_from = "load_vs_baseline"), "clipboard", sep="\t", row.names = FALSE)


## Verbrauch CH aktuell ####

### Daten einlesen und aufbereiten

## aktuelle Daten 2020 einlesen
df_in <- read_xlsx("Data_input/EnergieUebersichtCH-2020_april.xlsx", sheet = "Zeitreihen0h15", col_types = types)[-1, ] #, n_max = 10
colnames(df_in)[1] <- "Zeitstempel"

# Nur notwendige Daten / Kantone Auswählen
colnames(df_in)
df <- df_in[, c(1,2,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59,61,63,65,4)]

colnames(df)[2] <- "Gesamtverbrauch"
colnames(df)[3] <- "Verbrauch_AG"
colnames(df)[4] <- "Verbrauch_FR"
colnames(df)[5] <- "Verbrauch_GL"
colnames(df)[6] <- "Verbrauch_GR"
colnames(df)[7] <- "Verbrauch_LU"
colnames(df)[8] <- "Verbrauch_NE"
colnames(df)[9] <- "Verbrauch_SO"
colnames(df)[10] <- "Verbrauch_SG"
colnames(df)[11] <- "Verbrauch_TI"
colnames(df)[12] <- "Verbrauch_TG"
colnames(df)[13] <- "Verbrauch_VS"
colnames(df)[14] <- "Verbrauch_AI_AR"
colnames(df)[15] <- "Verbrauch_BL_BS"
colnames(df)[16] <- "Verbrauch_BE_JU"
colnames(df)[17] <- "Verbrauch_SZ_ZG"
colnames(df)[18] <- "Verbrauch_OW_NW_UR"
colnames(df)[19] <- "Verbrauch_GE_VD"
colnames(df)[20] <- "Verbrauch_SH_ZH"
colnames(df)[21] <- "Verbrauch_Kantonsübergreifend"
colnames(df)[22] <- "Verbrauch_Ausland"
colnames(df)[23] <- "Gesamtverbrauch_inkl_pump"

# Berechne Pumpenergie (+ Netzverluste + Eigenbedarf Kraftwerke)
df[, "pumpenergie"] <- df$Gesamtverbrauch_inkl_pump - df$Gesamtverbrauch

# Long machen
df_long <- df %>% pivot_longer(-Zeitstempel, names_to = "typ", values_to = "kWh")
df_long$typ <- as.factor(df_long$typ)

# Datum hinzufügen
df_long[, "Datum"] <- lubridate::as_date(df_long$Zeitstempel)
df_long[, "Week"] <- lubridate::week(df_long$Zeitstempel)


## Auf Tagesbasis aggregieren

# aggregate by day
df_agg_day <- df_long %>% group_by(typ, Datum) %>% 
                          summarise(Verbrauch_Tag_Mwh = sum(kWh)/1000) %>% 
                          filter(Datum <= date_end)
# Wochentag hinzufügen
df_agg_day[, "Weekday"] <- lubridate::wday(df_agg_day$Datum, week_start = 1) # Montag = 1

# Baseline und Lockdown Durchschnitte berechnen für Arbeitstage / Wochenende / ganze Woche
df_baseline_all_day <- df_agg_day %>% filter((Datum >= baseline_start) & (Datum <= baseline_end)) %>% 
  group_by(typ) %>%
  summarise(baseline_mean_all = mean(Verbrauch_Tag_Mwh))

df_lockdown_all_day <- df_agg_day %>% filter((Datum >= date_lockdown) & (Datum <= date_end)) %>% 
  group_by(typ) %>%
  summarise(lockdown_mean_all = mean(Verbrauch_Tag_Mwh))  

df_baseline_work_day <- df_agg_day %>% filter((Datum >= baseline_start) & (Datum <= baseline_end)) %>% 
  filter(Weekday %in% c(1,2,3,4,5)) %>% 
  group_by(typ) %>%
  summarise(baseline_mean_work = mean(Verbrauch_Tag_Mwh))

df_baseline_WE_day <- df_agg_day %>% filter((Datum >= baseline_start) & (Datum <= baseline_end)) %>% 
  filter(Weekday %in% c(6,7)) %>% 
  group_by(typ) %>%
  summarise(baseline_mean_WE = mean(Verbrauch_Tag_Mwh))

df_lockdown_work_day <- df_agg_day %>% filter((Datum >= date_lockdown) & (Datum <= date_end)) %>% 
  filter(Weekday %in% c(1,2,3,4,5)) %>% 
  group_by(typ) %>%
  summarise(lockdown_mean_work = mean(Verbrauch_Tag_Mwh))                

df_lockdown_WE_day <- df_agg_day %>% filter((Datum >= date_lockdown) & (Datum <= date_end)) %>% 
  filter(Weekday %in% c(6,7)) %>% 
  group_by(typ) %>%
  summarise(lockdown_mean_WE = mean(Verbrauch_Tag_Mwh))                

# berechnung standardisierter Verbrauch (5Arbeitstage und 2 Wochenendtage pro Woche)
df_baseline_all_day[, "baseline_mean_all_stand"] <- (df_baseline_WE_day$baseline_mean_WE*2 + df_baseline_work_day$baseline_mean_work*5)/7
df_lockdown_all_day[, "lockdown_mean_all_stand"] <- (df_lockdown_WE_day$lockdown_mean_WE*2 + df_lockdown_work_day$lockdown_mean_work*5)/7

# Kantonsübersicht zusammensetzen (Redukton an Arbeitstagen, Wochenenden, ganze Woche)
df_all_day <- left_join(df_baseline_all_day, df_lockdown_all_day, by = "typ") %>% 
              mutate(reduction_all = lockdown_mean_all / baseline_mean_all) %>% 
              mutate(reduction_all_stand = lockdown_mean_all_stand / baseline_mean_all_stand)

df_work_day <- left_join(df_baseline_work_day, df_lockdown_work_day, by = "typ") %>% 
               mutate(reduction_work = lockdown_mean_work / baseline_mean_work)

df_WE_day <- left_join(df_baseline_WE_day, df_lockdown_WE_day, by = "typ") %>% 
             mutate(reduction_WE = lockdown_mean_WE / baseline_mean_WE)

df_day <- df_all_day %>% left_join(df_work_day, by = "typ") %>%
                         left_join(df_WE_day, by ="typ")
# Export für Datawrapper
write.csv(df_day, "Data_output/Uebersicht_Kantone.csv", row.names = FALSE)
write.table(df_day, "clipboard", sep="\t", row.names = FALSE)


## Relative Entwicklung pro Kanton (verglichen mit Baseline)
df_agg_day <- df_agg_day %>% left_join(df_all_day[, c("typ", "baseline_mean_all")], by = "typ") %>% 
                              mutate(verbrauch_relativ_baseline = Verbrauch_Tag_Mwh/baseline_mean_all)

# Auf Wochenbasis Aggregieren:
df_agg_day[, "Week_floor"] <- lubridate::floor_date(df_agg_day$Datum, unit = "week")

df_agg_week <- df_agg_day %>% filter(Week_floor > "2020-01-01") %>% 
                              filter(Week_floor < max(Week_floor)) %>% 
                              group_by(Week_floor, typ) %>% 
                              summarise(verbrauch_week_all = sum(Verbrauch_Tag_Mwh))

df_agg_week_baseline <- df_agg_day %>% filter(Week_floor > "2020-01-01") %>% 
                                       group_by(Week_floor, typ) %>% 
                                       summarise(baseline_week_all = sum(baseline_mean_all))

df_agg_week[, "baseline_week"] <- df_agg_week_baseline[, "baseline_week_all"]
df_agg_week[, "verbrauch_relativ_week"] <- df_agg_week[, "verbrauch_week_all"] / df_agg_week[, "baseline_week"] 


### Plots

## Plots Kantonsverläufe Wochenbasis
df_plot <- df_agg_week %>% filter(1 <= 1) %>% filter(typ != "Gesamtverbrauch" & 
                                                             typ != "pumpenergie" & 
                                                             typ != "Gesamtverbrauch_inkl_pump" &
                                                             typ != "Verbrauch_Ausland" & 
                                                             typ != "Verbrauch_Kantonsübergreifend")

# Plot absolut
df_plot %>% ggplot(aes(x = Week_floor, y = verbrauch_week_all, group = typ, colour = typ)) +
  geom_line() +
  labs(x = 'Woche',
       y =  "MWh") +
  ggtitle("Verbrauch pro Kanton pro Tag")

# export für datawrapper
write.csv(pivot_wider(df_plot, id_cols = "Week_floor", names_from = "typ", values_from = "verbrauch_week_all"), "Data_output/Verlauf_Kantone_absolut.csv", row.names = FALSE)
write.table(pivot_wider(df_plot, id_cols = "Week_floor", names_from = "typ", values_from = "verbrauch_week_all"), "clipboard", sep="\t", row.names = FALSE)

# Plot relativ
df_plot %>% ggplot(aes(x = Week_floor, y = verbrauch_relativ_week, group = typ, colour = typ)) +
  geom_line() +
  labs(x = 'Anteil Baseline',
       y =  "MWh") +
  ggtitle("Verbrauch pro Kanton relativ zur Baseline")
write.csv(pivot_wider(df_plot, id_cols = "Week_floor", names_from = "typ", values_from = "verbrauch_relativ_week"), "Data_output/Verlauf_Kantone_relativ.csv", row.names = FALSE)
write.table(pivot_wider(df_plot, id_cols = "Week_floor", names_from = "typ", values_from = "verbrauch_relativ_week"), "clipboard", sep="\t", row.names = FALSE)


## Plots Gesamtverbrauch Wochenbasis
df_plot <- df_agg_week %>% filter(1 <= 1) %>% filter(typ == "Gesamtverbrauch")

# Plot absolut
df_plot %>% ggplot(aes(x = Week_floor, y = verbrauch_week_all, group = typ, colour = typ)) +
  geom_line() +
  labs(x = 'Woche',
       y =  "MWh") +
  ggtitle("Gesamtverbrauch pro Tag")
write.csv(pivot_wider(df_plot, id_cols = "Week_floor", names_from = "typ", values_from = "verbrauch_week_all"), "Data_output/Verlauf_Gesamtverbrauch_absolut.csv", row.names = FALSE)
write.table(pivot_wider(df_plot, id_cols = "Week_floor", names_from = "typ", values_from = "verbrauch_week_all"), "clipboard", sep="\t", row.names = FALSE)



