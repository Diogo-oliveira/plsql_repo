-- CHANGED BY: António Neto
-- CHANGE DATE: 27/04/2011 15:28
-- CHANGE REASON: [ALERT-174894] Set bmng_action and bmng_allocation_bed to outdated for free beds - Interaction between INPATIENT and SCHEDULE not complete on function set_bed_management

DECLARE
    l_dt_end bmng_bed_ea.dt_end%TYPE;
BEGIN

    DELETE FROM bmng_bed_ea;

    FOR rec IN (SELECT ba.id_bmng_action,
                       bed.id_bed,
                       ba.dt_begin_action dt_begin,
                       ba.dt_end_action dt_end,
                       ba.id_bmng_reason_type,
                       ba.id_bmng_reason,
                       bab.id_episode,
                       bab.id_patient,
                       roo.id_room,
                       dep.id_admission_type,
                       roo.id_room_type,
                       bab.id_bmng_allocation_bed,
                       bed.id_bed_type,
                       dep.id_department,
                       ds.dt_discharge_schedule,
                       nvl(en.flg_type, decode(nl.id_nch_level, NULL, NULL, 'U')) flg_type,
                       ai.id_nch_level,
                       CASE
                            WHEN bab.id_bmng_allocation_bed IS NULL
                                 AND ba.flg_bed_status IN ('N', 'R') THEN
                             'V'
                            ELSE
                             nvl(ba.flg_bed_ocupacity_status, bed.flg_status)
                        END flg_bed_ocupacity_status,
                       CASE
                            WHEN bab.id_bmng_allocation_bed IS NULL
                                 AND ba.flg_bed_status IN ('N', 'R') THEN
                             'N'
                            ELSE
                             ba.flg_bed_status
                        END flg_bed_status,
                       ba.flg_bed_cleaning_status,
                       bed.flg_type flg_bed_type,
                       decode(ba.action_notes, NULL, 'N', 'Y') has_notes,
                       ba.flg_action
                  FROM bmng_action ba
                  LEFT JOIN bmng_allocation_bed bab ON (bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed AND
                                                       bab.flg_outdated = 'N')
                  LEFT JOIN epis_nch en ON (en.id_epis_nch = bab.id_epis_nch AND en.flg_status = 'A')
                  LEFT JOIN bed bed ON (ba.id_bed = bed.id_bed AND bed.flg_available = 'Y')
                  LEFT JOIN room roo ON (roo.id_room = bed.id_room AND roo.flg_available = 'Y')
                 INNER JOIN department dep ON (dep.id_department = ba.id_department AND dep.flg_available = 'Y')
                  LEFT JOIN discharge_schedule ds ON (ds.id_episode = bab.id_episode AND ds.flg_status = 'Y')
                  LEFT JOIN adm_request ar ON (ar.id_dest_episode = bab.id_episode)
                  LEFT JOIN adm_indication ai ON (ai.id_adm_indication = ar.id_adm_indication)
                  LEFT JOIN nch_level nl ON nl.id_previous = ai.id_nch_level
                 WHERE ba.flg_status = 'A'
                   AND instr(dep.flg_type, 'I') > 0)
    LOOP
    
        IF rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_b
           OR rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_u
           OR rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_bt
           OR rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_ut
        THEN
            l_dt_end := rec.dt_end;
        ELSE
            l_dt_end := NULL;
        END IF;
    
        INSERT INTO bmng_bed_ea
            (id_bmng_action,
             id_bed,
             dt_begin,
             dt_end,
             id_bmng_reason_type,
             id_bmng_reason,
             id_episode,
             id_patient,
             id_room,
             id_admission_type,
             id_room_type,
             id_bmng_allocation_bed,
             id_bed_type,
             dt_discharge_schedule,
             flg_allocation_nch,
             id_nch_level,
             flg_bed_ocupacity_status,
             flg_bed_status,
             flg_bed_cleaning_status,
             has_notes,
             flg_bed_type,
             id_department,
             dt_dg_last_update)
        VALUES
            (rec.id_bmng_action,
             rec.id_bed,
             rec.dt_begin,
             l_dt_end,
             rec.id_bmng_reason_type,
             rec.id_bmng_reason,
             rec.id_episode,
             rec.id_patient,
             rec.id_room,
             rec.id_admission_type,
             rec.id_room_type,
             rec.id_bmng_allocation_bed,
             rec.id_bed_type,
             rec.dt_discharge_schedule,
             rec.flg_type,
             rec.id_nch_level,
             rec.flg_bed_ocupacity_status,
             rec.flg_bed_status,
             rec.flg_bed_cleaning_status,
             rec.has_notes,
             rec.flg_bed_type,
             rec.id_department,
             current_timestamp);
    
    END LOOP;
END;
/

-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 27/04/2011 15:37
-- CHANGE REASON: [ALERT-174894] Set bmng_action and bmng_allocation_bed to outdated for free beds - Interaction between INPATIENT and SCHEDULE not complete on function set_bed_management

DECLARE
    l_dt_end bmng_bed_ea.dt_end%TYPE;
BEGIN

    DELETE FROM bmng_bed_ea;

    FOR rec IN (SELECT ba.id_bmng_action,
                       bed.id_bed,
                       ba.dt_begin_action dt_begin,
                       ba.dt_end_action dt_end,
                       ba.id_bmng_reason_type,
                       ba.id_bmng_reason,
                       bab.id_episode,
                       bab.id_patient,
                       roo.id_room,
                       dep.id_admission_type,
                       roo.id_room_type,
                       bab.id_bmng_allocation_bed,
                       bed.id_bed_type,
                       dep.id_department,
                       ds.dt_discharge_schedule,
                       nvl(en.flg_type, decode(nl.id_nch_level, NULL, NULL, 'U')) flg_type,
                       ai.id_nch_level,
                       CASE
                            WHEN bab.id_bmng_allocation_bed IS NULL
                                 AND ba.flg_bed_status IN ('N', 'R') THEN
                             'V'
                            ELSE
                             nvl(ba.flg_bed_ocupacity_status, bed.flg_status)
                        END flg_bed_ocupacity_status,
                       CASE
                            WHEN bab.id_bmng_allocation_bed IS NULL
                                 AND ba.flg_bed_status IN ('N', 'R') THEN
                             'N'
                            ELSE
                             ba.flg_bed_status
                        END flg_bed_status,
                       ba.flg_bed_cleaning_status,
                       bed.flg_type flg_bed_type,
                       decode(ba.action_notes, NULL, 'N', 'Y') has_notes,
                       ba.flg_action
                  FROM bmng_action ba
                  LEFT JOIN bmng_allocation_bed bab ON (bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed AND
                                                       bab.flg_outdated = 'N')
                  LEFT JOIN epis_nch en ON (en.id_epis_nch = bab.id_epis_nch AND en.flg_status = 'A')
                  LEFT JOIN bed bed ON (ba.id_bed = bed.id_bed AND bed.flg_available = 'Y')
                  LEFT JOIN room roo ON (roo.id_room = bed.id_room AND roo.flg_available = 'Y')
                 INNER JOIN department dep ON (dep.id_department = ba.id_department AND dep.flg_available = 'Y')
                  LEFT JOIN discharge_schedule ds ON (ds.id_episode = bab.id_episode AND ds.flg_status = 'Y')
                  LEFT JOIN adm_request ar ON (ar.id_dest_episode = bab.id_episode)
                  LEFT JOIN adm_indication ai ON (ai.id_adm_indication = ar.id_adm_indication)
                  LEFT JOIN nch_level nl ON nl.id_previous = ai.id_nch_level
                 WHERE ba.flg_status = 'A'
                   AND instr(dep.flg_type, 'I') > 0)
    LOOP
    
        IF rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_b
           OR rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_u
           OR rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_bt
           OR rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_ut
        THEN
            l_dt_end := rec.dt_end;
        ELSE
            l_dt_end := NULL;
        END IF;
    
        INSERT INTO bmng_bed_ea
            (id_bmng_action,
             id_bed,
             dt_begin,
             dt_end,
             id_bmng_reason_type,
             id_bmng_reason,
             id_episode,
             id_patient,
             id_room,
             id_admission_type,
             id_room_type,
             id_bmng_allocation_bed,
             id_bed_type,
             dt_discharge_schedule,
             flg_allocation_nch,
             id_nch_level,
             flg_bed_ocupacity_status,
             flg_bed_status,
             flg_bed_cleaning_status,
             has_notes,
             flg_bed_type,
             id_department,
             dt_dg_last_update)
        VALUES
            (rec.id_bmng_action,
             rec.id_bed,
             rec.dt_begin,
             l_dt_end,
             rec.id_bmng_reason_type,
             rec.id_bmng_reason,
             rec.id_episode,
             rec.id_patient,
             rec.id_room,
             rec.id_admission_type,
             rec.id_room_type,
             rec.id_bmng_allocation_bed,
             rec.id_bed_type,
             rec.dt_discharge_schedule,
             rec.flg_type,
             rec.id_nch_level,
             rec.flg_bed_ocupacity_status,
             rec.flg_bed_status,
             rec.flg_bed_cleaning_status,
             rec.has_notes,
             rec.flg_bed_type,
             rec.id_department,
             current_timestamp);
    
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
		NULL;
END;
/

-- CHANGE END: António Neto


-- CHANGED BY: António Neto
-- CHANGE DATE: 27/04/2011 15:39
-- CHANGE REASON: [ALERT-174894] Set bmng_action and bmng_allocation_bed to outdated for free beds - Interaction between INPATIENT and SCHEDULE not complete on function set_bed_management

DECLARE
    l_dt_end bmng_bed_ea.dt_end%TYPE;
BEGIN

    DELETE FROM bmng_bed_ea;

    FOR rec IN (SELECT ba.id_bmng_action,
                       bed.id_bed,
                       ba.dt_begin_action dt_begin,
                       ba.dt_end_action dt_end,
                       ba.id_bmng_reason_type,
                       ba.id_bmng_reason,
                       bab.id_episode,
                       bab.id_patient,
                       roo.id_room,
                       dep.id_admission_type,
                       roo.id_room_type,
                       bab.id_bmng_allocation_bed,
                       bed.id_bed_type,
                       dep.id_department,
                       ds.dt_discharge_schedule,
                       nvl(en.flg_type, decode(nl.id_nch_level, NULL, NULL, 'U')) flg_type,
                       ai.id_nch_level,
                       CASE
                            WHEN bab.id_bmng_allocation_bed IS NULL
                                 AND ba.flg_bed_status IN ('N', 'R') THEN
                             'V'
                            ELSE
                             nvl(ba.flg_bed_ocupacity_status, bed.flg_status)
                        END flg_bed_ocupacity_status,
                       CASE
                            WHEN bab.id_bmng_allocation_bed IS NULL
                                 AND ba.flg_bed_status IN ('N', 'R') THEN
                             'N'
                            ELSE
                             ba.flg_bed_status
                        END flg_bed_status,
                       ba.flg_bed_cleaning_status,
                       bed.flg_type flg_bed_type,
                       decode(ba.action_notes, NULL, 'N', 'Y') has_notes,
                       ba.flg_action
                  FROM bmng_action ba
                  LEFT JOIN bmng_allocation_bed bab ON (bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed AND
                                                       bab.flg_outdated = 'N')
                  LEFT JOIN epis_nch en ON (en.id_epis_nch = bab.id_epis_nch AND en.flg_status = 'A')
                  LEFT JOIN bed bed ON (ba.id_bed = bed.id_bed AND bed.flg_available = 'Y')
                  LEFT JOIN room roo ON (roo.id_room = bed.id_room AND roo.flg_available = 'Y')
                 INNER JOIN department dep ON (dep.id_department = ba.id_department AND dep.flg_available = 'Y')
                  LEFT JOIN discharge_schedule ds ON (ds.id_episode = bab.id_episode AND ds.flg_status = 'Y')
                  LEFT JOIN adm_request ar ON (ar.id_dest_episode = bab.id_episode)
                  LEFT JOIN adm_indication ai ON (ai.id_adm_indication = ar.id_adm_indication)
                  LEFT JOIN nch_level nl ON nl.id_previous = ai.id_nch_level
                 WHERE ba.flg_status = 'A'
                   AND instr(dep.flg_type, 'I') > 0)
    LOOP
    
        IF rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_b
           OR rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_u
           OR rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_bt
           OR rec.flg_action = pk_bmng_constant.g_bmng_flg_origin_ux_ut
        THEN
            l_dt_end := rec.dt_end;
        ELSE
            l_dt_end := NULL;
        END IF;
    
        INSERT INTO bmng_bed_ea
            (id_bmng_action,
             id_bed,
             dt_begin,
             dt_end,
             id_bmng_reason_type,
             id_bmng_reason,
             id_episode,
             id_patient,
             id_room,
             id_admission_type,
             id_room_type,
             id_bmng_allocation_bed,
             id_bed_type,
             dt_discharge_schedule,
             flg_allocation_nch,
             id_nch_level,
             flg_bed_ocupacity_status,
             flg_bed_status,
             flg_bed_cleaning_status,
             has_notes,
             flg_bed_type,
             id_department,
             dt_dg_last_update)
        VALUES
            (rec.id_bmng_action,
             rec.id_bed,
             rec.dt_begin,
             l_dt_end,
             rec.id_bmng_reason_type,
             rec.id_bmng_reason,
             rec.id_episode,
             rec.id_patient,
             rec.id_room,
             rec.id_admission_type,
             rec.id_room_type,
             rec.id_bmng_allocation_bed,
             rec.id_bed_type,
             rec.dt_discharge_schedule,
             rec.flg_type,
             rec.id_nch_level,
             rec.flg_bed_ocupacity_status,
             rec.flg_bed_status,
             rec.flg_bed_cleaning_status,
             rec.has_notes,
             rec.flg_bed_type,
             rec.id_department,
             current_timestamp);
    
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
		NULL;
END;
/

-- CHANGE END: António Neto