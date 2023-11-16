-- CHANGED BY: António Neto
-- CHANGE DATE: 18/05/2011 14:27
-- CHANGE REASON: [ALERT-179647] Change Details screen to allow clob's - Descrição: No perfil Médico, no INP, no botão da História da Doença (truncated)

BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_table_inp_detail IS TABLE OF t_rec_inp_detail'; 
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
-- CHANGE END: António Neto
