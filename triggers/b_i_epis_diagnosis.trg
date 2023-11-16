CREATE OR REPLACE TRIGGER b_i_epis_diagnosis
    BEFORE INSERT ON epis_diagnosis
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM epis_diagnosis ed
      JOIN diagnosis d
        ON d.id_diagnosis = ed.id_diagnosis
     WHERE ed.id_episode = :new.id_episode
       AND ed.id_diagnosis = :new.id_diagnosis
       AND ed.id_alert_diagnosis = :new.id_alert_diagnosis
       AND ((ed.flg_type = :new.flg_type AND ed.flg_status != pk_diagnosis.g_diag_type_b) OR
           ed.flg_status = pk_diagnosis.g_diag_type_b)
       AND ((ed.desc_epis_diagnosis = :new.desc_epis_diagnosis AND
           nvl(d.flg_other, pk_alert_constant.g_no) = pk_alert_constant.g_yes) OR
           (nvl(d.flg_other, pk_alert_constant.g_no) != pk_alert_constant.g_yes AND :new.desc_epis_diagnosis IS NULL))
       AND ed.flg_status != pk_diagnosis.g_ed_flg_status_ca
       AND nvl(ed.id_diagnosis_condition, -999) = nvl(:new.id_diagnosis_condition, -999)
       AND nvl(ed.id_sub_analysis, -999) = nvl(:new.id_sub_analysis, -999)
       AND nvl(ed.id_anatomical_area, -999) = nvl(:new.id_anatomical_area, -999)
       AND nvl(ed.id_anatomical_side, -999) = nvl(:new.id_anatomical_side, -999);

    IF l_count > 0
    THEN
        raise_application_error(-20101, 'DIAG, TYPE AND DESC MUST BE UNIQUE IN EPISODE');
    END IF;
END;
/
