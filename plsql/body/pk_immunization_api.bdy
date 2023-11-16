/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/
CREATE OR REPLACE PACKAGE BODY pk_immunization_api IS

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    FUNCTION set_cancel_adm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_drug_presc_det   IN drug_presc_det.id_drug_presc_det%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_notes_cancel     IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'SET_CANCEL_ADM';
        l_params               VARCHAR2(1000 CHAR);
        l_id_drug_prescription drug_presc_det.id_drug_prescription%TYPE;
    
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        g_error := 'Call SET_CANCEL_ADM / ' || l_params;
    
        BEGIN
            SELECT id_drug_prescription
              INTO l_id_drug_prescription
              FROM drug_presc_det
             WHERE id_drug_presc_det = i_drug_presc_det;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE g_exception;
        END;
    
        IF NOT pk_immunization_core.set_cancel_adm(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_patient        => i_id_patient,
                                                   i_id_episode        => i_id_episode,
                                                   i_drug_prescription => l_id_drug_prescription,
                                                   i_id_cancel_reason  => i_id_cancel_reason,
                                                   i_notes_cancel      => i_notes_cancel,
                                                   o_error             => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END set_cancel_adm;

    FUNCTION set_vacc_administration
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN drug_prescription.id_episode%TYPE,
        i_pat                 IN patient.id_patient%TYPE,
        i_drug_presc          IN drug_prescription.id_drug_prescription%TYPE,
        i_dt_begin            IN VARCHAR2,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_id_drug             IN drug_presc_det.id_drug%TYPE,
        i_id_vacc             IN vacc.id_vacc%TYPE DEFAULT NULL,
        i_advers_react        IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react  IN drug_presc_plan.notes_advers_react%TYPE,
        i_application_spot    IN drug_presc_plan.application_spot_code%TYPE DEFAULT '',
        i_lot_number          IN drug_presc_plan.lot_number%TYPE,
        i_dt_exp              IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        i_vacc_manuf_desc     IN VARCHAR2,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        i_adm_route           IN VARCHAR2,
        i_vacc_origin         IN vacc_origin.id_vacc_origin%TYPE,
        i_doc_vis             IN vacc_doc_vis.id_vacc_doc_vis%TYPE,
        i_dt_doc_delivery     IN VARCHAR2,
        i_doc_cat             IN vacc_funding_eligibility.id_vacc_funding_elig%TYPE,
        i_doc_source          IN vacc_funding_source.id_vacc_funding_source%TYPE,
        i_order_by            IN professional.id_professional%TYPE,
        i_administer_by       IN professional.id_professional%TYPE,
        i_dt_predicted        IN VARCHAR2,
        i_notes               IN drug_presc_plan.notes%TYPE,
        o_drug_presc_plan     OUT NUMBER,
        o_drug_presc_det      OUT NUMBER,
        o_drug_prescription   OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'SET_VACC_ADMINISTRATION';
    
        l_flg_show   VARCHAR2(10 CHAR);
        l_msg        VARCHAR2(1000 CHAR);
        l_msg_result VARCHAR2(1000 CHAR);
        l_msg_title  VARCHAR2(1000 CHAR);
        l_type_admin VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF NOT pk_immunization_core.set_pat_administration(i_lang                  => i_lang,
                                                           i_episode               => i_episode,
                                                           i_prof                  => i_prof,
                                                           i_pat                   => i_pat,
                                                           i_drug_presc            => i_drug_presc,
                                                           i_dt_begin              => i_dt_begin,
                                                           i_prof_cat_type         => i_prof_cat_type,
                                                           i_id_drug               => i_id_drug,
                                                           i_id_vacc               => i_id_vacc,
                                                           i_advers_react          => i_advers_react,
                                                           i_notes_advers_react    => i_notes_advers_react,
                                                           i_application_spot      => i_application_spot,
                                                           i_application_spot_desc => NULL,
                                                           i_lot_number            => i_lot_number,
                                                           i_dt_exp                => i_dt_exp,
                                                           i_vacc_manuf            => i_vacc_manuf,
                                                           i_vacc_manuf_desc       => i_vacc_manuf_desc,
                                                           i_dosage_admin          => i_dosage_admin,
                                                           i_dosage_unit_measure   => i_dosage_unit_measure,
                                                           i_adm_route             => i_adm_route,
                                                           i_vacc_origin           => i_vacc_origin,
                                                           i_vacc_origin_desc      => NULL,
                                                           i_doc_vis               => i_doc_vis,
                                                           i_doc_vis_desc          => NULL,
                                                           i_dt_doc_delivery       => i_dt_doc_delivery,
                                                           i_doc_cat               => i_doc_cat,
                                                           i_doc_source            => i_doc_source,
                                                           i_doc_source_desc       => NULL,
                                                           i_order_by              => i_order_by,
                                                           i_order_desc            => NULL,
                                                           i_administer_by         => i_administer_by,
                                                           i_administer_desc       => NULL,
                                                           i_dt_predicted          => i_dt_predicted,
                                                           i_notes                 => i_notes,
                                                           o_drug_presc_plan       => o_drug_presc_plan,
                                                           o_drug_presc_det        => o_drug_presc_det,
                                                           o_flg_show              => l_flg_show,
                                                           o_msg                   => l_msg,
                                                           o_msg_result            => l_msg_result,
                                                           o_msg_title             => l_msg_title,
                                                           o_type_admin            => l_type_admin,
                                                           o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF o_drug_presc_det IS NOT NULL
        THEN
            BEGIN
                SELECT id_drug_prescription
                  INTO o_drug_prescription
                  FROM drug_presc_det
                 WHERE id_drug_presc_det = o_drug_presc_det;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE g_exception;
            END;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END set_vacc_administration;

/*


declare
  -- Boolean parameters are translated from/to integers: 
  -- 0/1/null <--> false/true/null 
  result boolean;
  -- Non-scalar parameters require additional processing 
  i_prof profissional := profissional(247034,50002,1);
  o_error t_error_out;
begin
  
--  [2,1763023,[247034,50002,1],69675450050002,null,"20171021061814","N","90681",6010,null,
--  "","O","Oral","","",null,"",1,"10012","OR",null,"",null,"","20171021061814",null,null,"",
--  247034,"Louise Marie Mackenstein, RN",null,"","20180219051814",""]


  -- Call the function
  result := pk_immunization_ux.set_pat_administration(i_lang => :i_lang,
                                                      i_episode => :i_episode,
                                                      i_prof => i_prof,
                                                      i_pat => :i_pat,
                                                      i_drug_presc => :i_drug_presc,
                                                      i_dt_begin => :i_dt_begin,
                                                      i_prof_cat_type => :i_prof_cat_type,
                                                      i_id_drug => :i_id_drug,
                                                      i_id_vacc => :i_id_vacc,
                                                      i_advers_react => :i_advers_react,
                                                      i_notes_advers_react => :i_notes_advers_react,
                                                      i_application_spot => :i_application_spot,
                                                      i_application_spot_desc => :i_application_spot_desc,
                                                      i_lot_number => :i_lot_number,
                                                      i_dt_exp => :i_dt_exp,
                                                      i_vacc_manuf => :i_vacc_manuf,
                                                      i_vacc_manuf_desc => :i_vacc_manuf_desc,
                                                      i_dosage_admin => :i_dosage_admin,
                                                      i_dosage_unit_measure => :i_dosage_unit_measure,
                                                      i_adm_route => :i_adm_route,
                                                      i_vacc_origin => :i_vacc_origin,
                                                      i_vacc_origin_desc => :i_vacc_origin_desc,
                                                      i_doc_vis => :i_doc_vis,
                                                      i_doc_vis_desc => :i_doc_vis_desc,
                                                      i_dt_doc_delivery => :i_dt_doc_delivery,
                                                      i_doc_cat => :i_doc_cat,
                                                      i_doc_source => :i_doc_source,
                                                      i_doc_source_desc => :i_doc_source_desc,
                                                      i_order_by => :i_order_by,
                                                      i_order_desc => :i_order_desc,
                                                      i_administer_by => :i_administer_by,
                                                      i_administer_desc => :i_administer_desc,
                                                      i_dt_predicted => :i_dt_predicted,
                                                      i_notes => :i_notes,
                                                      o_drug_presc_plan => :o_drug_presc_plan,
                                                      o_drug_presc_det => :o_drug_presc_det,
                                                      o_flg_show => :o_flg_show,
                                                      o_msg => :o_msg,
                                                      o_msg_result => :o_msg_result,
                                                      o_msg_title => :o_msg_title,
                                                      o_type_admin => :o_type_admin,
                                                      o_error => o_error);
  -- Convert false/true/null to 0/1/null 
  :result := sys.diutil.bool_to_int(result);
end;


*/

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package_name);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);

END pk_immunization_api;
/
