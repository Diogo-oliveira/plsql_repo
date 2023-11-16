/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/
CREATE OR REPLACE PACKAGE pk_immunization_api IS

    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    g_package_name  VARCHAR2(32) := pk_alertlog.who_am_i();
    g_package_owner VARCHAR2(32) := 'ALERT';

    --Variáveis globais do package
    --
    g_found BOOLEAN;
    g_error VARCHAR2(2000);

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_exception EXCEPTION;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
END pk_immunization_api;
/
