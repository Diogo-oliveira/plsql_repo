CREATE OR REPLACE TYPE t_rec_comp_axe_lvl AS OBJECT
(
    id_comp_axe  NUMBER(24),
    lvl          NUMBER(24),
    lst_ids      VARCHAR2(1000 CHAR),
    lst_descs    VARCHAR2(1000 CHAR),
    total_childs NUMBER(24)
)
/
