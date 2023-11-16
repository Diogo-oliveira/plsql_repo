/*-- Last Change Revision: $Rev: 1775189 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2017-03-16 09:22:05 +0000 (qui, 16 mar 2017) $*/

CREATE OR REPLACE PACKAGE pk_vwr_checklist_api IS

    FUNCTION EXECUTE
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_api_name   IN VARCHAR2,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

END pk_vwr_checklist_api;
/
