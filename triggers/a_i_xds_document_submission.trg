-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 27/11/2009 21:12
-- CHANGE REASON: [PIX-341] HIE XDS Content Creator module in Alert
CREATE OR REPLACE TRIGGER a_i_xds_document_submission
    AFTER INSERT ON xds_document_submission
    FOR EACH ROW
BEGIN
    --Trigger to call InterAlert function in order to submit report to HIE XDS document repository
    IF inserting
    THEN
        pk_ia_event_xds.xds_document_new(:NEW.id_institution, :NEW.id_doc_external);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        alertlog.pk_alertlog.log_error('A_I_XDS_DOCUMENT_SUBMISSION-' || SQLERRM);

END a_i_xds_document_submission;
/
-- CHANGE END: Ariel Machado


drop TRIGGER a_i_xds_document_submission;