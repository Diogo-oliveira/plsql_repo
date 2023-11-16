CREATE OR REPLACE TYPE t_epis_note AS OBJECT
(
    id_epis_pn NUMBER,
    note       CLOB,
    position   NUMBER,
    relevance  NUMBER
)
/
