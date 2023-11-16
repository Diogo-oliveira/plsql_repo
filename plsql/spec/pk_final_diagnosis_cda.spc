/*-- Last Change Revision: $Rev: 2028698 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:24 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE pk_final_diagnosis_cda AS

    -- Author  : JOEL.LOPES
    -- Created : 12/26/2013 10:50:50 AM
    -- Purpose : Package that should contain all functions/procedures for CDA

    /*/**********************************************************************************************
    * List all diagnosis registered in an episode
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param i_criteria               search criteria
    * @param i_format_text            
    *
    * @return                         Diagnoses list
    *
    * @author                               Joel Lopes
    * @version                              2.6.3
    * @since                                27-12-2013
    **********************************************************************************************/
    FUNCTION get_final_diagnosis_cda
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_pat               IN pat_history_diagnosis.id_patient%TYPE,
        i_id_scope          IN NUMBER,
        i_flg_visit_or_epis IN VARCHAR2
    ) RETURN t_coll_episode_diagnosis_cda;

END pk_final_diagnosis_cda;
/
