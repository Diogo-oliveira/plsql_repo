DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(1)
      INTO l_count
      FROM user_types t
     WHERE t.type_name = 'T_REC_REF_CONTEXT';

    IF l_count = 1
    THEN
        EXECUTE IMMEDIATE 'DROP TYPE T_REC_REF_CONTEXT';
    END IF;
END;
/

CREATE OR REPLACE TYPE t_rec_ref_context AS OBJECT
(
    id_external_request NUMBER(24),
    dt_system_date      TIMESTAMP(6) WITH LOCAL TIME ZONE,
		
    CONSTRUCTOR FUNCTION t_rec_ref_context RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_ref_context IS
    CONSTRUCTOR FUNCTION t_rec_ref_context RETURN SELF AS RESULT IS
    BEGIN

        self.id_external_request := NULL;
        self.dt_system_date      := NULL;
				
        RETURN;
    END;
END;
/





