-- CHANGED BY: Ant�nio Neto
-- CHANGE DATE: 18/05/2011 14:27
-- CHANGE REASON: [ALERT-179647] Change Details screen to allow clob's - Descri��o: No perfil M�dico, no INP, no bot�o da Hist�ria da Doen�a (truncated)

BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_table_inp_detail IS TABLE OF t_rec_inp_detail'; 
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
-- CHANGE END: Ant�nio Neto
