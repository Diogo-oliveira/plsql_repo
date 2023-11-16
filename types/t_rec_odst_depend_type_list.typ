-- CHANGED BY: Carlos Loureiro
-- CHANGED DATE: 04-JUL-2010
-- CHANGED REASON: [ALERT-109296] TDE Core versioning (DDL)
CREATE OR REPLACE TYPE t_rec_odst_depend_type_list AS OBJECT
(
    id_relationship_type   NUMBER(24),
    relationship_type_desc VARCHAR2(1000 CHAR),
    internal_name          VARCHAR2(200 CHAR)
);
-- CHANGE END: Carlos Loureiro
