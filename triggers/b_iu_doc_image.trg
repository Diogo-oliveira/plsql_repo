CREATE OR REPLACE TRIGGER "B_IU_DOC_IMAGE"
    BEFORE INSERT OR UPDATE OF flg_status ON doc_image
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
DECLARE
    -- Variables
    l_docimg_old_row doc_image%ROWTYPE;
    l_docimg_new_row doc_image%ROWTYPE;
    l_id_language    language.id_language%TYPE;
    l_prof           profissional;
    l_event          PLS_INTEGER;
    l_trigger_name   VARCHAR2(200 CHAR);
BEGIN

    -- this trigger is used only for referral documents

    -- initializing vars
    l_trigger_name := 'B_IU_DOC_IMAGE';
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
    l_docimg_old_row.id_doc_image      := :old.id_doc_image;
    l_docimg_old_row.id_doc_external   := :old.id_doc_external;
    l_docimg_old_row.rank              := :old.rank;
    l_docimg_old_row.file_name         := :old.file_name;
    l_docimg_old_row.doc_img           := :old.doc_img;
    l_docimg_old_row.doc_img_thumbnail := :old.doc_img_thumbnail;
    l_docimg_old_row.flg_import        := :old.flg_import;
    l_docimg_old_row.server_file_name  := :old.server_file_name;
    l_docimg_old_row.flg_status        := :old.flg_status;
    l_docimg_old_row.id_professional   := :old.id_professional;
    l_docimg_old_row.flg_img_thumbnail := :old.flg_img_thumbnail;
    l_docimg_old_row.dt_img_tstz       := :old.dt_img_tstz;
    l_docimg_old_row.dt_import_tstz    := :old.dt_import_tstz;
    l_docimg_old_row.dt_cancel         := :old.dt_cancel;
    l_docimg_old_row.id_prof_cancel    := :old.id_prof_cancel;
    l_docimg_old_row.title             := :old.title;

    -- new
    pk_alertlog.log_debug(l_trigger_name || ' / new');
    l_docimg_new_row.id_doc_image      := :new.id_doc_image;
    l_docimg_new_row.id_doc_external   := :new.id_doc_external;
    l_docimg_new_row.rank              := :new.rank;
    l_docimg_new_row.file_name         := :new.file_name;
    l_docimg_new_row.doc_img           := :new.doc_img;
    l_docimg_new_row.doc_img_thumbnail := :new.doc_img_thumbnail;
    l_docimg_new_row.flg_import        := :new.flg_import;
    l_docimg_new_row.server_file_name  := :new.server_file_name;
    l_docimg_new_row.flg_status        := :new.flg_status;
    l_docimg_new_row.id_professional   := :new.id_professional;
    l_docimg_new_row.flg_img_thumbnail := :new.flg_img_thumbnail;
    l_docimg_new_row.dt_img_tstz       := :new.dt_img_tstz;
    l_docimg_new_row.dt_import_tstz    := :new.dt_import_tstz;
    l_docimg_new_row.dt_cancel         := :new.dt_cancel;
    l_docimg_new_row.id_prof_cancel    := :new.id_prof_cancel;
    l_docimg_new_row.title             := :new.title;

    pk_api_ref_event.set_doc_image(i_lang           => l_id_language,
                                   i_prof           => l_prof,
                                   i_event          => l_event,
                                   i_docimg_old_row => l_docimg_old_row,
                                   i_docimg_new_row => l_docimg_new_row);
EXCEPTION
    WHEN OTHERS THEN
        pk_alertlog.log_error('ERROR IN ' || l_trigger_name || ' / DOC_EXTERNAL=' || l_docimg_new_row.id_doc_external ||
                              ' ID_DOC_IMAGE=' || l_docimg_new_row.id_doc_image || ' SQLERRM=' || SQLERRM);
END;
/
