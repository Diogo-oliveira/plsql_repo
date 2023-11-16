create or replace view V_INSTITUTION_GROUP_ADT as
  select ig.id_institution, ig.id_group from institution i, institution_group ig where i.id_institution = ig.id_institution AND ig.flg_relation = 'ADT';
   