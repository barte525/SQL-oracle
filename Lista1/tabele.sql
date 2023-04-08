ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

CREATE TABLE Bandy (
nr_bandy NUMBER(2) CONSTRAINT ban_pk PRIMARY KEY,
nazwa VARCHAR2(20) CONSTRAINT ban_naz_nn NOT NULL,
teren VARCHAR2(15) CONSTRAINT ban_ter_unq UNIQUE,
szef_bandy VARCHAR2(15) CONSTRAINT ban_szef_unq UNIQUE
);

CREATE TABLE Funkcje (
funkcja VARCHAR2(10) CONSTRAINT fun_pk PRIMARY KEY,
min_myszy NUMBER(3) CONSTRAINT fun_min_chek CHECK (min_myszy>5),
max_myszy NUMBER(3) CONSTRAINT fun_max_chek CHECK (max_myszy<200),
CONSTRAINT fun_max_gt_min CHECK(max_myszy >= min_myszy)
);

CREATE TABLE Wrogowie (
imie_wroga VARCHAR2(15) CONSTRAINT wro_pk PRIMARY KEY,
stopien_wrogosci NUMBER(2) CONSTRAINT wro_st_chek CHECK(stopien_wrogosci BETWEEN 1 AND 10),
gatunek VARCHAR2(15),
lapowka VARCHAR2(20)
);

CREATE TABLE Kocury (
imie VARCHAR2(15) CONSTRAINT koc_im_nn NOT NULL,
plec VARCHAR2(1) CONSTRAINT koc_plec_ch CHECK(plec IN ('M','D')),
pseudo VARCHAR2(15) CONSTRAINT koc_fun_pk PRIMARY KEY, 
funkcja VARCHAR2(10) CONSTRAINT koc_fun_fk REFERENCES Funkcje(funkcja),
szef VARCHAR2(15) CONSTRAINT koc_szef_fk REFERENCES Kocury(pseudo),
w_stadku_od DATE DEFAULT SYSDATE,
przydzial_myszy NUMBER(3),
myszy_extra NUMBER(3),            
nr_bandy NUMBER(2) CONSTRAINT koc_ban_fk REFERENCES Bandy(nr_bandy)
);

CREATE TABLE Wrogowie_Kocurow (
pseudo VARCHAR2(15) CONSTRAINT wrok_koc_fk REFERENCES Kocury(pseudo),    
imie_wroga VARCHAR2(15) CONSTRAINT wrok_wro_fk REFERENCES Wrogowie(imie_wroga),
data_incydentu DATE CONSTRAINT wrok_dat_nn NOT NULL,
opis_incydentu VARCHAR2(50),
CONSTRAINT wrok PRIMARY KEY(pseudo, imie_wroga)
);

ALTER TABLE Bandy ADD CONSTRAINT ban_szef_fk FOREIGN KEY (szef_bandy) REFERENCES Kocury(pseudo);

