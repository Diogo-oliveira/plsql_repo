-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2012-MAR-13
-- CHANGED REASON: ALERT-223093
CREATE OR REPLACE TYPE t_rec_ref_speciality AS OBJECT
(
    id_dep_clin_serv NUMBER(24),
    description      VARCHAR2(1000 CHAR),

    CONSTRUCTOR FUNCTION t_rec_ref_speciality RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_ref_speciality IS
    CONSTRUCTOR FUNCTION t_rec_ref_speciality RETURN SELF AS RESULT IS
    BEGIN
    
        self.id_dep_clin_serv := NULL;
        self.description      := NULL;
    
        RETURN;
    END;
END;
/

-- CHANGE END: Ana Monteiro