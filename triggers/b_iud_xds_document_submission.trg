CREATE OR REPLACE TRIGGER B_IUD_XDS_DOCUMENT_SUBMISSION
    BEFORE INSERT OR UPDATE OR DELETE ON XDS_DOCUMENT_SUBMISSION
    FOR EACH ROW
BEGIN
    --TRIGGER TO CALL INTERALERT FUNCTION IN ORDER TO SUBMIT REPORT TO HIE XDS DOCUMENT REPOSITORY
    IF :new.flg_status != 'I' --If we change the status to Inactive we do not want to send to HIE
    THEN
        IF inserting or updating 
        THEN
            -- xds_document_new (new document submission)
            IF :new.flg_submission_status = pk_hie_xds.g_flg_submission_status_n
            THEN
               pk_ia_event_xds.xds_document_new(:new.id_institution, :new.id_doc_external);
               :new.flg_submission_status := pk_hie_xds.g_flg_submission_status_s;

            -- xds_document_upd (update document submission)
            ELSIF :new.flg_submission_status = pk_hie_xds.g_flg_submission_status_u
            THEN
                pk_ia_event_xds.xds_document_upd(:new.id_institution, :new.id_doc_external);
                :new.flg_submission_status := pk_hie_xds.g_flg_submission_status_s;

            -- xds_document_del (delete document submission)
            ELSIF :new.flg_submission_status = pk_hie_xds.g_flg_submission_status_d
            THEN
                pk_ia_event_xds.xds_document_del(:old.id_institution, :new.id_doc_external);
                :new.flg_submission_status := pk_hie_xds.g_flg_submission_status_s;
            END IF;

        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        alertlog.pk_alertlog.log_error('B_IUD_XDS_DOCUMENT_SUBMISSION-' || SQLERRM);
        :new.flg_submission_status := pk_hie_xds.g_flg_submission_status_x;

    
END b_iud_xds_document_submission;

--ELSIF DELETING
--      AND :OLD.FLG_SUBMISSION_STATUS = 'P'
--THEN
--    PK_IA_EVENT_XDS.XDS_DOCUMENT_DEL(:OLD.ID_INSTITUTION, :OLD.ID_DOC_EXTERNAL);
/
DROP TRIGGER B_IUD_XDS_DOCUMENT_SUBMISSION;
/