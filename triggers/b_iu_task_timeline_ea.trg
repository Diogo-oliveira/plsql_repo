-- CHANGED BY: António Neto
-- CHANGE DATE: 01-02-2012 12:10
-- CHANGE REASON: [ALERT-216694] BD - Versioning Packages - Directions of meds are not being imported
CREATE OR REPLACE TRIGGER b_iu_task_timeline_ea
    BEFORE INSERT OR UPDATE ON task_timeline_ea

    FOR EACH ROW
BEGIN
    IF :new.id_task_aggregator IS NOT NULL
       AND :new.id_ref_group IS NULL
    THEN
        raise_application_error(-20001,
                                'Error INSERTING/UPDATING for TASK_TIMELINE_EA. Not possible an id_task_aggregator without an id_ref_group - id_task_refid: ' ||
                                :new.id_task_refid || ', id_ref_group: ' || :new.id_ref_group ||
                                ', id_task_aggregator: ' || :new.id_task_aggregator);
    END IF;
END b_iu_task_timeline_ea;
/
-- CHANGE END: António Neto