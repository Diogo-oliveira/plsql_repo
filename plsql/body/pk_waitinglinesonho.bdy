/*-- Last Change Revision: $Rev: 2027867 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY PK_WAITINGLINESONHO AS

function efectivacao return Varchar2 is
language java name 'mni.ehr.interfaces.db.WaitingLineSonho.efectivacao() return java.lang.String';

function efectivacao( id_institution in Number, connect_string in varchar2 ) return Varchar2 is
language java name 'mni.ehr.interfaces.db.WaitingLineSonho.efectivacao(java.lang.Number, java.lang.String ) return java.lang.String';


function gravacao_ficheiro_voz_loquendo(mensagem in Varchar2, ficheiro in Varchar2) return Number is
language java name 'mni.ehr.voice.LoquendoJacob.Gravacao_ficheiro(java.lang.String,java.lang.String) return int';


function getaudit3 return Varchar2 is
language java name 'mni.ehr.interfaces.db.WaitingLineSonho.audit3() return java.lang.String';


function getaudit return Varchar2 is
language java name 'mni.ehr.interfaces.db.WaitingLineSonho.audit() return java.lang.String';


function voz(maquina in Varchar2, mensagem in Varchar2) return varchar2 is
language java name 'mni.ehr.interfaces.db.WaitingLineSonho.voz(java.lang.String,java.lang.String) return java.lang.String';


--function getaudit return pk_types.cursor_type is
--language java name 'mni.ehr.interfaces.db.WaitingLineSonho.audit() return java.sql.ResultSet';

/**
 * Process new "efectivação" event.
 * This function is to be used only by the interfaces team.
 * Commit or rollback is controlled by interfaces.
 *
 * Interfaces must call this function with all I_WL_PATIENT_SONHO values set, except  MACHINE_NAME and in some circunstances ID_EPISODE.
 * ID_EPISODE should not be set when the Waiting Room is working alone, without Alert clinical software.
 * The fields PATIENT_ID, CLIN_PROF_ID, CONSULT_ID, PROF_ID, ID_INSTITUTION AND ID_EPISODE represent ALERT IDs and not ADT system IDs.
 * The field NUM_PROC represents the patient process number in the ADT system.
 *
 * CLIN_PROF_ID is the doctor's id
 * CONSULT_ID is the clinical service id
 * PROF_ID is the admin id
 *
 * Others fields names are self explanatory.
 *
 * @param   I_LANG language associated to the professional executing the request
 * @param   I_WL_PATIENT_SONHO The patient info
 * @param   O_ERROR an error message, set when return=false
 *
 * @RETURN  TRUE if sucess, FALSE otherwise
 * @author  Luís Gaspar
 * @version 1.0
 * @since   23-11-2006
 */
FUNCTION EFECTIVAR_EVENT (  I_LANG IN LANGUAGE.ID_LANGUAGE%TYPE,
                                               I_WL_PATIENT_SONHO IN WL_PATIENT_SONHO%ROWTYPE,
                                               O_ERROR OUT VARCHAR2 ) RETURN BOOLEAN IS
	L_ERROR VARCHAR2(4000);

BEGIN

        L_ERROR := 'INSERT INTO WL_PATIENT_SONHO';
	INSERT INTO WL_PATIENT_SONHO VALUES I_WL_PATIENT_SONHO;

      RETURN TRUE;

EXCEPTION
	WHEN OTHERS THEN
      	O_ERROR := Pk_Message.GET_MESSAGE(I_LANG, G_ERROR_MSG_CODE) || CHR(10)|| 'PK_WAITINGLINESONHO.EFECTIVAR_EVENT / ' || L_ERROR || ' / ' || SQLERRM;
      	RETURN FALSE;
END EFECTIVAR_EVENT;

BEGIN
	G_ERROR_MSG_CODE := 'COMMON_M001';
END;
/
