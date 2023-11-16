/*-- Last Change Revision: $Rev: 2028917 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_trans_resp_hist IS

    -- Author  : FILIPE.SOUSA
    -- Created : 06-09-2010 16:08:37
    -- Purpose : insert/update REF_TRANS_RESP_HIST

    -- Collection of %ROWTYPE records based on "ref_trans_resp_hist"
    TYPE ref_trans_resp_hist_tc IS TABLE OF ref_trans_resp_hist%ROWTYPE INDEX BY BINARY_INTEGER;
    TYPE ref_trans_resp_hist_ntt IS TABLE OF ref_trans_resp_hist%ROWTYPE;
    --TYPE ref_trans_resp_hist_vat IS VARRAY(100) OF ref_trans_resp_hist%ROWTYPE;

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
        id_trans_resp_hist_in   IN ref_trans_resp_hist.id_trans_resp_hist%TYPE,
        id_trans_resp_in        IN ref_trans_resp_hist.id_trans_resp%TYPE DEFAULT NULL,
        id_status_in            IN ref_trans_resp_hist.id_status%TYPE DEFAULT NULL,
        id_workflow_in          IN ref_trans_resp_hist.id_workflow%TYPE DEFAULT NULL,
        id_external_request_in  IN ref_trans_resp_hist.id_external_request%TYPE DEFAULT NULL,
        id_prof_ref_owner_in    IN ref_trans_resp_hist.id_prof_ref_owner%TYPE DEFAULT NULL,
        id_prof_transf_owner_in IN ref_trans_resp_hist.id_prof_transf_owner%TYPE DEFAULT NULL,
        id_prof_dest_in         IN ref_trans_resp_hist.id_prof_dest%TYPE DEFAULT NULL,
        id_professional_in      IN ref_trans_resp_hist.id_professional%TYPE DEFAULT NULL,
        id_institution_in       IN ref_trans_resp_hist.id_institution%TYPE DEFAULT NULL,
        dt_created_in           IN ref_trans_resp_hist.dt_created%TYPE DEFAULT NULL,
        id_reason_code_in       IN ref_trans_resp_hist.id_reason_code%TYPE DEFAULT NULL,
        reason_code_text_in     IN ref_trans_resp_hist.reason_code_text%TYPE DEFAULT NULL,
        flg_active_in           IN ref_trans_resp_hist.flg_active%TYPE DEFAULT NULL,
        notes_in                IN ref_trans_resp_hist.notes%TYPE DEFAULT NULL,
        id_inst_orig_tr_in      IN ref_trans_resp_hist.id_inst_orig_tr%TYPE DEFAULT NULL,
        id_inst_dest_tr_in      IN ref_trans_resp_hist.id_inst_dest_tr%TYPE DEFAULT NULL,
        id_workflow_action_in   IN ref_trans_resp_hist.id_workflow_action%TYPE DEFAULT NULL,
        handle_error_in         IN BOOLEAN := TRUE
    );

    /**
    * Inserts the entire record into table ref_trans_resp_hist
    *
    * @param   rec_in          record data
    * @param   handle_error_in error treatment
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   05-06-2013
    */
    PROCEDURE ins
    (
        rec_in          IN ref_trans_resp_hist%ROWTYPE,
        handle_error_in         IN BOOLEAN := TRUE
    );

    FUNCTION next_key(sequence_in IN VARCHAR2 := NULL) RETURN ref_trans_resp_hist.id_trans_resp_hist%TYPE;
END pk_ref_trans_resp_hist;
/
