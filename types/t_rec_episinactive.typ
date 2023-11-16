CREATE OR REPLACE TYPE t_rec_episinactive AS OBJECT
(
    num_episode     NUMBER,
    dt_birth_string VARCHAR2(4000 CHAR),
    dt_birth        VARCHAR2(4000 CHAR),
    name_pat        VARCHAR2(1000 CHAR),
		name_pat_sort   VARCHAR2(1000 CHAR),
    pat_ndo         VARCHAR2(1000 CHAR),
		pat_nd_icon     VARCHAR2(10 CHAR),
    location        VARCHAR2(200 CHAR),
    id_patient      NUMBER(24)
)
/
