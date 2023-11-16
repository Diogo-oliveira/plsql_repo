/*-- Last Change Revision: $Rev: 2028501 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_vacc IS

    -- Author  : Pedro Teixeira
    -- Created : 17-07-2009
    -- Purpose : API for Vaccine managment

    -- Types nedded to fill information
    TYPE rec_vacc IS RECORD(
        i_vacc         vacc.id_vacc%TYPE,
        i_dt_begin_str pat_vacc_adm_det.dt_take%TYPE,
        i_desc_vaccine pat_vacc_adm_det.desc_vaccine%TYPE,
        i_lot_number   pat_vacc_adm_det.lot_number%TYPE);

    /************************************************************************************************************
    *  Esta função permite registar o histórico das vacinas de uma paciente.
    *  O objectivo é criar no Alert© a informação das vacinas que foram tomadas 
    *  por um paciente em locais onde não é utilizado o Alert©.
    *
    * @param i_lang                        default language
    * @param i_rec_patient                 Registo dos dados do paciente
    * @param i_rec_vaccine                 Registo de administração de uma vacina
    * @param o_error                       error message
    *
    * @revision                            Pedro Teixeira 
    * @version                             0.2
    * @since                               2009/07/17
    ***********************************************************************************************************/
    FUNCTION presc_vacc_phf
    (
        i_lang        IN language.id_language%TYPE,
        i_rec_patient IN pk_api_patient.rec_patient,
        i_rec_vaccine IN rec_vacc,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**######################################################
      GLOBALS
    ######################################################**/
    g_owner   VARCHAR2(50);
    g_package VARCHAR2(50);
    g_error   VARCHAR2(4000);

END pk_api_vacc;
/
