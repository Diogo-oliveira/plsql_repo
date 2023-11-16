-- CHANGED BY: António Neto
-- CHANGE DATE: 27/04/2011 15:29
-- CHANGE REASON: [ALERT-174894] Set bmng_action and bmng_allocation_bed to outdated for free beds - Interaction between INPATIENT and SCHEDULE not complete on function set_bed_management

BEGIN
    DELETE FROM bmng_department_ea;

    FOR rec IN (SELECT dep1.id_department id_department,
                       nvl(nch_numbers.num_total_ocupied_nch_hours, 0) total_ocuppied_nch_hours,
                       nvl(beds_numbers.num_beds_blocked, 0) beds_blocked,
                       nvl(beds_numbers.num_beds_reserved, 0) beds_reserved,
                       nvl(beds_numbers.num_beds_occupied, 0) beds_ocuppied,
                       nch_numbers.num_total_avail_nch_hours total_avail_nch_hours,
                       nvl(beds_avail.num_avail_beds, 0) total_available_beds,
                       nvl(beds_occup.num_occup_beds, 0) total_unavailable_beds
                  FROM department dep1
                  LEFT JOIN (SELECT dep.id_department,
                                   nvl(COUNT(ba_blocked.flg_bed_status), 0) num_beds_blocked,
                                   COUNT(ba_reserved.flg_bed_status) num_beds_reserved,
                                   COUNT(ba_ocupied.flg_bed_status) num_beds_occupied
                              FROM department dep
                             INNER JOIN room roo ON (roo.id_department = dep.id_department AND roo.flg_available = 'Y')
                             INNER JOIN bed bed ON (bed.id_room = roo.id_room AND bed.flg_available = 'Y')
                              LEFT JOIN bmng_allocation_bed bab ON (bab.id_bed = bed.id_bed AND bab.flg_outdated = 'N')
                              LEFT JOIN bmng_action ba_blocked ON (ba_blocked.id_bed = bed.id_bed AND
                                                                  ba_blocked.id_room = roo.id_room AND
                                                                  ba_blocked.flg_status = 'A' AND
                                                                  ba_blocked.flg_bed_status = 'B' AND
                                                                  ba_blocked.flg_bed_ocupacity_status = 'V')
                              LEFT JOIN bmng_action ba_reserved ON (ba_reserved.id_bed = bed.id_bed AND
                                                                   ba_reserved.id_bmng_allocation_bed =
                                                                   bab.id_bmng_allocation_bed AND
                                                                   ba_reserved.id_room = roo.id_room AND
                                                                   ba_reserved.flg_status = 'A' AND
                                                                   ba_reserved.flg_bed_status = 'R' AND
                                                                   ba_reserved.flg_bed_ocupacity_status = 'O')
                              LEFT JOIN bmng_action ba_ocupied ON (ba_ocupied.id_bed = bed.id_bed AND
                                                                  ba_ocupied.id_bmng_allocation_bed =
                                                                  bab.id_bmng_allocation_bed AND
                                                                  ba_ocupied.id_room = roo.id_room AND
                                                                  ba_ocupied.flg_status = 'A' AND
                                                                  ba_ocupied.flg_bed_status = 'N' AND
                                                                  ba_ocupied.flg_bed_ocupacity_status = 'O')
                             WHERE dep.flg_available = 'Y'
                             GROUP BY dep.id_department) beds_numbers ON (beds_numbers.id_department =
                                                                         dep1.id_department)
                  LEFT JOIN (
                            
                            SELECT data.id_department,
                                    data.num_total_ocupied_nch_hours,
                                    SUM(data.nch_capacity) num_total_avail_nch_hours
                              FROM (SELECT dep2.id_department,
                                            pk_bmng_core.get_nch_service_level(2,
                                                                               profissional(142, dep2.id_institution, 11),
                                                                               dep2.id_department) num_total_ocupied_nch_hours,
                                            
                                            ba_avail_nch.nch_capacity
                                       FROM department dep2
                                      INNER JOIN bmng_action ba_avail_nch ON (ba_avail_nch.id_department =
                                                                             dep2.id_department AND
                                                                             ba_avail_nch.flg_target_action = 'S' AND
                                                                             ba_avail_nch.flg_status = 'A' AND
                                                                             ba_avail_nch.flg_origin_action IN
                                                                             ('NB', 'NT', 'ND'))
                                                                         AND ba_avail_nch.dt_begin_action <=
                                                                             current_timestamp
                                                                         AND (ba_avail_nch.dt_end_action >=
                                                                             current_timestamp OR
                                                                             ba_avail_nch.dt_end_action IS NULL)
                                      WHERE dep2.flg_available = 'Y') data
                             GROUP BY data.id_department, data.num_total_ocupied_nch_hours) nch_numbers ON (nch_numbers.id_department =
                                                                                                           dep1.id_department)
                  LEFT JOIN (SELECT COUNT(b1.id_bed) num_avail_beds, r1.id_department
                              FROM bmng_action ba
                             INNER JOIN bed b1 ON (b1.id_bed = ba.id_bed AND b1.flg_available = 'Y')
                             INNER JOIN room r1 ON (r1.id_room = b1.id_room AND r1.flg_available = 'Y')
                             WHERE b1.flg_type = 'P'
                               AND ba.flg_status = 'A'
                               AND ba.flg_bed_ocupacity_status <> 'O'
                               AND ba.flg_bed_status = 'N'
                             GROUP BY r1.id_department) beds_avail ON (beds_avail.id_department = dep1.id_department)
                  LEFT JOIN (SELECT COUNT(b2.id_bed) num_occup_beds, r2.id_department
                              FROM bmng_action ba
                             INNER JOIN bed b2 ON (b2.id_bed = ba.id_bed AND b2.flg_available = 'Y')
                             INNER JOIN room r2 ON (r2.id_room = b2.id_room AND r2.flg_available = 'Y')
                              LEFT JOIN bmng_allocation_bed bab ON (bab.id_bed = b2.id_bed AND bab.flg_outdated = 'N')
                             WHERE ba.flg_status = 'A'
                               AND ((ba.flg_bed_ocupacity_status = 'O' AND
                                   bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed) OR ba.flg_bed_status = 'B')
                             GROUP BY r2.id_department) beds_occup ON (beds_occup.id_department = dep1.id_department)
                 WHERE dep1.flg_available = 'Y'
                   AND instr(dep1.flg_type, 'I') > 0)
    LOOP
        INSERT INTO bmng_department_ea
            (id_department,
             total_ocuppied_nch_hours,
             total_unavailable_beds,
             beds_blocked,
             beds_reserved,
             beds_ocuppied,
             total_available_beds,
             total_avail_nch_hours,
             dt_dg_last_update)
        VALUES
            (rec.id_department,
             rec.total_ocuppied_nch_hours,
             rec.total_unavailable_beds,
             rec.beds_blocked,
             rec.beds_reserved,
             rec.beds_ocuppied,
             rec.total_available_beds,
             rec.total_avail_nch_hours,
             current_timestamp);
    END LOOP;
END;
/

-- CHANGE END: António Neto


-- CHANGED BY: António Neto
-- CHANGE DATE: 27/04/2011 15:38
-- CHANGE REASON: [ALERT-174894] Set bmng_action and bmng_allocation_bed to outdated for free beds - Interaction between INPATIENT and SCHEDULE not complete on function set_bed_management

BEGIN
    DELETE FROM bmng_department_ea;

    FOR rec IN (SELECT dep1.id_department id_department,
                       nvl(nch_numbers.num_total_ocupied_nch_hours, 0) total_ocuppied_nch_hours,
                       nvl(beds_numbers.num_beds_blocked, 0) beds_blocked,
                       nvl(beds_numbers.num_beds_reserved, 0) beds_reserved,
                       nvl(beds_numbers.num_beds_occupied, 0) beds_ocuppied,
                       nch_numbers.num_total_avail_nch_hours total_avail_nch_hours,
                       nvl(beds_avail.num_avail_beds, 0) total_available_beds,
                       nvl(beds_occup.num_occup_beds, 0) total_unavailable_beds
                  FROM department dep1
                  LEFT JOIN (SELECT dep.id_department,
                                   nvl(COUNT(ba_blocked.flg_bed_status), 0) num_beds_blocked,
                                   COUNT(ba_reserved.flg_bed_status) num_beds_reserved,
                                   COUNT(ba_ocupied.flg_bed_status) num_beds_occupied
                              FROM department dep
                             INNER JOIN room roo ON (roo.id_department = dep.id_department AND roo.flg_available = 'Y')
                             INNER JOIN bed bed ON (bed.id_room = roo.id_room AND bed.flg_available = 'Y')
                              LEFT JOIN bmng_allocation_bed bab ON (bab.id_bed = bed.id_bed AND bab.flg_outdated = 'N')
                              LEFT JOIN bmng_action ba_blocked ON (ba_blocked.id_bed = bed.id_bed AND
                                                                  ba_blocked.id_room = roo.id_room AND
                                                                  ba_blocked.flg_status = 'A' AND
                                                                  ba_blocked.flg_bed_status = 'B' AND
                                                                  ba_blocked.flg_bed_ocupacity_status = 'V')
                              LEFT JOIN bmng_action ba_reserved ON (ba_reserved.id_bed = bed.id_bed AND
                                                                   ba_reserved.id_bmng_allocation_bed =
                                                                   bab.id_bmng_allocation_bed AND
                                                                   ba_reserved.id_room = roo.id_room AND
                                                                   ba_reserved.flg_status = 'A' AND
                                                                   ba_reserved.flg_bed_status = 'R' AND
                                                                   ba_reserved.flg_bed_ocupacity_status = 'O')
                              LEFT JOIN bmng_action ba_ocupied ON (ba_ocupied.id_bed = bed.id_bed AND
                                                                  ba_ocupied.id_bmng_allocation_bed =
                                                                  bab.id_bmng_allocation_bed AND
                                                                  ba_ocupied.id_room = roo.id_room AND
                                                                  ba_ocupied.flg_status = 'A' AND
                                                                  ba_ocupied.flg_bed_status = 'N' AND
                                                                  ba_ocupied.flg_bed_ocupacity_status = 'O')
                             WHERE dep.flg_available = 'Y'
                             GROUP BY dep.id_department) beds_numbers ON (beds_numbers.id_department =
                                                                         dep1.id_department)
                  LEFT JOIN (
                            
                            SELECT data.id_department,
                                    data.num_total_ocupied_nch_hours,
                                    SUM(data.nch_capacity) num_total_avail_nch_hours
                              FROM (SELECT dep2.id_department,
                                            pk_bmng_core.get_nch_service_level(2,
                                                                               profissional(142, dep2.id_institution, 11),
                                                                               dep2.id_department) num_total_ocupied_nch_hours,
                                            
                                            ba_avail_nch.nch_capacity
                                       FROM department dep2
                                      INNER JOIN bmng_action ba_avail_nch ON (ba_avail_nch.id_department =
                                                                             dep2.id_department AND
                                                                             ba_avail_nch.flg_target_action = 'S' AND
                                                                             ba_avail_nch.flg_status = 'A' AND
                                                                             ba_avail_nch.flg_origin_action IN
                                                                             ('NB', 'NT', 'ND'))
                                                                         AND ba_avail_nch.dt_begin_action <=
                                                                             current_timestamp
                                                                         AND (ba_avail_nch.dt_end_action >=
                                                                             current_timestamp OR
                                                                             ba_avail_nch.dt_end_action IS NULL)
                                      WHERE dep2.flg_available = 'Y') data
                             GROUP BY data.id_department, data.num_total_ocupied_nch_hours) nch_numbers ON (nch_numbers.id_department =
                                                                                                           dep1.id_department)
                  LEFT JOIN (SELECT COUNT(b1.id_bed) num_avail_beds, r1.id_department
                              FROM bmng_action ba
                             INNER JOIN bed b1 ON (b1.id_bed = ba.id_bed AND b1.flg_available = 'Y')
                             INNER JOIN room r1 ON (r1.id_room = b1.id_room AND r1.flg_available = 'Y')
                             WHERE b1.flg_type = 'P'
                               AND ba.flg_status = 'A'
                               AND ba.flg_bed_ocupacity_status <> 'O'
                               AND ba.flg_bed_status = 'N'
                             GROUP BY r1.id_department) beds_avail ON (beds_avail.id_department = dep1.id_department)
                  LEFT JOIN (SELECT COUNT(b2.id_bed) num_occup_beds, r2.id_department
                              FROM bmng_action ba
                             INNER JOIN bed b2 ON (b2.id_bed = ba.id_bed AND b2.flg_available = 'Y')
                             INNER JOIN room r2 ON (r2.id_room = b2.id_room AND r2.flg_available = 'Y')
                              LEFT JOIN bmng_allocation_bed bab ON (bab.id_bed = b2.id_bed AND bab.flg_outdated = 'N')
                             WHERE ba.flg_status = 'A'
                               AND ((ba.flg_bed_ocupacity_status = 'O' AND
                                   bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed) OR ba.flg_bed_status = 'B')
                             GROUP BY r2.id_department) beds_occup ON (beds_occup.id_department = dep1.id_department)
                 WHERE dep1.flg_available = 'Y'
                   AND instr(dep1.flg_type, 'I') > 0)
    LOOP
        INSERT INTO bmng_department_ea
            (id_department,
             total_ocuppied_nch_hours,
             total_unavailable_beds,
             beds_blocked,
             beds_reserved,
             beds_ocuppied,
             total_available_beds,
             total_avail_nch_hours,
             dt_dg_last_update)
        VALUES
            (rec.id_department,
             rec.total_ocuppied_nch_hours,
             rec.total_unavailable_beds,
             rec.beds_blocked,
             rec.beds_reserved,
             rec.beds_ocuppied,
             rec.total_available_beds,
             rec.total_avail_nch_hours,
             current_timestamp);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
		NULL;
END;
/

-- CHANGE END: António Neto

