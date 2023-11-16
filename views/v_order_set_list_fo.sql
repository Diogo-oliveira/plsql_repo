CREATE OR REPLACE VIEW v_order_set_list_fo AS
SELECT odst.id_order_set,
       odst.title,
       alert_context('i_lang') l_lang,
       alert_context('i_prof_id') l_prof_id,
       alert_context('i_prof_institution') l_prof_institution,
       alert_context('i_prof_software') l_prof_software
  FROM order_set odst
	--INNER JOIN order_set_link osl on osl.id_order_set = odst.id_order_set and osl.flg_link_type = 'I'
 WHERE odst.id_institution = alert_context('i_prof_institution')
   AND odst.flg_status = 'F'
      -- verify professional use grants
   AND nvl((SELECT 'Y'
             FROM professional prof_edit
            WHERE prof_edit.id_professional = alert_context('i_prof_id')
              AND (
                  -- verify if professional is the author
                   odst.id_professional = alert_context('i_prof_id') OR
                  -- verify if professional has the same specialty as the author
                   (odst.flg_target_professionals = 'S' AND
                   nvl(prof_edit.id_speciality, -1) IN nvl((SELECT odst_lnk.id_link
                                                              FROM order_set_link odst_lnk
                                                             WHERE odst_lnk.id_order_set = odst.id_order_set
                                                               AND odst_lnk.flg_link_type = 'S'),
                                                            -1)) OR
                  -- verify if professional has the same category as the author
                   (odst.flg_target_professionals = 'C' AND
                   alert_context('i_category') = (SELECT pk_prof_utils.get_id_category(alert_context('i_lang'),
                                                                                        profissional(odst.id_professional,
                                                                                                     alert_context('i_prof_institution'),
                                                                                                     alert_context('i_prof_software')))
                                                     FROM dual)) OR
                  -- doesn't matter the specialty or category of the professional
                   odst.flg_target_professionals = 'A')),
           'N') = 'Y'
		AND alert_context('i_prof_software') IN (SELECT sd.id_software
                                             FROM software_dept sd, order_set_link odst_link
                                            WHERE odst_link.id_order_set = odst.id_order_set
                                              AND odst_link.flg_link_type = 'E'
                                              AND odst_link.id_link = sd.id_dept);
