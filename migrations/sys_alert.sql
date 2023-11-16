-- CHANGED BY: Ana Matos
-- CHANGE DATE: 22/11/2017 17:46
-- CHANGE REASON: [ALERT-334336] 
DECLARE

    CURSOR c_sys_alert IS
        SELECT *
          FROM sys_alert sa
         WHERE sa.id_sys_alert IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 20, 21, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 35, 36, 37, 39, 
         40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 83, 84, 85, 86, 87, 88, 
         89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 102, 103, 104, 105, 106, 107, 108, 110, 150, 201, 200, 208, 209, 210, 302, 303, 304, 305, 306, 310, 311, 
         312, 313, 314, 315, 316, 317, 320);

    l_sql_alert CLOB;

BEGIN

    FOR rec IN c_sys_alert
    LOOP
    
        l_sql_alert := 'SELECT id_sys_alert_det,
       id_reg,
       id_episode,
       id_institution,
       id_prof,
       dt_req,
       TIME,
       message,
       id_room,
       id_patient,
       name_pat,
       pat_ndo,
       pat_nd_icon,
       photo,
       gender,
       pat_age,
       desc_room,
       date_send,
       desc_epis_anamnesis,
       acuity,
       rank_acuity,
       id_schedule,
       id_sys_shortcut,
       id_reg_det,
       id_sys_alert,
       dt_first_obs_tstz,
       fast_track_icon,
       fast_track_color,
       fast_track_status,
       esi_level,
       name_pat_sort,
       id_prof_order
  FROM v_sys_alert_' || rec.id_sys_alert;
    
        UPDATE sys_alert
           SET sql_alert = l_sql_alert
         WHERE id_sys_alert = rec.id_sys_alert;
    END LOOP;

END;
/
-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 24/11/2017 16:02
-- CHANGE REASON: [ALERT-334360] 
DECLARE

    CURSOR c_sys_alert IS
        SELECT *
          FROM sys_alert sa
         WHERE sa.id_sys_alert IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 20, 21, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 35, 36, 37, 39, 
         40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 63, 64, 65, 72, 73, 74, 75, 76, 77, 79, 80, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 
				 94, 95, 96, 97, 98, 99, 102, 103, 104, 105, 106, 107, 108, 110, 150, 201, 200, 208, 209, 210, 302, 303, 304, 305, 306, 310, 311, 312, 313, 
				 314, 315, 316, 317, 320);

    l_sql_alert CLOB;

BEGIN

    FOR rec IN c_sys_alert
    LOOP
    
        l_sql_alert := 'SELECT id_sys_alert_det,
       id_reg,
       id_episode,
       id_institution,
       id_prof,
       dt_req,
       TIME,
       message,
       id_room,
       id_patient,
       name_pat,
       pat_ndo,
       pat_nd_icon,
       photo,
       gender,
       pat_age,
       desc_room,
       date_send,
       desc_epis_anamnesis,
       acuity,
       rank_acuity,
       id_schedule,
       id_sys_shortcut,
       id_reg_det,
       id_sys_alert,
       dt_first_obs_tstz,
       fast_track_icon,
       fast_track_color,
       fast_track_status,
       esi_level,
       name_pat_sort,
			 resp_icons,
       id_prof_order
  FROM v_sys_alert_' || rec.id_sys_alert;
    
        UPDATE sys_alert
           SET sql_alert = l_sql_alert
         WHERE id_sys_alert = rec.id_sys_alert;
    END LOOP;

END;
/
-- CHANGE END: Ana Matos
-- CHANGE END: Ana Matos