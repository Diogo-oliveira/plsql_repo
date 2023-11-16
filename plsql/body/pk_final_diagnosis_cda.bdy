/*-- Last Change Revision: $Rev: 2027160 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:20 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE BODY pk_final_diagnosis_cda IS

    --Package Info
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_exception EXCEPTION;
    g_diagnosis_type_final CONSTANT VARCHAR2(1) := 'D';

    /**********************************************************************************************
    * List all diagnosis registered in an episode
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    
    *
    * @return                         Diagnoses list
    *
    * @author                               Joel Lopes
    * @version                              2.6.3
    * @since                                26-12-2013
    **********************************************************************************************/
    FUNCTION get_final_diagnosis_cda
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_pat               IN pat_history_diagnosis.id_patient%TYPE,
        i_id_scope          IN NUMBER,
        i_flg_visit_or_epis IN VARCHAR2
    ) RETURN t_coll_episode_diagnosis_cda IS
    
        l_diagnosis t_coll_episode_diagnosis_cda;
        l_error     t_error_out;
    
    BEGIN
    
        l_diagnosis := pk_diagnosis_core.tb_get_epis_diagnosis_cda(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_pat               => i_pat,
                                                                   i_episode           => i_id_scope,
                                                                   i_flg_type          => g_diagnosis_type_final,
                                                                   i_criteria          => NULL,
                                                                   i_format_text       => NULL,
                                                                   i_flg_visit_or_epis => i_flg_visit_or_epis);
    
        RETURN l_diagnosis;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_FINAL_DIAGNOSIS_CDA',
                                              l_error);
            RETURN l_diagnosis;
        
    END get_final_diagnosis_cda;

END pk_final_diagnosis_cda;
/
