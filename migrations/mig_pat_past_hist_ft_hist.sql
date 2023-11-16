-- Past Medical
UPDATE pat_past_hist_ft_hist pphfth
  SET pphfth.id_doc_area = 45
WHERE pphfth.id_doc_area IS NULL
  AND pphfth.flg_type = 'M';

-- Past Surgical
UPDATE pat_past_hist_ft_hist pphfth
  SET pphfth.id_doc_area = 46
 WHERE pphfth.id_doc_area IS NULL
   AND pphfth.flg_type = 'S';   

-- Congenital anomalies
UPDATE pat_past_hist_ft_hist pphfth
  SET pphfth.id_doc_area = 52
 WHERE pphfth.id_doc_area IS NULL
   AND pphfth.flg_type = 'A';
