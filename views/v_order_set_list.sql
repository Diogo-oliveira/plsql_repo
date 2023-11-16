CREATE OR REPLACE VIEW V_ORDER_SET_LIST AS
SELECT odst.id_order_set,
       odst.title,
       odst.flg_status,
       odst.id_institution,
       odst.id_content,
       odst.id_professional,
       odst.flg_edit_permissions,
       odst.dt_order_set_tstz,
       prof.id_professional prof_id_profissional,
       alert_context('i_lang') l_lang,
       alert_context('i_prof_id') l_prof_id,
       alert_context('i_prof_institution') l_prof_institution,
       alert_context('i_prof_software') l_prof_software
  FROM order_set odst
	INNER JOIN order_set_link osl on osl.id_order_set = odst.id_order_set and osl.flg_link_type = 'I'
  LEFT OUTER JOIN professional prof
    ON (odst.id_professional = prof.id_professional)
 WHERE odst.flg_status NOT IN ('D', 'T')
   AND osl.id_link = alert_context('i_prof_institution');
              
             
