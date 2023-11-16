CREATE OR REPLACE TRIGGER "B_I_P1_TRACKING"
		BEFORE INSERT ON p1_tracking
    REFERENCING OLD AS old NEW AS new
    FOR EACH ROW
DECLARE
    -- Variables
    l_track_old_row p1_tracking%ROWTYPE;
    l_track_new_row p1_tracking%ROWTYPE;
    l_event         PLS_INTEGER;
    l_trigger_name  VARCHAR2(200 CHAR);
BEGIN
    -- initializing vars
    l_trigger_name := 'B_I_P1_TRACKING';

    -- getting event
    CASE
        WHEN inserting THEN
            l_event := pk_ref_constant.g_insert_event;
        WHEN updating THEN
            l_event := pk_ref_constant.g_update_event;
        WHEN deleting THEN
            l_event := pk_ref_constant.g_delete_event;
        ELSE
            pk_alertlog.log_error(l_trigger_name || ' invalid event');
    END CASE;

    -- old not set

    -- new
    l_track_new_row.id_tracking         := :new.id_tracking;
    l_track_new_row.ext_req_status      := :new.ext_req_status;
    l_track_new_row.id_external_request := :new.id_external_request;
    l_track_new_row.id_institution      := :new.id_institution;
    l_track_new_row.id_professional     := :new.id_professional;
    l_track_new_row.flg_type            := :new.flg_type;
    l_track_new_row.id_prof_dest        := :new.id_prof_dest;
    l_track_new_row.id_dep_clin_serv    := :new.id_dep_clin_serv;
    l_track_new_row.round_id            := :new.round_id;
    l_track_new_row.reason_code         := :new.reason_code;
    l_track_new_row.flg_reschedule      := :new.flg_reschedule;
    l_track_new_row.flg_subtype         := :new.flg_subtype;
    l_track_new_row.decision_urg_level  := :new.decision_urg_level;
    l_track_new_row.dt_tracking_tstz    := :new.dt_tracking_tstz;
    l_track_new_row.id_reason_code      := :new.id_reason_code;
    l_track_new_row.id_schedule         := :new.id_schedule;
    l_track_new_row.id_inst_dest        := :new.id_inst_dest;
    l_track_new_row.id_workflow_action  := :new.id_workflow_action;

    pk_api_ref_event.set_tracking(i_event         => l_event,
                                  i_track_old_row => l_track_old_row,
                                  i_track_new_row => l_track_new_row);

EXCEPTION
    WHEN OTHERS THEN
        pk_alertlog.log_error('ERROR IN ' || l_trigger_name || ' / ' || ' ID_REF=' ||
                              l_track_new_row.id_external_request || ' SQLERRM=' || SQLERRM);
END;
/
