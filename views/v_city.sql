CREATE OR REPLACE view v_city AS 
SELECT id_city, code_city, id_geo_location, flg_available
  FROM city;