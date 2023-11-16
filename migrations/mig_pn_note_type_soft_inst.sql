-- CHANGED BY: António Neto
-- CHANGE DATE: 02/01/2012
-- CHANGE REASON: [ALERT-211833] Fix findings - Solve findings identified by Technical Arq. BD
BEGIN
    EXECUTE IMMEDIATE 'UPDATE pn_note_type_soft_inst pnnt
       SET pnnt.flg_edit_after_disch = pnnt.flg_editable_after_discharge
     WHERE pnnt.flg_editable_after_discharge IS NOT NULL
       AND pnnt.flg_edit_after_disch IS NULL';
EXCEPTION
    WHEN OTHERS THEN
		    --If Column dropped after running first upgrade ignore error (AN)
        IF SQLCODE <> '-904'
        THEN
            RAISE;
        END IF;
END;
/
--CHANGE END: António Neto
