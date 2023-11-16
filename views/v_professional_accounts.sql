CREATE OR REPLACE view v_professional_accounts AS
    SELECT pa.id_professional, pa.id_account, pa.value, pa.id_institution
      FROM prof_accounts pa;
