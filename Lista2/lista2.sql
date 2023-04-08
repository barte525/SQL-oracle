ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

--Zad 17
SELECT pseudo "POLUJE W POLU", przydzial_myszy "PRZYDZIAL MYSZY", nazwa "BANDA"
FROM Kocury K JOIN Bandy B
ON K.nr_bandy = B.nr_bandy
WHERE (teren='POLE' OR teren='CALOSC') AND NVL(przydzial_myszy, 0) > 50
ORDER BY 2 DESC;

--Zad 18
SELECT K1.imie, K1.w_stadku_od "POLUJE OD"
FROM Kocury K1 JOIN Kocury K2
ON K2.imie = 'JACEK' AND K1.w_stadku_od < K2.w_stadku_od
ORDER BY 2 DESC;

--Zad 19a
SELECT K1.imie , K1.funkcja, K2.imie "Szef 1", K3.imie "Szef 2",
K4.imie "Szef 3"
FROM Kocury K1 LEFT JOIN Kocury K2 ON K1.szef=K2.pseudo LEFT JOIN Kocury K3
ON K2.szef=K3.pseudo LEFT JOIN Kocury K4 ON K3.szef = K4.pseudo
WHERE K1.funkcja IN ('KOT', 'MILUSIA');

--zad 19b
SELECT *
FROM (SELECT imie, level "Poziom", CONNECT_BY_ROOT imie "Imie", CONNECT_BY_ROOT funkcja "Funkcja"
      FROM KOCURY
      CONNECT BY PRIOR szef = pseudo
      START WITH FUNKCJA IN ('KOT', 'MILUSIA'))
       PIVOT (
        MIN(imie)
        FOR "Poziom"
        IN (2 "Szef 1",3 "Szef 2",4 "Szef 3")
        );
       
--zad 19c
SELECT imie, funkcja, LTRIM(REVERSE(LTRIM(SYS_CONNECT_BY_PATH(REVERSE(imie), ' |    '), ' |     ')), imie) "Imiona kolejnych szefow"
FROM Kocury
WHERE funkcja IN ('KOT', 'MILUSIA')
CONNECT BY PRIOR pseudo=szef
START WITH szef IS NULL;
      
--zad 20
SELECT K.imie "Imie kotki", B.nazwa "Nazwa bandy", W.imie_wroga "Imie wroga",
stopien_wrogosci "Ocena wroga", data_incydentu "Data inc."
FROM Kocury K JOIN Bandy B ON K.nr_bandy=B.nr_bandy
              JOIN Wrogowie_Kocurow W ON K.pseudo=W.pseudo
              JOIN Wrogowie WK ON W.imie_wroga=WK.imie_wroga
WHERE K.plec='D' AND data_incydentu>'2007-01-01'
ORDER BY 1;

--zad 21
SELECT nazwa "nazwa bandy" ,Count(DISTINCT WK.pseudo) "Koty z wrogami"
FROM Kocury K JOIN Bandy B ON K.nr_bandy=B.nr_bandy
    JOIN Wrogowie_kocurow WK ON K.pseudo=WK.pseudo
GROUP BY nazwa;

--zad 22
SELECT funkcja "Funkcja", pseudo "Pseudonim kota", Count(pseudo) "Liczba wrogow"
FROM Kocury JOIN Wrogowie_Kocurow USING(pseudo)
GROUP BY pseudo, funkcja
HAVING COUNT(pseudo) > 1;

--zad 23
SELECT imie, 12 * (przydzial_myszy + myszy_extra) "DAWKA ROCZNA", 'powyzej 864' "DAWKA"
FROM KOCURY
WHERE myszy_extra IS NOT NULL AND 12 * (przydzial_myszy + myszy_extra) > 864
UNION
SELECT imie, 12 * (przydzial_myszy + myszy_extra) "DAWKA ROCZNA", '864' "DAWKA"
FROM KOCURY
WHERE myszy_extra IS NOT NULL AND  12 * (przydzial_myszy + myszy_extra) = 864
UNION
SELECT imie, 12 * (przydzial_myszy + myszy_extra) "DAWKA ROCZNA", 'ponizej 864' "DAWKA"
FROM KOCURY
WHERE myszy_extra IS NOT NULL AND 12 * (przydzial_myszy + myszy_extra) < 864
ORDER BY 2 DESC;

--zad 24
--bez 
SELECT nr_bandy "NR BANDY", nazwa ,teren
FROM Bandy LEFT JOIN Kocury USING(nr_bandy)
WHERE pseudo IS NULL;

--z
SELECT nr_bandy "NR BANDY", nazwa "NAZWA", teren "TEREN"
FROM Bandy
MINUS
SELECT nr_bandy "NR BANDY", nazwa ,teren
FROM Bandy B
WHERE (SELECT COUNT(*) FROM Kocury K WHERE K.nr_bandy=B.nr_bandy) > 0;

-- zad 25
SELECT imie, funkcja, przydzial_myszy "PRZYDZIAL MYSZY"
FROM Kocury
WHERE przydzial_myszy >= ALL (SELECT 3*przydzial_myszy
                             FROM Kocury JOIN Bandy USING(nr_bandy)
                             WHERE funkcja = 'MILUSIA' AND teren IN ('SAD', 'CALOSC'));

--zad 26                            
SELECT funkcja, AVG(przydzial_myszy + NVL(myszy_extra, 0)) "Srednio najw. i najm. myszy"
FROM Kocury
GROUP BY funkcja
HAVING (AVG(przydzial_myszy + NVL(myszy_extra, 0)) <= 
ALL (SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0))
     FROM Kocury
     GROUP BY funkcja) OR
AVG(przydzial_myszy + NVL(myszy_extra, 0)) >= 
ALL (SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0))
     FROM Kocury
     GROUP BY funkcja
     HAVING funkcja != 'SZEFUNIO'))
AND funkcja != 'SZEFUNIO';
                             
--zad27a

SELECT pseudo, przydzial_myszy + NVL(myszy_extra, 0) "ZJADA"
FROM Kocury K
WHERE (SELECT COUNT(przydzial_myszy)
       FROM Kocury
       WHERE przydzial_myszy + NVL(myszy_extra, 0) > K.przydzial_myszy + NVL(K.myszy_extra, 0))
       <=&n
ORDER BY 2 DESC;

--zad27b
SELECT pseudo , przydzial_myszy + NVL(myszy_extra, 0) "ZJADA"
FROM Kocury
WHERE przydzial_myszy + NVL(myszy_extra, 0) IN (
    SELECT * 
    FROM (SELECT DISTINCT przydzial_myszy + NVL(myszy_extra, 0)
          FROM Kocury
          ORDER BY 1 DESC
    )
    WHERE ROWNUM <= &n
    )
ORDER BY 2 DESC;

--zad27c
SELECT K1.pseudo, AVG(K1.przydzial_myszy + NVL(K1.myszy_extra, 0)) ZJADA
FROM Kocury K1 JOIN Kocury K2 
    ON K1.przydzial_myszy + NVL(K1.myszy_extra, 0) <= K2.przydzial_myszy + NVL(K2.myszy_extra, 0)
GROUP BY K1.pseudo
HAVING COUNT(DISTINCT K2.przydzial_myszy + NVL(K2.myszy_extra, 0))  <=  &n
ORDER BY 2 DESC;


--zad27d
SELECT pseudo, przydzial_myszy + NVL(myszy_extra, 0) "ZJADA"
FROM (SELECT pseudo,przydzial_myszy, myszy_extra,
                DENSE_RANK()
                OVER (ORDER BY (przydzial_myszy + NVL(myszy_extra, 0)) DESC) pozycja
                FROM Kocury
                )
WHERE pozycja <= &n
ORDER BY 2 DESC;



--zad28
WITH Sr AS
  (SELECT AVG(COUNT(*)) sre FROM Kocury GROUP BY EXTRACT(YEAR FROM w_stadku_od))
SELECT rok "ROK", liczba_wstapien "LICZBA WSTAPIEN"
FROM (SELECT TO_CHAR(EXTRACT(YEAR FROM w_stadku_od)) rok, COUNT(*) liczba_wstapien
      FROM Kocury
      GROUP BY EXTRACT(YEAR FROM w_stadku_od)
      UNION
      SELECT 'SREDNIA' rok, AVG(COUNT(*)) liczba_wstapien
      FROM Kocury
      GROUP BY EXTRACT(YEAR FROM w_stadku_od)) JOIN Sr ON (liczba_wstapien <= sre AND 
      liczba_wstapien >=  ALL(SELECT COUNT(*) sre FROM Kocury GROUP BY EXTRACT(YEAR FROM w_stadku_od) HAVING COUNT(*) < sre))
      OR (liczba_wstapien >= sre AND 
      liczba_wstapien <=  ALL(SELECT COUNT(*) sre FROM Kocury GROUP BY EXTRACT(YEAR FROM w_stadku_od) HAVING COUNT(*) > sre))
ORDER BY 2;

--zad29a
SELECT K1.imie,
       K1.przydzial_myszy + NVL(K1.myszy_extra, 0) "ZJADA",
       K1.nr_bandy,
       AVG(K2.przydzial_myszy + NVL(K2.myszy_extra, 0)) "Srednia bandy"
FROM KOCURY K1
         JOIN KOCURY K2 ON K1.nr_bandy = K2.nr_bandy
WHERE K1.PLEC = 'M'
GROUP BY K1.IMIE, K1.nr_bandy, K1.przydzial_myszy + NVL(K1.myszy_extra, 0)
HAVING K1.przydzial_myszy + NVL(K1.myszy_extra, 0) <= AVG(K2.myszy_extra + NVL(K2.myszy_extra, 0));


--zad29b
SELECT imie, przydzial_myszy + NVL(myszy_extra, 0) "ZJADA", K1.nr_bandy, sre "SREDNIA BANDY"
FROM Kocury K1 JOIN (SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0)) sre, nr_bandy 
                  FROM Kocury GROUP BY nr_bandy) K2 ON przydzial_myszy + NVL(myszy_extra, 0)<sre AND K1.nr_bandy = K2.nr_bandy
WHERE plec = 'M'
ORDER BY 4;

--zad29c
SELECT imie, przydzial_myszy + NVL(myszy_extra, 0) "ZJADA", nr_bandy, 
(SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury K2 WHERE K1.nr_bandy=K2.Nr_bandy GROUP BY nr_bandy) "SREDNIA BANDY"
FROM Kocury K1
WHERE plec = 'M' AND (SELECT AVG(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury K3 WHERE K1.nr_bandy=K3.Nr_bandy GROUP BY nr_bandy) >
przydzial_myszy + NVL(myszy_extra, 0)
ORDER BY 4;

zad30
SELECT imie, w_stadku_od || ' <--- NAJSTARSZY STAZEM W BANDZIE ' || nazwa "WSTAPIL DO STADKA"
FROM Kocury K1
         JOIN (SELECT K2.nr_bandy, nazwa, MIN(K2.w_stadku_od) w_stadku
               FROM Kocury K2 JOIN Bandy ON K2.nr_bandy = Bandy.nr_bandy GROUP BY K2.nr_bandy, nazwa) Starzy
               ON K1.nr_bandy = Starzy.nr_bandy
WHERE K1.w_stadku_od = Starzy.w_stadku
UNION
SELECT imie, w_stadku_od || ' <--- NAJMLODSZY STAZEM W BANDZIE ' || nazwa "WSTAPIL DO STADKA"
FROM Kocury K1
         JOIN (SELECT K2.nr_bandy, nazwa, MAX(K2.w_stadku_od) w_stadku
               FROM Kocury K2 JOIN Bandy ON K2.nr_bandy = Bandy.nr_bandy GROUP BY K2.nr_bandy, nazwa) Mlodzi
               ON K1.nr_bandy = Mlodzi.nr_bandy
WHERE K1.w_stadku_od = Mlodzi.w_stadku
UNION
SELECT IMIE, W_STADKU_OD || ' ' "WSTAPIL DO STADKA"
FROM KOCURY K1
        JOIN (SELECT K2.nr_bandy, nazwa, MIN(K2.w_stadku_od) w_stadku
               FROM Kocury K2 JOIN Bandy ON K2.nr_bandy = Bandy.nr_bandy GROUP BY K2.nr_bandy, nazwa) Starzy
               ON K1.nr_bandy = Starzy.nr_bandy
         JOIN (SELECT K2.nr_bandy, nazwa, MAX(K2.w_stadku_od) w_stadku
               FROM Kocury K2 JOIN Bandy ON K2.nr_bandy = Bandy.nr_bandy GROUP BY K2.nr_bandy, nazwa) Mlodzi
               ON K1.nr_bandy = Mlodzi.nr_bandy
WHERE K1.w_stadku_od != Starzy.w_stadku AND K1.w_stadku_od != Mlodzi.w_stadku
ORDER BY imie;

--zad 31
CREATE OR REPLACE VIEW perspektywa(nazwa, sre_spoz, max_spoz, min_spoz, koty, koty_z_dod)
AS
SELECT nazwa, AVG(NVL(przydzial_myszy, 0)), MAX(NVL(przydzial_myszy, 0)), MIN(NVL(przydzial_myszy, 0)), COUNT(pseudo), COUNT(myszy_extra)
FROM Bandy B
         JOIN Kocury K ON B.nr_bandy = K.nr_bandy
GROUP BY nazwa;

SELECT *
FROM perspektywa;

SELECT pseudo, imie, funkcja, przydzial_myszy "ZJADA", 'OD ' || min_spoz || ' DO ' || max_spoz "GRANICE SPOZYCIA",
       w_stadku_od "LOWI_OD"
FROM Kocury K
         JOIN Bandy B ON K.nr_bandy = B.nr_bandy
         JOIN perspektywa p ON B.nazwa = p.nazwa
WHERE pseudo = &pseudonim;

--Zad.32
CREATE OR REPLACE VIEW podwyzki (pseudo, plec, przydzial_myszy, myszy_extra, nr_bandy)
AS SELECT pseudo, plec, przydzial_myszy, myszy_extra, nr_bandy
    FROM Kocury
    WHERE pseudo IN 
        (SELECT pseudo
        FROM Kocury JOIN Bandy USING(nr_bandy)
        WHERE nazwa = 'CZARNI RYCERZE'
        ORDER BY w_stadku_od
        FETCH NEXT 3 ROWS ONLY) 
        OR pseudo IN (SELECT pseudo
        FROM Kocury JOIN Bandy USING(nr_bandy)
        WHERE nazwa = 'LACIACI MYSLIWI'
        ORDER BY w_stadku_od
        FETCH NEXT 3 ROWS ONLY); 
        
SELECT pseudo "Pseudonim", plec "Plec", przydzial_myszy "Myszy przed podw.", myszy_extra "Extra przed podw." FROM Podwyzki;

UPDATE Podwyzki
SET przydzial_myszy = przydzial_myszy + DECODE(plec, 'D', 0.1 * (SELECT MIN(przydzial_myszy) FROM Kocury), 10),
    myszy_extra = NVL(myszy_extra, 0) + 0.15 * (SELECT AVG(NVL(myszy_extra, 0)) FROM Kocury WHERE nr_bandy = Podwyzki.nr_bandy);
                                        
SELECT pseudo "Pseudonim", plec "Plec", przydzial_myszy "Myszy po podw.", myszy_extra "Extra po podw." FROM Podwyzki;

ROLLBACK;

--zad 33a
SELECT * FROM (
SELECT TO_CHAR(DECODE(plec, 'D', nazwa, ' ')) "NAZWA BANDY",
  TO_CHAR(DECODE(plec, 'D', 'Kotka', 'Kocur')) "PLEC",
  TO_CHAR(COUNT(pseudo)) "ILE",
  TO_CHAR(SUM(DECODE(funkcja, 'SZEFUNIO', przydzial_myszy + NVL(myszy_extra, 0), 0))) "SZEFUNIO",
  TO_CHAR(SUM(DECODE(funkcja, 'BANDZIOR', przydzial_myszy + NVL(myszy_extra, 0), 0))) "BANDZIOR",
  TO_CHAR(SUM(DECODE(funkcja, 'LOWCZY', przydzial_myszy + NVL(myszy_extra, 0), 0))) "LOWCZY",
  TO_CHAR(SUM(DECODE(funkcja, 'LAPACZ', przydzial_myszy + NVL(myszy_extra, 0), 0))) "LAPACZ",
  TO_CHAR(SUM(DECODE(funkcja, 'KOT', przydzial_myszy + NVL(myszy_extra, 0), 0))) "KOT",
  TO_CHAR(SUM(DECODE(funkcja, 'MILUSIA', przydzial_myszy + NVL(myszy_extra, 0), 0))) "MILUSIA",
  TO_CHAR(SUM(DECODE(funkcja, 'DZIELCZY', przydzial_myszy + NVL(myszy_extra, 0), 0))) "DZIELCZY",
  TO_CHAR(SUM(przydzial_myszy + NVL(myszy_extra, 0))) "SUMA"
FROM (Kocury JOIN Bandy ON Kocury.nr_bandy = Bandy.nr_bandy)
GROUP BY nazwa, plec
ORDER BY nazwa)
UNION ALL
SELECT 'Z--------------', '------', '--------', '---------', '---------', '--------', '--------', '--------', '--------', '--------', '--------' 
FROM DUAL
UNION ALL
SELECT 'ZJADA RAZEM', ' ', ' ', 
  TO_CHAR(SUM(DECODE(funkcja, 'SZEFUNIO', przydzial_myszy + NVL(myszy_extra, 0), 0))) "SZEFUNIO",
  TO_CHAR(SUM(DECODE(funkcja, 'BANDZIOR', przydzial_myszy + NVL(myszy_extra, 0), 0))) "BANDZIOR",
  TO_CHAR(SUM(DECODE(funkcja, 'LOWCZY', przydzial_myszy + NVL(myszy_extra, 0), 0))) "LOWCZY",
  TO_CHAR(SUM(DECODE(funkcja, 'LAPACZ', przydzial_myszy + NVL(myszy_extra, 0), 0))) "LAPACZ",
  TO_CHAR(SUM(DECODE(funkcja, 'KOT', przydzial_myszy + NVL(myszy_extra, 0), 0))) "KOT",
  TO_CHAR(SUM(DECODE(funkcja, 'MILUSIA', przydzial_myszy + NVL(myszy_extra, 0), 0))) "MILUSIA",
  TO_CHAR(SUM(DECODE(funkcja, 'DZIELCZY', przydzial_myszy + NVL(myszy_extra, 0), 0))) "DZIELCZY",
  TO_CHAR(SUM(przydzial_myszy + NVL(myszy_extra, 0))) "SUMA"
FROM Kocury;

--zad33b 
--Zad.33
--a: z wykorzystaniem funkcji DECODE i SUM
SELECT * FROM (
SELECT TO_CHAR(DECODE(plec, 'D', nazwa, ' ')) "NAZWA BANDY",
  TO_CHAR(DECODE(plec, 'D', 'Kotka', 'Kocur')) "PLEC",
  TO_CHAR(COUNT(pseudo)) "ILE",
  TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury K WHERE funkcja = 'SZEFUNIO' AND K.nr_bandy= Kocury.nr_bandy AND K.plec = Kocury.plec),0)) "SZEFUNIO",
  TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury K WHERE funkcja = 'BANDZIOR' AND K.nr_bandy= Kocury.nr_bandy AND K.plec = Kocury.plec),0)) "BANDZIOR",
  TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury K WHERE funkcja = 'LOWCZY' AND K.nr_bandy= Kocury.nr_bandy AND K.plec = Kocury.plec),0)) "LOWCZY",
  TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury K WHERE funkcja = 'LAPACZ' AND K.nr_bandy= Kocury.nr_bandy AND K.plec = Kocury.plec),0)) "LAPACZ",
  TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury K WHERE funkcja = 'KOT' AND K.nr_bandy= Kocury.nr_bandy AND K.plec = Kocury.plec),0)) "KOT",
  TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury K WHERE funkcja = 'MILUSIA' AND K.nr_bandy= Kocury.nr_bandy AND K.plec = Kocury.plec),0)) "MILUSIA",
  TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury K WHERE funkcja = 'DZIELCZY' AND K.nr_bandy= Kocury.nr_bandy AND K.plec = Kocury.plec),0)) "DZIELCZY",
  TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury K WHERE K.nr_bandy= Kocury.nr_bandy AND K.plec = Kocury.plec),0)) "SUMA"
FROM (Kocury JOIN Bandy ON Kocury.nr_bandy = Bandy.nr_bandy)
GROUP BY nazwa, plec, Kocury.nr_bandy
ORDER BY nazwa)
UNION ALL
SELECT 'Z--------------', '------', '--------', '---------', '---------', '--------', '--------', '--------', '--------', '--------', '--------' 
FROM DUAL
UNION ALL
SELECT DISTINCT 'ZJADA RAZEM', ' ', ' ', 
    TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury WHERE funkcja = 'SZEFUNIO'), 0)) "SZEFUNIO",
    TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury WHERE funkcja = 'BANDZIOR'), 0)) "BANDZIOR",
    TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury WHERE funkcja = 'LOWCZY'), 0)) "LOWCZY",
    TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury WHERE funkcja = 'LAPACZ'), 0)) "LAPACZ",
    TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury WHERE funkcja = 'KOT'), 0)) "KOT",
    TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury WHERE funkcja = 'MILUSIA'), 0)) "MILUSIA",
    TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury WHERE funkcja = 'DZIELCZY'), 0)) "DZIELCZY",
    TO_CHAR(NVL((SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) FROM Kocury), 0)) "SUMA"
FROM Kocury;

--zad33b 
SELECT * FROM (
    SELECT TO_CHAR(DECODE(plec, 'D', nazwa, ' ')) "NAZWA BANDY",
        TO_CHAR(DECODE(plec, 'D', 'Kotka', 'Kocur')) "PLEC",
        TO_CHAR(ile) "ILE",
        TO_CHAR(NVL(szefunio,  0)) "SZEFUNIO",
        TO_CHAR(NVL(bandzior, 0)) "BANDZIOR",
        TO_CHAR(NVL(lowczy, 0)) "LOWCZY",
        TO_CHAR(NVL(lapacz, 0)) "LAPACZ",
        TO_CHAR(NVL(kot, 0)) "KOT",
        TO_CHAR(NVL(milusia, 0)) "MILUSIA",
        TO_CHAR(NVL(dzielczy, 0)) "DZIELCZY",
        TO_CHAR(NVL(suma, 0)) "SUMA"
    FROM (SELECT nazwa, plec, funkcja, przydzial_myszy + NVL(myszy_extra, 0) przydzial_cal FROM Kocury JOIN Bandy USING(nr_bandy)
    ) PIVOT (
        SUM(przydzial_cal) 
        FOR funkcja 
        IN ('SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz, 'KOT' kot, 'MILUSIA' milusia, 
        'DZIELCZY' dzielczy)
    ) JOIN (SELECT nazwa AS nazwa2, plec AS plec2, COUNT(pseudo) ile, SUM(przydzial_myszy + NVL(myszy_extra, 0)) suma
            FROM Kocury JOIN Bandy USING(nr_bandy)
            GROUP BY nazwa, plec
            ORDER BY nazwa) 
    ON nazwa2 = nazwa AND plec2 = plec
)
UNION ALL
SELECT 'Z--------------', '------', '--------', '---------', '---------', '--------', '--------', '--------', '--------', '--------', '--------' 
FROM DUAL
UNION ALL
SELECT 'ZJADA RAZEM', ' ', ' ', 
    TO_CHAR(NVL(szefunio, 0)) "SZEFUNIO",
    TO_CHAR(NVL(bandzior, 0)) "BANDZIOR",
    TO_CHAR(NVL(lowczy, 0)) "LOWCZY",
    TO_CHAR(NVL(lapacz, 0)) "LAPACZ",
    TO_CHAR(NVL(kot, 0)) "KOT",
    TO_CHAR(NVL(milusia, 0)) "MILUSIA",
    TO_CHAR(NVL(dzielczy, 0)) "DZIELCZY",
    TO_CHAR(NVL(suma, 0)) "SUMA"
FROM (SELECT funkcja, przydzial_myszy + NVL(myszy_extra, 0) przydzial
    FROM Kocury JOIN Bandy USING(nr_bandy))
    PIVOT (
        SUM(przydzial)
        FOR funkcja
        IN ('SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz, 'KOT' kot, 'MILUSIA' milusia, 
        'DZIELCZY' dzielczy)
    ), (SELECT SUM(przydzial_myszy + NVL(myszy_extra, 0)) suma FROM Kocury);

SELECT * FROM kOCURY;




