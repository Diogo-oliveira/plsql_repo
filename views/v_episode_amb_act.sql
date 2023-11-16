/*-- Last Change Revision: $Rev:$*/
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/

CREATE OR REPLACE view v_episode_amb_act AS
SELECT gea."ID_VISIT",
       gea."ID_PATIENT",
       gea."ID_INSTITUTION",
       gea."ID_EPISODE",
       gea."ID_CLINICAL_SERVICE",
       gea."ID_EPIS_TYPE",
       gea."FLG_TYPE",
       gea."ID_ROOM",
       r.desc_room,
       r.desc_room_abbreviation,
       r.code_room,
       r.code_abbreviation,
       gea."ID_PROFESSIONAL",
       gea."DESC_INFO",
       gea."ID_SCHEDULE",
       gea."ID_DEP_CLIN_SERV",
       gea."ID_DEPARTMENT",
       gea."ID_SOFTWARE",
       sp.dt_target_tstz,
       cr.num_clin_record,
       sp.flg_state, 
       gea.flg_ehr,
       gea.dt_begin_tstz
  FROM grids_ea gea
 INNER JOIN schedule_outp sp
    ON sp.id_schedule = gea.id_schedule
 INNER JOIN room r
    ON r.id_room = gea.id_room
 INNER JOIN clin_record cr
    ON cr.id_patient = gea.id_patient
    AND cr.id_institution = gea.id_institution
 WHERE gea.episode_flg_status = 'A'
   AND gea.id_software IN (1, 3, 12)
   AND gea.flg_ehr IN ('N', 'S')
   AND gea.id_announced_arrival IS NOT NULL;
/
