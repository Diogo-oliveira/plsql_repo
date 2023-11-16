
CREATE OR REPLACE VIEW V_PROF AS
SELECT su.desc_user,
       c.flg_type,
       p.nick_name,
       psi.id_software,
       psi.id_institution,
       p.id_professional,
       ppt.id_profile_template,
       pt.intern_name_templ,
			 s.desc_software
  FROM prof_cat              pc,
       category              c,
       finger_db.sys_user    su,
       professional          p,
       prof_soft_inst        psi,
       prof_profile_template ppt,
       profile_template      pt,
       software              s
 WHERE pc.id_category = c.id_category
   AND su.id_user = pc.id_professional
   AND p.id_professional = pc.id_professional
   AND psi.id_institution = pc.id_institution
   AND psi.id_professional = pc.id_professional
   AND ppt.id_professional = p.id_professional
   AND ppt.id_software = psi.id_software
   AND ppt.id_institution = psi.id_institution
   AND pt.id_software = ppt.id_software
   AND pt.id_profile_template = ppt.id_profile_template
   AND s.id_software = ppt.id_software;
   
   