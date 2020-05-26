# Schweizer Stromverbrauch während des Corona-Lockdowns

**Datenquelle(n)**: [swissgrid.ch](https://www.swissgrid.ch/de/home/operation/grid-data.html), [entsoe-e](https://www.entsoe.eu/) 

**Artikel**: [Wird publiziert im Mai 2020](https://www.tagesanzeiger.ch/)

**Code**: [R Script](elektrizitaet.R)

## Beschreibung

Der Stromverbrauch der Schweiz soll während des Lockdowns soll untersucht werden und im europäischen Vergleich dargestellt werden. 

## Datengrundlage

### Swissgrid

Die **Swissgrid** ist die Betreiberin des schweizerischen Übertragungsnetzes.

Die Swissgrid stellt den Gesamtverbrauch der Schweiz für die letzten Jahre [auf ihrer Webseite](https://www.swissgrid.ch/de/home/operation/grid-data.html) in Form eines Excel files zur Verfügung.

Jeweils ca. am 10 Arbeitstag des Monats werden die Daten für den letzten Monat im file des aktuellen Jahres hinzugefügt.

Verfügbar sind Gesamtverbrauch in der Schweiz (mit und ohne Pumpspeicherwerke), sowie Verbrauch der einzelnen Kantone (nur inklusive Pumpspeicherwerke). Erläuterungen zu den einzelnen Variablen befinden sich direkt im Excel file.

File: [Data_input/EnergieUebersichtCH-2020_april.xlsx](Data_input/EnergieUebersichtCH-2020_april.xlsx)

### Entso-e

Die **ENTSO-E** (European Network of Transmission System Operators for Electricity) ist die ist der europäische Verband in der alle [Übertragungsnetzbetreiber](https://de.wikipedia.org/wiki/Übertragungsnetzbetreiber) (ÜNB) Pflichtmitglieder sind.

Die ENTSO-E stellt Daten zum europaweiten Stromverbrauch auf ihrer [Transparency Webseite](https://transparency.entsoe.eu/) zur Verfügung. Um Daten zu beziehen muss man ein Login erstellen. 

Die Daten liegen in Stunden- oder Viertelstundenauflösung bis zur aktuellen Tageszeit vor. Bei den Daten die im aktuellen Monat liegen, handelt es sich aber um Prognosewerte und nicht um effektiv gemessenen Werte. Sobald effektive Werte vorliegen, werden diese Ausgetauscht. (Im Falle der Schweizer Daten von der Swissgrid ca. am 10. Arbeitstag im neuen Monat). Die Prognosedaten werden für diese Analyse nicht berücksichtigt.

Files: 

| Land          | File                                                         |
| ------------- | ------------------------------------------------------------ |
| `Deutschland` | [Data_input/DE_19.05.2020.csv](Data_input/DE_19.05.2020.csv) |
| `Schweiz`     | [Data_input/CH_25.05.2020.csv](Data_input/CH_25.05.2020.csv) |
| `Italien`     | [Data_input/IT_19.05.2020.csv](Data_input/IT_19.05.2020.csv) |
| `Schweden`    | [Data_input/SE_19.05.2020.csv](Data_input/SE_19.05.2020.csv) |
| `Frankreich`  | [Data_input/FR_19.05.2020.csv](Data_input/FR_19.05.2020.csv) |
| `Grossbritannien`  | [Data_input/UK_19.05.2020.csv](Data_input/UK_19.05.2020.csv) |


## Analyse

Der Code für die Analyse befindet sich im [R Script]([elektrizitaet.R](https://github.com/tamedia-ddj/2020_05_Stromverbrauch/blob/master/elektrizitaet.R)).


## Resultate

| Resultat                              | File                                                         |
| ------------------------------------- | ------------------------------------------------------------ |
| `Übersicht Kantone`                   | [Data_output/Uebersicht_Kantone.csv](Data_output/Uebersicht_Kantone.csv) |
| `Verlauf absoluter Verbrauch Kantone` | [Data_output/Verlauf_Kantone_absolut.csv](Data_output/Verlauf_Kantone_absolut.csv) |
| `Verlauf relativer Verbrauch Kantone` | [Data_output/Verlauf_Kantone_relativ.csv](Data_output/Verlauf_Kantone_relativ.csv) |
| `Verlauf Gesamtverbrauch absolut.csv` | [Data_output/Verlauf_Gesamtverbrauch_absolut.csv](Data_output/Verlauf_Gesamtverbrauch_absolut.csv) |

Alle absoluten Angaben sind in MWh. Die relativen Angaben beziehen sich jeweils auf den Mittelwert Monats Februars 2020.

In der Übersicht werden die Verbräuche für eine bessere Vergelichbarkeit für eine Standard Woche berechnet, die sich aus 5 Arbeitstagen und 2 Wochenendtagen berechnen.

Die Werte werden pro Woche angegeben, wobei sich das Wochen-Datum auf den ersten Tag der jeweiligen Woche bezieht.  Es werden nur vollständige Wochen berücksichtigt, deshalb ist die Woche vom 19.04.2020 der letzte Wert in der Betrachtung.



## Lizenz

*Schweizer Stromverbrauch während des Corona-Lockdowns* is free and open source software released under the permissive MIT License.
