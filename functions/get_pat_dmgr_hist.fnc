CREATE OR REPLACE FUNCTION GET_PAT_DMGR_HIST(i_lang in language.id_language%type, i_id_patient in patient.id_patient%type, o_pat_dmgr_hist OUT Pk_Types.CURSOR_TYPE, o_error out varchar2) RETURN boolean IS
g_error varchar2(200);
BEGIN
   
   RETURN true;
   EXCEPTION
     WHEN OTHERS THEN
       rollback;
       
       return false;
END GET_PAT_DMGR_HIST; 
/
