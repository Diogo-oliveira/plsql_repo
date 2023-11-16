 CREATE OR REPLACE  TYPE t_rec_sch_permission AS OBJECT (
        id_consult_permission NUMBER(24),
        id_institution        NUMBER(12),
        id_professional       NUMBER(24),
        id_prof_agenda        NUMBER(24),
        id_dep_clin_serv      NUMBER(24),
        id_sch_event          NUMBER(24),
        flg_permission        varchar2(1))
/
