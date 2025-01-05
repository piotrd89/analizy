-- 1. Całkowity przyrost wylesiania rok po roku w km^2
SELECT 
    "Ano/Estados" AS rok, 
    SUM("AC" + "AM" + "AP" + "MA" + "MT" + "PA" + "RO" + "RR" + "TO") AS calkowita_powierzchnia_wylesiania
FROM def_area
GROUP BY rok
ORDER BY rok;


-- 2. Wylesianie rok po roku, wg stanów 
SELECT 
    "Ano/Estados" AS rok, 
    "AC" AS acre, 
    "AM" AS amazonas, 
    "AP" AS amapa, 
    "MA" AS maranhao, 
    "MT" AS mato_grosso, 
    "PA" AS para, 
    "RO" AS rondonia, 
    "RR" AS roraima, 
    "TO" AS tocantins
FROM def_area
ORDER BY rok;

-- 2a. Największe wylesianie w danym roku  
SELECT "Ano/Estados" AS rok, 
       GREATEST(SUM("AC"), SUM("AM"), SUM("AP"), SUM("MA"), SUM("MT"), SUM("PA"), SUM("RO"), SUM("RR"), SUM("TO")) AS najwieksza_powierzchnia_wylesiania,
       CASE 
           WHEN SUM("AC") >= GREATEST(SUM("AC"), SUM("AM"), SUM("AP"), SUM("MA"), SUM("MT"), SUM("PA"), SUM("RO"), SUM("RR"), SUM("TO")) THEN 'Acre'
           WHEN SUM("AM") >= GREATEST(SUM("AC"), SUM("AM"), SUM("AP"), SUM("MA"), SUM("MT"), SUM("PA"), SUM("RO"), SUM("RR"), SUM("TO")) THEN 'Amazonas'
           WHEN SUM("AP") >= GREATEST(SUM("AC"), SUM("AM"), SUM("AP"), SUM("MA"), SUM("MT"), SUM("PA"), SUM("RO"), SUM("RR"), SUM("TO")) THEN 'Amapa'
           WHEN SUM("MA") >= GREATEST(SUM("AC"), SUM("AM"), SUM("AP"), SUM("MA"), SUM("MT"), SUM("PA"), SUM("RO"), SUM("RR"), SUM("TO")) THEN 'Maranhao'
           WHEN SUM("MT") >= GREATEST(SUM("AC"), SUM("AM"), SUM("AP"), SUM("MA"), SUM("MT"), SUM("PA"), SUM("RO"), SUM("RR"), SUM("TO")) THEN 'Mato Grosso'
           WHEN SUM("PA") >= GREATEST(SUM("AC"), SUM("AM"), SUM("AP"), SUM("MA"), SUM("MT"), SUM("PA"), SUM("RO"), SUM("RR"), SUM("TO")) THEN 'Para'
           WHEN SUM("RO") >= GREATEST(SUM("AC"), SUM("AM"), SUM("AP"), SUM("MA"), SUM("MT"), SUM("PA"), SUM("RO"), SUM("RR"), SUM("TO")) THEN 'Rondonia'
           WHEN SUM("RR") >= GREATEST(SUM("AC"), SUM("AM"), SUM("AP"), SUM("MA"), SUM("MT"), SUM("PA"), SUM("RO"), SUM("RR"), SUM("TO")) THEN 'Roraima'
           WHEN SUM("TO") >= GREATEST(SUM("AC"), SUM("AM"), SUM("AP"), SUM("MA"), SUM("MT"), SUM("PA"), SUM("RO"), SUM("RR"), SUM("TO")) THEN 'Tocantins'
       END AS stan
FROM def_area
GROUP BY rok
ORDER BY rok;

-- 3. Liczba pożarów wg roku w każdym ze stanów
SELECT 
    year as rok, 
    state as stan, 
    SUM(firespots) AS calkowita_liczba_ognisk_pozarow
FROM inpe_brazilian_amazon_fires
GROUP BY year, stan
ORDER BY year, calkowita_liczba_ognisk_pozarow DESC;

--4a wplyw zjawisk na wylesianie
SELECT enln.phenomenon as zjawisko, 
       enln.severity as dotkliwosc,
       enln.start_year as rok_poczatku_zjawiska, 
       enln.end_year as rok_konca_zjawiska, 
       SUM(def."AC") + SUM(def."AM") + SUM(def."AP") + SUM(def."MA") + SUM(def."MT") + SUM(def."PA") + SUM(def."RO") + SUM(def."RR") + SUM(def."TO") AS calkowita_powierzchnia_wylesiania
FROM el_nino_la_nina enln
JOIN def_area def 
  ON def."Ano/Estados" BETWEEN enln.start_year AND enln.end_year
GROUP BY enln.phenomenon, enln.severity, enln.start_year, enln.end_year
ORDER BY enln.start_year;

-- 4b wpływ zjawisk na wylesianie z wykorzystanie funkcji COALESCE, ponieważ w arkuszu ze zjawiskami, 3 wskazane zjawiska są poza zakresem dla danych z akrusza o wylesianiu, stąd wstawiamy dla nich wartość 0
SELECT enln.phenomenon as zjawisko, 
       enln.severity as dotkliwosc,
       enln.start_year as rok_poczatku_zjawiska, 
       enln.end_year as rok_konca_zjawiska, 
       COALESCE(SUM(def."AC") + SUM(def."AM") + SUM(def."AP") + SUM(def."MA") + SUM(def."MT") + SUM(def."PA") + SUM(def."RO") + SUM(def."RR") + SUM(def."TO"), 0) AS total_deforested_area
FROM el_nino_la_nina enln
LEFT JOIN def_area def 
  ON def."Ano/Estados" BETWEEN enln.start_year AND enln.end_year
GROUP BY enln.phenomenon, enln.severity, enln.start_year, enln.end_year
ORDER BY enln.start_year;


-- 5. Identyfikacja lat z największą liczbą pożarów
SELECT 
    year, 
    SUM(firespots) AS calkowita_liczba_pozarow
FROM inpe_brazilian_amazon_fires
GROUP BY year
ORDER BY calkowita_liczba_pozarow DESC
LIMIT 5;

-- 6. Korelacja pomiędzy liczbą pożarów a wylesianiem

SELECT fires.year as rok, 
       SUM(fires.firespots) AS calkowita_liczba_pozarow, 
       SUM(def_area."AC") + SUM(def_area."AM") + SUM(def_area."AP") + SUM(def_area."MA") + SUM(def_area."MT") + SUM(def_area."PA") + SUM(def_area."RO") + SUM(def_area."RR") + SUM(def_area."TO") AS calkowita_powierzchnia_wylesiania
FROM inpe_brazilian_amazon_fires fires
JOIN def_area ON fires.year = def_area."Ano/Estados"
GROUP BY fires.year
ORDER BY fires.year;

-- 7. Sezonowość pożarów. Sprawdzamy w jakich miesiącach wybuchało najwięcej pożarów
SELECT month as miesiac, SUM(firespots) AS calkowita_liczba_pozarow
FROM inpe_brazilian_amazon_fires
GROUP BY miesiac
ORDER BY calkowita_liczba_pozarow DESC;

-- 8. Wpływ El Nino i La Nina na liczbę pożarów
SELECT enln.start_year as rok_poczatku_zjawiska, enln.end_year as rok_konca_zjawiska, enln.phenomenon as typ_zjawiska, enln.severity as dotkliwosc, SUM(fires.firespots) AS calkowita_liczba_pozarow
FROM el_nino_la_nina enln
JOIN inpe_brazilian_amazon_fires fires ON fires.year BETWEEN enln.start_year AND enln.end_year
GROUP BY enln.start_year, enln.end_year, enln.phenomenon, enln.severity
ORDER BY enln.end_year;

