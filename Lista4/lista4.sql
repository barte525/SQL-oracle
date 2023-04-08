--zad 47
CREATE OR REPLACE TYPE KOCUR AS OBJECT (
  imie VARCHAR2(15),
  plec VARCHAR2(1),
  pseudo VARCHAR2(15),
  funkcja VARCHAR2(10),
  szef REF KOCUR,
  w_stadku_od DATE,
  przydzial_myszy NUMBER(3),
  myszy_extra NUMBER(3),
  nr_bandy NUMBER(2),
  MEMBER FUNCTION myszy RETURN NUMBER,
  MEMBER FUNCTION dane RETURN VARCHAR2,
  MAP MEMBER FUNCTION porownaj RETURN VARCHAR2
);

CREATE OR REPLACE TYPE BODY KOCUR
AS
  MEMBER FUNCTION myszy RETURN NUMBER
  IS
  BEGIN
    RETURN NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0);
  END;

  MEMBER FUNCTION dane RETURN VARCHAR2
  IS
    szef_ref KOCUR;
  BEGIN
    SELECT DEREF(szef) INTO szef_ref FROM Dual;
    RETURN 'imie: ' || imie || ' plec: ' || plec || ' pseudo: ' || pseudo || ' funkcja: ' || funkcja || ' szef: ' || szef_ref.pseudo || ' w stadku od: ' || w_stadku_od
    || ' przydzial_myszy: ' || przydzial_myszy     || ' myszy_extra: ' || myszy_extra || ' numer bandy: ' || nr_bandy;
  END;

  MAP MEMBER FUNCTION porownaj RETURN VARCHAR2
  IS
  BEGIN
    RETURN pseudo;
  END;
END;

CREATE TABLE KocuryO OF KOCUR (
  imie CONSTRAINT koco_im_nn NOT NULL,
  plec CONSTRAINT koco_plec_ch CHECK(plec IN ('M','D')),
  pseudo CONSTRAINT koco_fun_pk PRIMARY KEY, 
  funkcja CONSTRAINT koco_f_fk REFERENCES Funkcje(funkcja),
  szef SCOPE IS KocuryO,
  w_stadku_od DEFAULT SYSDATE,
  nr_bandy CONSTRAINT koco_ban_fk REFERENCES Bandy(nr_bandy)
);

CREATE OR REPLACE TYPE PLEBS AS OBJECT (
  plebs_id NUMBER(3),
  kot REF KOCUR,
  MEMBER FUNCTION dane RETURN VARCHAR2,
  MEMBER FUNCTION czy_ma_min_myszy RETURN BOOLEAN
);


CREATE OR REPLACE TYPE BODY PLEBS
AS
  MEMBER FUNCTION dane RETURN VARCHAR2
  IS
    kot_ref KOCUR;
  BEGIN
    SELECT DEREF(kot) INTO kot_ref FROM Dual;
    RETURN kot_ref.dane() || 'nale¿y do: PLEPS';
  END;

  MEMBER FUNCTION czy_ma_min_myszy RETURN BOOLEAN
  IS
    kot_ref KOCUR;
  BEGIN
    SELECT DEREF(kot) INTO kot_ref FROM Dual;
    RETURN kot_ref.myszy() > 30;
  END;
END;


CREATE TABLE PlebsO OF PLEBS (
  plebs_id CONSTRAINT pleb_fun_pk PRIMARY KEY,
  kot SCOPE IS KocuryO CONSTRAINT pleb_k_nn NOT NULL
);


CREATE OR REPLACE TYPE ELITA AS OBJECT (
  elita_id NUMBER(3),
  kot REF KOCUR,
  sluga REF PLEBS,
  MEMBER FUNCTION dane RETURN VARCHAR2,
  MEMBER FUNCTION czy_sluga_mlodszy_stazem RETURN BOOLEAN
);


CREATE OR REPLACE TYPE BODY ELITA
AS
  MEMBER FUNCTION dane RETURN VARCHAR2
  IS
    kot_ref KOCUR;
  BEGIN
    SELECT DEREF(kot) INTO kot_ref FROM Dual;
    RETURN kot_ref.dane() || 'nale¿y do: ELITA';
  END;
  
  MEMBER FUNCTION czy_sluga_mlodszy_stazem RETURN BOOLEAN
  IS
    sluga_ref KOCUR;
    kot_ref KOCUR;
  BEGIN
    SELECT DEREF(DEREF(sluga).kot) INTO sluga_ref FROM Dual;
    SELECT DEREF(kot) INTO kot_ref FROM Dual;
    RETURN sluga_ref.w_stadku_od < kot_ref.w_stadku_od;
  END;
END;


CREATE TABLE ElitaO OF ELITA (
  elita_id CONSTRAINT el_fun_pk PRIMARY KEY,
  kot SCOPE IS KocuryO CONSTRAINT el_k_nn NOT NULL,
  sluga SCOPE IS PlebsO
);


CREATE OR REPLACE TYPE INCYDENT AS OBJECT (
  incydent_id NUMBER(3),
  kot REF KOCUR,
  imie_wroga VARCHAR2(15),
  data_incydentu DATE,
  opis_incydentu VARCHAR2(50),
  MEMBER FUNCTION czy_posiada_opis RETURN BOOLEAN
);


CREATE OR REPLACE TYPE BODY INCYDENT
AS
  MEMBER FUNCTION czy_posiada_opis RETURN BOOLEAN
  IS
  BEGIN
    RETURN opis_incydentu IS NOT NULL;
  END;
END;


CREATE TABLE IncydentyO OF INCYDENT (
  incydent_id CONSTRAINT inc_fun_pk PRIMARY KEY,
  kot SCOPE IS KocuryO CONSTRAINT inc_k_nn NOT NULL,
  imie_wroga CONSTRAINT inc_iw_fk REFERENCES Wrogowie(imie_wroga),
  data_incydentu CONSTRAINT inc_d_nn NOT NULL
);

CREATE OR REPLACE TYPE WIERSZK AS OBJECT (
  wiersz_id NUMBER(3),
  kot REF ELITA,
  data_wprowadzenia DATE,
  data_usuniecia DATE,
  MEMBER FUNCTION czy_usunieta RETURN BOOLEAN
);


CREATE OR REPLACE TYPE BODY WIERSZK
AS
  MEMBER FUNCTION czy_usunieta RETURN BOOLEAN
  IS
  BEGIN
    RETURN data_usuniecia IS NOT NULL;
  END;
END;


CREATE TABLE KontaO OF WIERSZK (
  wiersz_id CONSTRAINT ko_fun_pk PRIMARY KEY,
  kot SCOPE IS ElitaO CONSTRAINT ko_w_nn NOT NULL,
  data_wprowadzenia CONSTRAINT ko_dw_nn NOT NULL,
  CONSTRAINT ko_du_gt_dw CHECK(data_wprowadzenia <= data_usuniecia)
);


--Ograniczenie mozeliwosci wlozenia kota do elity i do plebsu jednoczesnie
CREATE OR REPLACE TRIGGER elita
BEFORE INSERT OR UPDATE ON ElitaO
FOR EACH ROW
DECLARE
  plebs NUMBER;
  niezgodnosc EXCEPTION;
BEGIN
  SELECT COUNT(plebs_id) INTO plebs
  FROM PlebsO P
  WHERE P.kot = :NEW.kot;
  IF plebs > 0 THEN
    RAISE niezgodnosc;
  END IF;
EXCEPTION
    WHEN niezgodnosc THEN
        DBMS_OUTPUT.PUT_LINE('Kot nie moze nalezec jednoczesnie do elity i do plebsu');
END;

CREATE OR REPLACE TRIGGER plebs
BEFORE INSERT OR UPDATE ON PlebsO
FOR EACH ROW
DECLARE
  elita NUMBER;
  niezgodnosc EXCEPTION;
BEGIN
  SELECT COUNT(elita_id) INTO elita
  FROM ElitaO O
  WHERE O.kot = :NEW.kot;
  IF elita > 0 THEN
    RAISE niezgodnosc;
  END IF;
EXCEPTION
    WHEN niezgodnosc THEN
        DBMS_OUTPUT.PUT_LINE('Kot nie moze nalezec jednoczesnie do elity i do plebsu');
END;

DROP TRIGGER plebs;
DROP TRIGGER elita;
DROP TABLE KontaO;
DROP TYPE WIERSZK;
DROP TABLE IncydentyO;
DROP TYPE Incydent;
DROP TABLE ELITAO;
DROP TYPE ELITA;
DROP TABLE PLEBSO;
DROP TYPE PLEBS;
DROP TABLE KOCURYO;
DROP TYPE KOCUR;

INSERT INTO KocuryO VALUES (KOCUR('MRUCZEK','M','TYGRYS','SZEFUNIO',NULL,'2002-01-01',103,33,1));
INSERT INTO KocuryO VALUES (KOCUR('BOLEK','M','LYSY','BANDZIOR',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'TYGRYS'),'2006-08-15',72,21,2));
INSERT INTO KocuryO VALUES (KOCUR('KOREK','M','ZOMBI','BANDZIOR',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'TYGRYS'),'2004-03-16',75,13,3));
INSERT INTO KocuryO VALUES (KOCUR('PUNIA','D','KURKA','LOWCZY',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'ZOMBI'),'2008-01-01',61,NULL,3));
INSERT INTO KocuryO VALUES (KOCUR('PUCEK','M','RAFA','LOWCZY',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'TYGRYS'),'2006-10-15',65,NULL,4));

INSERT ALL
  INTO KocuryO VALUES (KOCUR('MICKA','D','LOLA','MILUSIA',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'TYGRYS'),'2009-10-14',25,47,1))
  INTO KocuryO VALUES (KOCUR('CHYTRY','M','BOLEK','DZIELCZY',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'TYGRYS'),'2002-05-05',50,NULL,1))
  INTO KocuryO VALUES (KOCUR('RUDA','D','MALA','MILUSIA',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'TYGRYS'),'2006-09-17',22,42,1))
  INTO KocuryO VALUES (KOCUR('JACEK','M','PLACEK','LOWCZY',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'LYSY'),'2008-12-01',67,NULL,2))
  INTO KocuryO VALUES (KOCUR('BARI','M','RURA','LAPACZ',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'LYSY'),'2009-09-01',56,NULL,2))
  INTO KocuryO VALUES (KOCUR('ZUZIA','D','SZYBKA','LOWCZY',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'LYSY'),'2006-07-21',65,NULL,2))
  INTO KocuryO VALUES (KOCUR('BELA','D','LASKA','MILUSIA',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'LYSY'),'2008-02-01',24,28,2))
  INTO KocuryO VALUES (KOCUR('SONIA','D','PUSZYSTA','MILUSIA',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'ZOMBI'),'2010-11-18',20,35,3))
  INTO KocuryO VALUES (KOCUR('LUCEK','M','ZERO','KOT',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'KURKA'),'2010-03-01',43,NULL,3))
  INTO KocuryO VALUES (KOCUR('LATKA','D','UCHO','KOT',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'RAFA'),'2011-01-01',40,NULL,4))
  INTO KocuryO VALUES (KOCUR('DUDEK','M','MALY','KOT',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'RAFA'),'2011-05-15',40,NULL,4))
  INTO KocuryO VALUES (KOCUR('KSAWERY','M','MAN','LAPACZ',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'RAFA'),'2008-07-12',51,NULL,4))
  INTO KocuryO VALUES (KOCUR('MELA','D','DAMA','LAPACZ',(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'RAFA'),'2008-11-01',51,NULL,4))
SELECT * FROM dual;


INSERT ALL
  INTO PlebsO VALUES (Plebs(1,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'ZOMBI')))
  INTO PlebsO VALUES (Plebs(2,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'LYSY')))
  INTO PlebsO VALUES (Plebs(3,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'SZYBKA')))
  INTO PlebsO VALUES (Plebs(4,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'MALA')))
  INTO PlebsO VALUES (Plebs(5,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'RAFA')))
  INTO PlebsO VALUES (Plebs(6,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'KURKA')))
SELECT * FROM Dual;

INSERT ALL
  INTO ElitaO VALUES (ELITA(1,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'TYGRYS'),(SELECT REF(P) FROM PlebsO P WHERE P.kot.pseudo = 'ZOMBI')))
  INTO ElitaO VALUES (ELITA(2,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'BOLEK'),NULL))
  INTO ElitaO VALUES (ELITA(3,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'LOLA'),(SELECT REF(P) FROM PlebsO P WHERE P.kot.pseudo = 'LYSY')))
  INTO ElitaO VALUES (ELITA(4,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'MALA'),(SELECT REF(P) FROM PlebsO P WHERE P.kot.pseudo = 'SZYBKA')))
  INTO ElitaO VALUES (ELITA(5,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'LASKA'),(SELECT REF(P) FROM PlebsO P WHERE P.kot.pseudo = 'MALA')))
  INTO ElitaO VALUES (ELITA(6,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'PUSZYSTA'),(SELECT REF(P) FROM PlebsO P WHERE P.kot.pseudo = 'RAFA')))
SELECT * FROM Dual;

INSERT ALL
  INTO IncydentyO VALUES (INCYDENT(1,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'TYGRYS'),'KAZIO','2004-10-13','USILOWAL NABIC NA WIDLY'))
  INTO IncydentyO VALUES (INCYDENT(2,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'ZOMBI'),'SWAWOLNY DYZIO','2005-03-07','WYBIL OKO Z PROCY'))
  INTO IncydentyO VALUES (INCYDENT(3,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'BOLEK'),'KAZIO','2005-03-29','POSZCZUL BURKIEM'))
  INTO IncydentyO VALUES (INCYDENT(4,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'SZYBKA'),'GLUPIA ZOSKA','2006-09-12','UZYLA KOTA JAKO SCIERKI'))
  INTO IncydentyO VALUES (INCYDENT(5,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'MALA'),'CHYTRUSEK','2007-03-07','ZALECAL SIE'))
  INTO IncydentyO VALUES (INCYDENT(6,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'TYGRYS'),'DZIKI BILL','2007-06-12','USILOWAL POZBAWIC ZYCIA'))
  INTO IncydentyO VALUES (INCYDENT(7,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'BOLEK'),'DZIKI BILL','2007-11-10','ODGRYZL UCHO'))
  INTO IncydentyO VALUES (INCYDENT(8,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'LASKA'),'DZIKI BILL','2008-12-12','POGRYZL ZE LEDWO SIE WYLIZALA'))
  INTO IncydentyO VALUES (INCYDENT(9,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'LASKA'),'KAZIO','2009-01-07','ZLAPAL ZA OGON I ZROBIL WIATRAK'))
  INTO IncydentyO VALUES (INCYDENT(10,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'DAMA'),'KAZIO','2009-02-07','CHCIAL OBEDRZEC ZE SKORY'))
  INTO IncydentyO VALUES (INCYDENT(11,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'MAN'),'REKSIO','2009-04-14','WYJATKOWO NIEGRZECZNIE OBSZCZEKAL'))
  INTO IncydentyO VALUES (INCYDENT(12,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'LYSY'),'BETHOVEN','2009-05-11','NIE PODZIELIL SIE SWOJA KASZA'))
  INTO IncydentyO VALUES (INCYDENT(13,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'RURA'),'DZIKI BILL','2009-09-03','ODGRYZL OGON'))
  INTO IncydentyO VALUES (INCYDENT(14,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'PLACEK'),'BAZYLI','2010-07-12','DZIOBIAC UNIEMOZLIWIL PODEBRANIE KURCZAKA'))
  INTO IncydentyO VALUES (INCYDENT(15,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'PUSZYSTA'),'SMUKLA','2010-11-19','OBRZUCILA SZYSZKAMI'))
  INTO IncydentyO VALUES (INCYDENT(16,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'KURKA'),'BUREK','2010-12-14','POGONIL'))
  INTO IncydentyO VALUES (INCYDENT(17,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'MALY'),'CHYTRUSEK','2011-07-13','PODEBRAL PODEBRANE JAJKA'))
  INTO IncydentyO VALUES (INCYDENT(18,(SELECT REF(K) FROM KocuryO K WHERE K.pseudo = 'UCHO'),'SWAWOLNY DYZIO','2011-07-14','OBRZUCIL KAMIENIAMI'))
SELECT * FROM Dual;

INSERT ALL
  INTO KontaO VALUES (WIERSZK(1,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'TYGRYS'), SYSDATE, NULL))
  INTO KontaO VALUES (WIERSZK(2,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'TYGRYS'), '2018-04-11', '2020-03-11'))
  INTO KontaO VALUES (WIERSZK(3,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'TYGRYS'), '2018-05-15', '2018-06-01'))
  INTO KontaO VALUES (WIERSZK(4,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'TYGRYS'), '2020-09-28', NULL))
  INTO KontaO VALUES (WIERSZK(5,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'BOLEK'), '2021-12-12', '2022-01-15'))
  INTO KontaO VALUES (WIERSZK(6,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'BOLEK'), '2022-01-22', NULL))
  INTO KontaO VALUES (WIERSZK(7,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'BOLEK'), SYSDATE, NULL))
  INTO KontaO VALUES (WIERSZK(8,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'LOLA'), SYSDATE, NULL))
  INTO KontaO VALUES (WIERSZK(9,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'LOLA'), '2021-10-10', '2022-01-01'))
  INTO KontaO VALUES (WIERSZK(10,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'LOLA'), '2020-12-26', NULL))
  INTO KontaO VALUES (WIERSZK(11,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'LASKA'), SYSDATE, NULL))
  INTO KontaO VALUES (WIERSZK(12,(SELECT REF(E) FROM ElitaO E WHERE E.kot.pseudo = 'LASKA'), '2021-01-19', NULL))
SELECT * FROM Dual;


SELECT K.pseudo, imie_wroga, data_incydentu
FROM KocuryO K JOIN IncydentyO I ON REF(K) = I.kot;

SELECT K.dane()
FROM KocuryO K
WHERE K.myszy() > ( SELECT AVG(K1.myszy()) FROM KocuryO K1);

SELECT I.kot.dane(), Count(incydent_id)
FROM IncydentyO I
GROUP BY I.kot
ORDER BY I.kot;

--zad 18
SELECT K1.imie, K1.w_stadku_od "POLUJE OD"
FROM KocuryO K1 JOIN KocuryO K2
ON K2.imie = 'JACEK' AND K1.w_stadku_od < K2.w_stadku_od
ORDER BY 2 DESC;

--zad 19a
SELECT K1.imie , K1.funkcja, K1.szef.imie "Szef 1", K1.szef.szef.imie "Szef 2",
K1.szef.szef.szef.imie "Szef 3"
FROM KocuryO K1
WHERE K1.funkcja IN ('KOT', 'MILUSIA');


--zad 34
DECLARE
    liczba          INTEGER;
    szukana_funkcja KocuryO.funkcja%TYPE := '&funkcja';
BEGIN
    SELECT COUNT(*) INTO liczba FROM KocuryO
    WHERE funkcja = szukana_funkcja;
    IF liczba > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Znaleziono kota o funkcji: ' || szukana_funkcja);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono kota o podanej funkcji');
    END IF;
END;        

--zad 37
DECLARE
    licznik INTEGER := 1;
BEGIN
    DBMS_OUTPUT.PUT_LINE('NR  PSEUDONIM  ZJADA');
    DBMS_OUTPUT.PUT_LINE('--------------------');
    FOR kot IN (SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra, 0) zjada
                FROM KocuryO
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

--zad 49
--BEGIN
--  EXECUTE IMMEDIATE 'CREATE TABLE Myszy (
--    mysz_id NUMBER       CONSTRAINT m_fun_pk PRIMARY KEY,
--    lowca VARCHAR2(15)   CONSTRAINT m_l_fk REFERENCES Kocury(pseudo)
--                         CONSTRAINT m_l_nn NOT NULL,
--    zjadacz VARCHAR2(15) CONSTRAINT m_z_fk REFERENCES Kocury(pseudo),
--    waga_myszy NUMBER    CONSTRAINT m_wm_nn NOT NULL
--                         CONSTRAINT m_wm_ch CHECK(waga_myszy BETWEEN 10 AND 20),
--    data_zlowienia DATE  CONSTRAINT m_dz_nn NOT NULL,
--    data_wydania DATE,
--    CONSTRAINT m_dw_gte_dz CHECK(data_zlowienia <= data_wydania));';
--END;

CREATE TABLE Myszy (
    mysz_id NUMBER       CONSTRAINT m_fun_pk PRIMARY KEY,
    lowca VARCHAR2(15)   CONSTRAINT m_l_fk REFERENCES Kocury(pseudo)
                         CONSTRAINT m_l_nn NOT NULL,
    zjadacz VARCHAR2(15) CONSTRAINT m_z_fk REFERENCES Kocury(pseudo),
    waga_myszy NUMBER    CONSTRAINT m_wm_nn NOT NULL
                         CONSTRAINT m_wm_ch CHECK(waga_myszy BETWEEN 10 AND 20),
    data_zlowienia DATE  CONSTRAINT m_dz_nn NOT NULL,
    data_wydania DATE,
    CONSTRAINT m_dw_gte_dz CHECK(data_zlowienia <= data_wydania));
    
    
    
    
    
    
    
--wypelnienie tabeli myszy
DECLARE
  TYPE kocury_table_type IS TABLE OF Kocury % ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE myszy_table_type IS TABLE OF Myszy % ROWTYPE INDEX BY BINARY_INTEGER;
  dzien_poczatkowy DATE := '2004-01-01';
  nastepny_miesiac DATE;
  dzien_koncowy DATE := '2022-01-18';
  sroda DATE;
  nastepna_sroda DATE;
  srednia NUMBER;
  suma NUMBER := 0;
  myszy_danego_kota NUMBER;
  kot_bez_myszy NUMBER;
  do_wydania NUMBER;
  kocury_table kocury_table_type;
  aktualny_kot NUMBER := 1;
  myszy_table myszy_table_type;
  myszy_iter NUMBER := 1;
  niewydane_myszy_iter NUMBER := 1;
BEGIN
  --dynamiczny sql zeby wprowadzic posortowane dane
  EXECUTE IMMEDIATE 'SELECT * FROM Kocury ORDER BY w_stadku_od'
  BULK COLLECT INTO kocury_table;

  sroda := NEXT_DAY(LAST_DAY(dzien_poczatkowy) - 7, 'œroda');
  nastepny_miesiac := ADD_MONTHS(dzien_poczatkowy, 1);
  nastepna_sroda := NEXT_DAY(LAST_DAY(nastepny_miesiac) - 7, 'œroda');

  WHILE nastepny_miesiac <= dzien_koncowy
  LOOP
    do_wydania := 0;
    --suma i srednia w aktualnym miesiacu
    WHILE aktualny_kot <= kocury_table.COUNT AND kocury_table(aktualny_kot).w_stadku_od <= dzien_poczatkowy
    LOOP
      suma := suma + NVL(kocury_table(aktualny_kot).przydzial_myszy, 0) + NVL(kocury_table(aktualny_kot).myszy_extra, 0);
      srednia := ROUND(suma / aktualny_kot);
      aktualny_kot := aktualny_kot + 1;
    END LOOP;
    --zlowienie myszy + data wydania
    FOR i IN 1..(aktualny_kot - 1)
    LOOP
      myszy_danego_kota := 0;
      WHILE myszy_danego_kota < srednia
      LOOP
        myszy_table(myszy_iter).mysz_id := myszy_iter;
        myszy_table(myszy_iter).lowca := kocury_table(i).pseudo;
        myszy_table(myszy_iter).waga_myszy := ROUND(DBMS_RANDOM.VALUE(10, 20), 2);
        myszy_table(myszy_iter).data_zlowienia := dzien_poczatkowy + TRUNC(DBMS_RANDOM.VALUE(0, nastepny_miesiac - dzien_poczatkowy));
        IF myszy_table(myszy_iter).data_zlowienia > sroda THEN
          myszy_table(myszy_iter).data_wydania := nastepna_sroda;
        ELSE
          myszy_table(myszy_iter).data_wydania := sroda;
        END IF;
        myszy_iter := myszy_iter + 1;
        myszy_danego_kota := myszy_danego_kota + 1;
      END LOOP;
    END LOOP;
    kot_bez_myszy := aktualny_kot;
    
    -- wydanie myszy
    WHILE niewydane_myszy_iter < myszy_iter
    LOOP
      IF do_wydania = 0 AND kot_bez_myszy > 1 THEN
        kot_bez_myszy := kot_bez_myszy - 1;
        do_wydania := NVL(kocury_table(kot_bez_myszy).przydzial_myszy, 0) + NVL(kocury_table(kot_bez_myszy).myszy_extra, 0);
      END IF;
      myszy_table(niewydane_myszy_iter).zjadacz := kocury_table(kot_bez_myszy).pseudo;
      do_wydania := do_wydania - 1;
      niewydane_myszy_iter := niewydane_myszy_iter + 1;
    END LOOP;
    
    --przesuniecie o miesiac przed kolejna petla
    dzien_poczatkowy := nastepny_miesiac;
    sroda := nastepna_sroda;
    nastepny_miesiac := ADD_MONTHS(dzien_poczatkowy, 1);
    nastepna_sroda := NEXT_DAY(LAST_DAY(nastepny_miesiac) - 7, 'œroda');
  END LOOP;

  nastepny_miesiac := dzien_koncowy;
  srednia := srednia * (nastepny_miesiac - dzien_poczatkowy) / 30;

  --wypelnienie ostatniego miesiac do dnia dnia koncowego, bez wydawania myszy
  FOR i IN 1..kocury_table.COUNT
  LOOP
    myszy_danego_kota := 0;
    WHILE myszy_danego_kota < srednia
    LOOP
      myszy_table(myszy_iter).mysz_id := myszy_iter;
      myszy_table(myszy_iter).lowca := kocury_table(i).pseudo;
      myszy_table(myszy_iter).waga_myszy := ROUND(DBMS_RANDOM.VALUE(10, 20), 2);
      myszy_table(myszy_iter).data_zlowienia := dzien_poczatkowy + TRUNC(DBMS_RANDOM.VALUE(0, nastepny_miesiac - dzien_poczatkowy));
      myszy_iter := myszy_iter + 1;
      myszy_danego_kota := myszy_danego_kota + 1;
    END LOOP;
  END LOOP;

  FORALL i IN 1..myszy_table.COUNT SAVE EXCEPTIONS
  INSERT INTO Myszy VALUES (
    myszy_table(i).mysz_id,
    myszy_table(i).lowca,
    myszy_table(i).zjadacz,
    myszy_table(i).waga_myszy,
    myszy_table(i).data_zlowienia,
    myszy_table(i).data_wydania
  );
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;


SELECT Count(mysz_id) FROM MYSZY;
DROP TABLE MYSZY;

BEGIN
  FOR kot IN (SELECT pseudo FROM Kocury)
  LOOP
   EXECUTE IMMEDIATE 'CREATE TABLE Myszy_' || kot.pseudo || ' (
    mysz_id NUMBER CONSTRAINT m_fun_' || kot.pseudo || '_pk PRIMARY KEY,
    waga_myszy NUMBER CONSTRAINT m_wm_' || kot.pseudo || '_nn NOT NULL
                      CONSTRAINT m_wm_' || kot.pseudo || '_ch CHECK(waga_myszy BETWEEN 10 AND 20),
    data_zlowienia DATE CONSTRAINT m_dz_' || kot.pseudo || '_nn NOT NULL
  )';
  END LOOP;
END;

INSERT ALL
  INTO Myszy_TYGRYS VALUES(1,10,'2022-01-19')
  INTO Myszy_TYGRYS VALUES(2,15,'2022-01-19')
  INTO Myszy_TYGRYS VALUES(3,20,'2022-01-19')
  INTO MYSZY_ZOMBI VALUES(1,20,'2022-01-19')
SELECT * FROM Dual;

SELECT * FROM Myszy_TYGRYS;
SELECT * FROM Myszy_ZOMBI;

SELECT COUNT(mysz_id) from Myszy;

CREATE OR REPLACE PROCEDURE Przyjmij(pseudonim Kocury.pseudo % TYPE, dzien DATE)
AS
  czy_kot_istnieje NUMBER;
  nowe_id NUMBER;
  kot_nie_istnieje EXCEPTION;
  TYPE tablica_mysz_pseudo_typ IS TABLE OF Myszy_TYGRYS % ROWTYPE INDEX BY BINARY_INTEGER;
  tablica_mysz_pseudo tablica_mysz_pseudo_typ;
  TYPE tablica_mysz_typ IS TABLE OF Myszy % ROWTYPE INDEX BY BINARY_INTEGER;
  tablica_mysz tablica_mysz_typ;
  
BEGIN
  SELECT COUNT(pseudo) INTO czy_kot_istnieje FROM Kocury WHERE pseudo = pseudonim;
  IF czy_kot_istnieje = 0 THEN
    RAISE kot_nie_istnieje;
  END IF;
  SELECT MAX(mysz_id) + 1 INTO nowe_id
  FROM Myszy;

  EXECUTE IMMEDIATE '
    SELECT mysz_id, waga_myszy, data_zlowienia
    FROM Myszy_' || pseudonim || '
    WHERE data_zlowienia = ''' || dzien || ''''
  BULK COLLECT INTO tablica_mysz_pseudo;

  FOR i IN 1..tablica_mysz_pseudo.COUNT
  LOOP
    tablica_mysz(i).mysz_id := nowe_id;
    tablica_mysz(i).lowca := pseudonim;
    tablica_mysz(i).waga_myszy := tablica_mysz_pseudo(i).waga_myszy;
    tablica_mysz(i).data_zlowienia := tablica_mysz_pseudo(i).data_zlowienia;
    nowe_id := nowe_id + 1;
  END LOOP;

  FORALL i IN 1..tablica_mysz.COUNT SAVE EXCEPTIONS
  INSERT INTO Myszy VALUES (
    tablica_mysz(i).mysz_id,
    tablica_mysz(i).lowca,
    tablica_mysz(i).zjadacz,
    tablica_mysz(i).waga_myszy,
    tablica_mysz(i).data_zlowienia,
    tablica_mysz(i).data_wydania
  );
  EXECUTE IMMEDIATE 'DELETE FROM Myszy_' || pseudonim || ' WHERE data_zlowienia = ''' || dzien || '''';
EXCEPTION
  WHEN kot_nie_istnieje THEN DBMS_OUTPUT.PUT_LINE('Kot o podanym pseudonimie nie istnieje');
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

DROP PROCEDURE PRZYJMIJ;

SELECT * FROM Myszy WHERE data_zlowienia = '2022-01-19';
BEGIN
    Przyjmij('TYGRYS','2022-01-19');
END;
SELECT * FROM Myszy WHERE data_zlowienia = '2022-01-19';
DELETE FROM Myszy WHERE data_zlowienia = '2022-01-19';


CREATE OR REPLACE PROCEDURE Wydaj
AS
  TYPE myszy_bez_zjadacza_tabela_typ IS TABLE OF Myszy % ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE kocury_przydzial_typ IS RECORD (pseudo Kocury.pseudo % TYPE, przydzial NUMBER(3));
  TYPE kocury_przydzial_tabela_typ IS TABLE OF kocury_przydzial_typ INDEX BY BINARY_INTEGER;
  sroda DATE := NEXT_DAY(LAST_DAY(SYSDATE) - 7, 'œroda');
  do_przydzielenia NUMBER := 0;
  kocury_przydzial_iter NUMBER := 1;
  myszy_bez_zjadacza_tabela myszy_bez_zjadacza_tabela_typ;
  kocury_przydzial_tabela kocury_przydzial_tabela_typ;
  myszy_z_miesiaca NUMBER;
BEGIN
 
  SELECT COUNT(mysz_id) INTO myszy_z_miesiaca FROM Myszy WHERE data_wydania = sroda;
  DBMS_OUTPUT.PUT_LINE(myszy_z_miesiaca);
  IF SYSDATE = sroda AND myszy_z_miesiaca = 0 THEN
  SELECT * BULK COLLECT INTO myszy_bez_zjadacza_tabela FROM Myszy WHERE zjadacz IS NULL;

  SELECT pseudo, NVL(przydzial_myszy, 0) + NVL(myszy_extra, 0) 
  BULK COLLECT INTO kocury_przydzial_tabela
  FROM Kocury
  WHERE w_stadku_od <= LAST_DAY(ADD_MONTHS(SYSDATE, -1)) --pomijamy koty dodane do stada w tym miesiacu 
  CONNECT BY PRIOR pseudo = szef
  START WITH szef IS NULL
  ORDER BY LEVEL;

  FOR i IN 1..kocury_przydzial_tabela.COUNT
  LOOP
    do_przydzielenia := do_przydzielenia + kocury_przydzial_tabela(i).przydzial;
  END LOOP;

  FOR i IN 1..myszy_bez_zjadacza_tabela.COUNT
  LOOP
    EXIT WHEN i > do_przydzielenia;
    IF kocury_przydzial_iter > kocury_przydzial_tabela.COUNT THEN
       kocury_przydzial_iter := 1;
    END IF;
    IF kocury_przydzial_tabela(kocury_przydzial_iter).przydzial <> 0 THEN
        myszy_bez_zjadacza_tabela(i).zjadacz := kocury_przydzial_tabela(kocury_przydzial_iter).pseudo;
        myszy_bez_zjadacza_tabela(i).data_wydania := sroda;
        kocury_przydzial_tabela(kocury_przydzial_iter).przydzial := kocury_przydzial_tabela(kocury_przydzial_iter).przydzial - 1;
    END IF;
    kocury_przydzial_iter := kocury_przydzial_iter + 1;
  END LOOP;
  FORALL i IN 1..myszy_bez_zjadacza_tabela.COUNT SAVE EXCEPTIONS
  UPDATE Myszy
    SET zjadacz = myszy_bez_zjadacza_tabela(i).zjadacz,
        data_wydania = myszy_bez_zjadacza_tabela(i).data_wydania
    WHERE mysz_id = myszy_bez_zjadacza_tabela(i).mysz_id;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Operacja niemozliwa');
  END IF;
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;


BEGIN
    Przyjmij('TYGRYS','2022-01-19');
END;

SELECT COUNT(mysz_id) FROM Myszy WHERE zjadacz IS null;
BEGIN
    Wydaj();
END;
SELECT COUNT(mysz_id) FROM Myszy WHERE zjadacz IS null;

DROP TABLE Myszy;


-- Zad 48
CREATE TABLE PlebsT (
  plebs_id NUMBER(3) CONSTRAINT p_np_pk PRIMARY KEY,
  pseudo VARCHAR2(15) CONSTRAINT p_p_fk REFERENCES Kocury(pseudo)
                      CONSTRAINT p_p_u UNIQUE
                      CONSTRAINT p_p_nn NOT NULL
);

CREATE TABLE ElitaT (
  elita_id NUMBER(3) CONSTRAINT e_ne_pk PRIMARY KEY,
  pseudo VARCHAR2(15) CONSTRAINT e_p_fk REFERENCES Kocury(pseudo)
                      CONSTRAINT e_p_u UNIQUE
                      CONSTRAINT e_p_nn NOT NULL,
  sluga NUMBER(3) CONSTRAINT e_s_fk REFERENCES PlebsT(plebs_id)
);

CREATE TABLE KontaT (
  wiersz_id NUMBER(3) CONSTRAINT k_nw_pk PRIMARY KEY,
  elita_id NUMBER(3) CONSTRAINT k_p_fk REFERENCES ElitaT(elita_id)
                     CONSTRAINT k_p_nn NOT NULL,
  data_wprowadzenia DATE CONSTRAINT k_dw_nn NOT NULL,
  data_usuniecia DATE,
  CONSTRAINT k_dw_du_ch CHECK(data_wprowadzenia <= data_usuniecia)
);

CREATE OR REPLACE FORCE VIEW KocuryV OF KOCUR
WITH OBJECT IDENTIFIER (pseudo) AS
  SELECT imie, plec, pseudo, funkcja, MAKE_REF(KocuryV, szef) szef,
         w_stadku_od, przydzial_myszy, myszy_extra, nr_bandy
  FROM Kocury;

CREATE OR REPLACE VIEW PlebsV OF PLEBS
WITH OBJECT IDENTIFIER (plebs_id) AS
  SELECT plebs_id, MAKE_REF(KocuryV, pseudo) kot
  FROM PlebsT;

CREATE OR REPLACE VIEW ElitaV OF ELITA
WITH OBJECT IDENTIFIER (elita_id) AS
  SELECT elita_id, MAKE_REF(KocuryV, pseudo) kot,
         MAKE_REF(PlebsV, sluga) sluga
  FROM ElitaT;

CREATE OR REPLACE VIEW IncydentyV OF INCYDENT
WITH OBJECT IDENTIFIER (incydent_id) AS
  SELECT ROW_NUMBER() OVER (ORDER BY data_incydentu) incydent_id,
         MAKE_REF(KocuryV, pseudo) kot, imie_wroga, data_incydentu, opis_incydentu
  FROM Wrogowie_Kocurow;

CREATE OR REPLACE VIEW KontaV OF WIERSZK
WITH OBJECT IDENTIFIER (wiersz_id) AS
  SELECT wiersz_id, MAKE_REF(ElitaV, elita_id) kot, data_wprowadzenia, data_usuniecia
  FROM KontaT;


INSERT INTO PlebsV VALUES (Plebs(1,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'ZOMBI')));
INSERT  INTO PlebsV VALUES (Plebs(2,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'LYSY')));
INSERT  INTO PlebsV VALUES (Plebs(3,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'SZYBKA')));
INSERT  INTO PlebsV VALUES (Plebs(4,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'MALA')));
INSERT INTO PlebsV VALUES (Plebs(5,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'RAFA')));
INSERT  INTO PlebsV VALUES (Plebs(6,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'KURKA')));


INSERT  INTO ElitaV VALUES (ELITA(1,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'TYGRYS'),(SELECT REF(P) FROM PlebsV P WHERE P.kot.pseudo = 'ZOMBI')));
INSERT  INTO ElitaV VALUES (ELITA(2,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'BOLEK'),NULL));
INSERT  INTO ElitaV VALUES (ELITA(3,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'LOLA'),(SELECT REF(P) FROM PlebsV P WHERE P.kot.pseudo = 'LYSY')));
INSERT  INTO ElitaV VALUES (ELITA(4,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'MALA'),(SELECT REF(P) FROM PlebsV P WHERE P.kot.pseudo = 'SZYBKA')));
INSERT  INTO ElitaV VALUES (ELITA(5,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'LASKA'),(SELECT REF(P) FROM PlebsV P WHERE P.kot.pseudo = 'MALA')));
INSERT INTO ElitaV VALUES (ELITA(6,(SELECT REF(K) FROM KocuryV K WHERE K.pseudo = 'PUSZYSTA'),(SELECT REF(P) FROM PlebsV P WHERE P.kot.pseudo = 'RAFA')));


INSERT  INTO KontaV VALUES (WIERSZK(1,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'TYGRYS'), SYSDATE, NULL));
INSERT  INTO KontaV VALUES (WIERSZK(2,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'TYGRYS'), '2018-04-11', '2020-03-11'));
INSERT  INTO KontaV VALUES (WIERSZK(3,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'TYGRYS'), '2018-05-15', '2018-06-01'));
INSERT  INTO KontaV VALUES (WIERSZK(4,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'TYGRYS'), '2020-09-28', NULL));
INSERT  INTO KontaV VALUES (WIERSZK(5,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'BOLEK'), '2021-12-12', '2022-01-15'));
INSERT  INTO KontaV VALUES (WIERSZK(6,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'BOLEK'), '2022-01-22', NULL));
INSERT  INTO KontaV VALUES (WIERSZK(7,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'BOLEK'), SYSDATE, NULL));
INSERT  INTO KontaV VALUES (WIERSZK(8,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'LOLA'), SYSDATE, NULL));
INSERT  INTO KontaV VALUES (WIERSZK(9,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'LOLA'), '2021-10-10', '2022-01-01'));
INSERT  INTO KontaV VALUES (WIERSZK(10,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'LOLA'), '2020-12-26', NULL));
INSERT  INTO KontaV VALUES (WIERSZK(11,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'LASKA'), SYSDATE, NULL));
INSERT  INTO KontaV VALUES (WIERSZK(12,(SELECT REF(E) FROM ElitaV E WHERE E.kot.pseudo = 'LASKA'), '2021-01-19', NULL));

SELECT K.pseudo, imie_wroga, data_incydentu
FROM KocuryV K JOIN IncydentyV I ON REF(K) = I.kot;

SELECT K.dane()
FROM KocuryV K
WHERE K.myszy() > ( SELECT AVG(K1.myszy()) FROM KocuryV K1);

SELECT I.kot.dane(), Count(incydent_id)
FROM IncydentyV I
GROUP BY I.kot
ORDER BY I.kot;

--zad 18
SELECT K1.imie, K1.w_stadku_od "POLUJE OD"
FROM KocuryV K1 JOIN KocuryV K2
ON K2.imie = 'JACEK' AND K1.w_stadku_od < K2.w_stadku_od
ORDER BY 2 DESC;

--zad 19a
SELECT K1.imie , K1.funkcja, K1.szef.imie "Szef 1", K1.szef.szef.imie "Szef 2",
K1.szef.szef.szef.imie "Szef 3"
FROM KocuryV K1
WHERE K1.funkcja IN ('KOT', 'MILUSIA');


--zad 34
DECLARE
    liczba          INTEGER;
    szukana_funkcja KocuryV.funkcja%TYPE := '&funkcja';
BEGIN
    SELECT COUNT(*) INTO liczba FROM KocuryV
    WHERE funkcja = szukana_funkcja;
    IF liczba > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Znaleziono kota o funkcji: ' || szukana_funkcja);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono kota o podanej funkcji');
    END IF;
END;        

--zad 37
DECLARE
    licznik INTEGER := 1;
BEGIN
    DBMS_OUTPUT.PUT_LINE('NR  PSEUDONIM  ZJADA');
    DBMS_OUTPUT.PUT_LINE('--------------------');
    FOR kot IN (SELECT pseudo, NVL(przydzial_myszy,0) + NVL(myszy_extra, 0) zjada
                FROM KocuryV
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


SELECT COUNT(mysz_id)  
    FROM Myszy
    WHERE EXTRACT(month FROM data_wydania) = EXTRACT(month FROM sroda) AND EXTRACT(year FROM data_wydania) = EXTRACT(year FROM sroda) AND EXTRACT(day FROM data_wydania) = EXTRACT(day FROM sroda); 

