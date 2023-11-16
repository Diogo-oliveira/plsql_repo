create or replace view v_prof_room as
SELECT pr.id_prof_room,
       pr.id_professional,
       pr.id_room,
       d.id_institution,
			 r.id_department,
       pr.flg_pref,
       pr.id_sr_prof_shift,
       pr.id_category_sub
  FROM prof_room pr
 INNER JOIN room r
    ON (r.id_room = pr.id_room AND r.flg_available = 'Y')
 INNER JOIN department d
    ON (d.id_department = r.id_department AND d.flg_available = 'Y');
