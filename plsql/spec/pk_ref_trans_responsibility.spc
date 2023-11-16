/*-- Last Change Revision: $Rev: 2028916 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_trans_responsibility IS

    -- Author  : FILIPE.SOUSA
    -- Created : 06-09-2010 15:23:43
    -- Purpose : update/insert REF_TRANS_RESPONSIBILITY

    /**
    * Get hand off record
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Professional id, institution and software
    * @param   i_id_trans_resp Hand off identifier 
    * @param   o_rec           Hand off record
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   30-05-2013
    */
    FUNCTION get_trans_resp_row
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_trans_resp IN ref_trans_responsibility.id_trans_resp%TYPE,
        o_row           OUT ref_trans_responsibility%ROWTYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get active hand off record
    *
    * @param   i_lang                         Language associated to the professional executing the request
    * @param   i_prof                         Professional id, institution and software
    * @param   i_id_external_request          Referral identifier 
    * @param   o_rec                          Hand off record
    * @param   o_error                        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-06-2013
    */
    FUNCTION get_active_trans_resp_row
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN ref_trans_responsibility.id_external_request%TYPE,
        o_row                 OUT ref_trans_responsibility%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-09-2010
    */
    PROCEDURE ins
    (
        id_trans_resp_in        IN ref_trans_responsibility.id_trans_resp%TYPE,
        id_status_in            IN ref_trans_responsibility.id_status%TYPE DEFAULT NULL,
        id_workflow_in          IN ref_trans_responsibility.id_workflow%TYPE DEFAULT NULL,
        id_external_request_in  IN ref_trans_responsibility.id_external_request%TYPE DEFAULT NULL,
        id_prof_ref_owner_in    IN ref_trans_responsibility.id_prof_ref_owner%TYPE DEFAULT NULL,
        id_prof_transf_owner_in IN ref_trans_responsibility.id_prof_transf_owner%TYPE DEFAULT NULL,
        id_prof_dest_in         IN ref_trans_responsibility.id_prof_dest%TYPE DEFAULT NULL,
        id_professional_in      IN ref_trans_responsibility.id_professional%TYPE DEFAULT NULL,
        id_institution_in       IN ref_trans_responsibility.id_institution%TYPE DEFAULT NULL,
        dt_created_in           IN ref_trans_responsibility.dt_created%TYPE DEFAULT NULL,
        id_reason_code_in       IN ref_trans_responsibility.id_reason_code%TYPE DEFAULT NULL,
        reason_code_text_in     IN ref_trans_responsibility.reason_code_text%TYPE DEFAULT NULL,
        flg_active_in           IN ref_trans_responsibility.flg_active%TYPE DEFAULT NULL,
        notes_in                IN ref_trans_responsibility.notes%TYPE DEFAULT NULL,
        id_inst_orig_tr_in      IN ref_trans_responsibility.id_inst_orig_tr%TYPE DEFAULT NULL,
        id_inst_dest_tr_in      IN ref_trans_responsibility.id_inst_dest_tr%TYPE DEFAULT NULL,
        id_workflow_action_in   IN ref_trans_resp_hist.id_workflow_action%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE
    );

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-09-2010
    */
    PROCEDURE upd
    (
        id_trans_resp_in        IN ref_trans_responsibility.id_trans_resp%TYPE,
        id_status_in            IN ref_trans_responsibility.id_status%TYPE DEFAULT NULL,
        id_workflow_in          IN ref_trans_responsibility.id_workflow%TYPE DEFAULT NULL,
        id_external_request_in  IN ref_trans_responsibility.id_external_request%TYPE DEFAULT NULL,
        id_prof_ref_owner_in    IN ref_trans_responsibility.id_prof_ref_owner%TYPE DEFAULT NULL,
        id_prof_transf_owner_in IN ref_trans_responsibility.id_prof_transf_owner%TYPE DEFAULT NULL,
        id_prof_dest_in         IN ref_trans_responsibility.id_prof_dest%TYPE DEFAULT NULL,
        id_prof_dest_nin        IN BOOLEAN := TRUE,
        dt_update_in            IN ref_trans_responsibility.dt_update%TYPE DEFAULT NULL,
        id_reason_code_in       IN ref_trans_responsibility.id_reason_code%TYPE DEFAULT NULL,
        reason_code_text_in     IN ref_trans_responsibility.reason_code_text%TYPE DEFAULT NULL,
        flg_active_in           IN ref_trans_responsibility.flg_active%TYPE DEFAULT NULL,
        notes_in                IN ref_trans_responsibility.notes%TYPE DEFAULT NULL,
        notes_nin               IN BOOLEAN := TRUE,
        id_professional_in      IN ref_trans_responsibility.id_professional%TYPE DEFAULT NULL,
        id_institution_in       IN ref_trans_responsibility.id_institution%TYPE DEFAULT NULL,
        id_workflow_action_in IN wf_workflow_action.id_workflow_action%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE
    );

    /**
    * <Function description>
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   <Parameter>    <Parameter usage description>
    *
    * @author  FILIPE.SOUSA
    * @version <Product Version>
    * @since   06-09-2010
    */
    PROCEDURE upd_by_id_external_request
    (
        --id_status_in            IN ref_trans_responsibility.id_status%TYPE DEFAULT NULL,
        --id_workflow_in          IN ref_trans_responsibility.id_workflow%TYPE DEFAULT NULL,
        id_external_request_in  IN ref_trans_responsibility.id_external_request%TYPE,
        --id_prof_ref_owner_in    IN ref_trans_responsibility.id_prof_ref_owner%TYPE DEFAULT NULL,
        --id_prof_transf_owner_in IN ref_trans_responsibility.id_prof_transf_owner%TYPE DEFAULT NULL,
        --id_prof_dest_in         IN ref_trans_responsibility.id_prof_dest%TYPE DEFAULT NULL,
        dt_update_in            IN ref_trans_responsibility.dt_update%TYPE DEFAULT NULL,
        --id_reason_code_in       IN ref_trans_responsibility.id_reason_code%TYPE DEFAULT NULL,
        --reason_code_text_in     IN ref_trans_responsibility.reason_code_text%TYPE DEFAULT NULL,
        flg_active_in           IN ref_trans_responsibility.flg_active%TYPE DEFAULT NULL,
        --notes_in                IN ref_trans_responsibility.notes%TYPE DEFAULT NULL,
        id_professional_in      IN ref_trans_responsibility.id_professional%TYPE DEFAULT NULL,
        id_institution_in       IN ref_trans_responsibility.id_institution%TYPE DEFAULT NULL,
        --id_inst_orig_in         IN ref_trans_responsibility.id_inst_orig%TYPE DEFAULT NULL,
        id_workflow_action_in IN wf_workflow_action.id_workflow_action%TYPE DEFAULT NULL
        --,handle_error_in         IN BOOLEAN := TRUE
    );

    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN ref_trans_responsibility.id_trans_resp%TYPE;

END pk_ref_trans_responsibility;
/
