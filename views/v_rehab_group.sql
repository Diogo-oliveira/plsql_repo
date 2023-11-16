CREATE OR REPLACE VIEW V_REHAB_GROUP AS
SELECT rg.id_rehab_group,
           rg.id_rehab_area,
           rg.name,
           rg.description,
           rg.id_institution,
           rg.id_professional,
           rg.dt_rehab_group,
           rg.flg_status,
           /*decode((SELECT COUNT(*)
              FROM rehab_group_prof rgp
             WHERE rgp.id_rehab_group = rg.id_rehab_group), 0, 'N', 'Y') flg_schedule*/
           'Y' flg_schedule  
      FROM rehab_group rg;
