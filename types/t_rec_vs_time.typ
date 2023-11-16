-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 02/12/2013 09:33
-- CHANGE REASON: [ALERT-270040] 
CREATE OR REPLACE TYPE t_rec_vs_time force AS OBJECT
(
    dt_vital_sign_read    VARCHAR2(1000 CHAR),
    tb_id_vital_sign_read table_number,
    
    CONSTRUCTOR FUNCTION t_rec_vs_time RETURN SELF AS RESULT
)
/
CREATE OR REPLACE TYPE BODY t_rec_vs_time IS
    CONSTRUCTOR FUNCTION t_rec_vs_time RETURN SELF AS RESULT IS
    BEGIN
        self.dt_vital_sign_read    := NULL;
        self.tb_id_vital_sign_read := table_number();
    
        RETURN;
    END;
END;
/
-- CHANGE END: Paulo Teixeira