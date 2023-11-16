--Changed by: Diamantino Campos
--Date:on 29-04-2011
--Reason: APS-1242 To have the category of the professional so that is possible to create an accurate resource type for the professional
CREATE OR REPLACE VIEW V_SCH_PROFESSIONAL AS
SELECT pi.id_institution,
       p.id_professional,
       p.nick_name,
       p.title,
       p.gender,
       p.work_phone,
       p.cell_phone,
       decode(pi.dt_end_tstz, NULL, 'A', 'I') prof_state,
       p.email,
       p.name,
       pi.flg_state flg_available,
       c.id_category,
       c.code_category
  FROM professional p
  JOIN prof_institution pi ON pi.id_professional = p.id_professional AND pi.flg_schedulable = 'Y'
  join prof_cat pc on pc.id_professional = p.id_professional and pc.id_institution = pi.id_institution
  join category c on c.id_category = pc.id_category;
-- CHANGE END: DC
