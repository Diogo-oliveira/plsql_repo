CREATE OR REPLACE TRIGGER "B_IU_DOC_COMMENTS"
    BEFORE INSERT OR UPDATE OF flg_cancel ON doc_comments
    REFERENCING OLD AS OLD NEW AS NEW
		FOR EACH ROW
DECLARE
    -- Variables
    l_doccom_old_row doc_comments%ROWTYPE;
    l_doccom_new_row doc_comments%ROWTYPE;
    l_id_language    language.id_language%TYPE;
    l_prof           profissional;
    l_event          PLS_INTEGER;
    l_trigger_name   VARCHAR2(200 CHAR);
BEGIN

    -- this trigger is used only for referral documents

    -- initializing vars
    l_trigger_name := 'B_IU_DOC_COMMENTS';
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
    l_doccom_old_row.id_doc_comment  := :old.id_doc_comment;
    l_doccom_old_row.id_doc_external := :old.id_doc_external;
    l_doccom_old_row.id_doc_image    := :old.id_doc_image;
    l_doccom_old_row.desc_comment    := :old.desc_comment;
    l_doccom_old_row.flg_type        := :old.flg_type;
    l_doccom_old_row.dt_comment      := :old.dt_comment;
    l_doccom_old_row.id_professional := :old.id_professional;
    l_doccom_old_row.flg_cancel      := :old.flg_cancel;
    l_doccom_old_row.dt_cancel       := :old.dt_cancel;
    l_doccom_old_row.id_prof_cancel  := :old.id_prof_cancel;
    l_doccom_old_row.adw_last_update := :old.adw_last_update;

    -- new
    pk_alertlog.log_debug(l_trigger_name || ' / new');
    l_doccom_new_row.id_doc_comment  := :new.id_doc_comment;
    l_doccom_new_row.id_doc_external := :new.id_doc_external;
    l_doccom_new_row.id_doc_image    := :new.id_doc_image;
    l_doccom_new_row.desc_comment    := :new.desc_comment;
    l_doccom_new_row.flg_type        := :new.flg_type;
    l_doccom_new_row.dt_comment      := :new.dt_comment;
    l_doccom_new_row.id_professional := :new.id_professional;
    l_doccom_new_row.flg_cancel      := :new.flg_cancel;
    l_doccom_new_row.dt_cancel       := :new.dt_cancel;
    l_doccom_new_row.id_prof_cancel  := :new.id_prof_cancel;
    l_doccom_new_row.adw_last_update := :new.adw_last_update;

    pk_api_ref_event.set_doc_comments(i_lang           => l_id_language,
                                      i_prof           => l_prof,
                                      i_event          => l_event,
                                      i_doccom_old_row => l_doccom_old_row,
                                      i_doccom_new_row => l_doccom_new_row);
EXCEPTION
    WHEN OTHERS THEN
        pk_alertlog.log_error('ERROR IN ' || l_trigger_name || ' / DOC_EXTERNAL=' || l_doccom_new_row.id_doc_external ||
                              ' ID_DOC_COMMENT=' || l_doccom_new_row.id_doc_comment || ' SQLERRM=' || SQLERRM);
END;
/
