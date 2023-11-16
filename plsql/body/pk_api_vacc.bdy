/*-- Last Change Revision: $Rev: 2026748 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_vacc IS

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
    ) RETURN BOOLEAN IS
    
        l_result       BOOLEAN := FALSE;
        l_dt_begin_str VARCHAR(200);
    BEGIN
        g_error := 'CREATE PRESCRIPTION';
    
        l_dt_begin_str := pk_date_utils.date_send_tsz(i_lang,
                                                      i_rec_vaccine.i_dt_begin_str,
                                                      profissional(i_rec_patient.id_professional,
                                                                   i_rec_patient.id_institution,
                                                                   i_rec_patient.id_software));
    
        l_result := pk_vacc.set_pat_vacc_adm_pfh(i_lang         => i_lang,
                                                 i_prof         => profissional(i_rec_patient.id_professional,
                                                                                i_rec_patient.id_institution,
                                                                                i_rec_patient.id_software),
                                                 i_id_patient   => i_rec_patient.id_patient,
                                                 i_vacc         => i_rec_vaccine.i_vacc,
                                                 i_dt_begin_str => l_dt_begin_str,
                                                 i_desc_vaccine => i_rec_vaccine.i_desc_vaccine,
                                                 i_lot_number   => i_rec_vaccine.i_lot_number,
                                                 o_error        => o_error);
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'PRESC_VACC_PHF',
                                                     o_error);
    END;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
    g_owner   := 'ALERT';
    g_package := 'PK_API_VACC';

END pk_api_vacc;
/
