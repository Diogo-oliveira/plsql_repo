CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_PROFILES_PROF AS
SELECT 'Search in ACTIONS by your PFH LOGIN to check your professional profile' AS software_desc,
       NULL AS login,
       NULL AS profile_desc,
       NULL AS category_desc,
       NULL AS id_category,
       NULL AS id_profile
  FROM dual;

