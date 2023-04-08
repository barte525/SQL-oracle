-- Zad1
SELECT imie_wroga "WROG", opis_incydentu "PRZEWINA"  
FROM Wrogowie_Kocurow 
WHERE EXTRACT(YEAR FROM data_incydentu) = 2009;

-- Zad2
SELECT imie, funkcja, w_stadku_od "Z NAMI OD"
FROM Kocury
WHERE plec = 'D' AND w_stadku_od BETWEEN '2005-09-01' AND '2007-07-31';

-- Zad3
SELECT imie_wroga "WROG", gatunek, stopien_wrogosci "STOPIEN WROGOSCI"
FROM Wrogowie
WHERE lapowka IS NULL
ORDER BY stopien_wrogosci;

-- Zad4 
SELECT imie || ' zwany ' || pseudo || ' (fun. ' || funkcja ||
') lowi myszki w bandzie '  || nr_bandy || ' od '  || w_stadku_od 
"WSZYSTKO O KOCURACH"
FROM Kocury
WHERE plec = 'M'
ORDER BY w_stadku_od DESC, pseudo;

-- Zad5
SELECT pseudo, REGEXP_REPLACE(REGEXP_REPLACE(pseudo,'A','#',1,1),'L','%',1,1)  
"Po wymianie A na # oraz L na %"
FROM Kocury
WHERE pseudo LIKE '%A%' AND pseudo LIKE '%L%';

-- Zad6
SELECT imie , w_stadku_od "W stadku", ROUND(przydzial_myszy * 10/11) "Zjadal",  
ADD_MONTHS(w_stadku_od, 6) "Podwyzka", przydzial_myszy "Zjada" 
FROM Kocury 
WHERE EXTRACT(month from w_stadku_od) BETWEEN 3 AND 9
AND SYSDATE > ADD_MONTHS(w_stadku_od, (12 * 12))
ORDER BY "Zjada" DESC;

-- Zad7
SELECT imie, przydzial_myszy * 3 "MYSZY KWARTALNE", NVL(myszy_extra, 0) * 3 "KWARTALNE DODATKI"
From Kocury
Where przydzial_myszy > 2 * NVL(myszy_extra, 0) AND przydzial_myszy >= 55
ORDER BY "MYSZY KWARTALNE" DESC;

-- Zad8
SELECT imie, DECODE(SIGN(12 * przydzial_myszy + 12 * NVL(myszy_extra, 0)-660),
                    -1, 'Ponizej 660',  
                    0,  'Limit', 
                    1, 12 * przydzial_myszy + 12 * NVL(myszy_extra, 0)) "Zjada rocznie"
FROM Kocury;

-- Zad9 26.10
SELECT pseudo, w_stadku_od "W stadku", CASE WHEN EXTRACT(DAY FROM w_stadku_od) > 15
THEN '2021-11-24'
ELSE '2021-10-27'
END  "WYPLATA"
FROM Kocury;

-- Zad9 28.10
SELECT pseudo, w_stadku_od "W stadku", '2021-11-24' "WYPLATA"
FROM Kocury;

-- Zad10 pseudo
SELECT pseudo || ' - ' ||  
    CASE WHEN COUNT(*) = 1 THEN 
    'Unikalny' 
    ELSE 
    'nieunikalny'
    END "Unikalnosc atr. PSEUDO" 
FROM Kocury 
GROUP BY pseudo;

-- Zad10 szef
SELECT szef || ' - ' ||  
    CASE WHEN COUNT(*) = 1 THEN 
    'Unikalny' 
    ELSE 
    'nieunikalny' 
    END "Unikalnosc atr. SZEF" 
FROM Kocury
GROUP BY szef
HAVING szef IS NOT NULL;


-- Zad11
SELECT pseudo "Pseudonim", COUNT(*) "Liczba wrogow" 
FROM Wrogowie_Kocurow 
GROUP BY pseudo 
HAVING COUNT(*) >= 2;

-- Zad12
SELECT 'Liczba kotow= ' || COUNT(*) || ' lowi jako ' || funkcja || ' i zjada max. ' ||
MAX(przydzial_myszy + NVL(myszy_extra, 0)) || ' myszy miesiecznie' " "
FROM Kocury
WHERE plec = 'D'
GROUP BY funkcja
HAVING MAX(przydzial_myszy + NVL(myszy_extra, 0)) > 50  AND funkcja != 'SZEFUNIO';

-- Zad13
SELECT nr_bandy "Nr bandy", plec "Plec" , MIN(przydzial_myszy) "Minimalny przydzial" 
FROM Kocury 
GROUP BY plec, nr_bandy;

-- Zad14
SELECT level "Poziom", pseudo "Pseudonim", funkcja "Funkcja", nr_bandy "Nr bandy"
FROM Kocury
WHERE plec = 'M'
CONNECT BY PRIOR pseudo = szef
START WITH funkcja = 'BANDZIOR'
ORDER BY nr_bandy, level;

-- Zad15
SELECT LPAD(level-1, 4*(level-1)+1, '===>') || '        ' || imie "Hierarchia",
CASE WHEN(szef IS NULL) THEN 'Sam sobie panem' ELSE szef END "Pseudo szefa",
funkcja "Funkcja"
FROM Kocury
WHERE myszy_extra IS NOT NULL
CONNECT BY PRIOR pseudo = szef
START WITH szef IS NULL;

-- Zad16
SELECT LPAD(pseudo, 4*(level - 1)+LENGTH(pseudo), '    ') "Droga sluzbowa" 
FROM Kocury 
CONNECT BY PRIOR szef = pseudo 
START WITH plec = 'M' AND myszy_extra IS NULL AND SYSDATE > ADD_MONTHS(w_stadku_od, (12 * 12));




