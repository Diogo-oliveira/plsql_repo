CREATE OR REPLACE VIEW V_CATEGORY_SUB AS
SELECT id_category_sub,
       id_category,
       code_category_sub,
       flg_available,
       flg_type,
       rank,
       num_prof
  FROM category_sub;