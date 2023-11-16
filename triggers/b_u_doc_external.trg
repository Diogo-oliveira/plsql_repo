CREATE OR REPLACE TRIGGER "B_U_DOC_EXTERNAL"
    BEFORE UPDATE OF flg_status ON doc_external
    REFERENCING OLD AS OLD NEW AS NEW
		FOR EACH ROW
DECLARE
    -- Variables
    l_docext_old_row doc_external%ROWTYPE;
    l_docext_new_row doc_external%ROWTYPE;
    l_id_language    language.id_language%TYPE;
    l_prof           profissional;
    l_event          PLS_INTEGER;
    l_trigger_name   VARCHAR2(200 CHAR);
BEGIN

    -- this trigger is used only for referral documents
    IF :new.id_external_request IS NOT NULL
    THEN
    
        -- initializing vars
        l_trigger_name := 'B_U_DOC_EXTERNAL';
        l_id_language  := 1;
        l_prof         := profissional(NULL, NULL, 4);
    
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
    
        -- old
        pk_alertlog.log_debug(l_trigger_name || ' / old');
        l_docext_old_row.id_doc_external             := :old.id_doc_external;
        l_docext_old_row.id_doc_type                 := :old.id_doc_type;
        l_docext_old_row.num_doc                     := :old.num_doc;
        l_docext_old_row.dt_emited                   := :old.dt_emited;
        l_docext_old_row.notes                       := :old.notes;
        l_docext_old_row.dt_digit                    := :old.dt_digit;
        l_docext_old_row.id_doc_ori_type             := :old.id_doc_ori_type;
        l_docext_old_row.id_doc_destination          := :old.id_doc_destination;
        l_docext_old_row.dt_expire                   := :old.dt_expire;
        l_docext_old_row.id_external_request         := :old.id_external_request;
        l_docext_old_row.desc_doc_type               := :old.desc_doc_type;
        l_docext_old_row.desc_doc_ori_type           := :old.desc_doc_ori_type;
        l_docext_old_row.desc_doc_destination        := :old.desc_doc_destination;
        l_docext_old_row.id_episode                  := :old.id_episode;
        l_docext_old_row.id_patient                  := :old.id_patient;
        l_docext_old_row.flg_status                  := :old.flg_status;
        l_docext_old_row.local_emited                := :old.local_emited;
        l_docext_old_row.id_institution              := :old.id_institution;
        l_docext_old_row.flg_sent_by                 := :old.flg_sent_by;
        l_docext_old_row.flg_received                := :old.flg_received;
        l_docext_old_row.id_doc_original             := :old.id_doc_original;
        l_docext_old_row.desc_doc_original           := :old.desc_doc_original;
        l_docext_old_row.id_professional             := :old.id_professional;
        l_docext_old_row.title                       := :old.title;
        l_docext_old_row.dt_inserted                 := :old.dt_inserted;
        l_docext_old_row.dt_updated                  := :old.dt_updated;
        l_docext_old_row.id_professional_upd         := :old.id_professional_upd;
        l_docext_old_row.id_prof_perf_by             := :old.id_prof_perf_by;
        l_docext_old_row.desc_perf_by                := :old.desc_perf_by;
        l_docext_old_row.id_grupo                    := :old.id_grupo;
        l_docext_old_row.dt_last_identification      := :old.dt_last_identification;
        l_docext_old_row.organ_shipper               := :old.organ_shipper;
    
        -- new
        pk_alertlog.log_debug(l_trigger_name || ' / new');
        l_docext_new_row.id_doc_external             := :new.id_doc_external;
        l_docext_new_row.id_doc_type                 := :new.id_doc_type;
        l_docext_new_row.num_doc                     := :new.num_doc;
        l_docext_new_row.dt_emited                   := :new.dt_emited;
        l_docext_new_row.notes                       := :new.notes;
        l_docext_new_row.dt_digit                    := :new.dt_digit;
        l_docext_new_row.id_doc_ori_type             := :new.id_doc_ori_type;
        l_docext_new_row.id_doc_destination          := :new.id_doc_destination;
        l_docext_new_row.dt_expire                   := :new.dt_expire;
        l_docext_new_row.id_external_request         := :new.id_external_request;
        l_docext_new_row.desc_doc_type               := :new.desc_doc_type;
        l_docext_new_row.desc_doc_ori_type           := :new.desc_doc_ori_type;
        l_docext_new_row.desc_doc_destination        := :new.desc_doc_destination;
        l_docext_new_row.id_episode                  := :new.id_episode;
        l_docext_new_row.id_patient                  := :new.id_patient;
        l_docext_new_row.flg_status                  := :new.flg_status;
        l_docext_new_row.local_emited                := :new.local_emited;
        l_docext_new_row.id_institution              := :new.id_institution;
        l_docext_new_row.flg_sent_by                 := :new.flg_sent_by;
        l_docext_new_row.flg_received                := :new.flg_received;
        l_docext_new_row.id_doc_original             := :new.id_doc_original;
        l_docext_new_row.desc_doc_original           := :new.desc_doc_original;
        l_docext_new_row.id_professional             := :new.id_professional;
        l_docext_new_row.title                       := :new.title;
        l_docext_new_row.dt_inserted                 := :new.dt_inserted;
        l_docext_new_row.dt_updated                  := :new.dt_updated;
        l_docext_new_row.id_professional_upd         := :new.id_professional_upd;
        l_docext_new_row.id_prof_perf_by             := :new.id_prof_perf_by;
        l_docext_new_row.desc_perf_by                := :new.desc_perf_by;
        l_docext_new_row.id_grupo                    := :new.id_grupo;
        l_docext_new_row.dt_last_identification      := :new.dt_last_identification;
        l_docext_new_row.organ_shipper               := :new.organ_shipper;
    
        pk_api_ref_event.set_doc_external(i_lang           => l_id_language,
                                          i_prof           => l_prof,
                                          i_event          => l_event,
                                          i_docext_old_row => l_docext_old_row,
                                          i_docext_new_row => l_docext_new_row);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        pk_alertlog.log_error('ERROR IN ' || l_trigger_name || ' / ID_REF=' || l_docext_new_row.id_external_request ||
                              ' ID_DOC_EXTERNAL=' || l_docext_new_row.id_doc_external || ' SQLERRM=' || SQLERRM);
END;
/
