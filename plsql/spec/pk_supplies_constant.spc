/*-- Last Change Revision: $Rev: 2028994 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_supplies_constant IS

    g_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no  CONSTANT VARCHAR2(1 CHAR) := 'N';

    -- supply_request.flg_status
    g_srt_requested CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_srt_cancelled CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_srt_ongoing   CONSTANT VARCHAR2(1 CHAR) := 'O';
    g_srt_completed CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_srt_draft     CONSTANT VARCHAR2(1 CHAR) := 'Z';

    -- supply_workflow.flg_status
    g_sww_request_local            CONSTANT supply_workflow.flg_status%TYPE := 'A';
    g_sww_request_central          CONSTANT supply_workflow.flg_status%TYPE := 'S';
    g_sww_rejected_pharmacist      CONSTANT supply_workflow.flg_status%TYPE := 'J';
    g_sww_prepared_pharmacist      CONSTANT supply_workflow.flg_status%TYPE := 'H';
    g_sww_validated                CONSTANT supply_workflow.flg_status%TYPE := 'V';
    g_sww_prepared_technician      CONSTANT supply_workflow.flg_status%TYPE := 'E';
    g_sww_rejected_technician      CONSTANT supply_workflow.flg_status%TYPE := 'Y';
    g_sww_in_transit               CONSTANT supply_workflow.flg_status%TYPE := 'T';
    g_sww_transport_concluded      CONSTANT supply_workflow.flg_status%TYPE := 'P';
    g_sww_loaned                   CONSTANT supply_workflow.flg_status%TYPE := 'L';
    g_sww_consumed                 CONSTANT supply_workflow.flg_status%TYPE := 'O';
    g_sww_deliver_needed           CONSTANT supply_workflow.flg_status%TYPE := 'N';
    g_sww_in_delivery              CONSTANT supply_workflow.flg_status%TYPE := 'I';
    g_sww_deliver_concluded        CONSTANT supply_workflow.flg_status%TYPE := 'F';
    g_sww_deliver_validated        CONSTANT supply_workflow.flg_status%TYPE := 'DV';
    g_sww_cancelled                CONSTANT supply_workflow.flg_status%TYPE := 'C';
    g_sww_transport_done           CONSTANT supply_workflow.flg_status%TYPE := 'D';
    g_sww_consumed_delivery_needed CONSTANT supply_workflow.flg_status%TYPE := 'M';
    g_sww_request_wait             CONSTANT supply_workflow.flg_status%TYPE := 'Z';
    g_sww_request_external_system  CONSTANT supply_workflow.flg_status%TYPE := 'W';
    g_sww_mismatch                 CONSTANT supply_workflow.flg_status%TYPE := 'M';
    g_sww_deliver_institution      CONSTANT supply_workflow.flg_status%TYPE := 'G'; --deliver to the institution concludes
    g_sww_all_consumed             CONSTANT supply_workflow.flg_status%TYPE := 'X'; --Dummy status for partial consumption
    g_sww_no_stock                 CONSTANT supply_workflow.flg_status%TYPE := 'M';

    --cancelled deliveries
    g_sww_deliver_cancelled CONSTANT supply_workflow.flg_status%TYPE := 'Q';
    g_sww_prep_sup_for_surg CONSTANT supply_workflow.flg_status%TYPE := 'B'; --prepare supplies for surgery
    g_sww_cons_and_count    CONSTANT supply_workflow.flg_status%TYPE := 'K'; --Consume and count supplies for surgery
    g_sww_predefined        CONSTANT supply_workflow.flg_status%TYPE := 'R'; -- predefined (used in order sets)
    g_sww_updated           CONSTANT supply_workflow.flg_status%TYPE := 'U'; -- updated by context functionality

    -- supply_workflow.flg_outdated
    g_sww_active   CONSTANT supply_workflow.flg_outdated%TYPE := 'A';
    g_sww_edited   CONSTANT supply_workflow.flg_outdated%TYPE := 'E';
    g_sww_outdated CONSTANT supply_workflow.flg_outdated%TYPE := 'O';

    g_wfs_req_local_stock CONSTANT wf_status.id_status%TYPE := 25;

    -- supply_loc_institution.flg_stock_type
    g_supply_central_stock CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_supply_local_stock   CONSTANT VARCHAR2(1 CHAR) := 'L';

    -- consumption type
    g_consumption_type_loan    CONSTANT VARCHAR2(1 CHAR) := 'L';
    g_consumption_type_local   CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_consumption_type_implant CONSTANT VARCHAR2(1 CHAR) := 'I';

    -- supply_location.flg_cat_workflow
    g_supply_cat_workflow_l CONSTANT supply_location.flg_cat_workflow%TYPE := 'L'; --local
    g_supply_cat_workflow_f CONSTANT supply_location.flg_cat_workflow%TYPE := 'F'; --pharmacy
    g_supply_cat_workflow_t CONSTANT supply_location.flg_cat_workflow%TYPE := 'T'; --laboratory

    -- supply mismatch
    g_icon_supply_mismatch CONSTANT VARCHAR(20 CHAR) := 'AttencionIcon';

    -- Supply types
    g_supply_kit_type       CONSTANT VARCHAR2(1 CHAR) := 'K';
    g_supply_set_type       CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_supply_type           CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_act_ther_supply       CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_supply_equipment_type CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_supply_implant_type   CONSTANT VARCHAR2(1 CHAR) := 'P';

    -- id_workflow
    g_id_workflow    wf_workflow.id_workflow%TYPE := 7;
    g_id_workflow_sr wf_workflow.id_workflow%TYPE := 12;
    g_id_workflow_at wf_workflow.id_workflow%TYPE := pk_act_therap_constant.g_id_workflow;

    -- supply reason type
    g_reason_request    supply_reason.flg_type%TYPE := 'R';
    g_reason_deliver    supply_reason.flg_type%TYPE := 'D';
    g_reason_return_sr  supply_reason.flg_type%TYPE := 'S';
    g_reason_request_sr supply_reason.flg_type%TYPE := 'Q';

    -- supply contexts
    g_context_supplies CONSTANT supply_workflow.flg_context%TYPE := 'I';

    g_context_procedure_req       CONSTANT supply_workflow.flg_context%TYPE := 'P';
    g_context_procedure_exec      CONSTANT supply_workflow.flg_context%TYPE := 'Q';
    g_context_procedure_exec_edit CONSTANT supply_workflow.flg_context%TYPE := 'E';

    g_context_medication     CONSTANT supply_workflow.flg_context%TYPE := 'M';
    g_context_pharm_dispense CONSTANT supply_workflow.flg_context%TYPE := 'D';
    g_context_surgery        CONSTANT supply_workflow.flg_context%TYPE := 'S'; --surgery    

    g_context_nic_activity      CONSTANT supply_workflow.flg_context%TYPE := 'N';
    g_context_nic_activity_exec CONSTANT supply_workflow.flg_context%TYPE := 'N';

    -- supply_area
    g_area_supplies          CONSTANT supply_area.id_supply_area%TYPE := 1; --Supplies deepnav
    g_area_activity_therapy  CONSTANT supply_area.id_supply_area%TYPE := 2; --Activity therapist profile
    g_area_surgical_supplies CONSTANT supply_area.id_supply_area%TYPE := 3; --Surgical supplies deepnav

    -- Supply location
    g_pharmacy_location CONSTANT supply_location.id_supply_location%TYPE := 1000;

    -- icon used when there're requisition for warehouse or local stock and the surgery date isn't defined
    g_icon_waiting_req CONSTANT wf_status_config.icon%TYPE := 'SuppliesWaitingReqIcon';

    g_pharmacist category.id_category%TYPE := 7;
    g_ancillary  category.id_category%TYPE := 6;

    g_flg_status_can_cancel table_varchar := table_varchar(g_sww_request_local, g_sww_request_central);

    g_flg_status_cannot_cancel table_varchar := table_varchar(g_sww_prepared_pharmacist,
                                                              g_sww_validated,
                                                              g_sww_prepared_technician,
                                                              g_sww_rejected_technician,
                                                              g_sww_in_transit,
                                                              g_sww_transport_concluded,
                                                              g_sww_loaned,
                                                              g_sww_consumed,
                                                              g_sww_deliver_needed,
                                                              g_sww_in_delivery,
                                                              g_sww_deliver_concluded,
                                                              g_sww_transport_done,
                                                              g_sww_consumed_delivery_needed,
                                                              g_sww_rejected_pharmacist,
                                                              g_sww_prep_sup_for_surg,
                                                              g_sww_cons_and_count,
                                                              g_sww_cancelled);

    -- desc separators
    g_str_separator CONSTANT VARCHAR2(5 CHAR) := '; ';
    g_str_sep_space CONSTANT VARCHAR2(5 CHAR) := ' ';
    g_semicolon     CONSTANT VARCHAR2(1 CHAR) := ';';
    g_cancel_sup_status table_varchar := table_varchar(pk_supplies_constant.g_sww_cancelled);
    g_dashes CONSTANT VARCHAR2(2 CHAR) := '--';

END pk_supplies_constant;
/
