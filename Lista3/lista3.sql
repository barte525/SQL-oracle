-- Zad 34
DECLARE
    liczba          INTEGER;
    szukana_funkcja Kocury.funkcja%TYPE := '&funkcja';
BEGIN
    SELECT COUNT(*) INTO liczba FROM Kocury
    WHERE funkcja = szukana_funkcja;
    IF liczba > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Znaleziono kota o funkcji: ' || szukana_funkcja);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono kota o podanej funkcji');
    END IF;
END;        

-- Zad 35
DECLARE
    roczny_przydzial    INTEGER;
    imie_k              Kocury.imie%TYPE;
    miesiac             INTEGER;
    pseudo_k            VARCHAR(15) := '&pseudo';
BEGIN
    SELECT 12 * (NVL(przydzial_myszy,0) + NVL(myszy_extra, 0)), imie, EXTRACT(MONTH FROM w_stadku_od), pseudo
    INTO roczny_przydzial, imie_k, miesiac, pseudo_k FROM Kocury    
    Where pseudo = pseudo_k;
    IF roczny_przydzial > 700 THEN
        DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy >700');
    ELSIF imie_k LIKE '%A%' THEN
        DBMS_OUTPUT.PUT_LINE('imiê zawiera litere A');
    ELSIF miesiac = 5 THEN
        DBMS_OUTPUT.PUT_LINE('maj jest miesiacem przystapienia do stada');
    ELSE
        DBMS_OUTPUT.PUT_LINE('nie odpowiada kryteriom');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('nie znaleziono kota o podanym pseudo');
END;


-- Zad 36
DECLARE
    CURSOR koty IS
        SELECT NVL(przydzial_myszy, 0) przydzial, max_myszy max
        FROM Kocury JOIN Funkcje USING(funkcja)
        ORDER BY przydzial
        FOR UPDATE OF przydzial_myszy;
    kot koty%ROWTYPE;
    suma_przydzialow NUMBER := 0;
    licznik NUMBER := 0;
BEGIN
    SELECT SUM(NVL(przydzial_myszy, 0)) INTO suma_przydzialow FROM Kocury;
    OPEN koty;
    WHILE suma_przydzialow <= 1050
        LOOP
            FETCH koty INTO kot;

            IF koty%NOTFOUND THEN
                CLOSE koty;
                OPEN koty;
                FETCH koty INTO kot;
            END IF;
            
            IF ROUND(kot.przydzial * 1.1) > kot.max AND kot.przydzial <> kot.max THEN
                suma_przydzialow := suma_przydzialow + (kot.max-kot.przydzial);
               licznik :=licznik + 1;
               UPDATE Kocury SET przydzial_myszy = kot.max WHERE CURRENT OF koty;
            ELSIF kot.przydzial < kot.max THEN
                suma_przydzialow := suma_przydzialow + ROUND(kot.przydzial * 0.1);
                licznik :=licznik + 1;
                UPDATE Kocury SET przydzial_myszy = ROUND(kot.przydzial * 1.1) WHERE CURRENT OF koty;
            END IF;
        END LOOP;
    DBMS_OUTPUT.PUT_LINE('Calk. przydzial w stadku ' || suma_przydzialow || '  Zmian - ' || licznik);
    CLOSE koty;
END;

SELECT imie, przydzial_myszy "Myszy po podwyzce" FROM Kocury;

ROLLBACK;


-- Zad 37
DECLARE
    licznik INTEGER := 1;
BEGIN
    DBMS_OUTPUT.PUT_LINE('NR  PSEUDONIM  ZJADA');
    DBMS_OUTPUT.PUT_LINE('--------------------');
    FOR kot IN (SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra, 0) zjada
                FROM Kocury
                ORDER BY zjada DESC)
    LOOP
        IF licznik <= 5 THEN
            DBMS_OUTPUT.PUT_LINE(RPAD(licznik, 4) || RPAD(kot.pseudo, 11) || kot.zjada);
            licznik := licznik + 1;
        ELSE
            EXIT;
        END IF;
    END LOOP;
END;


-- Zad 38
DECLARE
    liczba_przelozonych     NUMBER := :liczba_przelozonych;
    max_przelozonych        NUMBER;
    pseudo_aktualny         KOCURY.PSEUDO%TYPE;
    imie_aktualny           KOCURY.IMIE%TYPE;
    pseudo_nastepny         KOCURY.SZEF%TYPE;

BEGIN
    SELECT MAX(LEVEL) - 1
    INTO max_przelozonych
    FROM Kocury
    CONNECT BY PRIOR szef = pseudo
    START WITH funkcja IN ('KOT', 'MILUSIA');
   
    IF max_przelozonych < liczba_przelozonych THEN
        liczba_przelozonych := max_przelozonych;
    END IF;

    DBMS_OUTPUT.PUT(RPAD('IMIE ', 15));
    FOR i IN 1..liczba_przelozonych
        LOOP
            DBMS_OUTPUT.PUT(RPAD('|  SZEF ' || i, 15));
        END LOOP;
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 15 * (liczba_przelozonych + 1), '-'));

    FOR kot IN (SELECT pseudo, imie FROM Kocury WHERE funkcja IN ('MILUSIA', 'KOT'))
        LOOP
            DBMS_OUTPUT.PUT(RPAD(kot.imie, 15));
            SELECT szef INTO pseudo_nastepny FROM Kocury WHERE pseudo = kot.pseudo;
            FOR i IN 1..liczba_przelozonych
                LOOP
                    IF pseudo_nastepny IS NULL THEN
                        DBMS_OUTPUT.PUT(RPAD('|', 15));
                    ELSE
                        SELECT imie, pseudo, szef
                        INTO imie_aktualny, pseudo_aktualny, pseudo_nastepny
                        FROM Kocury 
                        WHERE pseudo = pseudo_nastepny;
                        DBMS_OUTPUT.PUT(RPAD('|  ' || imie_aktualny, 15));
                    END IF;
                END LOOP;
            DBMS_OUTPUT.NEW_LINE;
        END LOOP;
END;

-- Zad 39
DECLARE
    nr_bandy          Bandy.nr_bandy%TYPE := :nr_bandy;
    nazwa             Bandy.nazwa%TYPE     := :nazwa_bandy;
    teren             Bandy.teren%TYPE     := :teren_polowan;
    istnieje          EXCEPTION;
    ujemny            EXCEPTION;
    wiad              VARCHAR2(30) := '';
    flag              BOOLEAN := FALSE;
BEGIN 
    IF nr_bandy < 0 THEN
        RAISE ujemny;
    END IF;
    FOR banda in (SELECT nr_bandy, nazwa, teren FROM BANDY)
        LOOP
            IF nr_bandy = banda.nr_bandy THEN
                wiad := wiad || TO_CHAR(nr_bandy) || ', ';
                flag := TRUE;
            END IF;
            IF nazwa = banda.nazwa THEN
                wiad := wiad || nazwa || ', ';
                flag := TRUE;
            END IF;
            IF teren = banda.teren THEN
                wiad := wiad || teren || ', ';
                flag := TRUE;
            END IF;
        END LOOP;
    IF flag THEN
        RAISE istnieje;
    END IF;
    INSERT INTO Bandy(nr_bandy, nazwa, teren) VALUES (nr_bandy, nazwa, teren);
EXCEPTION
    WHEN istnieje THEN
        DBMS_OUTPUT.PUT_LINE(SUBSTR(wiad, 0, LENGTH(wiad)-2) || ': juz istnieje');
    WHEN ujemny THEN
        DBMS_OUTPUT.PUT_LINE('Numer');
END;

SELECT * FROM Bandy;

ROLLBACK;


--Zad 40
CREATE OR REPLACE PROCEDURE stworzBande(nr_bandy NUMBER, nazwa VARCHAR2, teren VARCHAR2)
AS
istnieje          EXCEPTION;
ujemny            EXCEPTION;
wiad              VARCHAR2(30) := '';
flag              BOOLEAN := FALSE;
BEGIN 
    IF nr_bandy < 0 THEN
        RAISE ujemny;
    END IF;
    FOR banda in (SELECT nr_bandy, nazwa, teren FROM BANDY)
        LOOP
            IF nr_bandy = banda.nr_bandy THEN
                wiad := wiad || TO_CHAR(nr_bandy) || ', ';
                flag := TRUE;
            END IF;
            IF nazwa = banda.nazwa THEN
                wiad := wiad || nazwa || ', ';
                flag := TRUE;
            END IF;
            IF teren = banda.teren THEN
                wiad := wiad || teren || ', ';
                flag := TRUE;
            END IF;
        END LOOP;
    IF flag THEN
        RAISE istnieje;
    END IF;
    INSERT INTO Bandy(nr_bandy, nazwa, teren) VALUES (nr_bandy, nazwa, teren);
EXCEPTION
    WHEN istnieje THEN
        DBMS_OUTPUT.PUT_LINE(SUBSTR(wiad, 0, LENGTH(wiad)-2) || ': juz istnieje');
    WHEN ujemny THEN
        DBMS_OUTPUT.PUT_LINE('Numer');
END;

BEGIN
    stworzBande(1, 'cos', 'POLE');
END;

-- zad 41
CREATE OR REPLACE TRIGGER trg_wstaw_bande
    BEFORE INSERT ON Bandy
    FOR EACH ROW
DECLARE
    max_nr Bandy.nr_bandy%TYPE;
BEGIN
    SELECT MAX(NR_BANDY)
    INTO max_nr
    FROM BANDY;
    :NEW.NR_BANDY := max_nr + 1;
END;

BEGIN
    stworzBande(10, 'Proba', 'POLE2');
END;

SELECT * FROM BANDY;

ROLLBACK;
DROP TRIGGER trg_wstaw_bande;

-- zad 42a
CREATE OR REPLACE PACKAGE wirus 
AS
    minPodwyzka NUMBER;
    kara BOOLEAN := FALSE;
    doZrobienia BOOLEAN := TRUE;
END;

CREATE OR REPLACE TRIGGER tgr_ustaw_wirusa
BEFORE UPDATE OF przydzial_myszy ON Kocury
BEGIN
    SELECT przydzial_myszy * 0.1 INTO wirus.minPodwyzka
    FROM Kocury
    WHERE pseudo = 'TYGRYS';
END;

CREATE OR REPLACE TRIGGER tgr_uzyj_wirusa
BEFORE UPDATE OF przydzial_myszy ON Kocury
FOR EACH ROW
BEGIN
    IF :NEW.funkcja = 'MILUSIA' THEN
        wirus.doZrobienia := TRUE;
        IF :NEW.przydzial_myszy < :OLD.przydzial_myszy
        THEN
            :NEW.przydzial_myszy := :OLD.przydzial_myszy;
        END IF;
    
        IF :NEW.przydzial_myszy - :OLD.przydzial_myszy < wirus.minPodwyzka
        THEN
            :NEW.przydzial_myszy := :NEW.przydzial_myszy + wirus.minPodwyzka;
            :NEW.myszy_extra := NVL(:NEW.myszy_extra, 0) + 5;
            wirus.kara := TRUE;
        ELSE
            wirus.kara := FALSE;
        END IF;
    END IF;
END;

CREATE OR REPLACE TRIGGER tgr_uzyj_wirusa_tygrys
AFTER UPDATE OF przydzial_myszy ON Kocury
BEGIN
    IF wirus.doZrobienia THEN
        wirus.doZrobienia := FALSE;
        IF wirus.kara THEN
            UPDATE Kocury SET przydzial_myszy = przydzial_myszy - wirus.minPodwyzka
            WHERE pseudo = 'TYGRYS';
        ELSE
            UPDATE Kocury SET myszy_extra = NVL(myszy_extra, 0) + 5
            WHERE pseudo = 'TYGRYS';
        END IF;
    END IF;
END;

SELECT * FROM kocury WHERE funkcja = 'MILUSIA' OR pseudo = 'TYGRYS' ORDER BY przydzial_myszy DESC;

UPDATE Kocury
SET przydzial_myszy = 20
WHERE funkcja = 'MILUSIA';

SELECT * FROM kocury WHERE funkcja = 'MILUSIA' OR pseudo = 'TYGRYS' ORDER BY przydzial_myszy DESC;

ROLLBACK;

UPDATE Kocury
SET przydzial_myszy = 50
WHERE funkcja = 'MILUSIA';

SELECT * FROM kocury WHERE funkcja = 'MILUSIA' OR pseudo = 'TYGRYS' ORDER BY przydzial_myszy DESC;

ROLLBACK;

DROP TRIGGER tgr_ustaw_wirusa;
DROP TRIGGER tgr_uzyj_wirusa;
DROP TRIGGER tgr_uzyj_wirusa_tygrys;

--zad 42b 
CREATE OR REPLACE TRIGGER tgr_update_kocury
FOR UPDATE OF przydzial_myszy ON Kocury
COMPOUND TRIGGER
        minPodwyzka NUMBER;
        kara BOOLEAN := FALSE;
        doZrobienia BOOLEAN := TRUE;
    BEFORE STATEMENT IS
    BEGIN
        SELECT przydzial_myszy * 0.1 INTO wirus.minPodwyzka
        FROM Kocury
        WHERE pseudo = 'TYGRYS';
    END BEFORE STATEMENT;
    
    BEFORE EACH ROW IS
    BEGIN
        IF :NEW.funkcja = 'MILUSIA' THEN
            wirus.doZrobienia := TRUE;
            IF :NEW.przydzial_myszy < :OLD.przydzial_myszy
            THEN
                :NEW.przydzial_myszy := :OLD.przydzial_myszy;
            END IF;
        
            IF :NEW.przydzial_myszy - :OLD.przydzial_myszy < wirus.minPodwyzka
            THEN
                :NEW.przydzial_myszy := :NEW.przydzial_myszy + wirus.minPodwyzka;
                :NEW.myszy_extra := NVL(:NEW.myszy_extra, 0) + 5;
                wirus.kara := TRUE;
            ELSE
                wirus.kara := FALSE;
            END IF;
        END IF;
    END BEFORE EACH ROW;
    
    AFTER STATEMENT IS
    BEGIN
    IF wirus.doZrobienia THEN
        wirus.doZrobienia := FALSE;
        IF wirus.kara THEN
            UPDATE Kocury SET przydzial_myszy = przydzial_myszy - wirus.minPodwyzka
            WHERE pseudo = 'TYGRYS';
        ELSE
            UPDATE Kocury SET myszy_extra = NVL(myszy_extra, 0) + 5
            WHERE pseudo = 'TYGRYS';
        END IF;
    END IF;
    END AFTER STATEMENT;
END;

SELECT * FROM kocury WHERE funkcja = 'MILUSIA' OR pseudo = 'TYGRYS' ORDER BY przydzial_myszy DESC;

UPDATE Kocury
SET przydzial_myszy = 20
WHERE funkcja = 'MILUSIA';

SELECT * FROM kocury WHERE funkcja = 'MILUSIA' OR pseudo = 'TYGRYS' ORDER BY przydzial_myszy DESC;

ROLLBACK;

UPDATE Kocury
SET przydzial_myszy = 50
WHERE funkcja = 'MILUSIA';

SELECT * FROM kocury WHERE funkcja = 'MILUSIA' OR pseudo = 'TYGRYS' ORDER BY przydzial_myszy DESC;

ROLLBACK;

DROP TRIGGER tgr_update_kocury;

SELECT nr_bandy ,nazwa
                     FROM Bandy
                     MINUS
                     SELECT nr_bandy, nazwa
                     FROM Bandy LEFT JOIN Kocury USING(nr_bandy)
                     WHERE pseudo IS NULL
                     ORDER BY nazwa;
                     
--zad 43
DECLARE
     CURSOR funkcje IS  SELECT funkcja FROM Funkcje MINUS
                        SELECT funkcja FROM Funkcje LEFT JOIN Kocury USING(funkcja) WHERE pseudo is NULL 
                        ORDER BY funkcja;
    CURSOR bandy IS SELECT nr_bandy ,nazwa
                     FROM Bandy
                     MINUS
                     SELECT nr_bandy, nazwa
                     FROM Bandy LEFT JOIN Kocury USING(nr_bandy)
                     WHERE pseudo IS NULL
                     ORDER BY nazwa;
    CURSOR plcie IS SELECT plec FROM Kocury GROUP BY plec ORDER BY plec;
    CURSOR iloscSuma IS SELECT COUNT(*) ilosc, SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) suma
                         FROM Kocury JOIN Bandy USING (nr_bandy)
                         GROUP BY nazwa, plec
                         ORDER BY nazwa, plec;
    CURSOR wiersze IS SELECT SUM(NVL(Kocury.PRZYDZIAL_MYSZY, 0) + NVL(Kocury.MYSZY_EXTRA, 0)) suma,
                            funkcja, nazwa, plec
                            FROM Kocury JOIN Bandy USING(nr_bandy)
                            GROUP BY nazwa, plec, funkcja
                            ORDER BY nazwa, plec, funkcja;
    ilosc NUMBER;
    iloscSuma_c    iloscSuma%ROWTYPE;
    wiersze_c   wiersze%ROWTYPE;
BEGIN
    DBMS_OUTPUT.put('NAZWA BANDY       PLEC    ILE ');
    FOR fun IN funkcje
        LOOP
            DBMS_OUTPUT.put(RPAD(fun.funkcja, 10));
        END LOOP;

    DBMS_OUTPUT.put_line('    SUMA');
    DBMS_OUTPUT.put('---------------- ------ ----');
    FOR fun IN funkcje
        LOOP
            DBMS_OUTPUT.put(' ---------');
        END LOOP;
    DBMS_OUTPUT.put_line(' --------');


    OPEN iloscSuma;
    OPEN wiersze;
    FETCH wiersze INTO wiersze_c;
    FOR banda IN bandy
        LOOP
            FOR plec IN plcie
                LOOP
                    DBMS_OUTPUT.put(CASE WHEN plec.plec = 'M' THEN RPAD(' ', 18) ELSE RPAD(banda.nazwa, 18) END);
                    DBMS_OUTPUT.put(CASE WHEN plec.plec = 'M' THEN 'Kocor' ELSE 'Kotka' END);

                    FETCH iloscSuma INTO iloscSuma_c;
                    DBMS_OUTPUT.put(LPAD(iloscSuma_c.ilosc, 4));
                    FOR fun IN funkcje
                        LOOP
                            IF fun.funkcja = wiersze_c.funkcja AND banda.nazwa = wiersze_c.nazwa AND plec.plec = wiersze_c.plec --sprawdzam czy gosc jest tak naprawde, bo wszystko posortowane
                            THEN
                                DBMS_OUTPUT.put(LPAD(NVL(wiersze_c.suma, 0), 10));
                                FETCH wiersze INTO wiersze_c;
                            ELSE
                                DBMS_OUTPUT.put(LPAD(NVL(0, 0), 10));

                            END IF;
                        END LOOP;
                    DBMS_OUTPUT.put(LPAD(NVL(iloscSuma_c.suma, 0), 10));
                    DBMS_OUTPUT.new_line();
                END LOOP;
        END LOOP;
    CLOSE iloscSuma;
    CLOSE wiersze;
    DBMS_OUTPUT.put('Z---------------- ------ ----');
    FOR fun IN funkcje
        LOOP
            DBMS_OUTPUT.put(' ---------');
        END LOOP;
    DBMS_OUTPUT.put_line(' --------');

    DBMS_OUTPUT.put('Zjada razem                ');
    FOR fun IN funkcje
        LOOP
            SELECT SUM(NVL(PRZYDZIAL_MYSZY, 0) + NVL(MYSZY_EXTRA, 0))
            INTO ilosc
            FROM Kocury K
            WHERE K.FUNKCJA = fun.FUNKCJA;
            DBMS_OUTPUT.put(LPAD(NVL(ilosc, 0), 10));
        END LOOP;

    SELECT SUM(NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0)) INTO ilosc FROM Kocury;
    DBMS_OUTPUT.put(LPAD(ilosc, 10));
    DBMS_OUTPUT.new_line();
END;


--Zad 44
CREATE OR REPLACE FUNCTION obliczPodatek(pseudoKota Kocury.pseudo%TYPE) RETURN NUMBER 
IS
    podatek NUMBER;
    liczbaPodwladnych NUMBER;
    liczbaWrogow NUMBER;
    funkcjaKota Kocury.w_stadku_od%TYPE;
BEGIN
    SELECT CEIL(0.05 * (NVL(przydzial_myszy,0) + NVL(myszy_extra, 0))) INTO podatek
    FROM Kocury
    WHERE pseudo = pseudoKota;
    
    SELECT COUNT(pseudo) INTO liczbaPodwladnych
    FROM Kocury
    WHERE szef = pseudoKota;
    
    SELECT COUNT(pseudo) INTO liczbaWrogow
    FROM Wrogowie_Kocurow
    WHERE pseudo = pseudoKota;
    
    SELECT funkcja into funkcjaKota
    FROM Kocury
    WHERE pseudo = pseudoKota;
    
    IF liczbaPodwladnych = 0 THEN 
        podatek := podatek + 2;
    END IF;
    
    IF liczbaWrogow = 0 THEN 
        podatek := podatek + 1;
    END IF;
    
    --Koty o funkcji milusia placa mysze wiecej
    IF funkcjaKota = 'MILUSIA' THEN
        podatek := podatek + 1;
    END IF;
    
    RETURN podatek;
END;

CREATE OR REPLACE PACKAGE procedura_funkcja AS
    FUNCTION obliczPodatek(pseudoKota Kocury.pseudo%TYPE) RETURN NUMBER;
    PROCEDURE stworzBande(nr_bandy NUMBER, nazwa VARCHAR2, teren VARCHAR2);
END procedura_funkcja;

CREATE OR REPLACE PACKAGE BODY procedura_funkcja AS

    FUNCTION obliczPodatek(pseudoKota Kocury.pseudo%TYPE) RETURN NUMBER 
        IS
            podatek NUMBER;
            liczbaPodwladnych NUMBER;
            liczbaWrogow NUMBER;
            funkcjaKota Kocury.funkcja%TYPE;
        BEGIN
            SELECT CEIL(0.05 * (NVL(przydzial_myszy,0) + NVL(myszy_extra, 0))) INTO podatek
            FROM Kocury
            WHERE pseudo = pseudoKota;
            
            SELECT COUNT(pseudo) INTO liczbaPodwladnych
            FROM Kocury
            WHERE szef = pseudoKota;
            
            SELECT COUNT(pseudo) INTO liczbaWrogow
            FROM Wrogowie_Kocurow
            WHERE pseudo = pseudoKota;
            
            SELECT funkcja into funkcjaKota
            FROM Kocury
            WHERE pseudo = pseudoKota;
            
            IF liczbaPodwladnych = 0 THEN 
                podatek := podatek + 2;
            END IF;
            
            IF liczbaWrogow = 0 THEN 
                podatek := podatek + 1;
            END IF;
            
            --Koty o funkcji milusia placa mysze wiecej
            IF funkcjaKota = 'MILUSIA' THEN
                podatek := podatek + 1;
            END IF;
            
            RETURN podatek;
    END obliczPodatek;
    
    PROCEDURE stworzBande(nr_bandy NUMBER, nazwa VARCHAR2, teren VARCHAR2)
        AS
        istnieje          EXCEPTION;
        ujemny            EXCEPTION;
        wiad              VARCHAR2(30) := '';
        flag              BOOLEAN := FALSE;
        BEGIN 
            IF nr_bandy < 0 THEN
                RAISE ujemny;
            END IF;
            FOR banda in (SELECT nr_bandy, nazwa, teren FROM BANDY)
                LOOP
                    IF nr_bandy = banda.nr_bandy THEN
                        wiad := wiad || TO_CHAR(nr_bandy) || ', ';
                        flag := TRUE;
                    END IF;
                    IF nazwa = banda.nazwa THEN
                        wiad := wiad || nazwa || ', ';
                        flag := TRUE;
                    END IF;
                    IF teren = banda.teren THEN
                        wiad := wiad || teren || ', ';
                        flag := TRUE;
                    END IF;
                END LOOP;
            IF flag THEN
                RAISE istnieje;
            END IF;
            INSERT INTO Bandy(nr_bandy, nazwa, teren) VALUES (nr_bandy, nazwa, teren);
        EXCEPTION
            WHEN istnieje THEN
                DBMS_OUTPUT.PUT_LINE(SUBSTR(wiad, 0, LENGTH(wiad)-2) || ': juz istnieje');
            WHEN ujemny THEN
                DBMS_OUTPUT.PUT_LINE('Numer');
    END stworzBande;
END procedura_funkcja;

BEGIN
    FOR kot IN (SELECT pseudo FROM Kocury)
    LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(kot.pseudo, 15) || ' | ' || RPAD(procedura_funkcja.obliczPodatek(kot.pseudo), 10));
    END LOOP;
END;


--zad 45
CREATE TABLE Dodatki_extra (
    pseudo    VARCHAR2(15) NOT NULL,
    dod_extra NUMBER(3) DEFAULT 0
);

CREATE OR REPLACE TRIGGER trg_kontrola
    BEFORE UPDATE OF przydzial_myszy ON Kocury
    FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF LOGIN_USER <> 'TYGRYS' AND :NEW.PRZYDZIAL_MYSZY > :OLD.PRZYDZIAL_MYSZY AND :NEW.FUNKCJA = 'MILUSIA' THEN
        EXECUTE IMMEDIATE
            'DECLARE
                ile NUMBER;
                dodatek NUMBER;
                CURSOR milusie IS SELECT pseudo FROM Kocury WHERE funkcja = ''MILUSIA'';
            BEGIN
                FOR milusia IN milusie
                LOOP
                    SELECT COUNT(*) INTO ile FROM Dodatki_extra WHERE pseudo = milusia.pseudo;
                    IF ile = 0 THEN
                        INSERT INTO Dodatki_extra VALUES(milusia.pseudo, -10);
                    ELSE
                        SELECT dod_extra INTO dodatek FROM Dodatki_extra WHERE pseudo = milusia.pseudo;
                        UPDATE Dodatki_extra SET dod_extra = dodatek - 10 WHERE pseudo = milusia.pseudo;
                    END IF;
                END LOOP;
            END;';
        COMMIT;
    END IF;
END;

UPDATE Kocury
SET przydzial_myszy = 100
WHERE pseudo = 'PUSZYSTA';

ROLLBACK;

SELECT * FROM Dodatki_extra;

UPDATE Kocury
SET przydzial_myszy = 101
WHERE pseudo = 'PUSZYSTA';

ROLLBACK;

SELECT * FROM Dodatki_extra;

SELECT pseudo, przydzial_myszy FROM Kocury WHERE funkcja ='MILUSIA';
DROP TABLE Dodatki_extra;
DROP TRIGGER trg_kontrola;


--zad 46
CREATE TABLE Wykroczenia
(
    kto      VARCHAR2(15) NOT NULL,
    kiedy    DATE         NOT NULL,
    komu     VARCHAR2(15) NOT NULL,
    operacja VARCHAR2(15) NOT NULL
);

CREATE OR REPLACE TRIGGER trg_sprawdz_widelki
    BEFORE INSERT OR UPDATE OF przydzial_myszy
    ON Kocury
    FOR EACH ROW
DECLARE
    min_m     funkcje.min_myszy%TYPE;
    max_m     funkcje.max_myszy%TYPE;
    poza_wid  EXCEPTION;
    data_z    DATE DEFAULT SYSDATE;
    zdarzenie VARCHAR2(20);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    SELECT min_myszy, max_myszy INTO min_m, max_m 
    FROM funkcje WHERE funkcja = :NEW.funkcja;
    IF max_m < :NEW.przydzial_myszy OR :NEW.przydzial_myszy < min_m THEN
        IF INSERTING THEN
            zdarzenie := 'INSERT';
        ELSIF UPDATING THEN
            zdarzenie := 'UPDATE';
        END IF;
        INSERT INTO Wykroczenia VALUES (ORA_LOGIN_USER, data_z, :NEW.pseudo, zdarzenie);
        COMMIT;
        RAISE poza_wid;
    END IF;
END;

UPDATE Kocury
SET przydzial_myszy = 200
WHERE pseudo = 'PLACEK';

SELECT * FROM Kocury WHERE PSEUDO='PLACEK';

SELECT * FROM Wykroczenia;
ROLLBACK;

DROP TABLE Wykroczenia;
DROP TRIGGER trg_sprawdz_widelki;

